# Entry point (`main.go`)

```mermaid
flowchart TD
    Start("<img src='barnacle:play.svg' width='20' alt=''/><br/>run(args)") --> Parse("<img src='barnacle:file-code.svg' width='20' alt=''/><br/><u>parseArgs</u>")
    Parse -->|"error"| E2("<img src='barnacle:circle-exclamation-point.svg' width='20' alt=''/><br/>usage error + hint<br/>exit 2")
    Parse -->|"--help"| H("<img src='barnacle:info.svg' width='20' alt=''/><br/>usageText<br/>exit 0")
    Parse -->|"--version"| V("<img src='barnacle:info.svg' width='20' alt=''/><br/>versionString<br/>exit 0")
    Parse --> Build("<img src='barnacle:cog.svg' width='20' alt=''/><br/>logger + signal-aware context")
    Build --> Dispatch{{"<img src='barnacle:hexagon.svg' width='20' alt=''/><br/>command"}}
    Dispatch -->|"<a href='install.go.md'>install / uninstall</a>"| Inst("<img src='barnacle:download.svg' width='20' alt=''/><br/>install / uninstall")
    Dispatch -->|"<a href='update.go.md'>update</a>"| Upd("<img src='barnacle:refresh-cw.svg' width='20' alt=''/><br/>update")
    Dispatch -->|"<a href='mirror.go.md'>(default) clone</a>"| Clone("<img src='barnacle:file-code.svg' width='20' alt=''/><br/>MirrorCloner")
    Clone --> Exit("<img src='barnacle:flag.svg' width='20' alt=''/><br/>exit 0 · 1 · 130")
    click Parse href "cli.go.md"
    class E2 errNode
    class Dispatch hexNode
    classDef errNode fill:#f6b8b8,stroke:#b91c1c,color:#450a0a
    classDef hexNode fill:#ffe08a,stroke:#a16207,color:#422006
```

`main.go` is the program entry point. It keeps `main()` trivial and puts the whole program logic in `run(args []string) int`, which returns the process exit code; `main` only does `os.Exit(run(os.Args[1:]))`.

## What `run` does

1. Parses the arguments with `parseArgs` ([cli.go.md](cli.go.md)). A parse error prints `mirror-clone: <err>` plus a hint to `--help` and returns exit code `2`.
2. `--help` prints `usageText` (with the default cache dir) and returns `0`; `--version` prints `mirror-clone <version>` and returns `0`.
3. Builds the logger ([logger.go.md](logger.go.md)) and a signal-aware context (`os.Interrupt`, `SIGTERM`).
4. Dispatches the self management commands `install`, `uninstall`, `update` ([install.go.md](install.go.md), [update.go.md](update.go.md)).
5. Otherwise clones: the cache dir comes from `--mirror-cache-dir`, then `MIRROR_CLONE_MIRROR_CACHE_DIR`, then `~/.mirror-clones` (see `defaultCacheDir`); the repository name is derived with `repoNameFromURL` ([url.go.md](url.go.md)); the destination defaults to the repository name inside the current directory.

The clone itself is done by `MirrorCloner` ([mirror.go.md](mirror.go.md)) built on `Git` ([git.go.md](git.go.md)). `--jobs` defaults to `runtime.NumCPU()`, capped at `maxDefaultJobs` (`8`).

## Exit codes

`2` for argument errors, `1` for runtime failures (the reason is logged), `exitInterrupted` (`130`, i.e. `128+2`) when the context was cancelled (Ctrl-C / SIGTERM, logged as `interrupted`), `0` on success and for `--help`/`--version`.

## Related pages

- [cli.go.md](cli.go.md) — argument parsing and the usage text
- [mirror.go.md](mirror.go.md) — the clone through the mirror cache
- [logger.go.md](logger.go.md) · [url.go.md](url.go.md) · [version.go.md](version.go.md)
- [install.go.md](install.go.md) · [update.go.md](update.go.md) · [scripts/release.sh.md](scripts/release.sh.md)
