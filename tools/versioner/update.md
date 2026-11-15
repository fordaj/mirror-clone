# The versioner bundle (`tools/versioner/`)

[Versioner](https://github.com/fordaj/Versioner) computes the repository version (the tag) from the git history and `.versioner.json` — the same computation the builds and the release use, so a local build and the published tag can never drift apart. It is consumed by [scripts/version.sh](../../scripts/version.md), [build.sh](../../build.md) and [release.sh](../../release.md).

## Layout

```text
tools/versioner/
  update.sh                     # refresh from fordaj/Versioner releases
  v0.0.3.0.5/
    macos-arm64/versioner
    macos-x86_64/versioner
    linux-arm64/versioner
    linux-x86_64/versioner
    windows-x86_64/versioner.exe
```

There is no `windows-arm64` build (upstream ships windows-amd64 only); on windows-arm64 the cascade falls back to `versioner` on `PATH` (see [../../scripts/env.md](../../scripts/env.md)).

## `update.sh` in detail

The `.7z` bundle family: assets are `*_<os>-<arch>.7z` archives plus `checksums.txt`, so a `7z`/`7zz` binary is required for a real update (the vendored one under `tools/7zip/` works). The script:

1. Resolves the tag (latest release, or `--tag vX.Y.Z...`), validating the tag shape.
2. Downloads via `gh`, then verifies the archives against `checksums.txt` (`shasum -a 256 -c` or `sha256sum -c`). A mismatch is fatal; a missing `checksums.txt` only warns.
3. Maps each asset stem to a platform (`*_macos-x86_64`/`*_darwin-amd64` → `macos-x86_64`, `*_macos-arm64`/`*_darwin-arm64` → `macos-arm64`, `*_linux-x86_64`/`*_linux-amd64` → `linux-x86_64`, `*_linux-arm64` → `linux-arm64`, `*_windows-x86_64`/`*_windows-amd64` → `windows-x86_64`, `*_windows-arm64` → `windows-arm64`), extracts with `$SEVENZIP`, copies the binary (`versioner`/`versioner.exe` at the archive root) into `v<tag>/<platform>/`, makes it executable and rejects empty files.
4. Swaps in the new version directory and deletes superseded `v*` folders only after the new one is fully staged — a failed download leaves the previous bundle intact.
5. Smoke-tests the host binary (`versioner --version`); a version that does not contain the tag only warns.

Environment overrides: `VERSIONER_REPO`, `VERSIONER_TAG`. `--dry-run` lists assets and planned removals without touching anything; `--help` shows usage. Prerequisites: `gh`, and `7z`/`7zz` for the real update. `update.sh` sources [scripts/entry.sh](../../scripts/entry.md) and can run from anywhere.

## Related pages

- [../README.md](../README.md) — the bundle index
- [../../scripts/version.md](../../scripts/version.md) — the consumer of the binary
- [../../build.md](../../build.md) · [../../release.md](../../release.md)
