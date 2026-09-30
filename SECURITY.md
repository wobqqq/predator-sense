# Security policy

predator-sense runs as root during installation and leaves two privileged paths on the system:

- `/etc/sudoers.d/predator-sense` lets the installing user run `/usr/local/bin/predator-profile-set` without a password. The helper accepts only `quiet`, `balanced`, `balanced-performance` and `performance`, writes only `/sys/firmware/acpi/platform_profile`, and reads no environment variable.
- `/etc/tmpfiles.d/linuwu_sense.conf` makes a fixed list of the driver's sysfs attributes writable by the `linuwu_sense` group, so the user can change fans, battery and keyboard without sudo.

A change that widens either of them is a security change.

## Reporting a vulnerability

Please do not open a public issue. Report it privately through [GitHub security advisories](https://github.com/wobqqq/predator-sense/security/advisories/new) with the steps to reproduce it. You will get an answer within five working days.
