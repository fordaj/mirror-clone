# Self update (`update.go`)

```mermaid
flowchart TD
    Run("<img src='barnacle:file-code.svg' width='20' alt=''/><br/>runUpdate") --> Chk{{"<img src='barnacle:hexagon.svg' width='20' alt=''/><br/>installed?"}}
    Chk -->|"<a href='install.go.md'>no — not installed</a>"| NotInst("<img src='barnacle:info.svg' width='20' alt=''/><br/>tell the user to run<br/>mirror-clone install")
    Chk -->|"yes"| Latest("<img src='barnacle:tag.svg' width='20' alt=''/><br/><u>latestRelease<br/>newest non-draft, non-prerelease</u>")
    Latest --> Cmp{{"<img src='barnacle:hexagon.svg' width='20' alt=''/><br/><u>compareVersions(available, installed)</u>"}}
    Cmp -->|"0"| UTD("<img src='barnacle:check.svg' width='20' alt=''/><br/>up to date · return")
    Cmp -->|"installed newer"| Warn("<img src='barnacle:triangle-exclamation-point.svg' width='20' alt=''/><br/>warn — never downgrade · return")
    Cmp -->|"available newer"| Pick("<img src='barnacle:package-check.svg' width='20' alt=''/><br/>platformName · selectArchive<br/>selectChecksums")
    Pick --> DL("<img src='barnacle:download.svg' width='20' alt=''/><br/>download archive + checksums.txt<br/>into a temp dir inside the install dir")
    DL --> Verify("<img src='barnacle:check.svg' width='20' alt=''/><br/>verifyChecksum — SHA256, sha256sum format")
    Verify --> Ext("<img src='barnacle:package.svg' width='20' alt=''/><br/>extractExecutable → mode 0755")
    Ext --> Repl("<img src='barnacle:file-diff.svg' width='20' alt=''/><br/><u>replaceFile — atomic, from install.go</u>")
    Repl --> Done("<img src='barnacle:check.svg' width='20' alt=''/><br/>updated")
    click Latest href "release.go.md"
    click Cmp href "version.go.md"
    click Repl href "install.go.md"
    class Chk,Cmp hexNode
    class Latest tagNode
    class UTD,Verify,Done checkNode
    class Pick,Ext boxNode
    class DL dlNode
    classDef hexNode fill:#ffe08a,stroke:#a16207,color:#422006
    classDef tagNode fill:#f6b8d4,stroke:#be185d,color:#500724
    classDef checkNode fill:#9fe8c9,stroke:#0f766e,color:#052e22
    classDef boxNode fill:#e8cf9d,stroke:#a16207,color:#33240a
    classDef dlNode fill:#93e2e2,stroke:#0f766e,color:#042f2e
```

`update.go` implements `mirror-clone update`: replace the installed executable with the latest stable release of [fordaj/MirrorClone](https://github.com/fordaj/MirrorClone).

## The `updater`

`newUpdater(log, dir, name)` wires the release client (from [scripts/release.sh.md](scripts/release.sh.md)), an HTTP client with a `downloadTimeout` (30-minute) timeout for asset downloads, the install directory, and the version of the running executable (`version`, the build-time variable in [version.go.md](version.go.md)).

## `Run`

1. `releases.latestRelease(ctx)` — the newest published, non-draft, non-prerelease release.
2. `compareVersions(available, installed)`: equal → log "up to date" and return; the installed version is newer → warn and return (never downgraded).
3. `platformName(GOOS, GOARCH)` picks the archive platform (`linux`/`macos`/`windows` × `x86_64`/`arm64`); no match → error.
4. `selectArchive` picks `mirror-clone_<version>_<platform>.zip` (exact name preferred, otherwise any `mirror-clone_*_<platform>.zip`); `selectChecksums` picks `checksums.txt` (exact or suffix match).
5. The download happens in a temporary directory **inside the install directory**, so the new executable is moved into place instead of copied across devices. Both the archive and `checksums.txt` are downloaded, then `verifyChecksum` checks the SHA256 (sha256sum format, optional leading `*` on the file name) before anything is replaced.
6. `extractExecutable` finds the entry whose base name is the executable inside the zip, writes it with mode `0755`, and `replaceFile` ([install.go.md](install.go.md)) moves it over the target atomically.

If the download, verification, extraction or replacement fails, the error is returned and the installed executable is kept — a failed update never breaks the installation. `runUpdate` first checks that the tool is actually installed (otherwise it tells the user to run `mirror-clone install` first) and resolves the install directory the same way [install.go.md](install.go.md) does.

## Helpers

`download` (streaming through the shared `httpGet` helper from [release.go.md](release.go.md), with a status check), `verifyChecksum` / `parseChecksums` / `sha256File` (sha256sum format), `extractExecutable` / `writeArchiveEntry` (zip).

## Related pages

- [scripts/release.sh.md](scripts/release.sh.md) — the release client and archive selection
- [install.go.md](install.go.md) — `replaceFile`, install paths
- [version.go.md](version.go.md) — `compareVersions` and the build-time version
- [main.go.md](main.go.md) — command dispatch
