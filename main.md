# Entry point (`main.go`)

`main.go` is the program entry point. It keeps `main()` trivial and puts the whole program logic in `run(args []string) int`, which returns the process exit code; `main` only does `os.Exit(run(os.Args[1:]))`.

## What `run` does

1. Parses the arguments with `parseArgs` ([cli.md](cli.md)). A parse error prints `mirror-clone: <err>` plus a hint to `--help` and returns exit code `2`.
2. `--help` prints `usageText` (with the default cache dir) and returns `0`; `--version` prints `mirror-clone <version>` and returns `0`.
3. Builds the logger ([logger.md](logger.md)) and a signal-aware context (`os.Interrupt`, `SIGTERM`).
4. Dispatches the self management commands `install`, `uninstall`, `update` ([install.md](install.md), [update.md](update.md)).
5. Otherwise clones: the cache dir comes from `--mirror-cache-dir`, then `MIRROR_CLONE_MIRROR_CACHE_DIR`, then `~/.mirror-clones` (see `defaultCacheDir`); the repository name is derived with `repoNameFromURL` ([url.md](url.md)); the destination defaults to the repository name inside the current directory.

The clone itself is done by `MirrorCloner` ([mirror.md](mirror.md)) built on `Git` ([git.md](git.md)). `--jobs` defaults to `runtime.NumCPU()`, capped at `8`.

## Exit codes

`2` for argument errors, `1` for runtime failures (the reason is logged), `130` when the context was cancelled (Ctrl-C / SIGTERM, logged as `interrupted`), `0` on success and for `--help`/`--version`.

## Related pages

- [cli.md](cli.md) — argument parsing and the usage text
- [mirror.md](mirror.md) — the clone through the mirror cache
- [logger.md](logger.md) · [url.md](url.md) · [version.md](version.md)
- [install.md](install.md) · [update.md](update.md) · [scripts/release.md](scripts/release.md)
