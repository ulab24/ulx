#!/usr/bin/env bash
# Runs every test_*.sh beside this file. They are hermetic: each works in a
# temporary directory with a throwaway GPG key and a file:// release, so
# nothing touches the network, your ~/.gnupg or an installed ulx.
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fail=0
for t in "$dir"/test_*.sh; do
  echo "== $t =="
  if bash "$t"; then
    echo "PASS: $t"
  else
    echo "FAIL: $t"
    fail=1
  fi
done
exit "$fail"
