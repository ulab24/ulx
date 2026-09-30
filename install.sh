#!/usr/bin/env bash
# ulx -- installer.
#
#   curl -fsSL https://raw.githubusercontent.com/ulab24/ulx/main/install.sh | bash
#
# Installs the latest ulx release, or updates an existing install in place.
# It only ever downloads signed, checksummed release archives published to
# this repository's GitHub Releases; ulx's source lives on ulab24's own
# infrastructure and is not involved.
set -euo pipefail

# ---- defaults ----------------------------------------------------------

BASE_URL="${ULX_INSTALL_BASE_URL:-https://github.com/ulab24/ulx}"
PUBKEY_URL="${ULX_INSTALL_PUBKEY_URL:-https://raw.githubusercontent.com/ulab24/ulx/main/ulab24-release-signing-key.asc}"
VERSION="latest"
INSTALL_DIR=""

# Set by detect_platform to the names the release archives use.
PLATFORM=""
ARCH=""

# Sandbox helpers that ship beside ulx on Linux. ulx looks them up in its own
# directory and runs them, so they must land together with the binary.
HELPERS_linux="ulx-linux-sandbox ulx-seccomp"
HELPERS_macos=""

# ---- output --------------------------------------------------------------

if [ -t 1 ]; then
  c_bold=$'\033[1m'; c_red=$'\033[31m'; c_yellow=$'\033[33m'; c_reset=$'\033[0m'
else
  c_bold=""; c_red=""; c_yellow=""; c_reset=""
fi

log()  { printf '%s\n' "$*"; }
warn() { printf '%s%s%s\n' "$c_yellow" "$*" "$c_reset" >&2; }
die()  { printf '%s%s%s\n' "$c_red" "$*" "$c_reset" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: install.sh [--version=vX.Y.Z] [--dir=PATH] [--help]

  --version=vX.Y.Z   Version to install. Default: the latest release.
  --dir=PATH         Directory to install into. Default: where an existing
                     ulx on PATH already lives, else /usr/local/bin when run
                     as root, else ~/.local/bin.
  --help             Show this help.

Re-run the installer to update. Your configuration and sessions are never
touched.
EOF
}

# ---- argument parsing ------------------------------------------------------

parse_args() {
  dir_given=0
  for arg in "$@"; do
    case "$arg" in
      --version=*) VERSION="${arg#*=}" ;;
      --dir=*) INSTALL_DIR="${arg#*=}"; dir_given=1 ;;
      --help) usage; exit 0 ;;
      *) die "unknown argument: $arg (see --help)" ;;
    esac
  done

  # The version becomes part of a download URL, so nothing but a plain tag is
  # accepted: a slash or dots would walk the URL somewhere else.
  if [ "$VERSION" != "latest" ] && ! [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    die "--version must look like v1.2.3 or v1.2.3-rc.1, got: $VERSION"
  fi
  if [ "$dir_given" -eq 1 ] && [ -z "$INSTALL_DIR" ]; then
    die "--dir must not be empty"
  fi
}

# ---- platform check ---------------------------------------------------

# detect_platform sets PLATFORM and ARCH to the names used in the release
# archive file names (linux|macos, x64|arm64).
detect_platform() {
  os="$(uname -s)"
  machine="$(uname -m)"
  case "$os" in
    Linux) PLATFORM=linux ;;
    Darwin) PLATFORM=macos ;;
    MINGW*|MSYS*|CYGWIN*)
      die "this installer supports Linux and macOS. On Windows, download ulx-<version>-windows-x64.zip from $BASE_URL/releases, unpack it, and update later with: ulx upgrade" ;;
    *) die "this installer supports Linux and macOS (found: $os)" ;;
  esac
  case "$machine" in
    x86_64|amd64) ARCH=x64 ;;
    arm64|aarch64) ARCH=arm64 ;;
    *) die "this installer supports amd64 and arm64 (found: $machine)" ;;
  esac
}

# ---- download + verification --------------------------------------------

# resolve_latest pins VERSION=latest to the concrete tag GitHub's
# /releases/latest redirects to. The archive names carry the version, so a
# concrete tag is required, not optional.
resolve_latest() {
  [ "$VERSION" = "latest" ] || return 0
  case "$BASE_URL" in
    https://*) : ;;
    *) die "cannot look up the latest release from $BASE_URL; pass --version=vX.Y.Z" ;;
  esac
  effective="$(curl -fsSLI -o /dev/null -w '%{url_effective}' "$BASE_URL/releases/latest" 2>/dev/null || true)"
  tag="${effective##*/tag/}"
  if [ "$tag" != "$effective" ] && [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
    VERSION="$tag"
  else
    die "could not find the latest release at $BASE_URL/releases/latest (no release published yet, or no network); pass --version=vX.Y.Z"
  fi
}

# download_url NAME -> the URL of release asset NAME at $VERSION.
download_url() {
  printf '%s/releases/download/%s/%s' "$BASE_URL" "$VERSION" "$1"
}

fetch() {
  curl -fsSL "$1" -o "$2"
}

# sha256_of FILE -> the hex digest. macOS has shasum, not sha256sum.
sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    die "need sha256sum or shasum to verify the download"
  fi
}

# verify_checksums DIR NAME... -- downloads checksums.txt(+.asc) into DIR,
# GPG-verifies it when gpg is available, then checks the sha256 sum of every
# NAME (each of which must already exist in DIR). With gpg present, a signing
# key that cannot be fetched is fatal: blocking that one URL must not
# downgrade the install to checksum-only.
verify_checksums() {
  dir="$1"; shift
  fetch "$(download_url checksums.txt)" "$dir/checksums.txt"
  fetch "$(download_url checksums.txt.asc)" "$dir/checksums.txt.asc"

  # A throwaway --homedir, not --keyring: GnuPG 2.4 set up with use-keyboxd
  # silently ignores --keyring and then finds no key, and either way the
  # invoker's ~/.gnupg must not be touched. The home holds only the release
  # key, so any good signature is one made by it.
  if command -v gpg >/dev/null 2>&1; then
    keyring="$(mktemp -d)"
    if fetch "$PUBKEY_URL" "$dir/ulab24-release-signing-key.asc"; then
      gpg --batch --homedir "$keyring" \
        --import "$dir/ulab24-release-signing-key.asc" >/dev/null 2>&1 || true
      verified=0
      if gpg --batch --homedir "$keyring" \
          --verify "$dir/checksums.txt.asc" "$dir/checksums.txt" >/dev/null 2>&1; then
        verified=1
      fi
      gpgconf --homedir "$keyring" --kill all >/dev/null 2>&1 || true
      rm -rf "$keyring"
      if [ "$verified" -eq 1 ]; then
        log "checksums.txt signature: OK"
      else
        die "checksums.txt failed GPG signature verification -- refusing to install"
      fi
    else
      rm -rf "$keyring"
      die "could not fetch the release signing key -- refusing to install without signature verification"
    fi
  else
    warn "gpg not found -- skipping signature verification, checking sha256 only"
  fi

  for name in "$@"; do
    want="$(awk -v f="$name" '$2==f {print $1}' "$dir/checksums.txt")"
    [ -n "$want" ] || die "checksums.txt has no entry for $name"
    got="$(sha256_of "$dir/$name")"
    [ "$want" = "$got" ] || die "checksum mismatch for $name -- refusing to install"
  done
}

# ---- destination ------------------------------------------------------------

# existing_ulx_dir prints the directory of a ulx already on PATH, if any.
existing_ulx_dir() {
  found="$(command -v ulx 2>/dev/null || true)"
  [ -n "$found" ] && [ -x "$found" ] || return 0
  # Resolve a symlink so the real files are replaced, not the link.
  if command -v readlink >/dev/null 2>&1; then
    resolved="$(readlink -f "$found" 2>/dev/null || true)"
    [ -z "$resolved" ] || found="$resolved"
  fi
  dirname "$found"
}

# choose_dir sets INSTALL_DIR. An update goes where ulx already is, so a
# non-root re-run cannot leave a second copy that PATH order might shadow.
choose_dir() {
  [ -z "$INSTALL_DIR" ] || return 0
  current="$(existing_ulx_dir)"
  if [ -n "$current" ]; then
    if [ -w "$current" ]; then
      INSTALL_DIR="$current"
      return 0
    fi
    die "ulx is installed in $current, which this user cannot write. Re-run with sudo to update it there, or pass --dir=PATH to install a second copy."
  fi
  if [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR=/usr/local/bin
  else
    INSTALL_DIR="$HOME/.local/bin"
  fi
}

# place SRC DEST_DIR NAME -- copies next to its destination and renames into
# place, so a running ulx or an interrupted install never leaves a half file.
place() {
  src="$1"; dest_dir="$2"; name="$3"
  cp "$src" "$dest_dir/.$name.new.$$"
  chmod 0755 "$dest_dir/.$name.new.$$"
  mv -f "$dest_dir/.$name.new.$$" "$dest_dir/$name"
}

# find_in DIR NAME -> path of the regular file NAME inside the unpacked archive.
find_in() {
  find "$1" -type f -name "$2" 2>/dev/null | head -n 1
}

# ---- install ------------------------------------------------------------------

install_release() {
  # EXIT, not RETURN: die exits the shell, and the download must not be left
  # behind when verification refuses it.
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT

  archive="ulx-${VERSION}-${PLATFORM}-${ARCH}.tar.gz"
  log "downloading ulx $VERSION ($PLATFORM-$ARCH)..."
  fetch "$(download_url "$archive")" "$WORK/$archive" \
    || die "could not download $archive from $BASE_URL (is $VERSION a published release?)"
  verify_checksums "$WORK" "$archive"

  mkdir -p "$WORK/unpacked"
  tar -xzf "$WORK/$archive" -C "$WORK/unpacked"
  binary="$(find_in "$WORK/unpacked" ulx)"
  [ -n "$binary" ] || die "$archive did not contain ulx"

  choose_dir
  mkdir -p "$INSTALL_DIR" 2>/dev/null || die "cannot create $INSTALL_DIR (try sudo, or pass --dir=PATH)"
  [ -w "$INSTALL_DIR" ] || die "cannot write to $INSTALL_DIR (try sudo, or pass --dir=PATH)"

  before=""
  if [ -x "$INSTALL_DIR/ulx" ]; then
    before="$("$INSTALL_DIR/ulx" --version 2>/dev/null || true)"
  fi

  # Helpers first, ulx last: if anything fails part-way, the old ulx is still
  # the one that runs, and the next attempt retries.
  helpers="HELPERS_$PLATFORM"
  for name in ${!helpers}; do
    source_path="$(find_in "$WORK/unpacked" "$name")"
    [ -n "$source_path" ] || continue
    place "$source_path" "$INSTALL_DIR" "$name"
  done
  place "$binary" "$INSTALL_DIR" ulx

  after="$("$INSTALL_DIR/ulx" --version 2>/dev/null || echo "ulx $VERSION")"
  log ""
  if [ -n "$before" ] && [ "$before" != "$after" ]; then
    log "${c_bold}ulx updated:${c_reset} $before -> $after ($INSTALL_DIR)"
  elif [ -n "$before" ]; then
    log "${c_bold}ulx reinstalled:${c_reset} $after ($INSTALL_DIR)"
  else
    log "${c_bold}ulx installed:${c_reset} $after ($INSTALL_DIR)"
  fi

  case ":$PATH:" in
    *":$INSTALL_DIR:"*) : ;;
    *) warn "$INSTALL_DIR is not on your PATH. Add it, for example:  export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
  esac
  log "Next: run 'ulx setup', then 'ulx'. Update later with 'ulx upgrade' or by re-running this installer."
}

# ---- entry point ------------------------------------------------------

main() {
  parse_args "$@"
  detect_platform
  resolve_latest
  log "version: $VERSION"
  install_release
}

if [ "${BASH_SOURCE[0]:-$0}" = "$0" ]; then
  main "$@"
fi
