#!/usr/bin/env bats

load helpers

setup() { setup_fake_system; }

PZ=devices/platform/acer-wmi/four_zoned_kb/per_zone_mode
FZ=devices/platform/acer-wmi/four_zoned_kb/four_zone_mode

@test "kb status reads the zones and the brightness" {
    run "$BIN/kb" status
    [ "$status" -eq 0 ]
    [[ "$output" == *"zones: ffffff / ffffff / ffffff    brightness: 100"* ]]
}

@test "kb color sets every zone, mirrors the phantom fourth zone and saves the state" {
    run "$BIN/kb" color ff0000 40
    [ "$status" -eq 0 ]
    [ "$(sysfs $PZ)" = "ff0000,ff0000,ff0000,ff0000,40" ]
    [ "$(cat "$PREDATOR_SENSE_STATE/kb.state")" = "PZ:ff0000,ff0000,ff0000,ff0000,40" ]
}

@test "kb zones, bright and off keep what they do not change" {
    run "$BIN/kb" zones 111111 222222 333333; [ "$status" -eq 0 ]
    [ "$(sysfs $PZ)" = "111111,222222,333333,333333,100" ]
    run "$BIN/kb" bright 30; [ "$status" -eq 0 ]
    [ "$(sysfs $PZ)" = "111111,222222,333333,333333,30" ]
    run "$BIN/kb" off; [ "$status" -eq 0 ]
    [ "$(sysfs $PZ)" = "111111,222222,333333,333333,0" ]
}

@test "kb effect writes the mode, the speed and the colour" {
    run "$BIN/kb" effect wave 3 00ff00
    [ "$status" -eq 0 ]
    [ "$(sysfs $FZ)" = "3,3,100,1,0,255,0" ]
    [ "$(cat "$PREDATOR_SENSE_STATE/kb.state")" = "FZ:3,3,100,1,0,255,0" ]
}

@test "kb refuses a bad colour, zone, brightness or effect" {
    run "$BIN/kb" color red;              [ "$status" -eq 1 ]
    run "$BIN/kb" zones ff0000 00ff00;    [ "$status" -eq 1 ]
    run "$BIN/kb" bright 101;             [ "$status" -eq 1 ]
    run "$BIN/kb" effect disco;           [ "$status" -eq 1 ]
    run "$BIN/kb" dance;                  [ "$status" -eq 1 ]
    [ "$(sysfs $PZ)" = "ffffff,ffffff,ffffff,ffffff,100" ]
}

@test "kb timeout switches the auto-off and reports a write failure" {
    run "$BIN/kb" timeout on;  [ "$status" -eq 0 ]; [[ "$output" == *"ON"* ]]
    [ "$(sysfs devices/platform/acer-wmi/predator_sense/backlight_timeout)" = 1 ]
    run "$BIN/kb" timeout;     [[ "$output" == *"backlight auto-off: ON"* ]]
    read_only devices/platform/acer-wmi/predator_sense/backlight_timeout
    run "$BIN/kb" timeout off
    [ "$status" -eq 1 ]
    [[ "$output" == *"cannot write"* ]]
}

@test "the saved backlight is restored at boot" {
    echo "PZ:abcdef,abcdef,abcdef,abcdef,55" > "$PREDATOR_SENSE_STATE/kb.state"
    run "$BIN/predator-kb-restore"
    [ "$status" -eq 0 ]
    [ "$(sysfs $PZ)" = "abcdef,abcdef,abcdef,abcdef,55" ]

    echo "FZ:1,5,80,1,255,0,0" > "$PREDATOR_SENSE_STATE/kb.state"
    run "$BIN/predator-kb-restore"
    [ "$(sysfs $FZ)" = "1,5,80,1,255,0,0" ]
}

@test "the restore does nothing without a driver or a saved state" {
    rm "$PREDATOR_SENSE_STATE/kb.state"
    run "$BIN/predator-kb-restore"
    [ "$status" -eq 0 ]
    rm -r "$PREDATOR_SENSE_SYSFS/devices/platform/acer-wmi/four_zoned_kb"
    run "$BIN/predator-kb-restore"
    [ "$status" -eq 0 ]
}
