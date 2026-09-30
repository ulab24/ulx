#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../install.sh"

out="$(usage)"
[[ "$out" == *"Usage: install.sh"* ]] || { echo "FAIL: usage() missing expected text"; exit 1; }

parse_args --version=v1.2.3 --dir=/tmp/x
[ "$VERSION" = "v1.2.3" ] || { echo "FAIL: --version not parsed"; exit 1; }
[ "$INSTALL_DIR" = "/tmp/x" ] || { echo "FAIL: --dir not parsed"; exit 1; }
( parse_args --version=v1.2.3-rc.1 ) || { echo "FAIL: prerelease version rejected"; exit 1; }
echo "parse_args (valid): ok"

# Each of these must be refused before anything is downloaded. A --version with
# a slash or dots would otherwise walk the release download URL.
for bad in --version=1.2.3 --version=v1.2 '--version=v1.2.3/../../x' \
           '--version=v1.2.3;rm' --dir= --mode=docker --nope; do
  if ( VERSION=latest; INSTALL_DIR=""; parse_args "$bad" ) 2>/dev/null; then
    echo "FAIL: $bad was accepted"
    exit 1
  fi
done
echo "parse_args (invalid, rejected): ok"

# detect_platform: fake uname to cover every answer the script must give.
check() { # check OS MACHINE WANT
  os="$1"; machine="$2"; want="$3"
  uname() { case "$1" in -s) echo "$os";; -m) echo "$machine";; esac; }
  # die exits, so probe in a subshell first; only a success is read back.
  if ( detect_platform ) >/dev/null 2>&1; then
    PLATFORM=""; ARCH=""; detect_platform; got="$PLATFORM-$ARCH"
  else
    got=REFUSED
  fi
  unset -f uname
  [ "$got" = "$want" ] || { echo "FAIL: $os/$machine -> $got, want $want"; exit 1; }
}
check Linux x86_64 linux-x64
check Linux aarch64 linux-arm64
check Darwin arm64 macos-arm64
check Darwin x86_64 macos-x64
check FreeBSD amd64 REFUSED
check Linux i686 REFUSED
check Linux riscv64 REFUSED
check MINGW64_NT-10.0 x86_64 REFUSED
echo "detect_platform: ok"

# Windows gets a pointer to the zip, not a bare refusal.
uname() { case "$1" in -s) echo MINGW64_NT-10.0;; -m) echo x86_64;; esac; }
msg="$( ( detect_platform ) 2>&1 || true )"
unset -f uname
[[ "$msg" == *"windows-x64.zip"* && "$msg" == *"ulx upgrade"* ]] \
  || { echo "FAIL: windows message should name the zip and 'ulx upgrade': $msg"; exit 1; }
echo "detect_platform (windows guidance): ok"

echo "test_platform_and_args: ok"
