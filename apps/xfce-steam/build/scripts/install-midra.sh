#!/usr/bin/env bash
# Fetches a SteaMidra release zip (AppImage + installer + icon) and runs its
# installer. Used at image build time so a fresh container never has to
# download/reinstall (HOME is ephemeral unless the deployer mounts a
# persistent volume onto it).
set -euo pipefail

source /opt/gow/bash-lib/utils.sh

MIDRA_URL="${1:?usage: install-midra.sh <release-zip-url>}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

gow_log "Fetching SteaMidra from ${MIDRA_URL}"
curl -fsSL "${MIDRA_URL}" -o "${WORKDIR}/steamidra.zip"
unzip -q "${WORKDIR}/steamidra.zip" -d "${WORKDIR}"

chmod +x "${WORKDIR}"/*.AppImage "${WORKDIR}"/*install.sh

installer="$(ls "${WORKDIR}"/*install.sh | head -1)"
gow_log "Running $(basename "${installer}")"
"${installer}" install
