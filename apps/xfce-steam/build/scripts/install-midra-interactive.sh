#!/usr/bin/env bash
# Run from the "Install SteaMidra" Desktop shortcut, in a terminal, so the
# download/install is actually visible instead of happening silently behind
# a black screen at container start.
set -e

if [ -f "$HOME/.local/share/SteaMidra/SteaMidra.AppImage" ]; then
    echo "SteaMidra is already installed at $HOME/.local/share/SteaMidra"
    read -r -p "Re-install (re-downloads ~500MB)? [y/N] " ans
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        read -r -p "Press Enter to close..."
        exit 0
    fi
fi

/opt/gow/install-midra.sh "$MIDRA_RELEASE_URL"

echo
read -r -p "Done. Press Enter to close..."
