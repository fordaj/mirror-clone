# The environment cascade (`scripts/env.sh` + the hidden `.*.env` files)

`scripts/env.sh` is the plumbing that makes the pinned helper tools resolvable from any script, in any working directory, on every supported platform. It is sourced — never executed.

## What it does

1. Locates the cascade files relative to itself (`$BASH_SOURCE`), so sourcing works from any cwd.
2. Brings in `.common.env`, then the platform file selected by `uname -s`/`uname -m` — for example `.macos-arm64.env` or `.windows-x86_64.env` (`MINGW*`/`MSYS*`/`CYGWIN*` map to the Windows files). Unsupported platforms print an error and return `1`.
3. **Resolves the newest bundled tool version dynamically** — `resolve_version_dir` looks at `tools/<tool>/v*` for the tool's directory and, when it carries a newer `v<number>` than the pin from `.common.env`, prefers it (`ls -1 | grep -E '^v[0-9]' | sort -V | tail -n 1`). Updating a tool bundle therefore does not require editing every platform env file. It applies to `versioner`, `logamuffin`, `runner-spawner`, `barnacle` and `7zip` (`VERSIONER_VERSION_DIR`, `LOGAMUFFIN_VERSION_DIR`, `RUNNER_SPAWNER_VERSION_DIR`, `BARNACLE_VERSION_DIR`, `SEVENZIP_VERSION_DIR`).
4. **Anchors** every repository-relative `*_BIN` to the repository root (`REPO_ROOT_DIR`), leaving absolute paths untouched — `$VERSIONER_BIN`, `$LOGAMUFFIN_BIN`, `$RUNNER_SPAWNER_BIN`, `$BARNACLE_BIN` and `$SEVENZZ_BIN` end up absolute.
5. **Falls back to `PATH`** when a bundled binary is missing or not executable — `fallback_to_path` maps `VERSIONER_BIN`→`versioner`, `LOGAMUFFIN_BIN`→`logamuffin`, `RUNNER_SPAWNER_BIN`→`runner-spawner`, `BARNACLE_BIN`→`barnacle`. Not every bundle ships every platform, so the fallback keeps the scripts usable (for example the versioner bundle has no windows-arm64 build).

Everything is exported with `set -a` while sourcing and un-exported at the end (`set +a`), so the cascade does not leak beyond the intended variables. `REPO_ROOT_DIR` is set for callers that need the repository root (for example [version.sh](version.md)).

### The SEVENZIP / 7zip handling

`SEVENZZ_BIN` is **not** run through `fallback_to_path`. Instead, when it is unset or not executable, `env.sh` probes `7zz` and then `7z` on `PATH`. The bundled variable points at the vendored 7-Zip under `tools/7zip/v26.06/`: `7zz` for macOS/Linux (`mac-arm64/7zz`, `mac-x64/7zz`, `linux-x64/7zz`, `linux-arm64/7zz`) and `7zr.exe` for Windows (`windows/7zr.exe`, 7z format only). Note the 7zip bundle uses its own platform naming, unlike the `<os>-<arch>` layout of the other bundles. 7zip is bundled for the release pipeline ([../release.md](release.md)) to create the release archives when `zip` is not installed, and by the legacy `.7z` tool updaters.

## The hidden files

Hidden files are excluded from barnacle's default scan, so their contract is documented here:

- **`.common.env`** — `TOOLS_DIR=tools`; the upstream `fordaj/*` repository slugs and patterns (`VERSIONER_REPO=fordaj/Versioner`, `VERSIONER_TAG_PATTERN=v[0-9]*`, `VERSIONER_CONFIG_FILE=.versioner.json`, `LOGAMUFFIN_REPO=fordaj/logamuffin`, `RUNNER_SPAWNER_TOOL_REPO=fordaj/runner-spawner`, `BARNACLE_REPO=fordaj/barnacle`); and the pinned `*_VERSION_DIR`s: **VERSIONER `v0.0.3.0.5`, LOGAMUFFIN `v0.1.3.0.35`, RUNNER_SPAWNER `v0.0.1.2.6` (fallback only), BARNACLE `v0.0.1.0.5`**, plus `SEVENZIP_VERSION_DIR=tools/7zip/v26.06`. "Fallback only" for runner-spawner means no script in this repository invokes it — the pin exists so the cascade resolves it uniformly (it falls back to `runner-spawner` on `PATH` like the other tools), and `resolve_version_dir` prefers whatever newer `v*` directory is checked out anyway; it reports unsupported on Linux (macOS + Windows only, the binary is still shipped for a uniform bundle layout — see the Linux platform files and [../tools/runner-spawner/update.md](../tools/runner-spawner/update.md)). When bumping a pinned tool, this file names the version directory the platform files point into.
- **`.<platform>.env`** — one per supported platform (`linux-arm64`, `linux-x86_64`, `macos-arm64`, `macos-x86_64`, `windows-arm64`, `windows-x86_64`). Sets `PROJECT_PLATFORM` and the `*_BIN` paths. The notes about runner-spawner being unsupported on Linux (macOS + Windows only; the binary is still shipped for a uniform bundle layout) and about the missing windows-arm64 versioner bundle are recorded in the platform files themselves.

## Related pages

- [entry.md](entry.md) — the entry point most scripts source (it loads this file and defines `log()`)
- [docs.md](docs.md) — the docs generator that resolves `BARNACLE_BIN` through this cascade
- [version.md](version.md) — the version script that resolves `VERSIONER_BIN` through this cascade
- [../tools/README.md](../tools/README.md) — the bundles selected by the `*_BIN` variables
