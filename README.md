# predator-sense

**PredatorSense-style control suite for Acer Predator laptops on Linux.**

A one-command setup that turns the [Linuwu-Sense](https://github.com/0x7375646F/Linuwu-Sense)
kernel driver into a fully working control stack for Acer Predator laptops:
thermal profiles, a real Turbo-button toggle, fan control, RGB keyboard, battery
health, temperature monitoring — all as simple console commands.

[![CI](https://github.com/wobqqq/predator-sense/actions/workflows/ci.yml/badge.svg)](https://github.com/wobqqq/predator-sense/actions/workflows/ci.yml)
![license](https://img.shields.io/badge/license-GPL--3.0-blue)
![platform](https://img.shields.io/badge/platform-Linux-informational)
![tested](https://img.shields.io/badge/tested%20on-Predator%20PT316--51s-brightgreen)

> ⚠️ **Tested on the Acer Predator PT316-51s (Triton 300 SE).** It may work on
> other Predator/Nitro models supported by Linuwu-Sense, but is only verified on
> that one. See **Compatibility** below.

---

## ⚠️ Disclaimer — no warranty

This project builds and loads a **kernel module** and changes system
configuration (fans, power limits, battery, keyboard, udev/hwdb). It is provided
**"AS IS", with NO WARRANTY of any kind**. You use it **entirely at your own
risk**. The authors are **not liable** for any damage, data loss, overheating,
hardware failure, voided warranty, or anything else. See [DISCLAIMER.md](DISCLAIMER.md)
and [LICENSE](LICENSE).

Manual fan control in particular can let the machine run hotter — **you** are
responsible for keeping it cool.

---

## Features

- 🔥 **Turbo button = toggle** — one press turns turbo on, another off
  (like the original PredatorSense), instead of cycling every profile.
- 🎚️ **Thermal profiles** — quiet / balanced / balanced-performance / performance.
- 🌀 **Fan control** — auto, max, or manual % per fan (CPU/GPU).
- 🌡️ **Live temps & RPM** monitor.
- 🔋 **Battery health** — 80% charge limit and calibration.
- 🌈 **RGB keyboard** — colours, per-zone, effects, brightness — **persistent
  across reboots** (the driver's own save is unreliable).
- 🔌 **USB charging while off** toggle.
- 🖥️ **Fn+F4 fix** — stops Fn+F4 (keyboard backlight) from also dimming the screen.

---

## Compatibility

**Laptop model.** Verified on the **Predator PT316-51s (Triton 300 SE)**, for
which this fork adds a DMI quirk and model-specific fixes. Other Predator
`predator_v4` models *may* work; please report success/failure via an issue.

**Distros.** The driver is a kernel module and is distro-independent. The
installer auto-detects the package manager for build dependencies:

| Distro family | Package manager | Status |
|---|---|---|
| Fedora / RHEL | `dnf` | tested |
| Debian / Ubuntu | `apt` | supported |
| Arch | `pacman` | supported |
| openSUSE | `zypper` | supported |

Requirements: a **systemd**-based distro, kernel headers + `gcc`/`make`, `dkms`
(installed automatically, and what keeps the module alive across kernel
upgrades), and **Secure Boot disabled** (the module is unsigned — or sign it
yourself via MOK).

---

## Install

```bash
git clone https://github.com/wobqqq/predator-sense.git
cd predator-sense
sudo ./install.sh
```

Then **log out and back in once** so your user joins the `linuwu_sense` group
(needed for `kb` / `fan` / `battery` to work without sudo).

## Uninstall

```bash
sudo ./uninstall.sh
```

Restores the stock `acer_wmi` driver and removes everything. Reboot afterwards.

### Kernel updates

The driver is registered with **DKMS**, so a kernel upgrade (`dnf upgrade`, a
Fedora release upgrade, …) rebuilds the module automatically for the new kernel
— nothing to re-run, and your settings keep working after the reboot.

Check it any time with:

```bash
dkms status linuwu-sense
```

You should see one line per installed kernel, each ending in `installed`. If a
kernel is missing there, its headers weren't available at upgrade time — install
them and rebuild:

```bash
sudo dnf install "kernel-devel-$(uname -r)"     # Fedora; use the equivalent elsewhere
sudo dkms autoinstall
```

Re-running `sudo ./install.sh` is still safe and idempotent, and is what you
want after editing the driver source.

> **Secure Boot:** with Secure Boot enabled, DKMS signs each rebuild with its own
> MOK key (`/etc/dkms/framework.conf`), which you must enrol once via `mokutil`.
> The simpler route remains disabling Secure Boot.

---

## Commands

All commands print in English. `fan` / `battery` / `kb` / `usbcharge` need no
sudo (group-writable sysfs); `turbo` / `profile` use a passwordless helper.

### `turbo`
```
turbo            toggle turbo
turbo on|off     turbo on / off
turbo status     show state
```

### `profile` — power level (CPU/GPU limits + base fan curve)
```
profile                       show current
profile list                  list available
profile quiet | balanced | balanced-performance | performance
```

### `fan` — cooling override, independent of the profile
```
fan              show mode + temps/RPM
fan auto         firmware-controlled
fan max          both fans 100%
fan 60           both fans 60%
fan 70 40        CPU 70%, GPU 40%   (0 = auto)
```

### `temps`
```
temps            live view (Ctrl+C to quit)
temps once       print once
```

### `battery`
```
battery                    show charge / limit / calibration
battery limit on|off       80% charge limit
battery calibrate start    start calibration (hours; don't interrupt)
battery calibrate stop     stop calibration
```

### `kb` — RGB keyboard (3 physical zones)
```
kb status
kb color RRGGBB [bright]        solid colour (e.g. kb color ff0000)
kb zones Z1 Z2 Z3               per-zone colours
kb bright N                     0..100
kb effect NAME [speed] [RRGGBB] static breathing neon wave shifting zoom meteor twinkling
kb timeout on|off               backlight auto-off timeout
kb off
```
Effects apply to the whole keyboard (`neon`/`wave` are rainbow); per-zone
colours are static only.

### `usbcharge` — charge USB devices while the laptop is off
```
usbcharge            show status
usbcharge off        disable
usbcharge 10|20|30   enable, stop at that battery %
```

---

## Notes

- The turbo **LED** is a firmware indicator (real turbo state) — it cannot be
  driven from software and may only light on AC power / under load.
- The keyboard is physically **3-zone** (the driver exposes a phantom 4th zone).

---

## Development

Everything runs in Docker; only `docker` and `make` are needed:

```bash
make lint    # ShellCheck + bash -n on every script
make test    # bats tests against a fake sysfs, no hardware touched
make build   # builds the driver against the newest Fedora kernel
make ready   # all of the above
```

CI runs the same on every pull request, and builds the driver every week so a new Fedora kernel that breaks it is caught early. Changes go through pull requests; see [CONTRIBUTING.md](CONTRIBUTING.md). Found a laptop where it works (or doesn't)? Open a **Hardware report** issue.

---

## Credits

- Built on **[Linuwu-Sense](https://github.com/0x7375646F/Linuwu-Sense)** by
  0x7375646F — the kernel driver that makes all of this possible. This repo
  bundles a patched copy (DMI quirk + fixes for the PT316-51s). GPL-3.0.

## License

[GPL-3.0](LICENSE), matching Linuwu-Sense.
