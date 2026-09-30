#!/usr/bin/env bats

load helpers

setup() { setup_fake_system; }

PP=firmware/acpi/platform_profile

@test "turbo toggles between balanced and performance through the helper" {
    run "$BIN/turbo"
    [ "$status" -eq 0 ]
    [[ "$output" == *"turbo: ON"* ]]
    [ "$(sysfs $PP)" = performance ]
    grep -q "predator-profile-set performance" "$SUDO_LOG"

    run "$BIN/turbo" toggle
    [ "$(sysfs $PP)" = balanced ]
    run "$BIN/turbo" status
    [[ "$output" == *"turbo: OFF"* ]]
}

@test "turbo does not switch the other way when setting the profile fails" {
    echo performance > "$PREDATOR_SENSE_SYSFS/$PP"
    printf '#!/bin/bash\nexit 1\n' > "$PREDATOR_SENSE_BIN/predator-profile-set"
    run "$BIN/turbo" toggle
    [ "$status" -eq 1 ]
    [ "$(sysfs $PP)" = performance ]
    [ "$(wc -l < "$SUDO_LOG")" -eq 1 ]
}

@test "profile lists, shows and switches" {
    run "$BIN/profile" list;         [[ "$output" == *"quiet balanced balanced-performance performance"* ]]
    run "$BIN/profile" quiet;        [ "$status" -eq 0 ]; [ "$(sysfs $PP)" = quiet ]
    run "$BIN/profile";              [[ "$output" == *"current: quiet"* ]]
    run "$BIN/profile" overclock;    [ "$status" -eq 1 ]; [ "$(sysfs $PP)" = quiet ]
}

@test "the root helper accepts only the four profiles" {
    for bad in "" overclock "performance; reboot" "../../etc/passwd" "quiet balanced"; do
        run "$BIN/predator-profile-set" "$bad"
        [ "$status" -eq 1 ]
        [[ "$output" == *"invalid profile"* ]]
    done
}

@test "the root helper reads no environment variable" {
    run grep -E '\$\{?[A-Z_]+' "$BIN/predator-profile-set"
    [ "$status" -eq 1 ]
}
