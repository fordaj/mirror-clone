# The docs generator (`scripts/docs.sh`)

```mermaid
flowchart LR
    Args("<img src='barnacle:keyboard.svg' width='20' alt=''/><br/>docs.sh [--site … · --config …]") --> Entry("<img src='barnacle:file-text.svg' width='20' alt=''/><br/><u>entry.sh.md<br/>cascade + log()</u>")
    Entry -->|"<a href='env.sh.md'>BARNACLE_BIN — cascade</a>"| Bin("<img src='barnacle:square-terminal.svg' width='20' alt=''/><br/>BARNACLE_BIN<br/>pinned bundle → PATH fallback")
    Bin --> Barnacle("<img src='barnacle:book-open.svg' width='20' alt=''/><br/>barnacle<br/>scans .md / .mmd in the tree")
    Barnacle --> Out("<img src='barnacle:folder.svg' width='20' alt=''/><br/>./site — static HTML<br/>git-ignored · wiped and rebuilt")
    click Entry href "entry.sh.md"
    class Entry mdFile
    class Out folder
    classDef mdFile fill:#dcd6ce,stroke:#6b6255,color:#292524
    classDef folder fill:#f0c558,stroke:#8a6d1c,color:#332a05
```

Generates the documentation site you are reading: it runs the pinned `tools/barnacle/update.sh.md` binary against this repository.

Barnacle scans the working tree for Markdown (`.md`) and Mermaid (`.mmd`) files, renders each as a page, and rewrites the relative links between them. Generated output is static HTML; it is written to `./site/` by default and is never committed (`/site/` is in `.gitignore`).

## Usage

```bash
scripts/docs.sh                       # generate into ./site/
scripts/docs.sh --site ./public       # forward --site to barnacle
scripts/docs.sh --config ./docs/barnacle.json
scripts/docs.sh --help                # usage for this script
```

Any arguments other than `--help`/`-h` are forwarded to barnacle verbatim; see `barnacle --help` for `--config`/`--site` semantics. Barnacle exits non-zero and leaves no half-built site on failure; regenerating into a directory previously produced by barnacle wipes and rebuilds it.

## How it locates barnacle

Sources [entry.sh.md](entry.sh.md); `BARNACLE_BIN` comes from the [cascade](env.sh.md) (`tools/barnacle/v<version>/<platform>/barnacle[.exe]`, falling back to `barnacle` on `PATH`). When `BARNACLE_BIN` is unset or not executable, the script fails with instructions to run `tools/barnacle/update.sh` (or set `BARNACLE_BIN` explicitly). It then runs barnacle with the repository root as the working directory, so barnacle's auto-discovered `./.barnacle.json` and its default `./site/` output land at the repository root regardless of the caller's cwd.

`.barnacle.json` sets `"title": "mirror-clone"` and `"exclude": ["tools"]`, so the pinned bundles' pages (`tools/**`) are not part of the site — they document the bundles for the repository, not for the documentation.

## What the site contains

Every `.md`/`.mmd` in the tree except `tools/` — see the [root README](../README.md) and [AGENTS.md](../AGENTS.md). `.git`, `node_modules`, `vendor`, `dist`, and the output directory are always excluded by barnacle; hidden files and directories (the cascade's `.common.env` et al.) are skipped unless `.barnacle.json` sets `includeHidden`.

## Related pages

- `tools/barnacle/update.sh.md` — the pinned binaries and how to refresh them
- [entry.sh.md](entry.sh.md) · [env.sh.md](env.sh.md)
