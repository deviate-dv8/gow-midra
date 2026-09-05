#!/bin/sh

source /opt/gow/bash-lib/utils.sh

# Steam Big Picture / controller pairing needs a couple of system services
# that aren't started by the xfce session bus.

mkdir -p /run/dbus
dbus-daemon --system --fork --nosyslog
gow_log "*** DBus started ***"
bluetoothd --nodetach &
gow_log "*** Bluez started ***"
NetworkManager
gow_log "*** NetworkManager started ***"
