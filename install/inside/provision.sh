#!/bin/bash
# Runs INSIDE a container as root. Two uses:
#   image build (install/provision-base.sh): turns images:ubuntu/24.04 into the artel-base image with user artel
#     (default, ARTEL_USER), harnesses claude, codex, opencode, and agy (the last only when AGY_BIN is passed),
#     tools, a virtual display, and the time zone;
#   installation from inside a container the user created themselves:
#     sudo ARTEL_USER=$USER bash ~/artel/install/inside/provision.sh
#     (every step is idempotent: an existing user is kept with its uid, present packages and lines are skipped).
# The artel repository is cloned into <home>/artel afterwards; PATH and ARTEL_HOME in /etc/profile.d and
# /etc/environment.d already point there. The user's home directory is the user project directory: it contains
# goal.md, agents/, src/, skills/, artel/, and scratch/.
# Environment parameters: TZ (default UTC), AGY_BIN (path to the downloaded agy binary).
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
TZ="${TZ:-UTC}"
ARTEL_USER="${ARTEL_USER:-artel}"
[ "$ARTEL_USER" != root ] || { echo "ARTEL_USER must be a regular user, not root (see docs/install.md)"; exit 2; }
HOME_DIR="$(getent passwd "$ARTEL_USER" | cut -d: -f6)"
HOME_DIR="${HOME_DIR:-/home/$ARTEL_USER}"
P="$(cd "$(dirname "$0")" && pwd)"

log() { printf '\n==> %s\n' "$*"; }

log "time zone $TZ, locales"
ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone
apt-get update -q
apt-get install -y -q locales tzdata
sed -i -E 's/^# *(en_US.UTF-8|ru_RU.UTF-8)/\1/' /etc/locale.gen && locale-gen >/dev/null
update-locale LANG=en_US.UTF-8

log "base packages"
apt-get install -y -q --no-install-recommends \
  sudo curl wget ca-certificates gnupg git gh tmux less vim-tiny htop procps file unzip zip rsync \
  python3 python3-yaml python3-pip jq ripgrep sqlite3 build-essential cmake make pkg-config \
  openssh-client iproute2 iputils-ping dnsutils net-tools

log "graphics: X server with VNC, window manager, noVNC, and automation tools"
apt-get install -y -q --no-install-recommends \
  tigervnc-standalone-server openbox novnc websockify xdotool scrot x11-utils x11-xserver-utils xterm dbus-x11 \
  dbus-user-session gnome-keyring libsecret-tools fonts-dejavu fonts-noto-core fonts-noto-color-emoji \
  libasound2t64 libgl1 libegl1 libgbm1 libnss3 libxss1 libgtk-3-0t64 libxkbcommon0 libdrm2

log "Node 22 (for codex and playwright)"
curl -fsSL https://deb.nodesource.com/setup_22.x | bash - >/dev/null
apt-get install -y -q nodejs
npx -y playwright@latest install-deps chromium >/dev/null 2>&1 || echo "playwright install-deps: skipped"

log "user $ARTEL_USER"
if id "$ARTEL_USER" &>/dev/null; then
  echo "  exists (uid $(id -u "$ARTEL_USER")); kept"
  usermod -aG sudo,video,audio,render "$ARTEL_USER"
else
  # image build: the stock ubuntu user gives way to the project user with uid 1000
  if id ubuntu &>/dev/null; then userdel -r ubuntu 2>/dev/null || userdel ubuntu; fi
  useradd -u 1000 -m -s /bin/bash -G sudo,video,audio,render "$ARTEL_USER"
fi
echo "$ARTEL_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$ARTEL_USER" && chmod 440 "/etc/sudoers.d/$ARTEL_USER"
loginctl enable-linger "$ARTEL_USER"
mkdir -p "$HOME_DIR/src" "$HOME_DIR/scratch" && chown "$ARTEL_USER:$ARTEL_USER" "$HOME_DIR/src" "$HOME_DIR/scratch"

# Image layout version. Increment whenever paths or the environment inside change (PATH, ARTEL_HOME, user):
# provision-base.sh stores it in the artel.layout image property; artel-up.sh checks it and refuses to start
# a container from an outdated image.
ARTEL_LAYOUT=2

log "environment for systemd --user and interactive shells"
mkdir -p /etc/environment.d
cat > /etc/environment.d/10-artel.conf <<ENV
PATH=$HOME_DIR/artel/bin:$HOME_DIR/.local/bin:$HOME_DIR/.npm-global/bin:$HOME_DIR/.opencode/bin:\${PATH}
ARTEL_HOME=$HOME_DIR/artel
DISPLAY=:1
LANG=en_US.UTF-8
ENV
cat > /etc/profile.d/artel.sh <<PROF
export PATH="$HOME_DIR/artel/bin:\$HOME/.local/bin:\$HOME/.npm-global/bin:\$HOME/.opencode/bin:\$PATH"
export ARTEL_HOME=$HOME_DIR/artel DISPLAY=:1 LANG=en_US.UTF-8
PROF
grep -q 'profile.d/artel.sh' "$HOME_DIR/.bashrc" || echo '. /etc/profile.d/artel.sh' >> "$HOME_DIR/.bashrc"

log "virtual display as a user service"
install -m755 "$P/artel-display" /usr/local/bin/artel-display
install -m644 "$P/artel-display.service" /etc/systemd/user/artel-display.service
systemctl --global enable artel-display.service

log "harnesses as $ARTEL_USER: claude, codex, opencode, Playwright Chromium"
sudo -u "$ARTEL_USER" -H bash -eo pipefail <<'AGENT'
cd ~
mkdir -p ~/.npm-global ~/.local/bin
npm config set prefix ~/.npm-global
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.opencode/bin:$PATH"
curl -fsSL https://claude.ai/install.sh | bash >/dev/null
npm install -g @openai/codex >/dev/null
curl -fsSL https://opencode.ai/install | bash >/dev/null
npx -y playwright@latest install chromium >/dev/null 2>&1 || echo "playwright chromium: download failed"
for b in claude codex opencode; do printf '  %-9s %s\n' "$b" "$($b --version 2>/dev/null | head -1)"; done
AGENT

log "agy: binary from the host"
if [ -n "${AGY_BIN:-}" ] && [ -f "$AGY_BIN" ]; then
  install -m755 "$AGY_BIN" /usr/local/bin/agy
  printf '  agy       %s\n' "$(sudo -u "$ARTEL_USER" -H /usr/local/bin/agy --version 2>/dev/null | head -1)"
else
  echo "  agy: binary not passed (AGY_BIN); install it later"
fi

log "cleanup"
apt-get clean && rm -rf /var/lib/apt/lists/*
[ "$P" != /tmp/provision ] || rm -rf /tmp/provision
cat > /etc/artel-base.txt <<INFO
artel-base built $(date -Is)
ubuntu $(. /etc/os-release && echo "$VERSION_ID") · node $(node --version) · TZ $TZ · user $ARTEL_USER
layout $ARTEL_LAYOUT
INFO
cat /etc/artel-base.txt
