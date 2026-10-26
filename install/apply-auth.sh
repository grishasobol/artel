#!/usr/bin/env bash
# Configures harness logins inside the container as the current user.
# Secrets are never printed. The environment is preserved for shells and systemd --user.
set -u
set -o pipefail

HOME_DIR="${HOME:-/home/artel}"
AUTH_FILE="$HOME_DIR/.config/artel/auth.json"
CHECK=0
FORCE=0
SKIP_LIST=""
ONLY_LIST=""

usage() {
  echo "usage: apply-auth.sh [--check] [--force] [--skip <harness>[,…]] [--only <harness>[,…]] [auth-file.json]" >&2
  return 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) CHECK=1; shift ;;
    --force) FORCE=1; shift ;;
    --skip|--only)
      [ "$#" -ge 2 ] || { usage; exit $?; }
      if [ "$1" = "--skip" ]; then SKIP_LIST="$SKIP_LIST,$2"; else ONLY_LIST="$ONLY_LIST,$2"; fi
      shift 2
      ;;
    --) shift; break ;;
    -*) usage; exit $? ;;
    *) AUTH_FILE="$1"; shift ;;
  esac
done
[ "$#" -eq 0 ] || { usage; exit $?; }

if [ ! -r "$AUTH_FILE" ]; then
  echo "apply-auth: auth file is unavailable" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "apply-auth: jq is required" >&2
  exit 1
fi

JSON_TMP="$(mktemp "${TMPDIR:-/tmp}/artel-auth.XXXXXX" 2>/dev/null)" || {
  echo "apply-auth: could not prepare temporary file" >&2
  exit 1
}
cleanup() {
  rm -f "$JSON_TMP"
}
trap cleanup EXIT

if ! sed -E '/^[[:space:]]*\/\//d' "$AUTH_FILE" > "$JSON_TMP" 2>/dev/null; then
  echo "apply-auth: auth file cannot be read" >&2
  exit 1
fi
if ! jq empty "$JSON_TMP" >/dev/null 2>&1; then
  echo "apply-auth: auth file contains invalid JSON" >&2
  exit 1
fi

PARTIAL=0
AUTH_ENV="$HOME_DIR/.config/artel/auth.env"
SYSTEMD_ENV="$HOME_DIR/.config/environment.d/20-artel-auth.conf"

declare -a ENV_NAMES=()
declare -a REMOVE_NAMES=()
declare -A ENV_VALUES=()

json_value() {
  local expr="$1"
  jq -r "$expr // empty" "$JSON_TMP" 2>/dev/null
}

section_skip() {
  # Skip: the --skip/--only flag or "skip": true in the file section.
  local harness="$1"
  case ",$SKIP_LIST," in *",$harness,"*) return 0 ;; esac
  if [ -n "$ONLY_LIST" ]; then
    case ",$ONLY_LIST," in *",$harness,"*) ;; *) return 0 ;; esac
  fi
  jq -e --arg h "$harness" '.[$h].skip == true' "$JSON_TMP" >/dev/null 2>&1
}

# section_method <harness>: login method from the file, empty if its value is still the REPLACE_ME placeholder.
# Otherwise --check prints “method=api_key” for a section that apply skipped as having no data.
section_method() {
  local harness="$1" method field value
  method="$(json_value ".${harness}.method")"
  [ -n "$method" ] || return 0
  case "$method" in
    oauth_token) field=oauth_token ;;
    api_key) field=api_key ;;
    chatgpt) field=auth_json ;;
    gemini_api_key) field=gemini_api_key ;;
    keyring_token) field=token ;;
    *) printf '%s' "$method"; return 0 ;;
  esac
  value="$(jq -c --arg h "$harness" --arg f "$field" '.[$h][$f] // empty' "$JSON_TMP" 2>/dev/null)"
  if usable "$value"; then printf '%s' "$method"; else printf '%s' "$method (placeholder, no data)"; fi
}

usable() {
  local value="${1:-}"
  [ -n "$value" ] || return 1
  case "$value" in
    *REPLACE_ME*) return 1 ;;
  esac
  return 0
}

add_env() {
  local key="$1" value="$2" n
  case "$key" in
    [A-Za-z_][A-Za-z0-9_]*) ;;
    *)
      echo "apply-auth: environment variable skipped" >&2
      PARTIAL=1
      return 1
      ;;
  esac
  ENV_VALUES["$key"]="$value"
  export "$key=$value"
  for n in "${ENV_NAMES[@]}"; do
    [ "$n" = "$key" ] && return 0
  done
  ENV_NAMES+=("$key")
  return 0
}

mark_managed() {
  local key="$1" n
  for n in "${REMOVE_NAMES[@]}"; do
    [ "$n" = "$key" ] && return 0
  done
  REMOVE_NAMES+=("$key")
}

shell_quote() {
  local value="$1"
  value=${value//\'/\'\\\'\'}
  printf "'%s'" "$value"
}

remove_active_lines() {
  local file="$1" key backup
  [ -f "$file" ] || return 0
  for key in "${REMOVE_NAMES[@]}"; do
    backup="$file.bak"
    if ! sed -E "/^[[:space:]]*(export[[:space:]]+)?${key}=/d" "$file" > "$backup" 2>/dev/null; then
      rm -f "$backup"
      return 1
    fi
    mv -f "$backup" "$file" || return 1
  done
  return 0
}

write_environment_files() {
  local dir auth_tmp systemd_tmp key quoted write_error=0
  dir="$(dirname "$AUTH_ENV")"
  if ! mkdir -p "$dir" "$(dirname "$SYSTEMD_ENV")"; then
    echo "apply-auth: could not create environment directories" >&2
    PARTIAL=1
    return
  fi

  auth_tmp="$(mktemp "$dir/.auth.env.XXXXXX" 2>/dev/null)" || {
    echo "apply-auth: could not write auth.env" >&2
    PARTIAL=1
    return
  }
  systemd_tmp="$(mktemp "$(dirname "$SYSTEMD_ENV")/.20-artel-auth.conf.XXXXXX" 2>/dev/null)" || {
    rm -f "$auth_tmp"
    echo "apply-auth: could not write environment.d" >&2
    PARTIAL=1
    return
  }

  if [ -f "$AUTH_ENV" ] && ! cp "$AUTH_ENV" "$auth_tmp"; then
    rm -f "$auth_tmp" "$systemd_tmp"
    echo "apply-auth: could not update auth.env" >&2
    PARTIAL=1
    return
  fi
  if [ -f "$SYSTEMD_ENV" ] && ! cp "$SYSTEMD_ENV" "$systemd_tmp"; then
    rm -f "$auth_tmp" "$systemd_tmp"
    echo "apply-auth: could not update environment.d" >&2
    PARTIAL=1
    return
  fi

  if ! remove_active_lines "$auth_tmp" || ! remove_active_lines "$systemd_tmp"; then
    rm -f "$auth_tmp" "$systemd_tmp"
    echo "apply-auth: could not update old environment variables" >&2
    PARTIAL=1
    return
  fi

  for key in "${ENV_NAMES[@]}"; do
    quoted="$(shell_quote "${ENV_VALUES[$key]}")"
    printf 'export %s=%s\n' "$key" "$quoted" >> "$auth_tmp" || write_error=1
    printf '%s=%s\n' "$key" "$quoted" >> "$systemd_tmp" || write_error=1
  done
  if [ "$write_error" -ne 0 ]; then
    rm -f "$auth_tmp" "$systemd_tmp"
    echo "apply-auth: could not write environment" >&2
    return
  fi

  chmod 600 "$auth_tmp" "$systemd_tmp" || PARTIAL=1
  if [ -f "$AUTH_ENV" ] && cmp -s "$auth_tmp" "$AUTH_ENV"; then
    rm -f "$auth_tmp"
  else
    mv -f "$auth_tmp" "$AUTH_ENV" || PARTIAL=1
  fi
  if [ -f "$SYSTEMD_ENV" ] && cmp -s "$systemd_tmp" "$SYSTEMD_ENV"; then
    rm -f "$systemd_tmp"
  else
    mv -f "$systemd_tmp" "$SYSTEMD_ENV" || PARTIAL=1
  fi
  chmod 600 "$AUTH_ENV" "$SYSTEMD_ENV" 2>/dev/null || PARTIAL=1

  if [ ! -f "$HOME_DIR/.bashrc" ]; then
    : > "$HOME_DIR/.bashrc" || PARTIAL=1
  fi
  if ! grep -Fqx '[ -f ~/.config/artel/auth.env ] && . ~/.config/artel/auth.env' "$HOME_DIR/.bashrc" 2>/dev/null; then
    printf '%s\n' '[ -f ~/.config/artel/auth.env ] && . ~/.config/artel/auth.env' >> "$HOME_DIR/.bashrc" || PARTIAL=1
  fi
  # A non-interactive login shell (bash -lc, sudo -iu artel cmd) does not read .bashrc: duplicate it in ~/.profile.
  if [ ! -f "$HOME_DIR/.profile" ]; then
    : > "$HOME_DIR/.profile" || PARTIAL=1
  fi
  if ! grep -Fqx '[ -f ~/.config/artel/auth.env ] && . ~/.config/artel/auth.env' "$HOME_DIR/.profile" 2>/dev/null; then
    printf '%s\n' '[ -f ~/.config/artel/auth.env ] && . ~/.config/artel/auth.env' >> "$HOME_DIR/.profile" || PARTIAL=1
  fi
}

write_claude_config() {
  local tail20="$1" patch tmp
  patch="$(jq -cn --arg k "$tail20" '
    {hasCompletedOnboarding: true}
    + (if $k != "" then {customApiKeyResponses: {approved: [$k], rejected: []}} else {} end)')" || return 1
  tmp="$(mktemp "$HOME_DIR/.claude.json.tmp.XXXXXX" 2>/dev/null)" || return 1
  if [ -f "$HOME_DIR/.claude.json" ]; then
    jq --argjson patch "$patch" '. * $patch' "$HOME_DIR/.claude.json" > "$tmp" 2>/dev/null || {
      rm -f "$tmp"
      return 1
    }
  else
    printf '%s\n' "$patch" > "$tmp" || {
      rm -f "$tmp"
      return 1
    }
  fi
  chmod 600 "$tmp" && mv -f "$tmp" "$HOME_DIR/.claude.json"
}

ensure_keyring_service() {
  local unit_dir="$HOME_DIR/.config/systemd/user" uid
  uid="$(id -u)" || return 1
  if ! mkdir -p "$unit_dir"; then
    return 1
  fi
  if ! cat > "$unit_dir/artel-keyring.service" <<UNIT
[Unit]
Description=Artel Secret Service keyring
After=dbus.socket

[Service]
Type=simple
Environment=XDG_RUNTIME_DIR=/run/user/$uid
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus
# Check the flags if the gnome-keyring version in the image changes.
ExecStart=/bin/sh -c 'printf "\\\\n" | exec gnome-keyring-daemon --foreground --unlock --components=secrets'
Restart=on-failure

[Install]
WantedBy=default.target
UNIT
  then
    return 1
  fi
  chmod 600 "$unit_dir/artel-keyring.service" || return 1
  command -v systemctl >/dev/null 2>&1 || return 1
  systemctl --user daemon-reload >/dev/null 2>&1 || return 1
  systemctl --user enable --now artel-keyring.service >/dev/null 2>&1 || return 1
  return 0
}

store_keyring_token() {
  local -a attrs=() pair key value
  while IFS=$'\t' read -r key value; do
    [ -n "$key" ] || continue
    attrs+=("$key" "$value")
  done < <(jq -r '.agy.keyring_attrs // {service:"gemini", username:"antigravity"} | to_entries[] | [.key, (.value | tostring)] | @tsv' "$JSON_TMP" 2>/dev/null)
  [ "${#attrs[@]}" -gt 0 ] || attrs=(service gemini username antigravity)
  jq -j '.agy.token' "$JSON_TMP" 2>/dev/null | secret-tool store --label=agy "${attrs[@]}" >/dev/null 2>/dev/null
}

configure_opencode_files() {
  local path tmp
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$HOME_DIR"/*) ;;
      *)
        echo "apply-auth: opencode: file outside $HOME_DIR skipped" >&2
        PARTIAL=1
        continue
        ;;
    esac
    tmp="$(mktemp "${TMPDIR:-/tmp}/artel-opencode.XXXXXX" 2>/dev/null)" || {
      PARTIAL=1
      continue
    }
    if ! jq -r --arg p "$path" '
      [.opencode.providers[]?.files // {} | .[$p] | select(. != null)][0]
      | if type == "string" then . else tojson end' "$JSON_TMP" > "$tmp" 2>/dev/null; then
      rm -f "$tmp"
      PARTIAL=1
      continue
    fi
    if grep -q 'REPLACE_ME' "$tmp" 2>/dev/null; then
      echo "apply-auth: opencode: file skipped (no data)" >&2
      rm -f "$tmp"
      continue
    fi
    if ! mkdir -p "$(dirname "$path")" || ! chmod 600 "$tmp" || ! mv -f "$tmp" "$path"; then
      rm -f "$tmp"
      PARTIAL=1
    fi
  done < <(jq -r '[.opencode.providers[]?.files // {} | keys[]] | unique[]' "$JSON_TMP" 2>/dev/null)
}

check_file() {
  local path="$1"
  [ -f "$path" ] && printf 'present' || printf 'missing'
}

env_names_from_file() {
  local file="$1" key
  shift
  [ -f "$file" ] || { printf 'missing'; return; }
  local result=""
  while [ "$#" -gt 0 ]; do
    key="$1"
    if grep -Eq "^[[:space:]]*(export[[:space:]]+)?${key}=" "$file" 2>/dev/null; then
      [ -n "$result" ] && result+=", "
      result+="$key"
    fi
    shift
  done
  [ -n "$result" ] && printf '%s' "$result" || printf 'missing'
}

keyring_check() {
  local method="$1" key value
  [ "$method" = "keyring_token" ] || { printf 'not used'; return; }
  command -v secret-tool >/dev/null 2>&1 || { printf 'missing (secret-tool not installed)'; return; }
  local -a attrs=()
  while IFS=$'\t' read -r key value; do
    [ -n "$key" ] || continue
    attrs+=("$key" "$value")
  done < <(jq -r '.agy.keyring_attrs // {service:"gemini", username:"antigravity"} | to_entries[] | [.key, (.value | tostring)] | @tsv' "$JSON_TMP" 2>/dev/null)
  [ "${#attrs[@]}" -gt 0 ] || attrs=(service gemini username antigravity)
  if secret-tool lookup "${attrs[@]}" >/dev/null 2>&1; then
    printf 'present'
  else
    printf 'missing'
  fi
}

opencode_files_state() {
  local path result=""
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    [ -n "$result" ] && result+=","
    result+="$path:$(check_file "$path")"
  done < <(jq -r '[.opencode.providers[]?.files // {} | keys[]] | unique[]' "$JSON_TMP" 2>/dev/null)
  [ -n "$result" ] && printf '%s' "$result" || printf 'missing'
}

claude_login_check() {
  # As agents run under systemd: with variables from auth.env. Prints one word; never prints secrets.
  command -v claude >/dev/null 2>&1 || { printf 'claude not installed'; return; }
  local out
  out="$( ( [ -f "$AUTH_ENV" ] && . "$AUTH_ENV"; timeout 30 claude auth status 2>/dev/null ) )" || true
  case "$(printf '%s' "$out" | jq -r 'if .loggedIn == true then "true" elif .loggedIn == false then "false" else "?" end' 2>/dev/null)" in
    true) printf 'logged in (%s)' "$(printf '%s' "$out" | jq -r '.authMethod // "?"' 2>/dev/null)" ;;
    false) printf 'NOT logged in' ;;
    *) printf 'could not check' ;;
  esac
}

check_mode() {
  local method files envs codex_status agy_method opencode_envs opencode_paths
  method="$(section_method claude)"
  if section_skip claude; then method="skip"; fi
  files="~/.claude.json:$(check_file "$HOME_DIR/.claude.json"), auth.env:$(check_file "$AUTH_ENV"), environment.d:$(check_file "$SYSTEMD_ENV")"
  envs="$(env_names_from_file "$AUTH_ENV" CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_API_KEY)"
  printf 'apply-auth: check: claude: method=%s; files=%s; env=%s; login=%s\n' "${method:-no data}" "$files" "$envs" "$(claude_login_check)"
  if [ -f "$HOME_DIR/.claude/.credentials.json" ] && [ "$envs" = "missing" ]; then
    echo "apply-auth: WARNING: Claude login relies on the copied session (~/.claude/.credentials.json) without a token in auth.env."
    echo "apply-auth:           This session expires when Claude refreshes its host session (‘OAuth session expired’)."
    echo "apply-auth:           Reliable setup: claude setup-token on the host -> claude.oauth_token in auth.json -> auth-transfer.sh --auth-file."
    CHECK_WARN=1
  fi

  method="$(section_method codex)"
  if section_skip codex; then method="skip"; fi
  if command -v codex >/dev/null 2>&1; then
    if codex login status >/dev/null 2>&1; then codex_status="logged in"; else codex_status="not logged in"; fi
  else
    codex_status="codex not installed"
  fi
  files="~/.codex/auth.json:$(check_file "$HOME_DIR/.codex/auth.json"), auth.env:$(check_file "$AUTH_ENV"), environment.d:$(check_file "$SYSTEMD_ENV")"
  printf 'apply-auth: check: codex: method=%s; files=%s; codex login status=%s; env=missing\n' "${method:-no data}" "$files" "$codex_status"

  agy_method="$(section_method agy)"
  if section_skip agy; then agy_method="skip"; fi
  files="~/.gemini/antigravity-cli/settings.json:$(check_file "$HOME_DIR/.gemini/antigravity-cli/settings.json"), ~/.config/systemd/user/artel-keyring.service:$(check_file "$HOME_DIR/.config/systemd/user/artel-keyring.service"), auth.env:$(check_file "$AUTH_ENV"), environment.d:$(check_file "$SYSTEMD_ENV")"
  envs="$(env_names_from_file "$AUTH_ENV" GEMINI_API_KEY GOOGLE_GEMINI_BASE_URL DBUS_SESSION_BUS_ADDRESS)"
  printf 'apply-auth: check: agy: method=%s; files=%s; keyring=%s; env=%s\n' "${agy_method:-no data}" "$files" "$(keyring_check "$agy_method")" "$envs"

  if section_skip opencode; then method="skip"; else method="providers"; fi
  opencode_envs="$(jq -r '.opencode.providers[]?.env // {} | keys[]' "$JSON_TMP" 2>/dev/null | sort -u | tr '\n' ',' | sed 's/,$//')"
  [ -n "$opencode_envs" ] || opencode_envs="missing"
  opencode_paths="$(opencode_files_state)"
  [ -n "$opencode_paths" ] || opencode_paths="missing"
  if [ "$opencode_envs" = "missing" ]; then
    envs="$(env_names_from_file "$AUTH_ENV" OPENCODE_MODEL)"
  else
    IFS=',' read -r -a OPENCODE_ENV_NAMES <<< "$opencode_envs"
    envs="$(env_names_from_file "$AUTH_ENV" "${OPENCODE_ENV_NAMES[@]}" OPENCODE_MODEL)"
  fi
  files="~/.local/share/opencode/auth.json:$(check_file "$HOME_DIR/.local/share/opencode/auth.json"), auth.env:$(check_file "$AUTH_ENV"), environment.d:$(check_file "$SYSTEMD_ENV"), files:$opencode_paths"
  printf 'apply-auth: check: opencode: method=%s; files=%s; env=%s\n' "$method" "$files" "$envs"
}

if [ "$CHECK" -eq 1 ]; then
  CHECK_WARN=0
  check_mode
  [ "$CHECK_WARN" -eq 0 ] || exit 3
  exit 0
fi

CLAUDE_METHOD="$(json_value '.claude.method')"
if section_skip claude; then
  echo "apply-auth: claude: skipped (skip)"
elif [ -z "$CLAUDE_METHOD" ]; then
  echo "apply-auth: claude: skipped (no data)"
else
  case "$CLAUDE_METHOD" in
    oauth_token)
      CLAUDE_VALUE="$(json_value '.claude.oauth_token')"
      if usable "$CLAUDE_VALUE"; then
        mark_managed CLAUDE_CODE_OAUTH_TOKEN
        mark_managed ANTHROPIC_API_KEY
        add_env CLAUDE_CODE_OAUTH_TOKEN "$CLAUDE_VALUE"
        # A copied claude.ai session next to the token only gets in the way: in a shell without auth.env,
        # `claude auth status` reports loggedIn: false or “OAuth session expired”.
        if [ -f "$HOME_DIR/.claude/.credentials.json" ]; then
          if mv -f "$HOME_DIR/.claude/.credentials.json" "$HOME_DIR/.claude/.credentials.json.stale" 2>/dev/null; then
            echo "apply-auth: claude: stale ~/.claude/.credentials.json renamed to .credentials.json.stale"
          fi
        fi
        if write_claude_config ""; then
          echo "apply-auth: claude: oauth_token configured"
        else
          echo "apply-auth: claude: oauth_token: configuration failed" >&2
          PARTIAL=1
        fi
      else
        echo "apply-auth: claude: skipped (no data)"
      fi
      ;;
    api_key)
      CLAUDE_VALUE="$(json_value '.claude.api_key')"
      if usable "$CLAUDE_VALUE"; then
        mark_managed CLAUDE_CODE_OAUTH_TOKEN
        mark_managed ANTHROPIC_API_KEY
        add_env ANTHROPIC_API_KEY "$CLAUDE_VALUE"
        CLAUDE_TAIL="${CLAUDE_VALUE: -20}"
        if write_claude_config "$CLAUDE_TAIL"; then
          echo "apply-auth: claude: api_key configured"
        else
          echo "apply-auth: claude: api_key: configuration failed" >&2
          PARTIAL=1
        fi
      else
        echo "apply-auth: claude: skipped (no data)"
      fi
      ;;
    *)
      echo "apply-auth: claude: unknown method" >&2
      PARTIAL=1
      ;;
  esac
fi

CODEX_METHOD="$(json_value '.codex.method')"
if section_skip codex; then
  echo "apply-auth: codex: skipped (skip)"
elif [ -z "$CODEX_METHOD" ]; then
  echo "apply-auth: codex: skipped (no data)"
else
  case "$CODEX_METHOD" in
    api_key)
      CODEX_VALUE="$(json_value '.codex.api_key')"
      if ! usable "$CODEX_VALUE"; then
        echo "apply-auth: codex: skipped (no data)"
      elif ! command -v codex >/dev/null 2>&1; then
        echo "apply-auth: codex: api_key: codex not installed" >&2
        PARTIAL=1
      elif printf '%s\n' "$CODEX_VALUE" | codex login --with-api-key >/dev/null 2>/dev/null; then
        mkdir -p "$HOME_DIR/.codex" && chmod 700 "$HOME_DIR/.codex" 2>/dev/null || true
        [ -f "$HOME_DIR/.codex/auth.json" ] && chmod 600 "$HOME_DIR/.codex/auth.json" 2>/dev/null || true
        echo "apply-auth: codex: api_key configured"
      else
        echo "apply-auth: codex: api_key: login failed" >&2
        PARTIAL=1
      fi
      ;;
    chatgpt)
      CODEX_AUTH_JSON="$(jq -c '.codex.auth_json // empty' "$JSON_TMP" 2>/dev/null)"
      case "$CODEX_AUTH_JSON" in *REPLACE_ME*|'') CODEX_AUTH_JSON="" ;; esac
      if [ -z "$CODEX_AUTH_JSON" ] || ! jq -e '.codex.auth_json | type == "object"' "$JSON_TMP" >/dev/null 2>&1; then
        echo "apply-auth: codex: skipped (no data)"
      elif [ "$FORCE" -eq 0 ] && [ -s "$HOME_DIR/.codex/auth.json" ]; then
        chmod 600 "$HOME_DIR/.codex/auth.json" 2>/dev/null || true
        echo "apply-auth: codex: chatgpt configured (auth.json already exists)"
      else
        mkdir -p "$HOME_DIR/.codex" || true
        if jq -c '.codex.auth_json' "$JSON_TMP" > "$HOME_DIR/.codex/auth.json" 2>/dev/null && chmod 600 "$HOME_DIR/.codex/auth.json"; then
          echo "apply-auth: codex: chatgpt configured"
        else
          echo "apply-auth: codex: chatgpt: could not write auth.json" >&2
          PARTIAL=1
        fi
      fi
      ;;
    *)
      echo "apply-auth: codex: unknown method" >&2
      PARTIAL=1
      ;;
  esac
fi

AGY_METHOD="$(json_value '.agy.method')"
if section_skip agy; then
  echo "apply-auth: agy: skipped (skip)"
elif [ -z "$AGY_METHOD" ]; then
  echo "apply-auth: agy: skipped (no data)"
else
  case "$AGY_METHOD" in
    gemini_api_key)
      AGY_VALUE="$(json_value '.agy.gemini_api_key')"
      if ! usable "$AGY_VALUE"; then
        echo "apply-auth: agy: skipped (no data)"
      elif ! mkdir -p "$HOME_DIR/.gemini/antigravity-cli"; then
        echo "apply-auth: agy: could not create directory" >&2
        PARTIAL=1
      else
        mark_managed GEMINI_API_KEY
        mark_managed GOOGLE_GEMINI_BASE_URL
        if [ -f "$HOME_DIR/.gemini/antigravity-cli/settings.json" ]; then
          if ! jq '.modelProvider = "gemini"' "$HOME_DIR/.gemini/antigravity-cli/settings.json" > "$HOME_DIR/.gemini/antigravity-cli/settings.json.tmp" 2>/dev/null || \
            ! mv -f "$HOME_DIR/.gemini/antigravity-cli/settings.json.tmp" "$HOME_DIR/.gemini/antigravity-cli/settings.json"; then
            rm -f "$HOME_DIR/.gemini/antigravity-cli/settings.json.tmp"
            echo "apply-auth: agy: could not update settings.json" >&2
            PARTIAL=1
          fi
        else
          if ! printf '%s\n' '{"modelProvider":"gemini"}' > "$HOME_DIR/.gemini/antigravity-cli/settings.json"; then
            echo "apply-auth: agy: could not write settings.json" >&2
            PARTIAL=1
          fi
        fi
        if ! chmod 600 "$HOME_DIR/.gemini/antigravity-cli/settings.json"; then PARTIAL=1; fi
        add_env GEMINI_API_KEY "$AGY_VALUE"
        AGY_BASE_URL="$(json_value '.agy.base_url')"
        if usable "$AGY_BASE_URL"; then add_env GOOGLE_GEMINI_BASE_URL "$AGY_BASE_URL"; fi
        echo "apply-auth: agy: gemini_api_key configured"
      fi
      ;;
    keyring_token)
      if ! jq -e '.agy.token | type == "string"' "$JSON_TMP" >/dev/null 2>&1 || ! usable "$(json_value '.agy.token')"; then
        echo "apply-auth: agy: skipped (no data)"
      elif ! command -v secret-tool >/dev/null 2>&1 || ! command -v gnome-keyring-daemon >/dev/null 2>&1; then
        echo "apply-auth: agy: keyring_token: secret-tool or gnome-keyring-daemon not found" >&2
        PARTIAL=1
      else
        mark_managed GEMINI_API_KEY
        mark_managed GOOGLE_GEMINI_BASE_URL
        XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
          export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
        fi
        add_env DBUS_SESSION_BUS_ADDRESS "$DBUS_SESSION_BUS_ADDRESS"
        if ! ensure_keyring_service; then
          echo "apply-auth: agy: keyring: systemd unit is not running" >&2
          PARTIAL=1
        elif ! store_keyring_token; then
          echo "apply-auth: agy: keyring_token: write failed" >&2
          PARTIAL=1
        else
          echo "apply-auth: agy: keyring_token configured"
        fi
      fi
      ;;
    *)
      echo "apply-auth: agy: unknown method" >&2
      PARTIAL=1
      ;;
  esac
fi

OPENCODE_SKIP=0
section_skip opencode && OPENCODE_SKIP=1
if [ "$OPENCODE_SKIP" -eq 1 ]; then
  echo "apply-auth: opencode: skipped (skip)"
else
  OPENCODE_HAS_DATA="$(jq -r '
    [(.opencode.providers[]?.env // {} | .[]?),
     (.opencode.providers[]?.files // {} | .[]?),
     .opencode.model?]
    | map(tostring | select(length > 0 and contains("REPLACE_ME") | not))
    | length > 0' "$JSON_TMP" 2>/dev/null)"
  if [ "$OPENCODE_HAS_DATA" != "true" ]; then
    echo "apply-auth: opencode: skipped (no data)"
  else
    configure_opencode_files
    mark_managed OPENCODE_MODEL
    while IFS=$'\t' read -r key value; do
      [ -n "$key" ] || continue
      if usable "$value"; then
        mark_managed "$key"
        add_env "$key" "$value"
      fi
    done < <(jq -r '.opencode.providers[]?.env // {} | to_entries[] | [.key, (.value | tostring)] | @tsv' "$JSON_TMP" 2>/dev/null)
    OPENCODE_MODEL="$(json_value '.opencode.model')"
    if usable "$OPENCODE_MODEL"; then add_env OPENCODE_MODEL "$OPENCODE_MODEL"; fi
    echo "apply-auth: opencode: providers configured"
  fi
fi

write_environment_files

if [ "${#ENV_NAMES[@]}" -gt 0 ] && command -v systemctl >/dev/null 2>&1; then
  # systemd rereads environment.d after daemon-reexec, import-environment, or a new session.
  systemctl --user import-environment "${ENV_NAMES[@]}" >/dev/null 2>&1 || \
    echo "apply-auth: systemd: import-environment failed" >&2
fi

if [ "$PARTIAL" -ne 0 ]; then
  exit 2
fi
exit 0
