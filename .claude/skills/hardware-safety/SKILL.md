---
name: hardware-safety
description: "Safety checklist for predator-sense. Use before changing anything that reaches the laptop's hardware or runs as root: a command in bin/ that writes sysfs (fan, profile, turbo, battery, kb, usbcharge), the root helper predator-profile-set or its sudoers rule, install.sh / uninstall.sh, the tmpfiles permissions, the modprobe or hwdb config, the systemd units, or the driver in driver/ (source, Makefile, dkms.conf). Also for a review of such a change."
license: GPL-3.0
---

# Hardware safety

This code drives fans, power limits and charging of a real laptop, as root. Every rule below exists because breaking it can overheat the machine, wear the battery, or leave it without a driver after a kernel update.

## 1. Ranges come from the firmware

- Fans: 0–100 % per fan, `0,0` is firmware control. Profiles: `quiet`, `balanced`, `balanced-performance`, `performance` (read `platform_profile_choices`). USB charging: 0, 10, 20, 30. Brightness: 0–100. Effect speed: 0–9.
- Validate the value in the command before writing it, and refuse anything else with a non-zero exit. Never clamp silently into a different value.
- Never add a "boost" beyond what the firmware offers, and never remove the `fan auto` way back.

## 2. Privilege

- `predator-profile-set` is the only thing sudoers lets the user run without a password. It takes one argument from a fixed allowlist, writes `/sys/firmware/acpi/platform_profile` and nothing else, and reads **no environment variable** (a test asserts it). Keep it that way; a new privileged action is a new helper with its own allowlist, reviewed as a security change.
- The tmpfiles rules give the `linuwu_sense` group write access to a fixed list of attributes. Adding one is a security change: say why in the pull request.
- The user-facing commands never call `sudo` except through the helper.

## 3. Install and uninstall

- `install.sh` is idempotent: a second run leaves the same system (DKMS version replaced, files reinstalled, no duplicated lines).
- Everything `install.sh` writes, `uninstall.sh` removes, and `acer_wmi` is loaded again. A new file in the installer comes with its removal in the uninstaller in the same change.
- Never overwrite a user's saved keyboard state; seed it only when empty.

## 4. The driver

- The module must build for a kernel other than the running one: `make build` builds against Fedora's newest `kernel-devel` in a container, and CI does it weekly.
- `dkms.conf` calls kbuild directly; never route the DKMS build through a target that uses `sudo` or signs the module.
- Keep the DMI quirk for the PT316-51s. A new model gets its own quirk, never a wider match.
- Kernel API changes (as the `strncpy()` → `memcpy()` fix for 7.2) keep the older supported kernels building.

## 5. Before a release

1. `make ready` passes.
2. On the real laptop: `sudo ./install.sh`, reboot, every command, a kernel upgrade (`dkms status` shows `installed` for the new kernel), `sudo ./uninstall.sh`, reboot, stock `acer_wmi` works.
3. The pull request says which model, BIOS and kernel it was tried on.
