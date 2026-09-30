# AGENTS.md

Guidance for AI coding agents (Claude Code, Codex, Junie, Cursor) working in this repository.

## What this is

**predator-sense** turns the [Linuwu-Sense](https://github.com/0x7375646F/Linuwu-Sense) kernel driver into a PredatorSense-style control suite for Acer Predator laptops on Linux: thermal profiles, a Turbo-button toggle, fan control, RGB keyboard, battery health, temperatures and USB charging, as plain console commands. It is verified on the **Acer Predator PT316-51s (Triton 300 SE)** only. License: GPL-3.0, matching the bundled driver.

It runs as root, loads a kernel module and drives fans and power limits. **A mistake here can overheat the laptop, drain or wear the battery, or leave the machine without a working keyboard backlight or driver.** Safety comes before features.

## The self-check gate (run before every commit)

Everything runs in Docker; the host needs only `docker` and `make`.

```bash
make lint    # ShellCheck (style level) on every script and test, plus bash -n
make test    # bats against a fake sysfs tree (tests/helpers.bash)
make build   # builds the driver against the newest Fedora kernel-devel, not the running kernel
make ready   # all of the above
```

`make ready` must pass. A ShellCheck finding is fixed, never disabled, unless the disable carries a one-line reason.

## Layout

| Path | Holds |
|------|-------|
| `bin/` | The console commands (`turbo`, `profile`, `fan`, `temps`, `battery`, `kb`, `usbcharge`), the boot restore (`predator-kb-restore`) and the root helper (`predator-profile-set`). |
| `config/` | The modprobe option (Turbo toggle), the Fn+F4 hwdb fix and the backlight restore unit. |
| `driver/` | The patched Linuwu-Sense module (`src/linuwu_sense.c`), its Makefile and `dkms.conf`. |
| `install.sh` / `uninstall.sh` | Set everything up and take it all back down. |
| `scripts/build-driver.sh` | The CI and `make build` driver build. |
| `tests/` | bats tests; `helpers.bash` builds the fake sysfs and stubs `sudo` and the helper. |

The user-facing commands read their sysfs and state paths from `PREDATOR_SENSE_SYSFS` (default `/sys`), `PREDATOR_SENSE_STATE` (default `/var/lib/predator-sense`) and `PREDATOR_SENSE_BIN` (default `/usr/local/bin`), which is how the tests point them at a fake tree.

## Safety rules (always)

Read the `hardware-safety` skill before touching fans, profiles, battery, the helper, the installer or the driver. The non-negotiables:

- **Never widen a range the firmware exposes.** Fans stay 0–100 %, profiles stay the four ACPI ones, USB charging stays 0/10/20/30, brightness 0–100.
- **The NOPASSWD helper stays an allowlist.** `predator-profile-set` runs as root through sudoers: it accepts only the four profiles, writes one fixed path and reads no environment variable. Never let it take a path, a value or an environment override.
- **The installer is idempotent and reversible.** Running `install.sh` twice gives the same system; everything it adds, `uninstall.sh` removes, and the stock `acer_wmi` comes back.
- **Driver changes keep DKMS working.** `dkms.conf` builds with kbuild directly (no `sudo`, no signing block); the module must build for kernels other than the running one (`make build` proves it).
- **Test on real hardware before a release.** CI proves the scripts and the build, not the firmware's reaction. Say in the pull request what was tried on which model, BIOS and kernel.

## Git workflow

- `main` is protected: **never push to it and never force-push.** Every change goes through a pull request:
  1. branch off the latest `main`, named after the change (`fix/…`, `feat/…`, `chore/…`, `docs/…`);
  2. commit on the branch and `git push -u origin <branch>`;
  3. open a pull request with the template filled in (what changes, what it was tested on);
  4. merge only once CI is green, then delete the branch.
- Code, comments, commit messages, pull requests, issues and documentation are written in **English**.

## Conventions

- Bash with `#!/bin/bash`, quoted expansions, `if … then … else` instead of `a && b || c`, errors to stderr with a non-zero exit.
- Every command answers `help`, and keeps its current arguments and output: users script against them.
- Code documents itself; a comment explains a non-obvious *why*, in one sentence.
- Commits: imperative subject saying what the change does for the user, a body with the why.
