# Automatic harness authentication in a container

**Claude Code · Codex · opencode · agy (Google Antigravity CLI)**

Goal: one JSON file with secrets is mounted into a fresh container, the entrypoint script puts
everything in place, and all four harnesses start already logged in, with no manual login.

Current as of October 2026. CLIs change quickly, so recheck sections marked ⚠️ when updating versions.

---

## Contents

1. [Summary: what each method provides](#1-summary-what-each-method-provides)
2. [The `harness-auth.json` file format](#2-the-harness-authjson-file-format)
3. [Claude Code](#3-claude-code)
4. [Codex](#4-codex)
5. [agy (Google Antigravity CLI)](#5-agy-google-antigravity-cli)
6. [opencode](#6-opencode)
7. [Dockerfile](#7-dockerfile)
8. [`apply-auth.sh` script](#8-apply-authsh-script)
9. [Running the container](#9-running-the-container)
10. [Verification](#10-verification)
11. [Security and risks](#11-security-and-risks)
12. [Sources](#12-sources)

---

## 1. Summary: what each method provides

| Harness | `method` | What goes in JSON | What pays for it | For automation |
|---|---|---|---|---|
| Claude Code | `oauth_token` | token from `claude setup-token` (`sk-ant-oat01-…`) | Pro/Max subscription quota | ✅ excellent |
| Claude Code | `api_key` | Console key (`sk-ant-api03-…`) | pay per token | ✅ excellent |
| Codex | `api_key` | Platform key (`sk-proj-…`) | pay per token | ✅ excellent |
| Codex | `chatgpt` | contents of `~/.codex/auth.json` | ChatGPT subscription quota | ⚠️ refresh token rotates |
| agy | `gemini_api_key` | AI Studio key (`AIza…`) | free tier / pay per token / Pro/Ultra Cloud credits | ✅ official path |
| agy | `keyring_token` | OAuth token extracted from the host keyring | Google AI Pro/Ultra subscription quota | ⚠️ working, undocumented workaround |
| agy | `token_file` | same token, but in a file | subscription quota | ⚠️ experimental, version-dependent |
| opencode | per-provider `env` | provider environment variables | depends on provider | ✅ excellent |

---

## 2. The `harness-auth.json` file format

### Principles

- Each harness has a `method` field and fields specific to that method. Omit unused fields or set them to `null`.
- opencode is described through `providers.<provider-id>.env` because providers need different data. If a provider needs a file (for example, a service-account JSON file), put it in `files`, where the key is an absolute path and the value is a string or JSON object.
- The file is never baked into the image; mount it as a secret (see [§9](#9-running-the-container)).

### Full template

```json
{
  "version": 1,

  "claude": {
    "method": "oauth_token",
    "oauth_token": "sk-ant-oat01-...",
    "api_key": null
  },

  "codex": {
    "method": "api_key",
    "api_key": "sk-proj-...",
    "auth_json": null
  },

  "agy": {
    "method": "keyring_token",
    "keyring_attrs": { "service": "gemini", "username": "antigravity" },
    "token": "<contents of secret-tool lookup as a string>",

    "gemini_api_key": null,
    "base_url": null
  },

  "opencode": {
    "model": "anthropic/<model-id>",
    "providers": {
      "anthropic":  { "env": { "ANTHROPIC_API_KEY": "sk-ant-api03-..." } },
      "openai":     { "env": { "OPENAI_API_KEY": "sk-proj-..." } },
      "openrouter": { "env": { "OPENROUTER_API_KEY": "sk-or-v1-..." } },

      "amazon-bedrock": {
        "env": {
          "AWS_ACCESS_KEY_ID": "AKIA...",
          "AWS_SECRET_ACCESS_KEY": "...",
          "AWS_REGION": "eu-central-1"
        }
      },

      "google-vertex": {
        "env": {
          "GOOGLE_CLOUD_PROJECT": "my-project",
          "GOOGLE_APPLICATION_CREDENTIALS": "/home/artel/.secrets/vertex-sa.json"
        },
        "files": {
          "/home/artel/.secrets/vertex-sa.json": { "type": "service_account", "project_id": "my-project", "...": "..." }
        }
      },

      "my-gateway": {
        "env": { "MYGW_API_KEY": "..." },
        "base_url": "https://llm.example.com/v1",
        "openai_compatible": true,
        "models": ["qwen3-coder"]
      }
    }
  }
}
```

### Minimal variants by method

**Claude: subscription**
```json
"claude": { "method": "oauth_token", "oauth_token": "sk-ant-oat01-..." }
```

**Claude: API**
```json
"claude": { "method": "api_key", "api_key": "sk-ant-api03-..." }
```

**Codex: API**
```json
"codex": { "method": "api_key", "api_key": "sk-proj-..." }
```

**Codex: ChatGPT subscription** (the full contents of `~/.codex/auth.json` in `auth_json`)
```json
"codex": { "method": "chatgpt", "auth_json": { "...": "contents of ~/.codex/auth.json" } }
```

**agy: Gemini API key**
```json
"agy": { "method": "gemini_api_key", "gemini_api_key": "AIza...", "base_url": null }
```

**agy: subscription through keyring**
```json
"agy": {
  "method": "keyring_token",
  "keyring_attrs": { "service": "gemini", "username": "antigravity" },
  "token": "<string from secret-tool lookup>"
}
```

**agy: subscription through a file (experimental)**
```json
"agy": {
  "method": "token_file",
  "token_file_name": "antigravity-oauth-token",
  "token": "<string from secret-tool lookup>",
  "force_env": { "<VARIABLE_FROM_strings>": "<value>" }
}
```

---

## 3. Claude Code

### `oauth_token` method (Pro/Max subscription)

1. On a machine with a browser:
   ```bash
   claude setup-token
   ```
2. Log in in the browser and copy the `sk-ant-oat01-…` token.
3. Put it in `claude.oauth_token`.

In the container, pass the token through `CLAUDE_CODE_OAUTH_TOKEN`. The token is long-lived. If it expires or is revoked, run `claude setup-token` again.

Common mistake: the file receives the browser authorization code instead of the token (a long string with `#`,
without the `sk-ant-oat01-` prefix). Enter the code in the terminal where `claude setup-token` is waiting;
the command prints the token afterward.

### Why you cannot copy the host session

`~/.claude/.credentials.json` on the host is an interactive claude.ai session: a short-lived access token and
a one-time refresh token. The copy in the container works only until Claude on the host refreshes the session
(every few hours): afterward, the copy's refresh token is invalid, it cannot refresh, and every run fails within
a second with “Failed to authenticate: OAuth session expired and could not be refreshed”. Therefore,
`auth-transfer.sh --from-host` does not copy the Claude session (there is a `--copy-claude-session` flag for a
temporary workaround with a warning), `apply-auth.sh --check` marks such credentials with “WARNING”, and
`artel run` immediately tells the user when authentication fails.

Side effect of the `oauth_token` method: the token from `claude setup-token` has only the `user:inference` scope,
while the quota server (`/api/oauth/usage`) that `claude -p /usage` uses for percentages requires `user:profile`
and returns 403 `oauth_scope_insufficient` (verified 2026-10-25). Claude Code then silently prints a cost summary
without percentages. With `authMethod: oauth_token`, `artel quota` instead sends a test request to haiku
(`max_tokens: 1`, about 25 tokens) and reads the 5-hour and 7-day windows from
`anthropic-ratelimit-unified-*` headers.

### `api_key` method (pay per token)

1. console.anthropic.com → Settings → API Keys → Create Key.
2. Put the `sk-ant-api03-…` key in `claude.api_key`.

In the container, pass the key through `ANTHROPIC_API_KEY`.

### Catch: onboarding

Even with a valid token, Claude Code in a clean container expects onboarding and trust confirmation to have
already been completed. The script therefore writes `~/.claude.json` in advance:

```json
{ "hasCompletedOnboarding": true }
```

For the `api_key` method, interactive Claude Code also asks whether to use the key from env. The answer is set
in advance in the same file, using the last 20 characters of the key:

```json
{
  "hasCompletedOnboarding": true,
  "customApiKeyResponses": { "approved": ["<last 20 characters of the key>"], "rejected": [] }
}
```

---

## 4. Codex

### `api_key` method (recommended for automation)

1. https://platform.openai.com/api-keys → Create new secret key.
2. Put the `sk-proj-…` key in `codex.api_key`.

In the container:
```bash
printenv OPENAI_API_KEY | codex login --with-api-key
```

⚠️ The `CODEX_API_KEY` variable works only for `codex exec`. Interactive `codex` ignores it, so the script runs a full `codex login`.

### `chatgpt` method (ChatGPT subscription)

1. On any machine:
   ```bash
   codex login                 # with a browser
   codex login --device-auth   # without a browser: code + link
   ```
2. Get `~/.codex/auth.json`. It is not tied to the host.
3. Put its contents in `codex.auth_json` as a JSON object.

⚠️ Drawbacks:
- Codex refreshes the tokens in `auth.json`, so the copy in your JSON eventually expires.
- The refresh token rotates. If you give the same `auth.json` to multiple containers at once, they interfere with each other.
- The script writes `auth.json` only if it does not already exist. If `~/.codex` is on a volume, refreshed tokens survive restarts.
- `auth-transfer.sh --from-host` also does not overwrite an existing `~/.codex/auth.json` in the container (codex inside
  may already have rotated the refresh token, and the host copy would break it); force replacement with `--force`.
  For long-running work, `codex login --device-auth` inside the container or `api_key` is more reliable.

For multiple containers, `api_key` is more reliable.

---

## 5. agy (Google Antigravity CLI)

### 5.1. Two different payment paths

| | Google login (subscription) | `GEMINI_API_KEY` |
|---|---|---|
| What is consumed | Google AI Pro/Ultra subscription quota, shared by the CLI, desktop app, and SDK | Gemini API free tier or pay per token |
| Account login required | yes | no |
| Officially supported headless | no | yes |

The API key **does not consume subscription quota**. However, the subscription may cover its costs through Cloud credits (see 5.3).

### 5.2. `gemini_api_key` method (official)

1. Create a key: https://aistudio.google.com/apikey (format `AIza…`).
2. You need **both** items; one variable without the setting will not work:
   ```bash
   mkdir -p ~/.gemini/antigravity-cli
   echo '{"modelProvider":"gemini"}' > ~/.gemini/antigravity-cli/settings.json
   export GEMINI_API_KEY="AIza..."
   ```
3. Details:
   - agy **ignores** `GOOGLE_API_KEY` and reads only `GEMINI_API_KEY`;
   - agy does not read `.env` files; the variable must be in the process environment;
   - `GOOGLE_GEMINI_BASE_URL` directs requests to a compatible endpoint (the `base_url` field).

**Free tier:**
- no billing account is required, but limits are small;
- exact figures are visible only in the AI Studio limits console;
- intended mainly for Flash models; Pro and preview models are usually unavailable or heavily restricted;
- Google may use free-tier requests to improve its products.

**Paid tier:** enable billing in AI Studio (link a billing account, with a $5 minimum prepayment). After that, pay per million tokens.

### 5.3. Cloud credits from a Pro/Ultra subscription

Google AI subscriptions include Google Developer Program premium benefits, including monthly Google Cloud credits that can be spent on the Gemini API:

| Plan | Credits per month |
|---|---|
| Google AI Pro | $10 |
| Google AI Ultra | $100 (the intermediate Ultra 20TB plan is reported as $40) |

Setup:
1. https://developers.google.com/program → My Benefits → activate and link to a Cloud billing account.
2. In AI Studio, create a key in a project linked to that billing account.
3. Set a budget with an alert in Cloud Console. When the credits run out, charges silently go to the card.

According to one source, each credited amount expires after one year.

### 5.4. `keyring_token` method: subscription in a container without manual login

**Problem.** agy 1.2.x stores the OAuth token in the OS keyring (on Linux, in the `login` Secret Service collection) and writes nothing to `~/.gemini/antigravity-cli/`. Containers have no keyring, so every new container requires a login.

**Solution.** Instead of working around the keyring, run it in the container: `gnome-keyring` without a GUI,
unlocked with an empty password, and seed it with the token from the JSON. To agy, this is an ordinary logged-in Linux system.

**Why this is stable:**
- Judging by the logs (`keyring.go`, `keyringAuth: loaded token`) and the `service`/`username` attributes, agy is written in Go and likely uses `zalando/go-keyring`. It looks up a Secret Service entry by `service=gemini` and `username=antigravity`.
- Google OAuth refresh tokens **do not rotate** by default: they are long-lived and simply issue new one-hour access tokens. One copy can therefore be given to new containers, unlike Codex.
- The token is revoked when the Google account password changes, access is revoked in account settings, and possibly when `/logout` is used in agy. **Do not use `/logout` on the host.**

#### Step 1. On the host: retrieve the token (root is not required)

Secret Service provides secrets to its user while the keyring is unlocked. Root cannot read anything without the keyring password: the keyring file is encrypted with the login password.

```bash
# 1. inspect all entry attributes so you can reproduce them exactly
secret-tool search --all service gemini

# 2. save the value as-is; do not parse it
secret-tool lookup service gemini username antigravity > agy-token.raw

# 3. insert it into harness-auth.json
jq --rawfile t agy-token.raw \
   '.agy = {method:"keyring_token",
            keyring_attrs:{service:"gemini",username:"antigravity"},
            token:$t}' \
   harness-auth.json > harness-auth.json.new && mv harness-auth.json.new harness-auth.json
```

If `search` shows additional attributes, add them to `keyring_attrs`.

macOS ⚠️ (names not verified; check them in Keychain Access):
```bash
security find-generic-password -s gemini -a antigravity -w > agy-token.raw
```
`go-keyring` on macOS may add the `go-keyring-base64:` prefix. Preserve the value as-is.

#### Step 2. In the container

Implemented in `apply-auth.sh` ([§8](#8-apply-authsh-script)): `dbus-launch` → `gnome-keyring-daemon --unlock/--start` → `secret-tool store`.

**D-Bus catch.** `dbus-launch` starts the bus only for entrypoint processes. Shells opened through `docker exec` do not know about it. The script therefore writes the bus address to `~/.dbus-env` and sources it from `~/.bashrc`. If agy launches an orchestrator, pass `DBUS_SESSION_BUS_ADDRESS` to its environment.

### 5.5. `token_file` method: experimental

The agy binary contains the strings `Using file-based token storage because %s detected` and `falling back to file storage`. This means there is a condition under which agy switches to storing the token in a file. If you find the switch, the container does not need a keyring.

The check takes a minute:
```bash
strings "$(command -v agy)" | grep -iE 'file-based|token.?storage|KEYRING|_TOKEN_FILE|detected' | head -50
```

If you find a switch variable, use the `token_file` method:
- the token goes in `~/.gemini/antigravity-cli/antigravity-oauth-token` (one report gives the name as `jetski-standalone-oauth-token`);
- set the variable in `force_env`.

⚠️ Reports conflict. Some say agy does not create the file even without a session bus. Others say that in older versions without a keyring, the token existed only in memory. Whether agy reads a pre-populated file depends on the version.

### 5.6. Alternative: log in once on a volume

If you do not want to touch the keyring:
- set `SSH_CONNECTION=1`; agy then treats the environment as remote and provides a link instead of opening a browser;
- open the link locally; the browser goes to `http://localhost:36742/oauth-callback?code=…`, and the page will not open, which is normal;
- copy the full URL and paste it into agy;
- keep the home directory on a volume.

Downside: the volume, rather than the JSON, becomes the secret. Each new volume still requires a login.

### 5.7. Risks of the subscription path

- **Ban.** Since February 2026, Google has mass-blocked accounts whose Antigravity OAuth was used for requests from third-party clients (OpenClaw, opencode), including paying Ultra subscribers. You run the official agy, so the risk is lower. But official-client users with multiple machines have also reported automatic blocks. One token in five containers at once looks like a farm.
- **Rule:** one or two active containers per token. Use `gemini_api_key` for mass parallel runs.
- **Never** use an Antigravity OAuth token in opencode or other third-party clients.

---

## 6. opencode

### How it works

Providers in the models.dev catalog declare their standard environment variables, and a non-empty variable automatically becomes a connection. The script therefore only needs to **export the variables**. This works in both v1 and v2.

Key-source precedence in v2:
1. the key saved through `/connect` (`opencode auth login`);
2. the first non-empty variable from the provider's `env`;
3. `settings.apiKey` from the config.

⚠️ If a database or `~/.local/share/opencode/auth.json` containing someone else's key gets into the image by accident, it overrides your env.

### Provider table

The key in `providers` is the provider ID in opencode. ⚠️ Variable names are listed from memory and the catalog changes: see the provider's `env` field at https://models.dev for the exact list.

| Provider ID | Variables | Where to get them |
|---|---|---|
| `anthropic` | `ANTHROPIC_API_KEY` | console.anthropic.com |
| `openai` | `OPENAI_API_KEY` | platform.openai.com/api-keys |
| `google` | `GOOGLE_GENERATIVE_AI_API_KEY` (or `GEMINI_API_KEY`) | aistudio.google.com/apikey |
| `openrouter` | `OPENROUTER_API_KEY` | openrouter.ai/keys |
| `deepseek` | `DEEPSEEK_API_KEY` | platform.deepseek.com |
| `xai` | `XAI_API_KEY` | console.x.ai |
| `groq` | `GROQ_API_KEY` | console.groq.com |
| `mistral` | `MISTRAL_API_KEY` | console.mistral.ai |
| `amazon-bedrock` | `AWS_ACCESS_KEY_ID` + `AWS_SECRET_ACCESS_KEY` + `AWS_REGION` (or `AWS_BEARER_TOKEN_BEDROCK`) | IAM user with `bedrock:InvokeModel*` permissions + model access enabled in Bedrock |
| `azure` | `AZURE_RESOURCE_NAME` + `AZURE_API_KEY` | Azure OpenAI resource → Keys and Endpoint; model name = deployment name |
| `google-vertex` | `GOOGLE_CLOUD_PROJECT` + `GOOGLE_APPLICATION_CREDENTIALS` + region | GCP → IAM → Service account with the Vertex AI User role → Keys → JSON (put in `files`) |
| custom OpenAI-compatible | any custom variable + `base_url` | gateway key; requires `opencode.json` (below) |

Providers with OAuth login (for example, GitHub Copilot) cannot be configured through env. You would have to transfer the entire opencode store, which is fragile.

### `opencode.json` template for a custom provider

The config format depends on the version.

**v1** (`provider` + `options`):
```json
{
  "$schema": "https://opencode.ai/config.json",
  "model": "my-gateway/qwen3-coder",
  "provider": {
    "my-gateway": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "My Gateway",
      "options": {
        "baseURL": "https://llm.example.com/v1",
        "apiKey": "{env:MYGW_API_KEY}"
      },
      "models": { "qwen3-coder": {} }
    }
  }
}
```

**v2** (`providers` + `env` + `settings`):
```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "my-gateway/qwen3-coder",
  "providers": {
    "my-gateway": {
      "name": "My Gateway",
      "env": ["MYGW_API_KEY"],
      "package": "@opencode-ai/ai/providers/openai-compatible",
      "settings": { "baseURL": "https://llm.example.com/v1" },
      "models": { "qwen3-coder": {} }
    }
  }
}
```

Do not write the key as a literal in the config; use only `{env:…}` or `env`.

---

## 7. Dockerfile

This fragment adds everything required by `apply-auth.sh`. Keep harness installation as you have it.

```dockerfile
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq bash \
      dbus dbus-x11 gnome-keyring libsecret-tools \
 && rm -rf /var/lib/apt/lists/*

# unprivileged user
RUN useradd -m -s /bin/bash artel
USER artel
WORKDIR /home/artel

# ... install claude / codex / opencode / agy ...
# RUN curl -fsSL https://antigravity.google/cli/install.sh | bash

COPY --chown=artel:artel apply-auth.sh /opt/apply-auth.sh
COPY --chown=artel:artel entrypoint.sh /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["bash"]
```

`entrypoint.sh`:
```bash
#!/usr/bin/env bash
# apply secrets to the current process and pass the environment onward
source /opt/apply-auth.sh "${HARNESS_AUTH_FILE:-/run/secrets/harness-auth.json}"
exec "$@"
```

The `dbus`, `gnome-keyring`, and `libsecret-tools` packages are needed only for `agy.method = keyring_token`.

---

## 8. `apply-auth.sh` script

Run the script through **`source`**, otherwise exported variables will not reach the harness process. For the same
reason, it has no `set -e`: in a sourced script, that would kill the parent shell.

```bash
#!/usr/bin/env bash
# usage: source /opt/apply-auth.sh [/run/secrets/harness-auth.json]

_apply_auth() {
  local C="${1:-/run/secrets/harness-auth.json}"
  if [ ! -r "$C" ]; then
    echo "apply-auth: $C not readable" >&2
    return 1
  fi
  command -v jq >/dev/null || { echo "apply-auth: jq required" >&2; return 1; }

  j() { jq -r "$1 // empty" "$C"; }

  ########################################################################
  # Claude Code
  ########################################################################
  local tail20=""
  case "$(j .claude.method)" in
    oauth_token)
      export CLAUDE_CODE_OAUTH_TOKEN="$(j .claude.oauth_token)" ;;
    api_key)
      export ANTHROPIC_API_KEY="$(j .claude.api_key)"
      tail20="${ANTHROPIC_API_KEY: -20}" ;;
  esac
  if [ -n "$(j .claude.method)" ]; then
    local patch
    patch="$(jq -n --arg k "$tail20" '
      {hasCompletedOnboarding: true}
      + (if $k != "" then {customApiKeyResponses: {approved: [$k], rejected: []}} else {} end)')"
    if [ -f ~/.claude.json ]; then
      jq --argjson p "$patch" '. * $p' ~/.claude.json > ~/.claude.json.tmp && mv ~/.claude.json.tmp ~/.claude.json
    else
      printf '%s\n' "$patch" > ~/.claude.json
    fi
    chmod 600 ~/.claude.json
  fi

  ########################################################################
  # Codex
  ########################################################################
  case "$(j .codex.method)" in
    api_key)
      mkdir -p ~/.codex
      j .codex.api_key | codex login --with-api-key >/dev/null ;;
    chatgpt)
      mkdir -p ~/.codex
      # do not overwrite auth.json already refreshed by Codex (if ~/.codex is on a volume)
      [ -s ~/.codex/auth.json ] || jq '.codex.auth_json' "$C" > ~/.codex/auth.json ;;
  esac
  [ -f ~/.codex/auth.json ] && chmod 600 ~/.codex/auth.json

  ########################################################################
  # agy (Google Antigravity CLI)
  ########################################################################
  local agy_dir=~/.gemini/antigravity-cli
  case "$(j .agy.method)" in

    gemini_api_key)
      mkdir -p "$agy_dir"
      if [ -f "$agy_dir/settings.json" ]; then
        jq '.modelProvider = "gemini"' "$agy_dir/settings.json" > "$agy_dir/settings.json.tmp" \
          && mv "$agy_dir/settings.json.tmp" "$agy_dir/settings.json"
      else
        echo '{"modelProvider":"gemini"}' > "$agy_dir/settings.json"
      fi
      export GEMINI_API_KEY="$(j .agy.gemini_api_key)"
      [ -n "$(j .agy.base_url)" ] && export GOOGLE_GEMINI_BASE_URL="$(j .agy.base_url)"
      ;;

    keyring_token)
      # 1) start the session bus if it is not running
      if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        eval "$(dbus-launch --sh-syntax)"
        export DBUS_SESSION_BUS_ADDRESS
      fi
      # 2) gnome-keyring without a GUI: empty password -> the "login" collection is created and unlocked
      mkdir -p ~/.cache ~/.local/share/keyrings
      eval "$(printf '\n' | gnome-keyring-daemon --unlock --components=secrets)"
      eval "$(printf '\n' | gnome-keyring-daemon --start  --components=secrets)"
      # 3) seed the token with the same attributes as on the host
      local -a attrs
      mapfile -t attrs < <(jq -r '(.agy.keyring_attrs // {service:"gemini",username:"antigravity"})
                                  | to_entries[] | .key, .value' "$C")
      jq -j '.agy.token' "$C" | secret-tool store --label='agy' "${attrs[@]}"
      # 4) make the bus visible to shells opened through docker exec too
      echo "export DBUS_SESSION_BUS_ADDRESS='$DBUS_SESSION_BUS_ADDRESS'" > ~/.dbus-env
      grep -q '.dbus-env' ~/.bashrc 2>/dev/null \
        || echo '[ -f ~/.dbus-env ] && . ~/.dbus-env' >> ~/.bashrc
      ;;

    token_file)
      mkdir -p "$agy_dir"
      local fname; fname="$(j .agy.token_file_name)"; fname="${fname:-antigravity-oauth-token}"
      jq -j '.agy.token' "$C" > "$agy_dir/$fname"
      chmod 600 "$agy_dir/$fname"
      while IFS=$'\t' read -r k v; do [ -n "$k" ] && export "$k=$v"; done < <(
        jq -r '.agy.force_env // {} | to_entries[] | [.key, .value] | @tsv' "$C")
      ;;
  esac

  ########################################################################
  # opencode: files first, then env
  ########################################################################
  local p
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    mkdir -p "$(dirname "$p")"
    jq -r --arg p "$p" '
      [.opencode.providers[]?.files // {} | .[$p] | select(. != null)][0]
      | if type == "string" then . else tojson end' "$C" > "$p"
    chmod 600 "$p"
  done < <(jq -r '[.opencode.providers[]?.files // {} | keys[]] | unique[]' "$C")

  while IFS=$'\t' read -r k v; do
    [ -n "$k" ] && export "$k=$v"
  done < <(jq -r '.opencode.providers[]?.env // {} | to_entries[] | [.key, .value] | @tsv' "$C")

  [ -n "$(j .opencode.model)" ] && export OPENCODE_MODEL="$(j .opencode.model)"

  unset -f j
}

_apply_auth "$@"
unset -f _apply_auth
```

Notes:
- The script does not handle custom opencode providers (`base_url`, `openai_compatible`). For them, put an `opencode.json` based on the template in [§6](#6-opencode) in the project or `~/.config/opencode/`.
- `OPENCODE_MODEL` is simply a convenient variable for your orchestrator. It is more reliable to set the default model with the `model` field in `opencode.json`.
- `@tsv` escapes tabs and newlines. This does not matter for ordinary keys; put multiline values in `files`.

---

## 9. Running the container

### `docker run`

```bash
chmod 600 ~/secrets/harness-auth.json

docker run --rm -it \
  -v ~/secrets/harness-auth.json:/run/secrets/harness-auth.json:ro \
  -v "$PWD":/workspace -w /workspace \
  my-agent-image
```

### `docker compose` with secrets

```yaml
services:
  agent:
    image: my-agent-image
    working_dir: /workspace
    volumes:
      - ./:/workspace
      # optional: keep Codex ChatGPT tokens across restarts
      - codex-home:/home/artel/.codex
    secrets:
      - harness-auth.json
    environment:
      HARNESS_AUTH_FILE: /run/secrets/harness-auth.json
    stdin_open: true
    tty: true

secrets:
  harness-auth.json:
    file: ~/secrets/harness-auth.json

volumes:
  codex-home:
```

### Refreshing the agy token on the host (one command)

It is convenient to keep this next to the secrets file:
```bash
#!/usr/bin/env bash
# refresh-agy-token.sh: copy the current agy token from the host keyring into harness-auth.json
set -euo pipefail
F="${1:-$HOME/secrets/harness-auth.json}"
t="$(mktemp)"; trap 'rm -f "$t"' EXIT
secret-tool lookup service gemini username antigravity > "$t"
[ -s "$t" ] || { echo "agy token not found in keyring (agy login on host first)" >&2; exit 1; }
jq --rawfile tok "$t" '.agy.method = "keyring_token"
                       | .agy.keyring_attrs = {service:"gemini", username:"antigravity"}
                       | .agy.token = $tok' "$F" > "$F.new"
mv "$F.new" "$F"; chmod 600 "$F"
echo "ok"
```

---

## 10. Verification

```bash
# Claude Code
claude -p "say ok"                         # should not ask for login/onboarding

# Codex
codex login status                         # should show the login method
codex exec "say ok"

# agy
agy                                        # should not ask for login
#   look for these in the agy log:
#   keyring_token -> "ChainedAuth: authenticated via keyring"
#   token_file    -> "file-based token storage" / "authenticated via file"
#   gemini_api_key -> "Gemini API key" instead of an email in the header

# is the keyring alive in the container?
secret-tool search --all service gemini

# opencode
opencode models | head                     # provider models from env should appear
```

Common problems:

| Symptom | Cause | Action |
|---|---|---|
| Claude asks for onboarding | `~/.claude.json` is missing | check that `apply-auth.sh` ran before startup |
| Claude asks about the API key | last 20 characters do not match | check `customApiKeyResponses.approved` |
| Interactive `codex` cannot see the key | only `CODEX_API_KEY` is set | `codex login --with-api-key` is required |
| agy asks for login in a `docker exec` shell | the shell does not know `DBUS_SESSION_BUS_ADDRESS` | `. ~/.dbus-env` or a new login shell |
| agy ignores `GEMINI_API_KEY` | `modelProvider: "gemini"` is missing from `settings.json` | check `~/.gemini/antigravity-cli/settings.json` |
| agy suddenly stops accepting the token | token revoked: password change, `/logout`, or ban | run `agy` on the host, log in again, then run `refresh-agy-token.sh` |
| opencode uses the wrong key | saved `/connect` key overrides env | remove the opencode store from the image |

---

## 11. Security and risks

**Secret storage**
- `harness-auth.json` has `0600` permissions on the host and is mounted `:ro` or as a docker/k8s secret at `/run/secrets/`.
- The file never goes into the image or git: add it to `.gitignore` and `.dockerignore`.
- All token files inside the container also use `chmod 600`; the container runs as an unprivileged user.

**Where each method fits**

| Scenario | Claude | Codex | agy | opencode |
|---|---|---|---|---|
| One long-lived dev container | `oauth_token` | `chatgpt` + volume | `keyring_token` | env |
| Many disposable containers | `oauth_token` or `api_key` | `api_key` | `gemini_api_key` | env |
| CI / mass parallel runs | `api_key` | `api_key` | `gemini_api_key` | env |

**Risks of subscription tokens**
- **Codex `chatgpt`:** the refresh token rotates, so one `auth.json` shared by several parallel containers will break.
- **agy `keyring_token`:** this method is undocumented. Google has banned anomalous use of Antigravity OAuth. Keep one or two active containers per token and never give this token to third-party clients.
- In all cases, a subscription token grants account access. Leaking one is worse than leaking an API key with a budget limit.

---

## 12. Sources

**Claude Code**
- [Claude Code container (tintinweb)](https://github.com/tintinweb/claude-code-container)
- [claude-code-sdk-docker (cabinlab)](https://github.com/cabinlab/claude-code-sdk-docker)
- [Issue #16238: CLAUDE_CODE_OAUTH_TOKEN precedence](https://github.com/anthropics/claude-code/issues/16238)

**Codex**
- [Codex Authentication (OpenAI)](https://developers.openai.com/codex/auth.md)
- [Codex auth paths (aguidetocloud)](https://claw.aguidetocloud.com/openai/codex-cli/auth/)
- [Codex CLI authentication & CI (danielvaughan)](https://codex.danielvaughan.com/2026/04/01/codex-cli-authentication-flows-credential-management/)

**opencode**
- [OpenCode v2 Providers](https://v2.opencode.ai/providers)
- [OpenCode Providers docs](https://opencode.ai/v2/docs/providers)
- [models.dev](https://models.dev)

**agy: API key and billing**
- [Antigravity CLI setup (agentworks wiki)](https://github.com/manishiitg/agentworks/wiki/antigravity-cli-setup)
- [Antigravity CLI cheat sheet (computingforgeeks)](https://computingforgeeks.com/?p=171560)
- [Using agy with GitHub Agentic Workflows](https://github.github.io/gh-aw/engines/agy/)
- [Google Antigravity pricing (CloudZero)](https://www.cloudzero.com/blog/google-antigravity-pricing/)
- [Google AI plans (ai.google.dev)](https://ai.google.dev/gemini-api/docs/google-ai-plans?hl=en)
- [Gemini API rate limits (Developers Digest)](https://www.developersdigest.tech/rate-limits/google)
- [Google AI Studio free tier (BenchLM)](https://benchlm.ai/free-tier/google-ai-studio)
- [Google AI Pro vs Gemini API (Developers Digest)](https://www.developersdigest.tech/blog/google-ai-pro-vs-gemini-api-for-developers-2026)
- [Claim your Pro/Ultra API credits (kocpc)](https://en.kocpc.com.tw/?p=1927)

**agy: keyring, tokens, containers**
- [agy-cli-manager #7: Secret Service storage on Linux](https://github.com/zcop/agy-cli-manager/issues/7)
- [hermes-antigravity-subscription #1](https://github.com/soyelmismo/hermes-antigravity-subscription/issues/1)
- [AiOverviewControl PR #30: file token fallback](https://github.com/bernardopg/AiOverviewControl/pull/30)
- [antigravity-cli #57: WSL persistence](https://github.com/google-antigravity/antigravity-cli/issues/57)
- [dceoy/docker-antigravity-cli](https://github.com/dceoy/docker-antigravity-cli)
- [shelajev/agy-sbx-kit](https://github.com/shelajev/agy-sbx-kit)

**agy: bans**
- [Account not eligible / ban wave (agentpedia)](https://agentpedia.codes/blog/account-not-eligible)
- [Account restricted (Google AI forum)](https://discuss.ai.google.dev/t/account-restricted-without-warning-google-ai-ultra-oauth-via-openclaw/122778?page=2)
