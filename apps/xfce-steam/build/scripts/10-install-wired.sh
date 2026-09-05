#!/usr/bin/env bash
set -e

source /opt/gow/bash-lib/utils.sh

# $HOME is a fresh per-app volume Wolf bind-mounts in on every session
# (persists across restarts of *this* app, but invisible to the image at
# build time), so the shortcuts have to be (re-)created here rather than
# baked in.
mkdir -p "$HOME/Desktop"

# Remove the old SteaMidra shortcut left behind on persistent volumes from
# before this app switched installers -- it points at install-midra-*.sh,
# which no longer exists in the image.
rm -f "$HOME/Desktop/Install SteaMidra.desktop"

WIRED_SHORTCUT="$HOME/Desktop/Enter the Wired.desktop"
if [ ! -f "$WIRED_SHORTCUT" ]; then
    gow_log "Creating Enter the Wired install shortcut on the Desktop"
    cat > "$WIRED_SHORTCUT" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Enter the Wired
Comment=Run the enter-the-wired installer
Exec=bash -c "curl -fsSL https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/enter-the-wired | bash; echo; read -r -p 'Done. Press Enter to close...'"
Icon=utilities-terminal
Terminal=true
Categories=Utility;
EOF
    chmod +x "$WIRED_SHORTCUT"
    gio set "$WIRED_SHORTCUT" metadata::trusted true 2>/dev/null || true
fi

PLUGINS_SHORTCUT="$HOME/Desktop/Install Plugins.desktop"
if [ ! -f "$PLUGINS_SHORTCUT" ]; then
    gow_log "Creating Install Plugins shortcut on the Desktop"
    cat > "$PLUGINS_SHORTCUT" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Install Plugins
Comment=Run the install-plugins installer
Exec=bash -c "curl -fsSL https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/install-plugins | bash; echo; read -r -p 'Done. Press Enter to close...'"
Icon=utilities-terminal
Terminal=true
Categories=Utility;
EOF
    chmod +x "$PLUGINS_SHORTCUT"
    gio set "$PLUGINS_SHORTCUT" metadata::trusted true 2>/dev/null || true
fi
