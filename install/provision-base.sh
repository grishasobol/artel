#!/bin/bash
# Builds the artel-base image on an Incus host: a container from images:ubuntu/24.04,
# install/inside/provision.sh inside it, then publishes it under the artel-base alias. Run on the host:
# install/provision-base.sh [--keep] [--user <name>]
# --keep keeps the build container for troubleshooting.
# --user selects the container user name (default: artel).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BUILD=artel-build
ALIAS=artel-base
KEEP=0
USER_IN=artel
while [ "$#" -gt 0 ]; do
  case "$1" in
    --keep) KEEP=1; shift ;;
    --user)
      [ "$#" -ge 2 ] && [ -n "$2" ] || { echo "flag --user requires a value" >&2; exit 2; }
      USER_IN="$2"
      shift 2
      ;;
    *) echo "unknown argument $1" >&2; exit 2 ;;
  esac
done
TZ_HOST="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
TZ_HOST="${TZ_HOST:-UTC}"
AGY_SRC="$(command -v agy || ls "$HOME/.local/bin/agy" 2>/dev/null || true)"
LAYOUT="$(sed -nE 's/^ARTEL_LAYOUT=([0-9]+).*/\1/p' "$HERE/inside/provision.sh" | head -1)"
[ -n "$LAYOUT" ] || { echo "install/inside/provision.sh has no ARTEL_LAYOUT=<n>"; exit 2; }

if incus info "$BUILD" >/dev/null 2>&1; then
  echo "build container $BUILD already exists; deleting"; incus delete -f "$BUILD"
fi
echo "==> container $BUILD from images:ubuntu/24.04"
incus launch images:ubuntu/24.04 "$BUILD" -q
for _ in $(seq 1 60); do
  incus exec "$BUILD" -- sh -c 'ping -c1 -W1 1.1.1.1 >/dev/null 2>&1' && break; sleep 1
done
echo "==> transferring files"
incus exec "$BUILD" -- mkdir -p /tmp/provision
for f in "$HERE"/inside/*; do
  incus file push -q "$f" "$BUILD/tmp/provision/"
done
AGY_ENV=""
if [ -n "$AGY_SRC" ]; then
  incus file push -q "$AGY_SRC" "$BUILD/tmp/provision/agy"; AGY_ENV="AGY_BIN=/tmp/provision/agy"
else
  echo "   agy not found on the host; it will not be included in the image"
fi
echo "==> provisioning inside (several minutes)"
incus exec "$BUILD" --env TZ="$TZ_HOST" --env ARTEL_USER="$USER_IN" ${AGY_ENV:+--env $AGY_ENV} -- bash /tmp/provision/provision.sh
echo "==> publishing as $ALIAS"
incus stop "$BUILD"
incus image delete "$ALIAS" 2>/dev/null || true
incus publish "$BUILD" --alias "$ALIAS" -q artel.layout="$LAYOUT" artel.user="$USER_IN" artel.commit="$(git -C "$HERE" rev-parse --short HEAD 2>/dev/null || echo unknown)"
incus image list "$ALIAS" --format csv -c l,s,u
echo "   image property artel.layout=$LAYOUT"
echo "   image property artel.user=$USER_IN"
[ "$KEEP" = 1 ] || incus delete "$BUILD"
echo "done: incus launch $ALIAS <name>, or install/artel-up.sh"
