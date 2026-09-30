#!/usr/bin/env bash
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
source "$here/../install.sh"
source "$here/lib.sh"

good="$(new_key release)"
other="$(new_key stranger)"
export_pubkey "$good" "$work/pubkey.asc"

build_release "$work/rel" v1.2.3 "$good"
name="ulx-v1.2.3-$PLATFORM-$ARCH.tar.gz"
BASE_URL="file://$work/rel"
PUBKEY_URL="file://$work/pubkey.asc"
VERSION=v1.2.3

fresh_dest() { d="$work/dest-$1"; mkdir -p "$d"; cp "$work/rel/releases/download/v1.2.3/$name" "$d/"; echo "$d"; }

# Valid signature and sums pass, and the invoker's own keyring is never made.
fakehome="$work/home"; mkdir -p "$fakehome"
dest="$(fresh_dest valid)"
HOME="$fakehome" verify_checksums "$dest" "$name" >/dev/null
echo "verify_checksums (valid): ok"
[ ! -e "$fakehome/.gnupg" ] || { echo "FAIL: verify_checksums touched ~/.gnupg"; exit 1; }
echo "verify_checksums (invoker keyring untouched): ok"

# A changed archive fails the sha256 check.
dest="$(fresh_dest tampered)"
echo tampered >> "$dest/$name"
if ( verify_checksums "$dest" "$name" ) >/dev/null 2>&1; then
  echo "FAIL: tampered archive should fail verification"; exit 1
fi
echo "verify_checksums (tampered archive, rejected): ok"

# A signature by a different key fails, even though the sums are right.
GNUPGHOME="$other" gpg --batch --yes --detach-sign --armor \
  -o "$work/stranger.asc" "$work/rel/releases/download/v1.2.3/checksums.txt" 2>/dev/null
good_asc="$work/rel/releases/download/v1.2.3/checksums.txt.asc"
cp "$good_asc" "$work/good.asc"
cp "$work/stranger.asc" "$good_asc"
dest="$(fresh_dest badsig)"
if ( verify_checksums "$dest" "$name" ) >/dev/null 2>&1; then
  echo "FAIL: a signature from another key should fail"; exit 1
fi
echo "verify_checksums (wrong signer, rejected): ok"
cp "$work/good.asc" "$good_asc"

# A checksums.txt edited after signing fails the signature, even when the edit
# makes the sums match a swapped archive.
dest="$(fresh_dest edited-sums)"
echo evil > "$dest/$name"
( cd "$dest" && sha256sum "$name" ) > "$work/rel/releases/download/v1.2.3/checksums.txt"
if ( verify_checksums "$dest" "$name" ) >/dev/null 2>&1; then
  echo "FAIL: an edited checksums.txt should fail the signature"; exit 1
fi
echo "verify_checksums (edited checksums.txt, rejected): ok"
build_release "$work/rel" v1.2.3 "$good"

# With gpg present, an unfetchable key is fatal: blocking that one URL must not
# downgrade the install to checksum-only.
dest="$(fresh_dest nokey)"
if ( PUBKEY_URL="file://$work/nonexistent.asc" verify_checksums "$dest" "$name" ) >/dev/null 2>&1; then
  echo "FAIL: missing public key must refuse when gpg is present"; exit 1
fi
echo "verify_checksums (key fetch fails, rejected): ok"

# A name missing from checksums.txt is refused, not skipped.
dest="$(fresh_dest noentry)"
cp "$dest/$name" "$dest/ulx-v1.2.3-other.tar.gz"
if ( verify_checksums "$dest" "ulx-v1.2.3-other.tar.gz" ) >/dev/null 2>&1; then
  echo "FAIL: an archive with no checksum entry must be refused"; exit 1
fi
echo "verify_checksums (no entry, rejected): ok"

# Without gpg it warns and still checks sha256, including for a tampered file.
nogpg="$(path_without '^gpg')"
dest="$(fresh_dest nogpg)"
out="$( PATH="$nogpg" verify_checksums "$dest" "$name" 2>&1 )"
[[ "$out" == *"gpg not found"* ]] || { echo "FAIL: should warn when gpg is absent: $out"; exit 1; }
echo x >> "$dest/$name"
if ( PATH="$nogpg" verify_checksums "$dest" "$name" ) >/dev/null 2>&1; then
  echo "FAIL: sha256 must still be enforced without gpg"; exit 1
fi
echo "verify_checksums (gpg absent: warns, still checks sha256): ok"

# macOS has shasum and no sha256sum.
shim="$work/shim"; mkdir -p "$shim"
printf '#!/bin/sh\n# shasum -a 256 FILE\nshift 2\nexec /usr/bin/sha256sum "$@"\n' > "$shim/shasum"
chmod +x "$shim/shasum"
nosha="$(path_without '^sha256sum$')"
dest="$(fresh_dest shasum)"
PATH="$shim:$nosha" verify_checksums "$dest" "$name" >/dev/null 2>&1
echo "verify_checksums (shasum fallback): ok"

echo "test_verify_checksums: ok"
