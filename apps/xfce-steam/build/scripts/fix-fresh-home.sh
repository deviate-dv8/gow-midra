#!/usr/bin/env bash
set -e

source /opt/gow/bash-lib/utils.sh

# On a brand-new (empty) persistent home, `useradd -m` (in 10-setup_user.sh)
# only populates skel files when it actually CREATES the home directory --
# since Wolf always bind-mounts an existing (if empty) per-app-slot
# directory onto $HOME, useradd sees it already exists and skips the skel
# copy entirely. Result: no .bashrc/.profile, so nothing adds ~/.local/bin
# to PATH, and e.g. ACCELA's installer telling you to "add ~/.local/bin to
# PATH to run accela from a terminal" has nothing to add it to.
gow_log "Ensuring skel files exist in $HOME"
cp -rn /etc/skel/. "$HOME"/ 2>/dev/null || true
chown "${PUID:-1000}:${PGID:-1000}" "$HOME"/.bashrc "$HOME"/.profile "$HOME"/.bash_logout 2>/dev/null || true
