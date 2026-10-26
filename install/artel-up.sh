#!/bin/bash
# Starts a user-project container from the artel-base image. Run on an Incus host.
#
#   install/artel-up.sh <name> [--user <name>] [--image <alias>]
#                 [--mount <host directory>:<path inside>[:ro]]... [--mem 8GiB] [--cpu N]
#                 [--novnc <port>] [--gpu] [--artel <clone directory>] [--artel-url <git url>] [--skip-image-check]
#
# The container is named artel-<name>. The user project is the selected user's home directory
# inside the container: it contains goal.md, agents/, src/, skills/, artel/ and scratch/. The project
# decides which of these are mounted from the host: --mount is optional and can be repeated.
# The path inside can be absolute or relative to the home directory (for example, src/project). Files on
# the host belong to whoever runs the script (shift=true). The artel repository is cloned to
# <home>/artel. --novnc sets the host port (noVNC is always 6080 inside), one per project.
#
#   install/artel-up.sh demo --mount ~/work/demo:src/demo --gpu --novnc 6081
set -euo pipefail
usage() { sed -n 2,15p "$0" | sed 's/^# \{0,1\}//'; exit 2; }
NAME="${1:-}"; [ -n "$NAME" ] && [ "${NAME#-}" = "$NAME" ] || usage; shift
USER_IN=""; USER_SET=0; IMAGE="artel-base"
MOUNTS=(); MEM="8GiB"; CPU=""; NOVNC=""; GPU=0; ARTEL="$(cd "$(dirname "$0")/.." && pwd)"; ARTEL_URL=""; IMAGE_CHECK=1
val() { [ $# -ge 2 ] && [ -n "$2" ] || { echo "flag $1 requires a value"; usage; }; }
while [ $# -gt 0 ]; do
  case "$1" in
    --user) val "$@"; USER_IN="$2"; USER_SET=1; shift 2;;
    --image) val "$@"; IMAGE="$2"; shift 2;;
    --mount) val "$@"; MOUNTS+=("$2"); shift 2;;
    --mem) val "$@"; MEM="$2"; shift 2;;
    --cpu) val "$@"; CPU="$2"; shift 2;;
    --novnc) val "$@"; NOVNC="$2"; shift 2;;
    --gpu) GPU=1; shift;;
    --artel) val "$@"; ARTEL="$2"; shift 2;;
    --artel-url) val "$@"; ARTEL_URL="$2"; shift 2;;
    --skip-image-check) IMAGE_CHECK=0; shift;;
    *) echo "unknown argument $1"; usage;;
  esac
done
C="artel-$NAME"
if incus info "$C" >/dev/null 2>&1; then echo "container $C already exists; delete it (incus delete -f $C) or choose another name"; exit 1; fi
incus image info "$IMAGE" >/dev/null 2>&1 || { echo "$IMAGE image not found: build it with install/provision-base.sh"; exit 2; }
if [ "$USER_SET" -eq 0 ]; then
  USER_IN="$(incus image get-property "$IMAGE" artel.user 2>/dev/null || true)"
  USER_IN="${USER_IN:-artel}"
fi
HOME_IN="/home/$USER_IN"
# An old-layout image technically exists but would start a container with broken PATH/ARTEL_HOME:
# check the layout version (the artel.layout image property set by provision-base.sh).
WANT_LAYOUT="$(sed -nE 's/^ARTEL_LAYOUT=([0-9]+).*/\1/p' "$(dirname "$0")/inside/provision.sh" | head -1)"
HAVE_LAYOUT="$(incus image get-property "$IMAGE" artel.layout 2>/dev/null || true)"
if [ "$IMAGE_CHECK" = 1 ] && [ -n "$WANT_LAYOUT" ] && [ "$HAVE_LAYOUT" != "$WANT_LAYOUT" ]; then
  echo "$IMAGE image is outdated: layout ‘${HAVE_LAYOUT:-unset}’, need ‘$WANT_LAYOUT’ (built $(incus image info "$IMAGE" 2>/dev/null | sed -nE 's/^ *Created: *//p' | head -1))."
  echo "rebuild it: install/provision-base.sh (10–20 minutes). Start from the old image despite the check: --skip-image-check"
  exit 2
fi
ARTEL_SRC_MOUNT=0
if [ -z "$ARTEL_URL" ]; then
  [ -d "$ARTEL" ] || { echo "artel repository not found: $ARTEL (use --artel <clone directory>)"; exit 2; }
  ARTEL="$(cd "$ARTEL" && pwd)"
  if ! ARTEL_URL="$(git -C "$ARTEL" remote get-url origin 2>/dev/null)" || [ -z "$ARTEL_URL" ]; then
    ARTEL_URL=/mnt/artel-src
    ARTEL_SRC_MOUNT=1
  fi
fi
if [ -n "$NOVNC" ] && ss -ltn 2>/dev/null | awk '{print $4}' | grep -qE "[:.]$NOVNC\$"; then
  echo "host port $NOVNC is already in use: choose another --novnc port (one per project)"; exit 2
fi
TZ_HOST="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
TZ_HOST="${TZ_HOST:-UTC}"

# Parse --mount before creating the container so no partial container is left behind.
M_SRC=(); M_DST=(); M_RO=()
for m in "${MOUNTS[@]}"; do
  src="${m%%:*}"; rest="${m#*:}"; [ "$rest" != "$m" ] || { echo "--mount expects <host>:<path inside>[:ro], got $m"; exit 2; }
  dst="${rest%%:*}"; mode="${rest#*:}"; [ "$mode" != "$rest" ] || mode=rw
  [ -d "$src" ] || { echo "--mount: host directory $src does not exist"; exit 2; }
  case "$dst" in /*) ;; *) dst="$HOME_IN/$dst";; esac
  M_SRC+=("$(cd "$src" && pwd)"); M_DST+=("$dst"); M_RO+=("$mode")
done

echo "==> $C from $IMAGE"
incus init "$IMAGE" "$C" -q
incus config set "$C" boot.autostart=true limits.memory="$MEM" snapshots.schedule="@daily" snapshots.expiry=14d \
  environment.TZ="$TZ_HOST"
[ -n "$CPU" ] && incus config set "$C" limits.cpu="$CPU"
# Ubuntu 26.04 (kernel 7.0, AppArmor 5): processes inside the container appear to the host as
# "profile//&unconfined", which the standard Incus `signal peer=@{profile_name}` rule does not cover.
# Without these lines, no process inside the container can signal another (kill, timeout,
# tmux kill-server, stopping systemd units), leaving workers orphaned.
incus config set "$C" raw.apparmor="signal peer=@{profile_name}//&*,
ptrace peer=@{profile_name}//&*,"
if [ "$ARTEL_SRC_MOUNT" = 1 ]; then
  incus config device add "$C" artel-src disk source="$ARTEL" path=/mnt/artel-src shift=true readonly=true -q
fi
for i in "${!M_SRC[@]}"; do
  incus config device add "$C" "mount$i" disk source="${M_SRC[$i]}" path="${M_DST[$i]}" shift=true \
    $([ "${M_RO[$i]}" = ro ] && echo readonly=true) -q
done
if [ "$GPU" = 1 ]; then
  incus config set "$C" nvidia.runtime=true
  incus config device add "$C" gpu gpu -q
fi
if [ -n "$NOVNC" ]; then
  incus config device add "$C" novnc proxy listen="tcp:0.0.0.0:$NOVNC" connect=tcp:127.0.0.1:6080 -q
fi
incus start "$C"
echo "==> waiting for systemd inside"
for _ in $(seq 1 60); do
  st="$(incus exec "$C" -- systemctl is-system-running 2>/dev/null || true)"
  case "$st" in running|degraded) break;; esac; sleep 1
done
USER_UID="$(incus exec "$C" -- id -u "$USER_IN")" || { echo "user $USER_IN does not exist in the $IMAGE image (see --user)"; exit 2; }
for _ in $(seq 1 30); do incus exec "$C" -- systemctl is-active "user@$USER_UID.service" >/dev/null 2>&1 && break; sleep 1; done
# Incus creates intermediate mount directories as root; give them back to the user.
for i in "${!M_DST[@]}"; do
  p="$(dirname "${M_DST[$i]}")"
  while [[ "$p" == "$HOME_IN"/* ]]; do
    incus exec "$C" -- chown "$USER_IN:$USER_IN" "$p" 2>/dev/null || true; p="$(dirname "$p")"
  done
done
# Signals must work inside, otherwise agents cannot stop workers and systemd units
if incus exec "$C" -- sudo -u "$USER_IN" bash -c 'sleep 5 & kill $! 2>&1' | grep -q "Permission denied"; then
  echo "WARNING: inside $C, a process cannot signal even its own child (host AppArmor)." >&2
  echo "  Check raw.apparmor: incus config get $C raw.apparmor ; kernel version: $(uname -r)" >&2
fi
# The artel clone initializes the project home directory after systemd starts.
INIT_OUTPUT=""
set +e
INIT_OUTPUT="$(incus exec "$C" -- sudo -iu "$USER_IN" env ARTEL_URL="$ARTEL_URL" PROJECT_NAME="$NAME" bash -se <<'INNER'
set -euo pipefail
cd "$HOME"
if [ ! -e "$HOME/artel" ]; then
  git -c protocol.file.allow=always clone -q "$ARTEL_URL" "$HOME/artel"
fi
python3 "$HOME/artel/bin/artel" init --project "$PROJECT_NAME" --artel-url "$ARTEL_URL"
INNER
)"
INIT_STATUS=$?
set -e
if [ "$INIT_STATUS" -ne 0 ]; then
  printf 'failed to initialize project home directory:\n%s\n' "$INIT_OUTPUT" >&2
  exit 1
fi
incus snapshot create "$C" fresh
cat <<MSG

Done: $C ($st). Snapshot ‘fresh’ created.
  user project: $HOME_IN (goal.md, agents/, src/, skills/, artel/, scratch/)
MSG
for i in "${!M_SRC[@]}"; do printf '  mounted:      %s  <-  %s (%s)\n' "${M_DST[$i]}" "${M_SRC[$i]}" "${M_RO[$i]}"; done
[ "$ARTEL_SRC_MOUNT" = 1 ] && printf '  mounted:      /mnt/artel-src  <-  %s (ro)\n' "$ARTEL"
[ -n "$NOVNC" ] && printf '  agent screen: http://<host address>:%s/vnc.html\n' "$NOVNC"
echo
incus exec "$C" -- sudo -iu "$USER_IN" artel cheatsheet --container "$C"
