# Shared helpers for the installer tests. Source it; it runs nothing itself.
# The caller sets `here` to the test directory and `work` to a temp directory.

# new_key NAME -> creates a GPG home in $work/gpg-NAME with one key, echoes it.
new_key() {
  home="$work/gpg-$1"
  mkdir -m 700 "$home"
  GNUPGHOME="$home" gpg --batch --quick-generate-key --passphrase '' \
    "$1 <$1@example.invalid>" default default 2>/dev/null
  echo "$home"
}

# build_release ROOT VERSION KEYHOME [ROOTS_PUBKEY_FILE]
#
# Lays out ROOT/releases/download/VERSION/ like a GitHub Release would: the
# archive for this machine's platform, checksums.txt, and its signature made
# with KEYHOME. The fake ulx prints "ulx <VERSION without v>", so a test can
# tell which release it got. Needs install.sh already sourced (detect_platform).
build_release() {
  root="$1"; version="$2"; keyhome="$3"
  detect_platform
  stage="$work/stage-$version"
  rm -rf "$stage"; mkdir -p "$stage"
  printf '#!/bin/sh\necho "ulx %s"\n' "${version#v}" > "$stage/ulx"
  echo "# license" > "$stage/LICENSE"
  if [ "$PLATFORM" = linux ]; then
    printf '#!/bin/sh\necho helper-%s\n' "${version#v}" > "$stage/ulx-linux-sandbox"
    printf '#!/bin/sh\necho helper-%s\n' "${version#v}" > "$stage/ulx-seccomp"
  fi
  chmod +x "$stage"/ulx*

  out="$root/releases/download/$version"
  mkdir -p "$out"
  archive="ulx-$version-$PLATFORM-$ARCH.tar.gz"
  tar -czf "$out/$archive" -C "$stage" .
  ( cd "$out" && sha256sum "$archive" > checksums.txt )
  rm -f "$out/checksums.txt.asc"
  GNUPGHOME="$keyhome" gpg --batch --yes --detach-sign --armor \
    -o "$out/checksums.txt.asc" "$out/checksums.txt" 2>/dev/null
}

export_pubkey() { GNUPGHOME="$1" gpg --batch --armor --export > "$2"; }

# A PATH directory holding every /usr/bin tool except those whose names match
# the extended regex in $1, for simulating a machine that lacks one.
path_without() {
  bin="$work/bin-without-$(echo "$1" | tr -c 'a-z0-9' '_')"
  mkdir -p "$bin"
  for tool in /usr/bin/*; do
    name="$(basename "$tool")"
    [[ "$name" =~ $1 ]] && continue
    ln -s "$tool" "$bin/$name" 2>/dev/null || true
  done
  echo "$bin"
}
