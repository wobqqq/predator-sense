# Changelog

All notable changes are documented here. The project follows [semantic versioning](https://semver.org/); the version is `PACKAGE_VERSION` in `driver/dkms.conf`.

## [1.0.0] - 2026-09-30

First release. Tested on the **Acer Predator PT316-51s (Triton 300 SE)** with Fedora and kernel 7.2.

### Added

- One-command installer and uninstaller for the patched [Linuwu-Sense](https://github.com/0x7375646F/Linuwu-Sense) driver, registered with **DKMS** so it is rebuilt on every kernel upgrade; multi-distro build dependencies (dnf, apt, pacman, zypper).
- Console commands: `turbo` (the Turbo button toggles instead of cycling profiles), `profile`, `fan`, `temps`, `battery` (80 % limit, calibration), `kb` (RGB keyboard, persistent across reboots), `usbcharge`.
- Fn+F4 fix: the keyboard-backlight key no longer dims the screen.
- CI: ShellCheck, bats tests against a fake sysfs, and a weekly build of the driver against the latest Fedora kernel.

### Fixed

- The driver builds on kernel 7.2 (`strncpy()` replaced with `memcpy()`).
- `turbo` no longer switches the wrong way when a write fails, and `turbo`, `profile` and `kb timeout` exit with an error on a failed write.

[1.0.0]: https://github.com/wobqqq/predator-sense/releases/tag/v1.0.0
