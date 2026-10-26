#!/usr/bin/env bash
# Transfers harness credentials from a Linux host to an Incus container.
# Credential files are transferred directly; their contents are never printed or parsed.
# Use --user <name> when the container user is not artel.
set -u
set -o pipefail

usage() {
  cat >&2 <<'USAGE'
usage: auth-transfer.sh <container> [--user <name>] [--from-host] [--copy-claude-session] [--auth-file <path>]
                         [--skip <harness>[,…]] [--only <harness>[,…]] [--force] [--shred] [--check]
  --user <name>          container user name (default: artel)
  --from-host            transfer codex, opencode, and the agy keyring token from the host. The Claude session
                         (~/.claude/.credentials.json) is NOT copied: its refresh token is one-time, and the
                         copy expires as soon as Claude refreshes the host session (agents fail with
                         “OAuth session expired”). Claude needs a long-lived token: run `claude setup-token`
                         on the host and put the value in claude.oauth_token in the --auth-file.
  --copy-claude-session  copy the Claude session from the host anyway (temporary, with a warning)
  --skip / --only        harnesses to touch (claude, codex, agy, opencode); repeat or separate with commas.
                         Example: --skip agy if one Google login is shared across several containers.
  --force                overwrite an existing codex/opencode login in the container (by default, a live
                         ~/.codex/auth.json is left alone: codex rotates the refresh token, and a host copy
                         would break it)
  --shred                shred --auth-file on the host after a successful transfer (it contains tokens)
USAGE
  return 2
}

[ "$(uname -s)" = "Darwin" ] && {
  echo "Incus on macOS is not supported by this script"
  exit 2
}
[ "$(uname -s)" = "Linux" ] || {
  echo "auth-transfer: a Linux host with Incus is required" >&2
  exit 2
}
command -v incus >/dev/null 2>&1 || {
  echo "auth-transfer: incus command not found" >&2
  exit 2
}

CONTAINER="${1:-}"
[ -n "$CONTAINER" ] && [ "${CONTAINER#-}" = "$CONTAINER" ] || { usage; exit $?; }
shift

FROM_HOST=0
USER_IN=artel
COPY_CLAUDE_SESSION=0
CHECK=0
FORCE=0
SHRED=0
AUTH_FILE=""
SKIP_LIST=""
ONLY_LIST=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --user)
      [ "$#" -ge 2 ] || { echo "auth-transfer: specify a name after --user" >&2; exit 2; }
      USER_IN="$2"
      shift 2
      ;;
    --from-host) FROM_HOST=1; shift ;;
    --copy-claude-session) COPY_CLAUDE_SESSION=1; shift ;;
    --auth-file)
      [ "$#" -ge 2 ] || { echo "auth-transfer: specify a path after --auth-file" >&2; exit 2; }
      AUTH_FILE="$2"
      shift 2
      ;;
    --skip|--only)
      [ "$#" -ge 2 ] || { echo "auth-transfer: specify a harness after $1" >&2; exit 2; }
      if [ "$1" = "--skip" ]; then SKIP_LIST="$SKIP_LIST,$2"; else ONLY_LIST="$ONLY_LIST,$2"; fi
      shift 2
      ;;
    --force) FORCE=1; shift ;;
    --shred) SHRED=1; shift ;;
    --check) CHECK=1; shift ;;
    *) echo "auth-transfer: unknown argument $1" >&2; usage; exit 2 ;;
  esac
done
HOME_IN="/home/$USER_IN"
for h in $(printf '%s' "$SKIP_LIST$ONLY_LIST" | tr ',' ' '); do
  case "$h" in claude|codex|agy|opencode) ;; *) echo "auth-transfer: unknown harness ‘$h’ (allowed: claude, codex, agy, opencode)" >&2; exit 2 ;; esac
done

# wanted <harness>: whether to touch this harness, considering --skip/--only
wanted() {
  local h="$1"
  case ",$SKIP_LIST," in *",$h,"*) return 1 ;; esac
  [ -z "$ONLY_LIST" ] && return 0
  case ",$ONLY_LIST," in *",$h,"*) return 0 ;; *) return 1 ;; esac
}
APPLY_ARGS=()
[ -z "$SKIP_LIST" ] || APPLY_ARGS+=(--skip "${SKIP_LIST#,}")
[ -z "$ONLY_LIST" ] || APPLY_ARGS+=(--only "${ONLY_LIST#,}")
[ "$FORCE" -eq 0 ] || APPLY_ARGS+=(--force)

if ! incus info "$CONTAINER" >/dev/null 2>&1; then
  echo "auth-transfer: container $CONTAINER not found" >&2
  exit 2
fi
USER_UID="$(incus exec "$CONTAINER" -- id -u "$USER_IN")" || {
  echo "auth-transfer: could not find user $USER_IN in $CONTAINER" >&2
  exit 2
}
USER_GID="$(incus exec "$CONTAINER" -- id -g "$USER_IN")" || {
  echo "auth-transfer: could not find group for user $USER_IN in $CONTAINER" >&2
  exit 2
}

HOST_HOME="${HOME:-}"
[ -n "$HOST_HOME" ] || {
  echo "auth-transfer: host home directory is undefined" >&2
  exit 2
}

ERRORS=0
APPLY_STATUS=0
TMP_FILES=()
cleanup() {
  local file
  for file in "${TMP_FILES[@]}"; do rm -f "$file"; done
}
trap cleanup EXIT

remote_mkdir() {
  local path="$1"
  echo "auth-transfer: creating $path"
  if ! incus exec "$CONTAINER" -- sudo -u "$USER_IN" mkdir -p "$path" >/dev/null 2>&1; then
    echo "auth-transfer: could not create directory" >&2
    ERRORS=1
    return 1
  fi
}

copy_host_file() {
  local source="$1" target="$2"
  if [ ! -f "$source" ]; then
    echo "auth-transfer: $source: not found, skipped"
    return 0
  fi
  if [ "$FORCE" -eq 0 ] && incus exec "$CONTAINER" -- test -s "$target" 2>/dev/null; then
    echo "auth-transfer: $target already exists and is non-empty in the container; not overwriting (the login may have been refreshed inside; use --force to replace)"
    return 0
  fi
  echo "auth-transfer: transferring $source -> $target"
  if ! incus file push --uid "$USER_UID" --gid "$USER_GID" --mode 0600 "$source" "$CONTAINER$target" >/dev/null 2>&1; then
    echo "auth-transfer: could not transfer file" >&2
    ERRORS=1
    return 1
  fi
  return 0
}

if [ "$FROM_HOST" -eq 1 ]; then
  wanted codex && remote_mkdir "$HOME_IN/.codex"
  wanted opencode && remote_mkdir "$HOME_IN/.local/share/opencode"
  if ! wanted claude; then
    echo "auth-transfer: claude skipped by --skip/--only"
  elif [ "$COPY_CLAUDE_SESSION" -eq 1 ]; then
    echo "auth-transfer: WARNING: copying the Claude session from the host; it will expire at the next host session refresh." >&2
    echo "auth-transfer:           reliable login: claude setup-token on the host -> claude.oauth_token in --auth-file." >&2
    remote_mkdir "$HOME_IN/.claude"
    copy_host_file "$HOST_HOME/.claude/.credentials.json" "$HOME_IN/.claude/.credentials.json"
  else
    echo "auth-transfer: Claude session is not copied from the host (the one-time refresh token expires)."
    echo "auth-transfer:   Claude login: run \`claude setup-token\` on the host; put the sk-ant-oat01-… token in claude.oauth_token in --auth-file."
  fi
  wanted codex && copy_host_file "$HOST_HOME/.codex/auth.json" "$HOME_IN/.codex/auth.json"
  wanted opencode && copy_host_file "$HOST_HOME/.local/share/opencode/auth.json" "$HOME_IN/.local/share/opencode/auth.json"
fi

MERGED_AUTH=""
AGY_JSON=""
AUTH_MERGE_FILE=""
if [ "$FROM_HOST" -eq 1 ] && ! wanted agy; then
  echo "auth-transfer: agy skipped by --skip/--only"
elif [ "$FROM_HOST" -eq 1 ] && command -v secret-tool >/dev/null 2>&1; then
  AGY_TOKEN="$(mktemp "${TMPDIR:-/tmp}/artel-agy-token.XXXXXX" 2>/dev/null || true)"
  if [ -n "$AGY_TOKEN" ]; then
    chmod 600 "$AGY_TOKEN"
    TMP_FILES+=("$AGY_TOKEN")
    if secret-tool lookup service gemini username antigravity > "$AGY_TOKEN" 2>/dev/null && [ -s "$AGY_TOKEN" ]; then
      AGY_JSON="$(mktemp "${TMPDIR:-/tmp}/artel-agy-auth.XXXXXX" 2>/dev/null || true)"
      if [ -n "$AGY_JSON" ]; then
        chmod 600 "$AGY_JSON"
        TMP_FILES+=("$AGY_JSON")
        if jq -n --rawfile token "$AGY_TOKEN" \
          '{agy:{method:"keyring_token",keyring_attrs:{service:"gemini",username:"antigravity"},token:$token}}' \
          > "$AGY_JSON" 2>/dev/null; then
          echo "auth-transfer: agy keyring found; value is not printed"
        else
          echo "auth-transfer: agy keyring: could not prepare auth; skipped" >&2
          AGY_JSON=""
          ERRORS=1
        fi
      fi
    else
      echo "auth-transfer: agy keyring: not found, skipped"
    fi
  else
    echo "auth-transfer: agy temporary file was not created, skipped" >&2
    ERRORS=1
  fi
elif [ "$FROM_HOST" -eq 1 ]; then
  echo "auth-transfer: secret-tool not found, agy keyring: unavailable, skipped"
fi

if [ -n "$AUTH_FILE" ]; then
  if [ ! -r "$AUTH_FILE" ]; then
    echo "auth-transfer: auth file is unavailable" >&2
    ERRORS=1
  elif [ -n "$AGY_JSON" ]; then
    if ! command -v jq >/dev/null 2>&1; then
      echo "auth-transfer: jq is required for merging" >&2
      ERRORS=1
    else
      MERGED_AUTH="$(mktemp "${TMPDIR:-/tmp}/artel-auth-merged.XXXXXX" 2>/dev/null || true)"
      if [ -z "$MERGED_AUTH" ]; then
        echo "auth-transfer: temporary auth file was not created" >&2
        ERRORS=1
      else
        chmod 600 "$MERGED_AUTH"
        TMP_FILES+=("$MERGED_AUTH")
        AUTH_MERGE_FILE="$(mktemp "${TMPDIR:-/tmp}/artel-auth-source.XXXXXX" 2>/dev/null || true)"
        if [ -n "$AUTH_MERGE_FILE" ]; then
          chmod 600 "$AUTH_MERGE_FILE"
          TMP_FILES+=("$AUTH_MERGE_FILE")
        fi
        if [ -z "$AUTH_MERGE_FILE" ] || ! sed -E '/^[[:space:]]*\/\//d' "$AUTH_FILE" > "$AUTH_MERGE_FILE" 2>/dev/null || \
          ! jq -s '.[0] as $g | .[1] | if ($g.agy != null) and ((.agy == null) or ((.agy | tostring) | test("REPLACE_ME"))) then .agy = $g.agy else . end' "$AGY_JSON" "$AUTH_MERGE_FILE" > "$MERGED_AUTH" 2>/dev/null; then
          echo "auth-transfer: auth file contains invalid JSON" >&2
          ERRORS=1
          MERGED_AUTH=""
        fi
      fi
    fi
  else
    MERGED_AUTH="$AUTH_FILE"
  fi
fi

if [ -n "$AGY_JSON" ] && [ -z "$MERGED_AUTH" ] && [ -z "$AUTH_FILE" ]; then
  MERGED_AUTH="$AGY_JSON"
fi

if [ "$FROM_HOST" -eq 1 ] && [ -z "$MERGED_AUTH" ]; then
  # Auth files have already been transferred. Empty JSON lets apply-auth finish
  # normally even when the host has no agy keyring and no separate auth file.
  MERGED_AUTH="$(mktemp "${TMPDIR:-/tmp}/artel-auth-empty.XXXXXX" 2>/dev/null || true)"
  if [ -n "$MERGED_AUTH" ]; then
    chmod 600 "$MERGED_AUTH"
    TMP_FILES+=("$MERGED_AUTH")
    printf '%s\n' '{}' > "$MERGED_AUTH"
  else
    echo "auth-transfer: empty auth file was not created" >&2
    ERRORS=1
  fi
fi

if [ -n "$MERGED_AUTH" ]; then
  remote_mkdir "$HOME_IN/.config/artel"
  echo "auth-transfer: transferring auth file to $HOME_IN/.config/artel/auth.json"
  if ! incus file push --uid "$USER_UID" --gid "$USER_GID" --mode 0600 "$MERGED_AUTH" "$CONTAINER$HOME_IN/.config/artel/auth.json" >/dev/null 2>&1; then
    echo "auth-transfer: could not transfer auth file" >&2
    ERRORS=1
  fi
elif [ -n "$AUTH_FILE" ]; then
  echo "auth-transfer: auth file not transferred because of an error" >&2
fi

if [ "$FROM_HOST" -eq 1 ] && [ "$COPY_CLAUDE_SESSION" -eq 1 ] && [ -f "$HOST_HOME/.claude/.credentials.json" ]; then
  # apply-auth creates this file when the claude section is present. If it is absent,
  # credentials must still clear Claude's onboarding lock.
  echo "auth-transfer: checking ~/.claude.json for copied credentials"
  if ! incus exec "$CONTAINER" -- sudo -u "$USER_IN" env HOME_IN="$HOME_IN" bash -c '
    if [ ! -f "$HOME_IN/.claude.json" ] || ! jq -e "has(\"claude\")" "$HOME_IN/.config/artel/auth.json" >/dev/null 2>&1; then
      printf "%s\n" "{\"hasCompletedOnboarding\":true}" > "$HOME_IN/.claude.json"
      chmod 600 "$HOME_IN/.claude.json"
    fi
  ' >/dev/null 2>&1; then
    echo "auth-transfer: could not prepare ~/.claude.json" >&2
    ERRORS=1
  fi
fi

if [ "$CHECK" -eq 1 ] && [ "$FROM_HOST" -eq 0 ] && [ -z "$AUTH_FILE" ]; then
  echo "auth-transfer: check only; nothing changed"
elif echo "auth-transfer: running apply-auth inside $CONTAINER" && incus exec "$CONTAINER" -- sudo -iu "$USER_IN" bash "$HOME_IN/artel/install/apply-auth.sh" "${APPLY_ARGS[@]}"; then
  APPLY_STATUS=0
else
  APPLY_STATUS=$?
  echo "auth-transfer: apply-auth exited with code $APPLY_STATUS" >&2
  ERRORS=1
fi

if [ "$CHECK" -eq 1 ]; then
  echo "auth-transfer: checking harness status"
  incus exec "$CONTAINER" -- sudo -iu "$USER_IN" bash "$HOME_IN/artel/install/apply-auth.sh" --check
  case $? in
    0) ;;
    3) echo "auth-transfer: check found a fragile login (see WARNING above)" >&2 ;;
    *) echo "auth-transfer: check failed" >&2; ERRORS=1 ;;
  esac
fi

if [ "$SHRED" -eq 1 ] && [ -n "$AUTH_FILE" ] && [ -f "$AUTH_FILE" ]; then
  if [ "$ERRORS" -eq 0 ] && [ "$APPLY_STATUS" -eq 0 ]; then
    if command -v shred >/dev/null 2>&1; then shred -u "$AUTH_FILE" 2>/dev/null || rm -f "$AUTH_FILE"; else rm -f "$AUTH_FILE"; fi
    echo "auth-transfer: shredded $AUTH_FILE on the host (--shred); secrets now exist only in the container"
  else
    echo "auth-transfer: skipped --shred; transfer had errors, so the host file was kept" >&2
  fi
fi

cat <<MSG
auth-transfer: done without printing secrets.
If any harness still has no login, sign in manually inside the container:
  incus exec $CONTAINER -- sudo -iu $USER_IN claude
  incus exec $CONTAINER -- sudo -iu $USER_IN codex login --device-auth
  incus exec $CONTAINER -- sudo -iu $USER_IN env SSH_CONNECTION=1 agy
  incus exec $CONTAINER -- sudo -iu $USER_IN opencode auth login
MSG

[ "$ERRORS" -eq 0 ] || exit 2
[ "$APPLY_STATUS" -eq 0 ] || exit "$APPLY_STATUS"
exit 0
