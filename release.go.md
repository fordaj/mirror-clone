# The GitHub releases client (`release.go`)

```mermaid
flowchart LR
    Upd("<img src='barnacle:refresh-cw.svg' width='20' alt=''/><br/><u>self update</u>") --> Client("<img src='barnacle:globe.svg' width='20' alt=''/><br/>releaseClient<br/>30 s timeout")
    Client --> API("<img src='barnacle:globe.svg' width='20' alt=''/><br/>GET api.github.com/repos/fordaj/MirrorClone/releases")
    API --> Latest("<img src='barnacle:tag.svg' width='20' alt=''/><br/><u>latestRelease<br/>selectLatestRelease: skip drafts and prereleases</u>")
    Latest --> Plat("<img src='barnacle:monitor.svg' width='20' alt=''/><br/>platformName<br/>linux · macos · windows × x86_64 · arm64")
    Plat --> Sel("<img src='barnacle:package-check.svg' width='20' alt=''/><br/>selectArchive + selectChecksums<br/>exact name, else platform fallback")
    Sel --> DL("<img src='barnacle:download.svg' width='20' alt=''/><br/><u>download for the configured platform</u>")
    click Upd href "update.go.md"
    click Latest href "version.go.md"
    click DL href "update.go.md"
    class Latest tagNode
    class Sel boxNode
    class DL dlNode
    classDef tagNode fill:#f6b8d4,stroke:#be185d,color:#500724
    classDef boxNode fill:#e8cf9d,stroke:#a16207,color:#33240a
    classDef dlNode fill:#93e2e2,stroke:#0f766e,color:#042f2e
```

`release.go` is the small client the self update uses to find the latest stable release of [fordaj/MirrorClone](https://github.com/fordaj/MirrorClone) on the GitHub API and to pick the archive to install. `scripts/release.sh` publishes the releases this client reads; see [scripts/release.sh.md](scripts/release.sh.md).

## The client

`newReleaseClient` targets `https://api.github.com/repos/fordaj/MirrorClone/releases` (constant `releasesURL`) with a `releaseTimeout` (30-second) timeout. `latestRelease` lists all releases and `selectLatestRelease` picks the newest that is neither draft nor pre-release, comparing tags with `compareVersions` ([version.go.md](version.go.md)). Both the release feed and the asset downloads in [update.go.md](update.go.md) go through the shared `httpGet` helper: it builds the `GET` request with the `User-Agent` header (and an optional `Accept`), logs the request at debug level, returns the open response, and turns a non-200 status into an error (`unexpected status <status>`; the body is closed first).

## Archive selection

`platformName(goos, goarch)` maps the build platform to the archive platform — `linux`/`macos`/`windows` × `x86_64`/`arm64` (`amd64` → `x86_64`), empty otherwise. `releaseAssetName(version, platform)` builds `mirror-clone_<version>_<platform>.zip`. `selectArchive` prefers the exact archive name for the version and falls back to any `mirror-clone_*_<platform>.zip` so a release that names its assets differently can still be installed. `selectChecksums` finds `checksums.txt` (exact match, or any asset whose name ends with it). Both are thin wrappers over the shared `selectAsset` helper, which implements the two-pass lookup (exact name, then a caller-supplied predicate).

## Related pages

- [update.go.md](update.go.md) — the consumer of the release feed
- [version.go.md](version.go.md) — `compareVersions` and `releaseVersion`
- [scripts/release.sh.md](scripts/release.sh.md) — the pipeline that publishes the release
- [README.md](README.md) — the releasing section
