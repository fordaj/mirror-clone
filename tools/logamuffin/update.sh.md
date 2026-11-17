# The logamuffin bundle (`tools/logamuffin/`)

```mermaid
flowchart TD
    Args("<img src='barnacle:keyboard.svg' width='20' alt=''/><br/>update.sh [--dry-run · --tag TAG]") --> Tag("<img src='barnacle:tag.svg' width='20' alt=''/><br/>resolve tag<br/>latest release or --tag · validated")
    Tag --> DL("<img src='barnacle:download.svg' width='20' alt=''/><br/>gh release download<br/>ASSET_&lt;os&gt;-&lt;arch&gt;.7z + checksums.txt")
    Args --> Need("<img src='barnacle:package.svg' width='20' alt=''/><br/><u>needs 7z/7zz — the vendored<br/>tools/7zip bundle works</u>")
    DL --> Sum("<img src='barnacle:check.svg' width='20' alt=''/><br/>verify checksums.txt<br/>mismatch → fatal · absent → warn")
    Sum --> Map("<img src='barnacle:funnel.svg' width='20' alt=''/><br/>stem → platform<br/>macos/linux/windows × x86_64/arm64")
    Map --> Ext("<img src='barnacle:package.svg' width='20' alt=''/><br/>7z extract → vTAG/PLATFORM")
    Ext --> Swap("<img src='barnacle:folder.svg' width='20' alt=''/><br/>swap: mv staging → vTAG<br/>then delete superseded v* folders")
    Swap --> Smoke("<img src='barnacle:check.svg' width='20' alt=''/><br/>smoke: logamuffin --version")
    click Need href "../7zip/update.sh.md"
    class Tag tagNode
    class DL dlNode
    class Need,Ext boxNode
    class Sum,Smoke checkNode
    class Swap folder
    classDef tagNode fill:#f6b8d4,stroke:#be185d,color:#500724
    classDef dlNode fill:#93e2e2,stroke:#0f766e,color:#042f2e
    classDef boxNode fill:#e8cf9d,stroke:#a16207,color:#33240a
    classDef checkNode fill:#9fe8c9,stroke:#0f766e,color:#052e22
    classDef folder fill:#f0c558,stroke:#8a6d1c,color:#332a05
```

[logamuffin](https://github.com/fordaj/logamuffin) is the structured logging backend used by the repository's scripts: [scripts/entry.sh](../../scripts/entry.sh.md) forwards `log LEVEL MESSAGE...` to `LOGAMUFFIN_BIN`, passing the call site in `LOG_SOURCE`.

## Layout

```text
tools/logamuffin/
  update.sh                     # refresh from fordaj/logamuffin releases
  v0.1.3.0.35/
    macos-arm64/logamuffin
    macos-x86_64/logamuffin
    linux-arm64/logamuffin
    linux-x86_64/logamuffin
    windows-arm64/logamuffin.exe
    windows-x86_64/logamuffin.exe
```

## `update.sh` in detail

The `.7z` bundle family: assets are `*_<os>-<arch>.7z` archives plus `checksums.txt`, so a `7z`/`7zz` binary is required for a real update (the vendored one under `tools/7zip/` works). The script:

1. Resolves the tag (latest release, or `--tag vX.Y.Z...`), validating the tag shape.
2. Downloads via `gh`, then verifies the archives against `checksums.txt` (`shasum -a 256 -c` or `sha256sum -c`). A mismatch is fatal; a missing `checksums.txt` only warns.
3. Maps each asset stem to a platform exactly as the versioner bundle does, extracts with `$SEVENZIP`, copies the binary (`logamuffin`/`logamuffin.exe` at the archive root) into `v<tag>/<platform>/`, makes it executable and rejects empty files.
4. Swaps in the new version directory and deletes superseded `v*` folders only after the new one is fully staged — a failed download leaves the previous bundle intact.
5. Smoke-tests the host binary (`logamuffin --version`); a version that contains neither the tag nor `${TAG#v}` only warns.

Environment overrides: `LOGAMUFFIN_REPO`, `LOGAMUFFIN_TAG`. `--dry-run` lists assets and planned removals without touching anything; `--help` shows usage. Prerequisites: `gh`, and `7z`/`7zz` for the real update. `update.sh` sources [scripts/entry.sh](../../scripts/entry.sh.md) and can run from anywhere.

## Related pages

- [../README.md](../README.md) — the bundle index
- [../../scripts/entry.sh.md](../../scripts/entry.sh.md) — the `log()` function that calls the binary
- [../../scripts/env.sh.md](../../scripts/env.sh.md) — how `LOGAMUFFIN_BIN` is resolved
