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
        dnf install -y "kernel-devel-$(uname -r)" kernel-headers gcc make git \
            || dnf install -y kernel-devel kernel-headers gcc make git
    elif command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y "linux-headers-$(uname -r)" build-essential git \
            || apt-get install -y linux-headers-generic build-essential git
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm --needed linux-headers base-devel git
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install kernel-devel gcc make git \
            || zypper --non-interactive install kernel-default-devel gcc make git
    else
        echo "!! Unknown package manager. Install these manually and re-run:" >&2
        echo "   kernel headers for $(uname -r), gcc, make, git" >&2
        exit 1
    fi
}
echo "[1/8] Installing build dependencies..."
install_deps

# ---------------------------------------------------------------------------
echo "[2/8] Turbo button -> toggle mode (modprobe option)..."
install -m 0644 "$HERE/config/linuwu_sense-options.conf" \
    /etc/modprobe.d/linuwu_sense-options.conf

# ---------------------------------------------------------------------------
echo "[3/8] Building and installing the Linuwu-Sense driver..."
make -C "$HERE/driver" clean >/dev/null 2>&1 || true
make -C "$HERE/driver"
# The driver Makefile install target handles: blacklist acer_wmi, module
# install, depmod, modules-load.d autoload, modprobe, the unload service,
# the linuwu_sense group and 0660 sysfs permissions (tmpfiles.d).
make -C "$HERE/driver" install

# ---------------------------------------------------------------------------
echo "[4/8] Installing console utilities to /usr/local/bin..."
for u in turbo profile fan temps battery kb usbcharge \
         predator-profile-set predator-kb-restore; do
    install -m 0755 "$HERE/bin/$u" "/usr/local/bin/$u"
done

# ---------------------------------------------------------------------------
echo "[5/8] Passwordless helper for platform-profile (sudoers)..."
printf '%s ALL=(root) NOPASSWD: /usr/local/bin/predator-profile-set\n' "$TARGET_USER" \
    > /etc/sudoers.d/predator-sense
chmod 0440 /etc/sudoers.d/predator-sense
visudo -cf /etc/sudoers.d/predator-sense >/dev/null

# ---------------------------------------------------------------------------
echo "[6/8] Fn+F4 fix (stop it from dimming the screen)..."
install -m 0644 "$HERE/config/90-predator-fnf4.hwdb" \
    /etc/udev/hwdb.d/90-predator-fnf4.hwdb
systemd-hwdb update
udevadm trigger --subsystem-match=input --action=change || true

# ---------------------------------------------------------------------------
echo "[7/8] Keyboard-backlight persistence..."
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
echo "[8/8] Reloading module so the Turbo toggle option takes effect..."
modprobe -r linuwu_sense 2>/dev/null || true
modprobe linuwu_sense

echo
echo "==================================================="
echo " Done!"
echo " Commands: turbo, profile, fan, temps, battery, kb, usbcharge"
echo " Try: 'kb help', 'fan', 'battery', 'temps'"
echo
echo " NOTE: log out and back in once so '$TARGET_USER' picks up the"
echo "       'linuwu_sense' group (needed for kb/fan/battery without sudo)."
echo "==================================================="
