#!/usr/bin/env bash
#
# predator-sense — uninstaller
# Removes everything install.sh set up and restores the stock acer_wmi driver.
#
#   sudo ./uninstall.sh
#
set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "This uninstaller must run as root:  sudo ./uninstall.sh" >&2
    exit 1
fi

echo "== predator-sense uninstaller =="

echo "[1/7] Removing keyboard-backlight persistence..."
systemctl disable --now predator-kb-restore.service 2>/dev/null || true
rm -f /etc/systemd/system/predator-kb-restore.service
systemctl daemon-reload
rm -rf /var/lib/predator-sense

echo "[2/7] Removing Fn+F4 hwdb fix..."
rm -f /etc/udev/hwdb.d/90-predator-fnf4.hwdb
systemd-hwdb update
udevadm trigger --subsystem-match=input --action=change || true

echo "[3/7] Removing sudoers helper..."
rm -f /etc/sudoers.d/predator-sense /etc/sudoers.d/predator-profile

echo "[4/7] Removing console utilities..."
for u in turbo profile fan temps battery kb usbcharge \
         predator-profile-set predator-kb-restore; do
    rm -f "/usr/local/bin/$u"
done

echo "[5/7] Removing Turbo-toggle modprobe option..."
rm -f /etc/modprobe.d/linuwu_sense-options.conf

echo "[6/7] Deregistering the driver from DKMS..."
if command -v dkms >/dev/null 2>&1; then
    DKMS_NAME="$(sed -n 's/^PACKAGE_NAME="\(.*\)"$/\1/p' "$HERE/driver/dkms.conf")"
    for src in /usr/src/"$DKMS_NAME"-*; do
        [ -d "$src" ] || continue
        dkms remove -m "$DKMS_NAME" -v "${src##*-}" --all || true
        rm -rf "$src"
    done
fi

echo "[7/7] Uninstalling the driver (module, service, group, autoload)..."
make -C "$HERE/driver" uninstall || true

# The Makefile only cleans the running kernel, and `dkms remove` restores any
# module archived by an earlier pre-DKMS install. Sweep every kernel so no stale
# copy is left to load on an older boot entry.
find /lib/modules -name 'linuwu_sense.ko*' -delete 2>/dev/null || true
depmod -a || true

echo
echo "Done. The stock acer_wmi driver has been restored."
echo "A reboot is recommended."
