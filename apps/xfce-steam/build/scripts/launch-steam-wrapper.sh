#!/usr/bin/env bash
# See the Dockerfile for why this replaces /usr/games/steam. Headcrab
# (SLSsteam) patches $HOME/.steam/steam/steam.sh with the actual LD_AUDIT
# injection and its attach notification, but nothing else ever points
# there by default -- not Ubuntu's own steam.desktop, not the real
# /usr/games/steam (now at steam.real), and not even Headcrab's own
# internal update probe. Since nothing actually executes the patched file,
# SLSsteam only ever attached by accident depending on which internal path
# a given Headcrab run happened to take -- that's the real cause of the
# "50/50, have to retry" flakiness and the missing attach notification, not
# anything wrong with the patch itself. Route through it whenever it
# exists (i.e. once enter-the-wired/Headcrab has run at least once);
# otherwise fall back to the real launcher unmodified.
if [ -x "$HOME/.steam/steam/steam.sh" ]; then
    exec "$HOME/.steam/steam/steam.sh" "$@"
else
    exec /usr/games/steam.real "$@"
fi
