#!/usr/bin/env bash
# Links the template into Pandoc's user data directory, so `pandoc -d unicam` works
# without --data-dir. Safe to repeat.
set -euo pipefail

cd "$(dirname "$0")/pandoc"
data="$(pandoc --version | sed -n 's/^User data directory: //p')"
[ ! -L "$data" ] || { echo "$data is a symlink; remove it first" >&2; exit 1; }

for p in defaults/unicam.yaml filters/unicam csl/unicam assets/unicam templates/*.latex; do
  mkdir -p "$data/$(dirname "$p")"
  ln -sfn "$PWD/$p" "$data/$p"
done
