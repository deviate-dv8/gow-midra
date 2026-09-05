#!/usr/bin/env bash
# Wrapper around enter-the-wired's combo installer. The upstream script
# unconditionally re-runs Headcrab (SLSsteam) on every invocation, which
# forces a Steam client update (-forcesteamupdate) and then immediately
# reads the just-forced update's manifest -- a race against Steam's own
# background update finishing that's the actual cause of the "50/50,
# sometimes need to retry" flakiness, not anything wrong with the patch
# itself. There's no reason to force that race again once SLSsteam is
# already attached, e.g. re-clicking this shortcut just to pick up an
# ACCELA update.
set -e

if [ -f "$HOME/.local/share/SLSsteam/SLSsteam.so" ]; then
    echo "SLSsteam is already attached -- skipping Headcrab's Steam-client patch"
    echo "(that's the flaky/racy part) and just refreshing ACCELA + dependencies."
    echo "Run ~/enter-the-wired/slssteam manually if you actually need to re-attach it."
    echo
    curl -fsSL --retry 3 --retry-delay 2 https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/fix-deps | bash
    curl -fsSL --retry 3 --retry-delay 2 https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/accela | bash
else
    curl -fsSL https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/enter-the-wired | bash
fi
