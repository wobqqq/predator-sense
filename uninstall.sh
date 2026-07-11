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

echo "[1/6] Removing keyboard-backlight persistence..."
systemctl disable --now predator-kb-restore.service 2>/dev/null || true
rm -f /etc/systemd/system/predator-kb-restore.service
systemctl daemon-reload
rm -rf /var/lib/predator-sense

echo "[2/6] Removing Fn+F4 hwdb fix..."
rm -f /etc/udev/hwdb.d/90-predator-fnf4.hwdb
systemd-hwdb update
udevadm trigger --subsystem-match=input --action=change || true

echo "[3/6] Removing sudoers helper..."
rm -f /etc/sudoers.d/predator-sense /etc/sudoers.d/predator-profile

echo "[4/6] Removing console utilities..."
for u in turbo profile fan temps battery kb usbcharge \
         predator-profile-set predator-kb-restore; do
    rm -f "/usr/local/bin/$u"
done

echo "[5/6] Removing Turbo-toggle modprobe option..."
rm -f /etc/modprobe.d/linuwu_sense-options.conf

echo "[6/6] Uninstalling the driver (module, service, group, autoload)..."
make -C "$HERE/driver" uninstall || true

echo
echo "Done. The stock acer_wmi driver has been restored."
echo "A reboot is recommended."
