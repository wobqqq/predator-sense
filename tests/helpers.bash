# Builds a fake sysfs tree and stubs for every test, so no test touches real hardware.

setup_fake_system() {
    export BIN="$BATS_TEST_DIRNAME/../bin"
    export PREDATOR_SENSE_SYSFS="$BATS_TEST_TMPDIR/sys"
    export PREDATOR_SENSE_STATE="$BATS_TEST_TMPDIR/state"
    export PREDATOR_SENSE_BIN="$BATS_TEST_TMPDIR/helper"
    export PREDATOR_SENSE_WAIT=1
    export SUDO_LOG="$BATS_TEST_TMPDIR/sudo.log"

    local ps="$PREDATOR_SENSE_SYSFS/devices/platform/acer-wmi"
    mkdir -p "$ps/predator_sense" "$ps/hwmon/hwmon3" "$ps/four_zoned_kb" \
        "$PREDATOR_SENSE_SYSFS/firmware/acpi" "$PREDATOR_SENSE_SYSFS/class/power_supply/BAT1" \
        "$PREDATOR_SENSE_STATE" "$PREDATOR_SENSE_BIN" "$BATS_TEST_TMPDIR/path"

    echo "0,0" > "$ps/predator_sense/fan_speed"
    echo 0 > "$ps/predator_sense/battery_limiter"
    echo 0 > "$ps/predator_sense/battery_calibration"
    echo 0 > "$ps/predator_sense/usb_charging"
    echo 0 > "$ps/predator_sense/backlight_timeout"
    echo acer > "$ps/hwmon/hwmon3/name"
    echo 45000 > "$ps/hwmon/hwmon3/temp1_input"
    echo 0 > "$ps/hwmon/hwmon3/temp2_input"
    echo 52000 > "$ps/hwmon/hwmon3/temp3_input"
    echo 2100 > "$ps/hwmon/hwmon3/fan1_input"
    echo 2300 > "$ps/hwmon/hwmon3/fan2_input"
    echo "ffffff,ffffff,ffffff,ffffff,100" > "$ps/four_zoned_kb/per_zone_mode"
    echo "0,5,100,1,255,255,255" > "$ps/four_zoned_kb/four_zone_mode"
    echo balanced > "$PREDATOR_SENSE_SYSFS/firmware/acpi/platform_profile"
    echo "quiet balanced balanced-performance performance" > "$PREDATOR_SENSE_SYSFS/firmware/acpi/platform_profile_choices"
    echo 77 > "$PREDATOR_SENSE_SYSFS/class/power_supply/BAT1/capacity"
    echo Charging > "$PREDATOR_SENSE_SYSFS/class/power_supply/BAT1/status"
    : > "$PREDATOR_SENSE_STATE/kb.state"

    # The real helper writes to /sys as root; this stand-in applies the same allowlist
    # to the fake tree.
    cat > "$PREDATOR_SENSE_BIN/predator-profile-set" <<STUB
#!/bin/bash
case "\$1" in
    quiet|balanced|balanced-performance|performance) echo "\$1" > "$PREDATOR_SENSE_SYSFS/firmware/acpi/platform_profile" ;;
    *) exit 1 ;;
esac
STUB
    chmod +x "$PREDATOR_SENSE_BIN/predator-profile-set"

    cat > "$BATS_TEST_TMPDIR/path/sudo" <<'STUB'
#!/bin/bash
echo "$*" >> "$SUDO_LOG"
exec "$@"
STUB
    chmod +x "$BATS_TEST_TMPDIR/path/sudo"
    export PATH="$BATS_TEST_TMPDIR/path:$PATH"
}

sysfs() {
    cat "$PREDATOR_SENSE_SYSFS/$1"
}

read_only() {
    chmod a-w "$PREDATOR_SENSE_SYSFS/$1"
}
