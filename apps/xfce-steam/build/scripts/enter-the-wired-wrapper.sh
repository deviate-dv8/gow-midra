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

# Headcrab's own SLSsteam-Any-release.7z has shipped bin/library-inject.so
# as a 0-byte file since its 2026-09-03 release (20260903114323) -- verified
# against the previous release (20260820085507), where it's a real 26KB
# ELF library. LD_AUDIT loads library-inject.so and SLSsteam.so together;
# an empty first library breaks that chain, which is why SLSsteam's config
# loads (its own init log lines appear) but it never gets far enough to
# report attaching to steamclient.so. Not something we can fix upstream
# from here, so patch the known-good copy in over the broken one until
# AceSLS/SLSsteam ships a fix.
INJECT_LIB="$HOME/.local/share/SLSsteam/library-inject.so"
if [ -f "$INJECT_LIB" ] && [ ! -s "$INJECT_LIB" ]; then
    echo
    echo "library-inject.so shipped empty in this SLSsteam release (upstream"
    echo "regression) -- patching in a known-good copy from the previous release."
    GOOD_LIB_TMP="$(mktemp -d)"
    if curl -fsSL --retry 3 --retry-delay 2 \
         "https://github.com/AceSLS/SLSsteam/releases/download/20260820085507/SLSsteam-Any-release.7z" \
         -o "$GOOD_LIB_TMP/good.7z" \
       && 7z x -y -o"$GOOD_LIB_TMP/extract" "$GOOD_LIB_TMP/good.7z" bin/library-inject.so >/dev/null 2>&1 \
       && [ -s "$GOOD_LIB_TMP/extract/bin/library-inject.so" ]; then
        cp "$GOOD_LIB_TMP/extract/bin/library-inject.so" "$INJECT_LIB"
        chmod 755 "$INJECT_LIB"
        echo "Fixed: library-inject.so replaced with a working copy."
    else
        echo "Could not fetch a working library-inject.so -- SLSsteam may not fully attach."
    fi
    rm -rf "$GOOD_LIB_TMP"
fi
