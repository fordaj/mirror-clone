# Logging (`logger.go`)

```mermaid
flowchart LR
    Argv("<img src='barnacle:keyboard.svg' width='20' alt=''/><br/><u>--log-level · -q/--quiet</u>") --> Parse("<img src='barnacle:file-code.svg' width='20' alt=''/><br/>ParseLevel<br/>error · warn · info · debug<br/>unknown → LevelInfo")
    Parse --> Min("<img src='barnacle:sliders-horizontal.svg' width='20' alt=''/><br/>min level")
    Min --> Logger("<img src='barnacle:file-code.svg' width='20' alt=''/><br/>Logger — NewLogger(out, err, min)")
    Logger --> Out("<img src='barnacle:terminal.svg' width='20' alt=''/><br/>Infof / Debugf → stdout<br/>(prefixed)")
    Logger --> Err("<img src='barnacle:triangle-exclamation-point.svg' width='20' alt=''/><br/>Warnf / Errorf → stderr<br/>(prefixed)")
    Logger --> Drop("<img src='barnacle:trash.svg' width='20' alt=''/><br/>below min → discarded")
    click Argv href "cli.go.md"
```

`logger.go` defines the severity levels and the small `Logger` the whole tool uses. It is the Go-side counterpart of the shell `log()` in [scripts/entry.sh.md](scripts/entry.sh.md).

## Levels

`Level` is an `int`: `LevelError` (0), `LevelWarn` (1), `LevelInfo` (2), `LevelDebug` (3). `ParseLevel` maps `error`, `warn`/`warning`, `info`, `debug`/`trace` (case-insensitive, trimmed) and falls back to `LevelInfo` for unknown names, so a typo never silences the tool.

## The logger

`NewLogger(out, err, min)` writes informational output to `out` and warnings/errors to `err`, so stdout stays usable for piping. `DefaultLogger(min)` uses the process streams. Messages below `min` are discarded (`if l == nil || level > l.min { return }`).

- `Infof` — stdout, prefixed `mirror-clone:`
- `Debugf` — stdout, prefixed `debug:`
- `Warnf` — stderr, prefixed `warning:`
- `Errorf` — stderr, prefixed `error:`

`--log-level`, `-q`/`--quiet` and `--verbose`-style flags feed `DefaultLogger` via [cli.go.md](cli.go.md) and [main.go.md](main.go.md).

## Related pages

- [cli.go.md](cli.go.md) — where `--log-level` is parsed
- [main.go.md](main.go.md) — where the logger is constructed
- [scripts/entry.sh.md](scripts/entry.sh.md) — the shell-side `log()`
