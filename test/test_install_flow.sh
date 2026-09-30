#!/usr/bin/env bash
# Runs install.sh itself, as a subprocess, against a file:// release.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
source "$here/../install.sh"
source "$here/lib.sh"

good="$(new_key release)"
other="$(new_key stranger)"
export_pubkey "$good" "$work/pubkey.asc"
export_pubkey "$other" "$work/stranger-pubkey.asc"

root="$work/rel"
build_release "$root" v0.1.0 "$good"
build_release "$root" v0.2.0 "$good"

fakehome="$work/home"; mkdir -p "$fakehome"
# The installer's scratch space, so a test can see whether it was cleaned up.
tmp="$work/tmp"; mkdir -p "$tmp"
no_scratch_left() { [ -z "$(ls -A "$tmp")" ] || fail "$1: scratch files left behind: $(ls -A "$tmp")"; }
# A PATH with the system tools and no ulx, so the test's answer never depends
# on a ulx installed on the machine running it.
syspath="/usr/bin:/bin"

# install WHICH_ARGS... -> runs the installer hermetically, output to $work/out.
install() {
  env -i HOME="$fakehome" PATH="${TEST_PATH:-$syspath}" TMPDIR="$tmp" \
    ULX_INSTALL_BASE_URL="file://$root" \
    ULX_INSTALL_PUBKEY_URL="file://${TEST_PUBKEY:-$work/pubkey.asc}" \
    bash "$here/../install.sh" "$@" > "$work/out" 2>&1
}
fail() { echo "FAIL: $1"; sed 's/^/    | /' "$work/out" 2>/dev/null; exit 1; }

# ---- fresh install ---------------------------------------------------------
dest="$work/bin"
install --version=v0.1.0 --dir="$dest" || fail "fresh install failed"
[ -x "$dest/ulx" ] || fail "ulx not installed executable"
[ "$("$dest/ulx")" = "ulx 0.1.0" ] || fail "wrong ulx installed"
if [ "$PLATFORM" = linux ]; then
  [ -x "$dest/ulx-linux-sandbox" ] && [ -x "$dest/ulx-seccomp" ] || fail "sandbox helpers must be installed beside ulx"
fi
[ -z "$(ls -A "$dest" | grep '^\.' || true)" ] || fail "temporary files left in the install directory"
grep -q "ulx installed" "$work/out" || fail "should say it installed"
grep -q "signature: OK" "$work/out" || fail "should verify the signature"
no_scratch_left "after an install"
echo "fresh install (binary, helpers, no leftovers, signature checked): ok"

# ---- update in place -------------------------------------------------------
echo "user data" > "$dest/notes.txt"
install --version=v0.2.0 --dir="$dest" || fail "update failed"
[ "$("$dest/ulx")" = "ulx 0.2.0" ] || fail "update did not replace ulx"
grep -q "ulx updated: ulx 0.1.0 -> ulx 0.2.0" "$work/out" || fail "should report the version change"
[ "$(cat "$dest/notes.txt")" = "user data" ] || fail "update touched an unrelated file"
echo "update (replaced, reports old -> new, leaves other files): ok"

# ---- reinstalling the same version is harmless ------------------------------
install --version=v0.2.0 --dir="$dest" || fail "reinstall failed"
grep -q "reinstalled" "$work/out" || fail "should say reinstalled"
echo "reinstall same version: ok"

# ---- a tampered archive never replaces a working install -------------------
archive="ulx-v0.2.0-$PLATFORM-$ARCH.tar.gz"
cp "$root/releases/download/v0.2.0/$archive" "$work/archive.good"
echo junk >> "$root/releases/download/v0.2.0/$archive"
if install --version=v0.2.0 --dir="$dest"; then fail "tampered archive was installed"; fi
grep -q "checksum mismatch" "$work/out" || fail "should name the checksum mismatch"
[ "$("$dest/ulx")" = "ulx 0.2.0" ] || fail "a refused install changed the existing ulx"
no_scratch_left "after a refused install (holds the downloaded archive)"
cp "$work/archive.good" "$root/releases/download/v0.2.0/$archive"
echo "tampered archive (refused, existing install intact): ok"

# ---- a release signed by another key is refused -----------------------------
if TEST_PUBKEY="$work/stranger-pubkey.asc" install --version=v0.2.0 --dir="$dest"; then
  fail "a release not signed by the release key was installed"
fi
grep -q "GPG signature verification" "$work/out" || fail "should name the signature failure"
echo "wrong signing key (refused): ok"

# ---- a version that was never published -------------------------------------
if install --version=v9.9.9 --dir="$work/never"; then fail "installed a release that does not exist"; fi
grep -q "could not download" "$work/out" || fail "should say the release could not be downloaded"
[ ! -e "$work/never/ulx" ] || fail "created ulx for a missing release"
echo "unpublished version (refused): ok"

# ---- latest needs a real release URL, not a file:// one ---------------------
if install --dir="$work/latest"; then fail "resolved 'latest' from a file:// base"; fi
grep -q -- "--version=vX.Y.Z" "$work/out" || fail "should tell the user to pass --version"
echo "latest without a resolvable release (clear error): ok"

# ---- where it installs when --dir is not given ------------------------------
if [ "$(id -u)" -ne 0 ]; then
  # An existing ulx on PATH is updated where it is, not duplicated elsewhere.
  existing="$work/existing"; mkdir -p "$existing"
  install --version=v0.1.0 --dir="$existing" || fail "setup install failed"
  TEST_PATH="$existing:$syspath" install --version=v0.2.0 || fail "in-place update failed"
  [ "$("$existing/ulx")" = "ulx 0.2.0" ] || fail "did not update the ulx already on PATH"
  [ ! -e "$fakehome/.local/bin/ulx" ] || fail "left a second copy in ~/.local/bin"
  echo "update finds the ulx on PATH (no shadowing copy): ok"

  # If that location is not writable, say so instead of installing elsewhere.
  ro="$work/readonly"; mkdir -p "$ro"; cp "$existing/ulx" "$ro/ulx"; chmod 0555 "$ro"
  if TEST_PATH="$ro:$syspath" install --version=v0.2.0; then fail "installed despite an unwritable existing location"; fi
  grep -q "cannot write" "$work/out" || fail "should explain the unwritable location"
  chmod 0755 "$ro"
  echo "existing ulx in an unwritable dir (clear error): ok"

  # With nothing installed, a non-root run goes to ~/.local/bin and warns about PATH.
  install --version=v0.2.0 || fail "default install failed"
  [ -x "$fakehome/.local/bin/ulx" ] || fail "default location should be ~/.local/bin"
  grep -q "not on your PATH" "$work/out" || fail "should warn that ~/.local/bin is not on PATH"
  echo "default install (~/.local/bin, PATH hint): ok"
else
  echo "skipped non-root location tests (running as root)"
fi

echo "test_install_flow: ok"
