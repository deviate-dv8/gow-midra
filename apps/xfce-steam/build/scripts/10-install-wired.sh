#!/usr/bin/env bash
set -e

source /opt/gow/bash-lib/utils.sh

# $HOME is a fresh per-app volume Wolf bind-mounts in on every session
# (persists across restarts of *this* app, but invisible to the image at
# build time), so the shortcuts have to be (re-)created here rather than
# baked in.
mkdir -p "$HOME/Desktop"

WIRED_SHORTCUT="$HOME/Desktop/Enter the Wired.desktop"
if [ ! -f "$WIRED_SHORTCUT" ]; then
    gow_log "Creating Enter the Wired install shortcut on the Desktop"
    cat > "$WIRED_SHORTCUT" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Enter the Wired
Comment=Run the enter-the-wired installer
Exec=bash -c "/opt/gow/enter-the-wired-wrapper.sh; echo; read -r -p 'Done. Press Enter to close...'"
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

# The panel's own Log Out button is broken (its command-logout string uses
# "&&", which xfce4-panel spawns via g_shell_parse_argv rather than a real
# shell -- that only tokenizes, it doesn't interpret shell operators, so
# "&&" ends up passed to pkill as a literal extra argument and pkill just
# errors out on "only one pattern can be provided", doing nothing). This
# shortcut does the same job xfce4-session-logout should: ending
# xfce4-session and Xwayland, which is what launch-comp.sh's exec chain is
# blocked on, so it makes the whole container exit and Wolf return to its
# own UI.
WOLFUI_SHORTCUT="$HOME/Desktop/Go back to Wolf UI.desktop"
if [ ! -f "$WOLFUI_SHORTCUT" ]; then
    gow_log "Creating Go back to Wolf UI shortcut on the Desktop"
    cat > "$WOLFUI_SHORTCUT" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Go back to Wolf UI
Comment=End this session and return to the Wolf UI
Exec=sh -c "pkill xfce4-session; pkill Xwayland"
Icon=system-log-out
Terminal=false
Categories=Utility;
EOF
    chmod +x "$WOLFUI_SHORTCUT"
    gio set "$WOLFUI_SHORTCUT" metadata::trusted true 2>/dev/null || true
fi
