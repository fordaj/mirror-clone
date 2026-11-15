# AGENTS.md

## Project Overview

mirror-clone is a cross-platform command-line tool that clones GitHub repositories (and their submodules) through a local cache of mirrors, so repeated clones only transfer the objects that are actually new. It is written in Go (module `github.com/fordaj/MirrorClone`, Go 1.23, no third-party dependencies — the standard library only) and ships as a single, dependency-free binary for Linux, macOS and Windows (x86_64 and arm64).

The binary clones through `~/.mirror-clones` by default, refreshes the mirror on every use (`git fetch --prune`), resolves relative submodule URLs against the superproject, and can install, update and uninstall itself. The release archives are built with `scripts/build.sh`/`scripts/release.sh` and published to the GitHub releases of `fordaj/MirrorClone`.

## Core Principles

- **Clone through the mirror cache.** Every clone and every submodule clone goes through the mirror; the working copy borrows the mirror's objects (`--reference … --dissociate`) and stays valid when the cache is removed.
- **Never lose work.** A failed update, a failed copy or a diverged branch must not destroy the user's installation or the local clone: backups and `replaceFile` restore the previous state, and fast-forwards are `--ff-only` with a warning, not a reset.
- **Unattended operation.** The tool must work from scripts and CI: no interactive credential prompts (`GIT_TERMINAL_PROMPT=0`), no `PATH` edits, no config changes — it prints the line the user has to add and stops there.
- **Source, don't reimplement.** Shell logic flows through `scripts/entry.sh` (environment cascade + `log()`); versions come from versioner; binaries are stamped with `-ldflags`, never with a hand-edited constant.
- **Documentation lives next to the code.** Every documented file has a sibling `.md` page; see "Documentation files (barnacle)" below.

## Build and Test

The README is the source of truth for the commands; the real ones are:

```bash
./scripts/build.sh                # release build of the host platform (dist/<platform>/)
./scripts/build.sh --all          # every platform
./scripts/test.sh                 # gofmt, go vet, go build, go test, smoke test, shellcheck, formatting
./scripts/test.sh --coverage      # also writes coverage.out
./scripts/format.sh               # format the sources (formattington via uv)
./scripts/format.sh --check       # verify only
./scripts/version.sh      # print the version computed by versioner
./scripts/docs.sh           # regenerate the documentation site (./site/)
```

Requirements: the Go toolchain (1.23+), `git`, `uv` for the formatters (`uv sync` installs the locked versions), `gh` for releases and tool refreshes. Tests live next to the code (`*_test.go`, standard `testing` package) and use no network access. Do not invent commands for tools that are not configured.

Before considering a change complete, run `./scripts/test.sh`. If you touch any documented file, also run `./scripts/docs.sh` and keep the sibling pages current (see below).

## Repository Layout

```text
<root>/                the Go module (package main) — one .go per concern:
                       cli.go, mirror.go, git.go, url.go, version.go, logger.go,
                       install.go, update.go, release.go, main.go, plus the
                       per-platform executable_unix.go / executable_windows.go
scripts/           task scripts — format.sh, build.sh, release.sh, run.sh, test.sh,
                       docs.sh, version.sh — plus entry.sh, env.sh (the cascade)
                       and the hidden .common.env + .<platform>.env. See scripts/README.md
tools/                 pinned helper bundles (versioner, logamuffin, runner-spawner,
                       barnacle, 7zip) — see tools/README.md
.formattington.json    formatter configuration
.versioner.json        versioner configuration
pyproject.toml/uv.lock formattington environment (uv)
```

The Go sources are at the root on purpose; `dist/` holds build output and is git-ignored. `site/` is the generated documentation and is git-ignored as well.

## Documentation files (barnacle)

The repository's documentation is a set of Markdown (`.md`) and Mermaid (`.mmd`) source files rendered into a static site by the pinned [barnacle](https://github.com/fordaj/barnacle) binary (`tools/barnacle/`, wired into the environment cascade as `BARNACLE_BIN`). Generate the site with `scripts/docs.sh`; the output (`./site/`) is git-ignored and never committed.

Layout — documentation lives next to the code it describes:

- One sibling `.md` per root Go file (`cli.go` → [cli.go.md](cli.go.md)), plus `main.go.md` for the entry point. Two deliberate exceptions: one `executable.md` page covers both `executable_unix.go` and `executable_windows.go` (the build-tag pair shares one contract), and one `scripts/release.sh.md` page covers both `release.go` and `scripts/release.sh` (the stem is taken by both).
- One sibling `.md` per task script that used to live at the root (`scripts/build.sh` → [scripts/build.sh.md](scripts/build.sh.md), `scripts/format.sh` → [scripts/format.sh.md](scripts/format.sh.md), `scripts/release.sh` → [scripts/release.sh.md](scripts/release.sh.md), `scripts/run.sh` → [scripts/run.sh.md](scripts/run.sh.md), `scripts/test.sh` → [scripts/test.sh.md](scripts/test.sh.md)).
- One sibling `.md` per script in `scripts/` (`entry.sh` → [entry.md](scripts/entry.sh.md), `env.sh` → [env.md](scripts/env.sh.md), `version.sh` → [version.go.md](scripts/version.sh.md), `docs.sh` → [docs.md](scripts/docs.sh.md)), plus `scripts/README.md` as the hub.
- One sibling `.md` per bundle in `tools/` (`tools/<name>/update.md`), plus `tools/README.md` as the hub. The 7zip bundle is documented by `tools/7zip/update.sh.md` like the others.
- `README.md` stays the project front page; do not restructure it.

Rules for keeping these files current:

- When you add, rename, remove, or repurpose a documented file — a Go file, a script, or a bundle — update its sibling `.md` **in the same change**. A new file without its page is incomplete work; a stale page is worse than none.
- Source every fact: the `.go`/`.sh`/`.bash` file itself, this file (AGENTS.md), and README.md are the accepted sources. Never invent flags, exit codes, extensions, or bundle-platform matrices.
- Use plain relative links (`cli.go.md`, `../../README.md`) with the linking file's `.md` path — barnacle rewrites them to `.html`. Do not link to files barnacle does not render (binaries, `.sh`, `LICENSE`); link the related `.md` page (for external references, a full `https://` URL is fine).
- A `foo.md` and a `foo.mmd` may not coexist for the same stem — barnacle fails the whole site rather than overwriting.
- Hub pages (`README.md` in each documented directory) list their siblings; adding a page means linking it from the hub too.
- Barnacle skips hidden files by default, so the `.common.env` and `.<platform>.env` cascade is documented inside [scripts/env.sh.md](scripts/env.sh.md) — keep it accurate there instead of adding hidden doc files.
- Regenerate and self-review the site before publishing: `./scripts/docs.sh`; the generator output must remain free of broken local links.

Definition of Done addition: a change that touches any documented file updates (or creates) its sibling page in the same commit.

## Definition of Done

A change is complete when it:

- Implements the requested behavior.
- Preserves the established CLI contract (commands, flags, exit codes) unless intentionally changed — `cli.go` and the README option table move together.
- Handles errors without losing the user's work (see the "Never lose work" principle).
- Remains compatible with the supported platforms (Linux, macOS, Windows × x86_64, arm64) — platform differences go in the `executable_*.go` pair or the environment cascade, not in ad-hoc conditionals.
- Includes or updates tests where appropriate (`go test ./...` via `./scripts/test.sh`).
- Updates relevant documentation — including the sibling `.md` pages above for every Go, bash, or tools/ file touched, and the hub listing when a page is added or removed.
