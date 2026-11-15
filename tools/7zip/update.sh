#!/usr/bin/env bash
# update.sh — refresh the bundled 7-Zip binaries from the ip7z/7zip releases.
#
# 7-Zip is published at https://www.7-zip.org/ and mirrored as a GitHub
# release at ip7z/7zip. Unlike the other bundles, the release tag carries no
# leading "v" (e.g. 26.06) while the bundle directory keeps the "v" prefix
# (tools/7zip/v26.06), and the platform layout is the vendored 7zip naming
# (linux-x64, mac-arm64, windows, ...), not the <os>-<arch> layout used by the
# other bundles.
#
# The bundle keeps the full upstream payload per platform (binaries plus
# readme.txt, History.txt, License.txt and MANUAL/), not just the executable.
# The Windows bundle keeps only 7zr.exe (7z format only), exactly as vendored.
#
# Assets consumed (tag 26.06 example):
#   7z2606-linux-x64.tar.xz  -> linux-x64/   (7zz + 7zzs)
#   7z2606-linux-x86.tar.xz  -> linux-x86/   (7zz + 7zzs)
#   7z2606-linux-arm64.tar.xz -> linux-arm64/ (7zz + 7zzs)
#   7z2606-linux-arm.tar.xz  -> linux-arm/   (7zz + 7zzs)
#   7z2606-mac.tar.xz        -> mac-arm64/   (7zz)
#   7z2606-mac-x64.tar.xz    -> mac-x64/     (7zz)
#   7zr.exe                  -> windows/7zr.exe
#
# The release ships no checksums.txt; instead every asset digest is verified
# against the SHA-256 digest that GitHub publishes for each asset (via
# gh release view --json assets). A downloaded asset without a digest entry
# is fatal — the script never installs unverified binaries.
#
# Usage:
#   tools/7zip/update.sh              # download latest, replace old versions
#   tools/7zip/update.sh --dry-run    # resolve tag + list assets, change nothing
#   tools/7zip/update.sh --help       # usage
#
# Prerequisites: gh (https://cli.github.com/) and tar with xz support
# (xz on Linux; macOS bsdtar handles .tar.xz natively). The script resolves
# its own directory, so it can be run from anywhere. Logging uses log
# <level> <message> from scripts/entry.sh (logamuffin, with printf fallback).
#
# Layout after a successful run (example for tag 26.06):
#   tools/7zip/
#     update.sh
#     v26.06/
#       linux-arm/{7zz,7zzs,readme.txt,History.txt,License.txt,MANUAL/}
#       linux-arm64/{...}
#       linux-x64/{...}
#       linux-x86/{...}
#       mac-arm64/{...}
#       mac-x64/{...}
#       windows/7zr.exe
#
# Env:
#   SEVENZIP_REPO  Repository slug (default: ip7z/7zip)
#   SEVENZIP_TAG   Pinned tag (default: latest release)

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPO_ROOT_FOR_ENV=$(cd -- "$SCRIPT_DIR/../.." &>/dev/null && pwd)
if [[ ! -f "$REPO_ROOT_FOR_ENV/scripts/entry.sh" ]]; then
    printf 'update.sh: error: entry point not found: %s/scripts/entry.sh\n' "$REPO_ROOT_FOR_ENV" >&2
    exit 1
fi
# shellcheck disable=SC1091
. "$REPO_ROOT_FOR_ENV/scripts/entry.sh"

DRY_RUN=0
TAG="${SEVENZIP_TAG:-}"
REPO="${SEVENZIP_REPO:-ip7z/7zip}"

usage() {
    cat <<'EOF'
Usage: tools/7zip/update.sh [--dry-run] [--tag TAG] [--repo REPO]

Download the latest 7-Zip release from GitHub via gh (ip7z/7zip), extract
each platform payload into tools/7zip/v<tag>/<platform>/ (the vendored 7zip
layout: linux-x64, linux-x86, linux-arm64, linux-arm, mac-arm64, mac-x64 and
windows), and delete old version folders. The full upstream payload is kept
(binaries plus readme/History/License and MANUAL/), as tracked in git today.

Flags:
  --dry-run, -n   Resolve tag + list planned assets, change nothing.
  --tag TAG       Pin a specific release tag (default: latest release).
  --repo REPO     Repository slug (default: ip7z/7zip).
  --help, -h      Show this help.

Env:
  SEVENZIP_REPO  Repository slug (overridden by --repo).
  SEVENZIP_TAG   Pinned tag (overridden by --tag).
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run | -n)
        DRY_RUN=1
        shift
        ;;
    --help | -h)
        usage
        exit 0
        ;;
    --tag)
        [[ $# -ge 2 ]] || {
            log ERROR "--tag requires a value"
            usage >&2
            exit 2
        }
        TAG="$2"
        shift 2
        ;;
    --tag=*)
        TAG="${1#--tag=}"
        shift
        ;;
    --repo)
        [[ $# -ge 2 ]] || {
            log ERROR "--repo requires a value"
            usage >&2
            exit 2
        }
        REPO="$2"
        shift 2
        ;;
    --repo=*)
        REPO="${1#--repo=}"
        shift
        ;;
    *)
        log ERROR "unknown argument: $1"
        usage >&2
        exit 2
        ;;
    esac
done

[[ -n "$REPO" ]] || {
    log ERROR "repository must not be empty"
    exit 2
}

die() {
    log ERROR "$*" || true
    exit 1
}
need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1 (https://cli.github.com/)"
}

need_cmd gh
need_cmd tar

# tar needs xz support for .tar.xz: macOS/bsdtar has it built in; GNU tar
# relies on the xz binary.
tar_is_bsdtar() {
    tar --version 2>/dev/null | grep -qi bsdtar
}
if [[ "$DRY_RUN" -ne 1 ]]; then
    if ! tar_is_bsdtar && ! command -v xz >/dev/null 2>&1; then
        die "required command not found: xz (needed by GNU tar for .tar.xz; brew install xz / apt-get install xz-utils)"
    fi
fi

TOOL_ROOT="$SCRIPT_DIR"
[[ -d "$TOOL_ROOT" ]] || die "7zip bundle directory not found: $TOOL_ROOT"
log INFO "7zip bundle directory: $TOOL_ROOT"
log INFO "repository: $REPO"

if [[ -z "$TAG" ]]; then
    TAG="$(gh release view --repo "$REPO" --json tagName -q .tagName)" ||
        die "could not determine latest release from $REPO (is gh authenticated and the repo visible?)"
fi
[[ -n "$TAG" ]] || die "could not determine release tag from $REPO"
# Upstream tags carry no leading "v" (e.g. 26.06); the bundle directory does.
if ! [[ "$TAG" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    die "invalid tag '$TAG' (expected X.Y[.Z...], e.g. 26.06)"
fi
VERSION_DIR="v$TAG"
log INFO "release tag: $TAG (bundle directory: $VERSION_DIR)"

# asset_to_platform <asset> sets PLATFORM (the vendored 7zip layout) or
# returns 1 for assets this bundle does not consume. Matches on the suffix,
# so the version-embedded stem (7z2606-mac -> mac-arm64) needs no parsing.
asset_to_platform() {
    local name="$1"
    case "$name" in
    *-linux-arm64.tar.xz) PLATFORM="linux-arm64" ;;
    *-linux-arm.tar.xz) PLATFORM="linux-arm" ;;
    *-linux-x64.tar.xz) PLATFORM="linux-x64" ;;
    *-linux-x86.tar.xz) PLATFORM="linux-x86" ;;
    *-mac-x64.tar.xz) PLATFORM="mac-x64" ;;
    *-mac.tar.xz) PLATFORM="mac-arm64" ;;
    7zr.exe) PLATFORM="windows" ;;
    *) return 1 ;;
    esac
}

# The release ships no checksums.txt; GitHub publishes a SHA-256 digest per
# asset, which is what we verify against. Refuse to install anything without
# an entry — same stance as the runner-spawner updater.
fetch_digests() {
    gh release view "$TAG" --repo "$REPO" --json assets -q '.assets[] | .name + " " + (.digest // "")' ||
        die "could not list assets for $TAG in $REPO"
}

if [[ "$DRY_RUN" -eq 1 ]]; then
    log INFO "DRY RUN: no download, extraction, or deletion will happen"
    log INFO "release $TAG assets:"
    digests_list="$(fetch_digests)"
    [[ -n "$digests_list" ]] || die "no assets found for $TAG in $REPO"
    asset_count=0
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        asset="${line%% *}"
        digest="${line#* }"
        if asset_to_platform "$asset"; then
            asset_count=$((asset_count + 1))
            case "$asset" in
            *.tar.xz) log INFO "  $asset -> $VERSION_DIR/$PLATFORM/ (digest: ${digest:-MISSING})" ;;
            *) log INFO "  $asset -> $VERSION_DIR/$PLATFORM/7zr.exe (digest: ${digest:-MISSING})" ;;
            esac
        else
            log INFO "  $asset (ignored)"
        fi
    done <<<"$digests_list"
    ((asset_count > 0)) || die "no 7-Zip platform assets found for $TAG in $REPO"
    shopt -s nullglob
    old_found=0
    for dir in "$TOOL_ROOT"/v*/; do
        [[ -d "$dir" ]] || continue
        dir_name="$(basename "$dir")"
        if [[ "$dir_name" != "$VERSION_DIR" ]]; then
            log INFO "would remove old $dir_name"
            old_found=1
        fi
    done
    if [[ "$old_found" -eq 0 ]]; then
        log INFO "no old version folders to remove"
    fi
    log INFO "dry run complete: would update $TOOL_ROOT/$VERSION_DIR"
    exit 0
fi

# --- Real update: download to a temp dir, stage the bundle, then swap. ---
TMP_DIR=""
STAGE_DIR=""
cleanup() {
    if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
        rm -rf -- "$TMP_DIR"
    fi
    if [[ -n "${STAGE_DIR:-}" && -d "$STAGE_DIR" ]]; then
        rm -rf -- "$STAGE_DIR"
    fi
}
trap cleanup EXIT

TMP_DIR="$(mktemp -d)"
STAGE_DIR="$(mktemp -d "$TOOL_ROOT/.tmp.XXXXXX")"

log INFO "downloading $TAG assets from $REPO..."
digests_list="$(fetch_digests)"
[[ -n "$digests_list" ]] || die "no assets found for $TAG in $REPO"
asset_names=()
while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    asset="${line%% *}"
    if asset_to_platform "$asset"; then
        asset_names+=("$asset")
    fi
done <<<"$digests_list"
((${#asset_names[@]} > 0)) || die "no 7-Zip platform assets found for $TAG in $REPO"
for asset in "${asset_names[@]}"; do
    gh release download "$TAG" --repo "$REPO" --dir "$TMP_DIR" --pattern "$asset" --clobber
done
log INFO "downloaded ${#asset_names[@]} assets"

log INFO "verifying SHA-256 digests from the GitHub release..."
checksum_tool=""
if command -v shasum >/dev/null 2>&1; then
    checksum_tool="shasum -a 256"
elif command -v sha256sum >/dev/null 2>&1; then
    checksum_tool="sha256sum"
fi
[[ -n "$checksum_tool" ]] || die "neither shasum nor sha256sum found; cannot verify digests"
verify_list="$TMP_DIR/.verify-list"
: >"$verify_list"
while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    asset="${line%% *}"
    digest="${line#* }"
    [[ -f "$TMP_DIR/$asset" ]] || continue
    [[ -n "$digest" ]] ||
        die "no digest published for asset $asset; refusing to install unverified binaries"
    case "$digest" in
    sha256:*) hex="${digest#sha256:}" ;;
    *) die "unsupported digest format for asset $asset: '$digest' (expected sha256:...)" ;;
    esac
    printf '%s  %s\n' "$hex" "$asset" >>"$verify_list"
done <<<"$digests_list"
(cd "$TMP_DIR" && $checksum_tool -c "$verify_list") || die "digest verification failed for $TAG"
log INFO "digests verified"

for asset in "${asset_names[@]}"; do
    asset_to_platform "$asset"
    case "$asset" in
    *.tar.xz)
        if [[ -e "$STAGE_DIR/$PLATFORM" ]]; then
            die "duplicate asset for platform $PLATFORM (from $asset)"
        fi
        log INFO "extracting $asset -> $VERSION_DIR/$PLATFORM/"
        mkdir -p "$STAGE_DIR/$PLATFORM"
        tar -xJf "$TMP_DIR/$asset" -C "$STAGE_DIR/$PLATFORM"
        for bin in 7zz 7zzs; do
            if [[ -f "$STAGE_DIR/$PLATFORM/$bin" ]]; then
                chmod 755 "$STAGE_DIR/$PLATFORM/$bin"
                [[ -s "$STAGE_DIR/$PLATFORM/$bin" ]] || die "installed binary is empty: $STAGE_DIR/$PLATFORM/$bin"
            fi
        done
        [[ -x "$STAGE_DIR/$PLATFORM/7zz" ]] || die "no 7zz binary in $asset"
        ;;
    7zr.exe)
        mkdir -p "$STAGE_DIR/windows"
        cp -p "$TMP_DIR/$asset" "$STAGE_DIR/windows/7zr.exe"
        [[ -s "$STAGE_DIR/windows/7zr.exe" ]] || die "installed binary is empty: $STAGE_DIR/windows/7zr.exe"
        ;;
    *)
        die "unsupported asset: $asset"
        ;;
    esac
done

TAG_DIR="$TOOL_ROOT/$VERSION_DIR"
rm -rf -- "$TAG_DIR"
mv "$STAGE_DIR" "$TAG_DIR"
STAGE_DIR=""

for dir in "$TOOL_ROOT"/v*/; do
    [[ -d "$dir" ]] || continue
    dir_name="$(basename "$dir")"
    if [[ "$dir_name" != "$VERSION_DIR" ]]; then
        log INFO "removing old $dir_name"
        rm -rf -- "$dir"
    fi
done

# Best-effort host verification: run the bundled binary for this machine.
# 7-Zip has no --version flag; running it with no arguments prints the
# version banner (first line mentions the tag) and exits 0.
host_os_raw="$(uname -s | tr '[:upper:]' '[:lower:]')"
host_arch_raw="$(uname -m | tr '[:upper:]' '[:lower:]')"
case "$host_os_raw" in
darwin*) host_os="mac" ;;
linux*) host_os="linux" ;;
msys* | mingw* | cygwin* | windows* | win*) host_os="windows" ;;
*) host_os="$host_os_raw" ;;
esac
case "$host_arch_raw" in
x86_64 | amd64) host_arch="x64" ;;
i?86) host_arch="x86" ;;
arm64 | aarch64) host_arch="arm64" ;;
arm | armv*) host_arch="arm" ;;
*) host_arch="$host_arch_raw" ;;
esac
if [[ "$host_os" == "linux" && "$host_arch" == "arm64" ]]; then host_plat="linux-arm64"
elif [[ "$host_os" == "linux" ]]; then host_plat="linux-$host_arch"
elif [[ "$host_os" == "mac" ]]; then host_plat="mac-$host_arch"
else host_plat="$host_os"; fi
host_bin=""
if [[ "$host_plat" == "windows" ]]; then
    host_bin="$TAG_DIR/windows/7zr.exe"
else
    host_bin="$TAG_DIR/$host_plat/7zz"
fi
if [[ -x "$host_bin" ]]; then
    host_ver="$("$host_bin" 2>&1 | grep -m1 -i '7-zip' || true)"
    log INFO "host binary $host_plat reports: $host_ver"
    case "$host_ver" in
    *"$TAG"*) ;;
    *) log WARNING "host binary banner '$host_ver' does not mention $TAG" ;;
    esac
else
    log WARNING "host platform $host_plat not in bundle; skipped version check"
fi

log INFO "done: $TAG_DIR now contains:"
for dir in "$TAG_DIR"/*/; do
    [[ -d "$dir" ]] || continue
    log INFO "  $(basename "$dir")"
done
