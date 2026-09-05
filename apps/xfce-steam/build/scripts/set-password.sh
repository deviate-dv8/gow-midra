#!/usr/bin/env bash
set -e

source /opt/gow/bash-lib/utils.sh

gow_log "Setting default sudo password for ${UNAME}"
echo "${UNAME}:retro" | chpasswd

gow_log "DONE"
