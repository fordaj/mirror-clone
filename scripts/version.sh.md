# The version script (`scripts/version.sh`)

```mermaid
flowchart LR
    Args("<img src='barnacle:keyboard.svg' width='20' alt=''/><br/>version.sh [--format text|shell|json|version|tag]") --> Bin("<img src='barnacle:square-terminal.svg' width='20' alt=''/><br/><u>VERSIONER_BIN<br/>cascade-resolved · fallback on PATH</u>")
    Bin --> Run("<img src='barnacle:git-commit-horizontal.svg' width='20' alt=''/><br/>versioner --repo-dir ROOT --quiet<br/>version from git history + .versioner.json")
    Run --> Out{{"<img src='barnacle:hexagon.svg' width='20' alt=''/><br/>--format"}}
    Out -->|"text"| T("<img src='barnacle:file-text.svg' width='20' alt=''/><br/>VERSION= / TAG= lines<br/>(default)")
    Out -->|"shell"| Sh("<img src='barnacle:terminal.svg' width='20' alt=''/><br/>export VERSION=… TAG=…<br/>for eval")
    Out -->|"json"| J("<img src='barnacle:braces.svg' width='20' alt=''/><br/>raw versioner JSON")
    Out -->|"version / tag"| V("<img src='barnacle:hash.svg' width='20' alt=''/><br/>only the value<br/>(build.sh · release.sh)")
    T --> Consumers("<img src='barnacle:terminal.svg' width='20' alt=''/><br/><u>build.sh · release.sh</u>")
    click Bin href "env.sh.md"
    click Consumers href "release.sh.md"
    class Out hexNode
    class Sh shFile
    class J jsonFile
    class Consumers shFile
    classDef hexNode fill:#ffe08a,stroke:#a16207,color:#422006
    classDef shFile fill:#abe07a,stroke:#3f6212,color:#16280a
    classDef jsonFile fill:#cdb9f7,stroke:#6d28d9,color:#2e1065
```

Prints the version of this repository as computed by the pinned `tools/versioner/update.sh.md` — the same computation the release pipeline uses, so a local build and the published tag can never drift apart.

## Usage

```bash
scripts/version.sh                 # VERSION=<v> and TAG=<t> lines (default)
scripts/version.sh --format text   # same
scripts/version.sh --format shell  # export VERSION=... and export TAG=...
scripts/version.sh --format json   # the raw versioner JSON document
scripts/version.sh --format version  # only the version
scripts/version.sh --format tag      # only the tag
```

`--format` requires a value; `--help`/`-h` prints usage. Unknown arguments are a usage error (exit `2`).

## How it works

Sources [entry.sh.md](entry.sh.md) for the cascade and `log()`. If `VERSIONER_BIN` is unset or not executable, it fails with `no versioner binary found (run tools/versioner/update.sh or set VERSIONER_BIN)`. Otherwise it runs `versioner --repo-dir <root> --quiet [--format json]`; the repository root defaults to `VERSIONER_REPO_DIR` or the parent of `scripts/`. The `text` format parses the `VERSION=`/`TAG=` lines out of the versioner output (a missing one is an error); `json` passes the document through untouched; `version` and `tag` print only the value and are what `scripts/build.sh` and `scripts/release.sh` consume. The version is computed from the git history and `.versioner.json` (`defaultBranchVersion`, `exemptBranches`, `tagPattern`).

## Consumers

- `scripts/build.sh` — stamps the version into the binaries ([build.sh.md](build.sh.md)).
- `scripts/release.sh` — computes the tag of the release ([release.sh.md](release.sh.md)).

## Related pages

- [entry.sh.md](entry.sh.md) · [env.sh.md](env.sh.md)
- [build.sh.md](build.sh.md) · [release.sh.md](release.sh.md)
- `tools/versioner/update.sh.md`
