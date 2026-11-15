# The version script (`scripts/version.bash`)

Prints the version of this repository as computed by the pinned [versioner](../tools/versioner/update.md) — the same computation the release pipeline uses, so a local build and the published tag can never drift apart.

## Usage

```bash
scripts/version.bash                 # VERSION=<v> and TAG=<t> lines (default)
scripts/version.bash --format text   # same
scripts/version.bash --format shell  # export VERSION=... and export TAG=...
scripts/version.bash --format json   # the raw versioner JSON document
```

`--format` requires a value; `--help`/`-h` prints usage. Unknown arguments are a usage error (exit `2`).

## How it works

Sources [entry.md](entry.md) for the cascade and `log()`. If `VERSIONER_BIN` is unset or not executable, it fails with `no versioner binary found (run tools/versioner/update.bash or set VERSIONER_BIN)`. Otherwise it runs `versioner --repo-dir <root> --quiet [--format json]`; the repository root defaults to `VERSIONER_REPO_DIR` or the parent of `scripts/`. The `text` format parses the `VERSION=`/`TAG=` lines out of the versioner output (a missing one is an error); `json` passes the document through untouched. The version is computed from the git history and `.versioner.json` (`defaultBranchVersion`, `exemptBranches`, `tagPattern`).

## Consumers

- `build.bash` — stamps the version into the binaries ([../build.md](../build.md)).
- `release.bash` — computes the tag of the release ([../release.md](../release.md)).

## Related pages

- [entry.md](entry.md) · [env.md](env.md)
- [../build.md](../build.md) · [../release.md](../release.md)
- [../tools/versioner/update.md](../tools/versioner/update.md)
