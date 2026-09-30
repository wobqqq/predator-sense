# CLAUDE.md

@AGENTS.md

## Claude Code

- Skill in `.claude/skills/`: `hardware-safety` — read it before any change to fans, profiles, battery, the root helper, the installer or the driver.
- Never run `install.sh`, `uninstall.sh`, `sudo` or anything that writes `/sys` on this machine to "try" a change: use the bats tests and `make build`, and leave hardware testing to the user.
- Run `make ready` before you say a change is done, and report its result.
- Never push to `main`: work on a branch and open a pull request (see *Git workflow* in AGENTS.md). Write everything in English.
