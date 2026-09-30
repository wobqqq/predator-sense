# Contributing

1. Fork, branch off `main` (`fix/…`, `feat/…`), commit, open a pull request. `main` only changes through pull requests.
2. Run `make ready` (ShellCheck, the bats tests against a fake sysfs, the driver build). Only Docker and make are needed.
3. Say in the pull request which laptop, BIOS and kernel you tried it on. A change that only CI has seen is marked as such.
4. A new command or option comes with a test in `tests/`.

A laptop model that works (or does not) is reported with the **Hardware report** issue form.
