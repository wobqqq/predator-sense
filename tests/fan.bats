#!/usr/bin/env bats

load helpers

setup() { setup_fake_system; }

@test "fan shows the mode, the temperatures and the speeds" {
    run "$BIN/fan"
    [ "$status" -eq 0 ]
    [[ "$output" == *"fan mode: auto"* ]]
    [[ "$output" == *"CPU: 45C / 2100 RPM"* ]]
    [[ "$output" == *"GPU: 52C / 2300 RPM"* ]]
}

@test "fan max, auto, one speed and two speeds" {
    run "$BIN/fan" max;   [ "$status" -eq 0 ]; [ "$(sysfs devices/platform/acer-wmi/predator_sense/fan_speed)" = "100,100" ]
    run "$BIN/fan" 60;    [ "$status" -eq 0 ]; [ "$(sysfs devices/platform/acer-wmi/predator_sense/fan_speed)" = "60,60" ]
    run "$BIN/fan" 70 40; [ "$status" -eq 0 ]; [ "$(sysfs devices/platform/acer-wmi/predator_sense/fan_speed)" = "70,40" ]
    run "$BIN/fan" auto;  [ "$status" -eq 0 ]; [ "$(sysfs devices/platform/acer-wmi/predator_sense/fan_speed)" = "0,0" ]
}

@test "fan refuses speeds outside 0..100" {
    for bad in 101 -1 abc "50 200" "1.5"; do
        # shellcheck disable=SC2086
        run "$BIN/fan" $bad
        [ "$status" -eq 1 ]
    done
    [ "$(sysfs devices/platform/acer-wmi/predator_sense/fan_speed)" = "0,0" ]
}

@test "fan reports a missing write permission" {
    read_only devices/platform/acer-wmi/predator_sense/fan_speed
    run "$BIN/fan" max
    [ "$status" -eq 1 ]
    [[ "$output" == *"no write permission"* ]]
}
