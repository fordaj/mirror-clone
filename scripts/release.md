# The release flow (`scripts/release.sh` + `release.go`)

This page documents the two files behind the release side of the project: the `scripts/release.sh` script that builds, packages, tags and publishes a release, and the `release.go` client the tool itself uses to find that release.

## `scripts/release.sh` — the release pipeline

Computes the version and tag with the pinned [versioner](../tools/versioner/update.md) (via [scripts/version.md](version.md) and [scripts/entry.md](entry.md)), cross compiles every platform with [scripts/build.sh](build.md), and packages one archive per platform.

1. Requires a clean working tree (a dirty tree is only tolerated in `--dry-run`), `git`, `gh` authenticated, and a successful `git fetch origin --tags`.
2. The tag must match `vX.Y.Z...` and must not exist locally or on origin.
3. Builds with `scripts/build.sh --all --release` (unless `--skip-build`).
4. Packages `<RELEASE_DIR>/mirror-clone_<VERSION>_<platform>.zip` (`RELEASE_DIR` defaults to `temp/release`), each containing the binary, the `LICENSE` and the `README.md`. Archives are written with `zip` when available, otherwise with the bundled 7zz (`SEVENZZ_BIN`, from [scripts/env.md](env.md)) as `7zz a -tzip`.
5. Writes `checksums.txt` (SHA256, sha256sum format) into the release directory.
6. Creates the annotated tag, pushes it, and runs `gh release create <TAG> --verify-tag --generate-notes` with the archives attached.

`--dry-run` prints the plan and changes nothing; `--package-only` builds and packages without tagging, pushing or uploading; `--skip-build` reuses the binaries already in `dist/`. Prerequisites: `git`, `gh`, `zip` or the bundled 7zz, and a clean tree.

## `release.go` — the GitHub releases client

The client the self update ([update.md](../update.md)) uses. `newReleaseClient` targets `https://api.github.com/repos/fordaj/MirrorClone/releases` (constant `releasesURL`) with a 30-second timeout. `latestRelease` lists all releases and `selectLatestRelease` picks the newest that is neither draft nor pre-release, comparing tags with `compareVersions` ([version.md](../version.md)).

`platformName(goos, goarch)` maps the build platform to the archive platform — `linux`/`macos`/`windows` × `x86_64`/`arm64` (`amd64` → `x86_64`), empty otherwise. `releaseAssetName(version, platform)` builds `mirror-clone_<version>_<platform>.zip`. `selectArchive` prefers the exact archive name for the version and falls back to any `mirror-clone_*_<platform>.zip` so a release that names its assets differently can still be installed. `selectChecksums` finds `checksums.txt` (exact match, or any asset whose name ends with it).

## Related pages

- [update.md](../update.md) — the consumer of the release feed
- [scripts/build.md](build.md) — the cross compiler
- [scripts/version.md](version.md) · [scripts/env.md](env.md)
- [tools/versioner/update.md](../tools/versioner/update.md)
- [README.md](../README.md) — the releasing section
