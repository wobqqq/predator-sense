#!/usr/bin/env bats

load helpers

setup() { setup_fake_system; }

PS=devices/platform/acer-wmi/predator_sense

@test "battery shows the charge, the limit and the calibration" {
    run "$BIN/battery"
    [ "$status" -eq 0 ]
    [[ "$output" == *"charge now  : 77%  (Charging)"* ]]
    [[ "$output" == *"80% limit   : off"* ]]
}

@test "battery limit and calibration" {
    run "$BIN/battery" limit on;        [ "$status" -eq 0 ]; [ "$(sysfs $PS/battery_limiter)" = 1 ]
    run "$BIN/battery" limit off;       [ "$status" -eq 0 ]; [ "$(sysfs $PS/battery_limiter)" = 0 ]
    run "$BIN/battery" calibrate start; [ "$status" -eq 0 ]; [ "$(sysfs $PS/battery_calibration)" = 1 ]
    run "$BIN/battery" calibrate stop;  [ "$status" -eq 0 ]; [ "$(sysfs $PS/battery_calibration)" = 0 ]
}

@test "battery refuses an unknown action and reports a missing permission" {
    run "$BIN/battery" limit maybe; [ "$status" -eq 1 ]
    run "$BIN/battery" explode;     [ "$status" -eq 1 ]
    read_only $PS/battery_limiter
    run "$BIN/battery" limit on
    [ "$status" -eq 1 ]
    [[ "$output" == *"no write permission"* ]]
}

@test "usbcharge takes only the thresholds the firmware knows" {
    run "$BIN/usbcharge" 20;  [ "$status" -eq 0 ]; [ "$(sysfs $PS/usb_charging)" = 20 ]
    run "$BIN/usbcharge";     [[ "$output" == *"enabled (until battery drops to 20%)"* ]]
    run "$BIN/usbcharge" off; [ "$status" -eq 0 ]; [ "$(sysfs $PS/usb_charging)" = 0 ]
    run "$BIN/usbcharge" 50;  [ "$status" -eq 1 ]; [ "$(sysfs $PS/usb_charging)" = 0 ]
}

@test "temps once prints the profile, the temperatures and a sleeping dGPU" {
    run "$BIN/temps" once
    [ "$status" -eq 0 ]
    [[ "$output" == *"Profile: balanced"* ]]
    [[ "$output" == *"CPU temp :  45 C"* ]]
    [[ "$output" == *"dGPU temp: asleep (0)"* ]]
}

@test "temps reports a missing driver" {
    rm -r "$PREDATOR_SENSE_SYSFS/devices/platform/acer-wmi/hwmon"
    run "$BIN/temps" once
    [ "$status" -eq 1 ]
    [[ "$output" == *"acer hwmon not found"* ]]
}
