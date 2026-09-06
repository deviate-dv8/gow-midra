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

# `cp` above runs as root, so anything it actually copied (only happens on
# a brand-new empty home; cp -n leaves pre-existing files alone) is left
# root-owned -- including .config, which retro then can't write into
# (`mkdir .config/xfce4: Permission denied`, breaking startup entirely).
# Recurse into skel's own top-level entries by name rather than the whole
# $HOME: cheap and correct regardless of how large the rest of $HOME has
# grown (games, ACCELA, etc.), since skel itself is tiny.
for entry in /etc/skel/. /etc/skel/..?* /etc/skel/.[!.]* /etc/skel/*; do
    name="$(basename "$entry")"
    [ "$name" = "." ] && continue
    [ -e "$HOME/$name" ] || continue
    chown -R "${PUID:-1000}:${PGID:-1000}" "$HOME/$name" 2>/dev/null || true
done
