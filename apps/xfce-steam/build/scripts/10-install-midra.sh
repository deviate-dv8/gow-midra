#!/usr/bin/env bash
set -e

source /opt/gow/bash-lib/utils.sh

# $HOME is a fresh per-app volume Wolf bind-mounts in on every session
# (persists across restarts of *this* app, but invisible to the image at
# build time), so the shortcut has to be (re-)created here rather than
# baked in. This only ever writes a couple of small text files -- the
# actual ~500MB install is left for the user to trigger from the Desktop,
# instead of blocking startup behind a silent download.
SHORTCUT="$HOME/Desktop/Install SteaMidra.desktop"

if [ ! -f "$SHORTCUT" ]; then
    gow_log "Creating SteaMidra install shortcut on the Desktop"
    mkdir -p "$HOME/Desktop"
    cat > "$SHORTCUT" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Install SteaMidra
Comment=Download and install SteaMidra (one-time, ~500MB)
Exec=bash /opt/gow/install-midra-interactive.sh
Icon=utilities-terminal
Terminal=true
Categories=Utility;
EOF
    chmod +x "$SHORTCUT"
    gio set "$SHORTCUT" metadata::trusted true 2>/dev/null || true
fi
