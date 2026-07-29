#!/usr/bin/env bash
#
# predator-sense — installer
# PredatorSense-style control suite for Acer Predator laptops on Linux.
# Tested on the Acer Predator PT316-51s (Triton 300 SE).
#
# Installs a patched Linuwu-Sense driver plus console utilities, the Turbo
# button toggle, keyboard-backlight persistence and the Fn+F4 screen fix.
#
#   sudo ./install.sh
#
# NO WARRANTY. This modifies kernel modules and system configuration.
# You run it entirely at your own risk. See DISCLAIMER.md / LICENSE.
#
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

# DKMS identity, read straight from driver/dkms.conf so there is one source of
# truth for the package version.
DKMS_NAME="$(sed -n 's/^PACKAGE_NAME="\(.*\)"$/\1/p' "$HERE/driver/dkms.conf")"
DKMS_VER="$(sed -n 's/^PACKAGE_VERSION="\(.*\)"$/\1/p' "$HERE/driver/dkms.conf")"
DKMS_SRC="/usr/src/$DKMS_NAME-$DKMS_VER"

if [ "$(id -u)" -ne 0 ]; then
    echo "This installer must run as root:  sudo ./install.sh" >&2
    exit 1
fi

TARGET_USER="${SUDO_USER:-}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
    echo "Could not determine the target (non-root) user." >&2
    echo "Run it as:  sudo ./install.sh   (not from a root login)" >&2
    exit 1
fi

echo "==================================================="
echo " predator-sense installer"
echo " target user: $TARGET_USER"
echo "---------------------------------------------------"
echo " NO WARRANTY — use at your own risk (see DISCLAIMER.md)"
echo "==================================================="

# ---------------------------------------------------------------------------
# 1) dependencies (multi-distro)
install_deps() {
    if command -v dnf >/dev/null 2>&1; then
        dnf install -y "kernel-devel-$(uname -r)" kernel-headers gcc make git dkms \
            || dnf install -y kernel-devel kernel-headers gcc make git dkms
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y "linux-headers-$(uname -r)" build-essential git dkms \
            || apt-get install -y linux-headers-generic build-essential git dkms
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm --needed linux-headers base-devel git dkms
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install kernel-devel gcc make git dkms \
            || zypper --non-interactive install kernel-default-devel gcc make git dkms
    else
        echo "!! Unknown package manager. Install these manually and re-run:" >&2
        echo "   kernel headers for $(uname -r), gcc, make, git, dkms" >&2
        exit 1
    fi
}
echo "[1/9] Installing build dependencies..."
install_deps

# ---------------------------------------------------------------------------
echo "[2/9] Turbo button -> toggle mode (modprobe option)..."
install -m 0644 "$HERE/config/linuwu_sense-options.conf" \
    /etc/modprobe.d/linuwu_sense-options.conf

# ---------------------------------------------------------------------------
# The driver is registered with DKMS so that a kernel upgrade rebuilds it
# automatically. Without this the module only matches the kernel it was built
# against and silently stops loading after the next upgrade.
echo "[3/9] Registering the driver with DKMS and building it..."
if command -v dkms >/dev/null 2>&1; then
    # Deregister any previously registered version, so re-running this
    # installer (after editing the driver, or on a fresh clone) is idempotent.
    for old in /usr/src/"$DKMS_NAME"-*; do
        [ -d "$old" ] || continue
        dkms remove -m "$DKMS_NAME" -v "${old##*-}" --all >/dev/null 2>&1 || true
        rm -rf "$old"
    done

    make -C "$HERE/driver" clean >/dev/null 2>&1 || true
    install -d -m 0755 "$DKMS_SRC"
    cp -a "$HERE/driver/." "$DKMS_SRC/"
    # Never ship build leftovers into the DKMS source tree.
    find "$DKMS_SRC" \( -name '*.o' -o -name '*.ko' -o -name '*.mod' \
        -o -name '*.mod.c' -o -name '.*.cmd' -o -name 'Module.symvers' \
        -o -name 'modules.order' \) -delete

    dkms add -m "$DKMS_NAME" -v "$DKMS_VER"

    # Build for every installed kernel that has headers, not just the running
    # one, so booting an older kernel entry keeps the driver.
    for kdir in /lib/modules/*/build; do
        [ -d "$kdir" ] || continue
        kver="$(basename "$(dirname "$kdir")")"
        if ! dkms build -m "$DKMS_NAME" -v "$DKMS_VER" -k "$kver" --force; then
            echo "!! DKMS build failed for $kver — leaving any existing module alone." >&2
            continue
        fi
        # Drop the hand-installed module from a pre-DKMS install *before* DKMS
        # puts its own copy in .../extra. Doing it after would let DKMS archive
        # the stale module as an "original" and restore it again on uninstall.
        rm -f "/lib/modules/$kver/kernel/drivers/platform/x86/linuwu_sense.ko"*
        dkms install -m "$DKMS_NAME" -v "$DKMS_VER" -k "$kver" --force
        depmod -a "$kver"
    done

    if ! modinfo -k "$(uname -r)" linuwu_sense >/dev/null 2>&1; then
        echo "!! DKMS did not produce a module for the running kernel $(uname -r)." >&2
        echo "   Check 'dkms status' and /var/lib/dkms/$DKMS_NAME/$DKMS_VER/build/make.log" >&2
        exit 1
    fi
    DKMS_ACTIVE=1
else
    echo "!! dkms is unavailable — falling back to a one-off build for $(uname -r)."
    echo "!! You will have to re-run this installer after every kernel upgrade."
    make -C "$HERE/driver" clean >/dev/null 2>&1 || true
    make -C "$HERE/driver"
    # This target also does everything step 4 below would have done.
    make -C "$HERE/driver" install
    DKMS_ACTIVE=0
fi

# ---------------------------------------------------------------------------
echo "[4/9] Autoload, unload service, group and sysfs permissions..."
if [ "$DKMS_ACTIVE" = 1 ]; then
    rmmod acer_wmi 2>/dev/null || true
    echo "blacklist acer_wmi" > /etc/modprobe.d/blacklist-acer_wmi.conf
    echo "linuwu_sense"      > /etc/modules-load.d/linuwu_sense.conf
    modprobe linuwu_sense 2>/dev/null || true
    # Unload service, linuwu_sense group and 0660 sysfs permissions (tmpfiles.d).
    make -C "$HERE/driver" config
fi

# ---------------------------------------------------------------------------
echo "[5/9] Installing console utilities to /usr/local/bin..."
for u in turbo profile fan temps battery kb usbcharge \
         predator-profile-set predator-kb-restore; do
    install -m 0755 "$HERE/bin/$u" "/usr/local/bin/$u"
done

# ---------------------------------------------------------------------------
echo "[6/9] Passwordless helper for platform-profile (sudoers)..."
printf '%s ALL=(root) NOPASSWD: /usr/local/bin/predator-profile-set\n' "$TARGET_USER" \
    > /etc/sudoers.d/predator-sense
chmod 0440 /etc/sudoers.d/predator-sense
visudo -cf /etc/sudoers.d/predator-sense >/dev/null

# ---------------------------------------------------------------------------
echo "[7/9] Fn+F4 fix (stop it from dimming the screen)..."
install -m 0644 "$HERE/config/90-predator-fnf4.hwdb" \
    /etc/udev/hwdb.d/90-predator-fnf4.hwdb
systemd-hwdb update
udevadm trigger --subsystem-match=input --action=change || true

# ---------------------------------------------------------------------------
echo "[8/9] Keyboard-backlight persistence..."
install -d -m 0755 /var/lib/predator-sense
# Seed a default "on" state so the backlight comes up at boot (white, full
# brightness). The user can change it any time with `kb` and it will persist.
if [ ! -s /var/lib/predator-sense/kb.state ]; then
    echo "PZ:ffffff,ffffff,ffffff,ffffff,100" > /var/lib/predator-sense/kb.state
fi
chgrp linuwu_sense /var/lib/predator-sense/kb.state 2>/dev/null || true
chmod 0664 /var/lib/predator-sense/kb.state
install -m 0644 "$HERE/config/predator-kb-restore.service" \
    /etc/systemd/system/predator-kb-restore.service
systemctl daemon-reload
systemctl enable predator-kb-restore.service

# ---------------------------------------------------------------------------
echo "[9/9] Reloading module so the Turbo toggle option takes effect..."
modprobe -r linuwu_sense 2>/dev/null || true
modprobe linuwu_sense
sleep 2
# Reloading recreates the sysfs attributes from scratch, so they come back as
# 0644 root:root and the group loses write access until the next boot. Re-apply
# the tmpfiles rules now.
systemd-tmpfiles --create /etc/tmpfiles.d/linuwu_sense.conf 2>/dev/null || true
# The reload also drops the keyboard backlight, and the restore service only
# runs at boot — so re-apply the saved state right away.
/usr/local/bin/predator-kb-restore || true

echo
echo "==================================================="
echo " Done!"
echo " Commands: turbo, profile, fan, temps, battery, kb, usbcharge"
echo " Try: 'kb help', 'fan', 'battery', 'temps'"
echo
echo " NOTE: log out and back in once so '$TARGET_USER' picks up the"
echo "       'linuwu_sense' group (needed for kb/fan/battery without sudo)."
echo "==================================================="
