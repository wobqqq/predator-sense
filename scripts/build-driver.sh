#!/usr/bin/env bash
# Builds the driver against the newest kernel-devel of the container, not the running kernel.
set -euo pipefail

dnf install -y -q kernel-devel gcc make elfutils-libelf-devel >/dev/null

kdir=$(find /usr/src/kernels -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)
if [ -z "$kdir" ]; then
    echo "no kernel-devel headers found" >&2
    exit 1
fi

build=$(mktemp -d)
cp -a driver/. "$build/"
make -C "$kdir" M="$build" modules
test -f "$build/src/linuwu_sense.ko"
echo "built linuwu_sense.ko against $(basename "$kdir")"
