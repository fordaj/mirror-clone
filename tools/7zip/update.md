# The 7-Zip bundle (`tools/7zip/`)

[7-Zip](https://www.7-zip.org/) is a free file archiver. mirror-clone vendors the upstream console builds so the release pipeline can create `zip` archives without a system `zip`, and so the legacy `.7z` tool updaters have a `7z`/`7zz` on hand. The upstream release is mirrored as a GitHub release at [ip7z/7zip](https://github.com/ip7z/7zip), which is what `update.sh` downloads from.

## Layout

```text
tools/7zip/
  update.sh                     # refresh from the ip7z/7zip releases
  v26.06/
    linux-arm/{7zz,7zzs,readme.txt,History.txt,License.txt,MANUAL/}
    linux-arm64/{7zz,7zzs,readme.txt,History.txt,License.txt,MANUAL/}
    linux-x64/{7zz,7zzs,readme.txt,History.txt,License.txt,MANUAL/}
    linux-x86/{7zz,7zzs,readme.txt,History.txt,License.txt,MANUAL/}
    mac-arm64/{7zz,readme.txt,History.txt,License.txt,MANUAL/}
    mac-x64/{7zz,readme.txt,History.txt,License.txt,MANUAL/}
    windows/7zr.exe
```

Unlike the other bundles, the platform layout is the vendored 7zip naming (`linux-x64`, `mac-arm64`, `windows`, …), not the `<os>-<arch>` layout, and the release tag carries no leading `v` (`26.06`) while the bundle directory keeps it (`v26.06`). The bundle keeps the **full upstream payload** per platform (binaries plus `readme.txt`, `History.txt`, `License.txt` and `MANUAL/`), as tracked in git; the Windows bundle keeps only `7zr.exe` (7z format only).

## `update.sh` in detail

Assets consumed (example for tag `26.06`): `7z2606-linux-x64.tar.xz` → `linux-x64/`, `7z2606-linux-x86.tar.xz` → `linux-x86/`, `7z2606-linux-arm64.tar.xz` → `linux-arm64/`, `7z2606-linux-arm.tar.xz` → `linux-arm/`, `7z2606-mac.tar.xz` → `mac-arm64/` (the `-mac` asset is the Apple Silicon build), `7z2606-mac-x64.tar.xz` → `mac-x64/`, and `7zr.exe` → `windows/7zr.exe`. The platform assets ship no checksums file; instead every asset is verified against the SHA-256 **digest that GitHub publishes per asset** (`gh release view --json assets`), and a downloaded asset without a digest entry is fatal — the script never installs unverified binaries. The script:

1. Resolves the tag (latest release, or `--tag X.Y[.Z...]`), validating the tag shape (`^[0-9]+(\.[0-9]+)+$`). The bundle directory is `v<tag>`.
2. Downloads the platform assets via `gh` (no p7zip needed: `.tar.xz` is extracted with `tar -xJf`), verifies every downloaded asset against its published digest (`shasum -a 256 -c` or `sha256sum -c`). A mismatch, or a missing digest entry, is fatal.
3. Extracts each archive into `v<tag>/<platform>/` (keeping the full payload), makes `7zz`/`7zzs` executable and rejects empty or missing binaries; `7zr.exe` is copied into `v<tag>/windows/` as-is.
4. Swaps in the new version directory and deletes superseded `v*` folders only after the new one is fully staged — a failed download leaves the previous bundle intact.
5. Smoke-tests the host binary: 7-Zip has no `--version` flag, so it runs the binary with no arguments and checks the banner (first line matching `7-Zip`) contains the tag; a mismatch only warns.

Environment overrides: `SEVENZIP_REPO` (default `ip7z/7zip`), `SEVENZIP_TAG`. `--dry-run` lists assets, planned digests and removals without touching anything; `--help` shows usage. Prerequisites: `gh` and `tar` with xz support (macOS bsdtar handles `.tar.xz` natively; otherwise `xz` is required). `update.sh` resolves its own directory, so it can run from anywhere. The `.exe` installers, `.msi` packages, extra `.7z` builds and source archives are ignored.

After a refresh, `scripts/.common.env`'s `SEVENZIP_VERSION_DIR` pin needs no edit: [env.sh](../../scripts/env.md) prefers the newest `tools/7zip/v*` directory (`resolve_version_dir`), so the pin is only a fallback. Note that a refresh can drop support for platforms upstream stops publishing (today: Linux x86, ARM, x86-64, ARM64; macOS x64, ARM64; Windows x86 via `7zr.exe`).

## How the repository uses it

`SEVENZZ_BIN` resolves through the [env cascade](../../scripts/env.md) to `mac-*/7zz` or `linux-*/7zz` (or `windows/7zr.exe`). It is used by [release.sh](../../scripts/release.md) as a `zip` replacement (`7zz a -tzip`) and by the legacy `.7z` tool updaters ([versioner](../versioner/update.md), [logamuffin](../logamuffin/update.md)).

## Related pages

- [../README.md](../README.md) — the bundle index
- [../../scripts/README.md](../../scripts/README.md) — the scripts that consume the bundle
