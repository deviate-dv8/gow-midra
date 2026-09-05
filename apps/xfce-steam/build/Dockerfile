# syntax=docker/dockerfile:1.4
ARG BASE_APP_IMAGE

######################################
# Steam's Linux Runtime (pressure-vessel) needs bwrap with CAP_SYS_ADMIN.
# Explicitly granting CAP_SYS_ADMIN at the container level (see
# assets/wolf.config.toml) makes stock bwrap refuse to run because it
# detects "tampered" capabilities, so we build the same patched bwrap the
# steam app uses and use it in place of the xfce app's setuid-root one
# further down.
FROM ${BASE_APP_IMAGE} AS bwrap-builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /root
COPY ignore_capabilities.patch /root/
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends git meson ca-certificates dpkg-dev && \
    git clone https://github.com/containers/bubblewrap && \
    cd bubblewrap && \
    ./ci/builddeps.sh && \
    patch -p1 < ../ignore_capabilities.patch && \
    meson _builddir && \
    meson compile -C _builddir

######################################
# Everything below this point up to the "Extend with Steam" marker is an
# unmodified copy of apps/xfce/build/Dockerfile.
######################################

# hadolint ignore=DL3006
FROM ${BASE_APP_IMAGE}

ARG CORE_PACKAGES=" \
    lsb-release \
    wget \
    gnupg2 \
    dbus-x11 \
    flatpak \
    sudo \
    "

ARG DE_PACKAGES=" \
    xfce4 \
    xfce4-settings \
    xubuntu-default-settings \
    xubuntu-icon-theme \
    papirus-icon-theme arc-theme \
    at-spi2-core \
    "

ARG ADDITIONAL_PACKAGES=" \
    xfce4-terminal \
    xfce4-taskmanager \
    xfce4-whiskermenu-plugin \
    xfce4-docklike-plugin \
    xarchiver \
    mousepad \
    zip unzip p7zip-full \
    gnome-software gnome-software-plugin-flatpak \
    "
RUN \
    # \
    # Setup Mozilla official APT repo (mozillateam PPA dropped Plucky support) \
    apt-get update && \
    install -d -m 0755 /etc/apt/keyrings && \
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O /etc/apt/keyrings/packages.mozilla.org.asc && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list && \
    printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla && \
    apt-get update && \
    apt-get install -y --no-install-recommends firefox && \
    # \
    # Install core packages \
    apt-get install -y $CORE_PACKAGES && \
    # \
    # Install de \
    apt-get install -y $DE_PACKAGES && \
    # \
    # Install additional apps \
    apt-get install -y --no-install-recommends $ADDITIONAL_PACKAGES && \
    # \
    # Fixes \
    rm -f \
    /etc/xdg/autostart/xscreensaver.desktop && \
    # \
    # Clean \
    apt update && \
    apt-get remove -y foot && \
    apt autoremove -y &&\
    apt clean && \
    rm -rf \
        /config/.cache \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*

#
# Replace launch scripts
COPY --chmod=777 scripts/launch-comp.sh scripts/startup.sh /opt/gow/
COPY --chmod=777 scripts/startdbus.sh /opt/gow/startdbus

#
# Include default xfce config
COPY --chmod=777 --chown=retro:retro scripts/xfce4 /opt/gow/xfce4

#
# Fix locals
COPY scripts/locale /etc/default/locale

#
# Allow anyone to start dbus without password
RUN echo "\nALL ALL=NOPASSWD: /opt/gow/startdbus" >> /etc/sudoers

#
# Fix bwarp perms for flatpaks
RUN chmod u+s /usr/bin/bwrap

######################################
# Extend with Steam + AppImage/FUSE + enter-the-wired
######################################

ARG DEBIAN_FRONTEND=noninteractive

# libxcb-cursor0 / libxcb-keysyms1: Qt 6.5+'s xcb platform plugin links
# both at load time -- missing either makes the whole plugin fail to
# dlopen, which a PyQt6 app can't recover from (aborts immediately, no
# display backend). Qt's own error message only ever mentions
# libxcb-cursor0 regardless of which one is actually missing, which is
# what made libxcb-keysyms1 easy to miss the first time around -- confirm
# with `ldd libqxcb.so | grep "not found"` if this plugin ever fails to
# load again. Not steam-specific, but there's nowhere better to put a
# couple of small packages for the desktop's other GUI apps.
ARG STEAM_PACKAGES=" \
    steam \
    dbus-daemon dbus-system-bus-common dbus-session-bus-common whoopsie network-manager bluez \
    ibus curl pkexec xz-utils zenity file xdg-user-dirs xdg-utils pciutils mesa-utils \
    libfontconfig1:i386 libfontconfig1:amd64 libfreetype6 libfreetype6:i386 \
    libxcb-cursor0 libxcb-keysyms1 \
    "

ARG AVOID_PACKAGES=" \
    nvidia-driver-libs- nvidia-vulkan-icd- \
"

# AppImage support: libfuse2/libfuse2t64 provide the FUSE 2 shim most
# AppImage runtimes link against. /dev/fuse + CapAdd SYS_ADMIN are also
# wired up (assets/wolf.config.toml) for real FUSE mounting, but that
# reliably fails with EPERM on the actual mount() syscall in this
# environment -- confirmed via strace: even a setuid-root fusermount3
# child (proven to genuinely have working CAP_SYS_ADMIN, since `sudo mount
# -t tmpfs` succeeds in the same container) gets EPERM specifically on the
# FUSE mount. This is a known enough failure mode that this repo's own
# lutris and pegasus apps already avoid real FUSE mounting entirely -- see
# https://github.com/AppImage/AppImageKit/wiki/FUSE#docker -- so we do the
# same via APPIMAGE_EXTRACT_AND_RUN below rather than relying on the mount
# actually working.
ARG FUSE_PACKAGES=" \
    libfuse2 \
    libfuse2t64 \
    "
ENV APPIMAGE_EXTRACT_AND_RUN=1

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends software-properties-common python3-six && \
    # \
    # Steam is 32-bit only \
    dpkg --add-architecture i386 && \
    add-apt-repository -y multiverse && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends \
      $STEAM_PACKAGES $AVOID_PACKAGES $FUSE_PACKAGES && \
    # \
    # Fix steam updater UI font file \
    ln -s /usr/share/fonts/truetype/dejavu /usr/share/fonts/truetype/ttf-dejavu && \
    # \
    # Cleanup \
    apt-get remove -y python3-six software-properties-common && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /config/.cache /var/tmp/* /tmp/*

# Deliberately NOT removing /var/lib/apt/lists/* above (unlike the other RUN
# blocks in this Dockerfile): enter-the-wired's fix-deps script only runs
# `apt update` when it detects i386 needs to be newly enabled, which never
# happens here since i386 is already on from the Steam packages above.
# Without a live index every apt-get install it runs -- for every package,
# not just the 32-bit ones -- reports "not found" even though the packages
# exist. Keeping the index warm costs some image size but means fix-deps
# (and any ad-hoc apt-get install troubleshooting) works without the user
# having to know to run `apt update` first.

# fix NetworkManager not picking up devices
RUN touch /etc/NetworkManager/conf.d/10-globally-managed-devices.conf

# skip annoying debian dialog
RUN rm -f /usr/bin/zenity && ln -s /usr/bin/true /usr/bin/zenity

# refresh system font cache. For font warnings on startup see: https://github.com/ValveSoftware/steam-runtime/issues/482
RUN fc-cache -f -v

# create symlink for improved decky loader / runtime compatibility
RUN ln -sf "$HOME" /home/deck

# Overwrite the setuid bwrap installed above with the patched one Steam's
# Linux Runtime needs (see the bwrap-builder stage comment).
COPY --from=bwrap-builder --chmod=755 /root/bubblewrap/_builddir/bwrap /usr/bin/bwrap

# enter-the-wired / install-plugins: run on-demand from Desktop shortcuts
# rather than automatically at container start -- Wolf bind-mounts a fresh
# per-app-slot persistent volume onto $HOME on every session
# (/etc/wolf/profile-data/user/<app name> -> /home/retro) so the mount
# starts out empty and completely hides anything written to $HOME at build
# time, and running an installer silently at startup means staring at a
# black screen until it finishes. So 10-install-wired.sh (startup.d, below)
# just drops the two Desktop shortcuts that fetch and run each installer
# visibly, in a terminal, whenever you actually want them.
RUN mkdir -p /opt/gow/startup.d
COPY --chmod=777 scripts/10-install-wired.sh /opt/gow/startup.d/10-install-wired.sh

# Fix a brand-new (empty) persistent home missing skel dotfiles and having
# Steam's own mount-point directories owned by root -- see script for why.
# Numbered to run right after 10-setup_user.sh creates the user, and before
# Steam or anything else in cont-init.d touches $HOME.
COPY --chmod=777 scripts/fix-fresh-home.sh /etc/cont-init.d/12-fix-fresh-home.sh

# Steam system services (dbus-system/bluetooth/NetworkManager for controller pairing)
COPY --chmod=777 scripts/system-services.sh /etc/cont-init.d/system-services.sh

# Default sudo password. The account name is configurable at deploy time via
# the UNAME env var (defaults to "retro"), so "ALL ALL=..." rather than a
# hardcoded username. The account itself doesn't exist until
# 10-setup_user.sh creates it at container start, so the password itself
# can only be set at runtime (see set-password.sh below), not baked in here.
#
# Inserted at the TOP of /etc/sudoers, not appended: sudoers uses
# last-match-wins, and xfce's own "ALL ALL=NOPASSWD: /opt/gow/startdbus"
# line (added earlier, above) must stay the last-matching rule for that one
# command so launch-comp.sh's passwordless `sudo /opt/gow/startdbus` keeps
# working. Appending this general rule after it previously shadowed that
# NOPASSWD entry for every command, including startdbus, which made sudo
# demand a password with no TTY to supply it and crashed the container.
RUN sed -i '1i ALL ALL=(ALL:ALL) ALL' /etc/sudoers
COPY --chmod=777 scripts/set-password.sh /etc/cont-init.d/11-set-password.sh

# enter-the-wired's fix-deps script installs packages via bare
# `sudo apt-get install ...` (no password piped in, stderr suppressed) for
# every dependency it checks -- including ones that genuinely aren't
# available, which it's built to tolerate and just skip. Without a NOPASSWD
# rule every one of those sudo calls instead fails on "a password is
# required" and gets misreported as the package itself being missing, which
# masked the real problem the first time this surfaced. Scoped to
# apt-get/dpkg/apt rather than a second blanket ALL rule, and appended here
# (after the general password-requiring ALL rule above) for the same
# last-match-wins reason as the startdbus rule below.
RUN echo "ALL ALL=NOPASSWD: /usr/bin/apt-get, /usr/bin/apt, /usr/bin/dpkg" >> /etc/sudoers

ENV XDG_RUNTIME_DIR=/tmp/.X11-unix

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
