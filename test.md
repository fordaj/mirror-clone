# The check suite (`test.bash`)

`test.bash` runs every check of the project and exits `1` when at least one of them failed. The checks, in order:

1. **gofmt** — `gofmt -l .` must report nothing (excluding `vendor/`).
2. **go vet** — `go vet ./...`.
3. **go build** — `go build -o <tmp>/ ./...`.
4. **go test** — `go test -count=1 ./...`; `-race` when CGO is enabled (skipped by `--quick`); `--coverage` adds `-coverprofile=coverage.out -covermode=atomic`; extra flags via `GO_TEST_FLAGS`.
5. **smoke test** — builds the binary in a temporary directory and runs `--version` and `--help`.
6. **shellcheck** — `shellcheck -x` on `build.bash`, `release.bash`, `test.bash`, `run.bash`, `format.bash` and `scripts/entry.sh`, `scripts/env.sh`, `scripts/version.bash` (skipped when shellcheck is not installed or `SKIP_SHELLCHECK=true`).
7. **formatting** — `./format.bash --check` (skipped when `uv` is not installed or `SKIP_FORMATTING=true`).

Usage: `./test.bash`, `./test.bash --coverage`, `./test.bash --quick`. The script requires the Go toolchain; it sources [scripts/entry.md](scripts/entry.md) for the environment cascade and `log()`.

Tests live next to the sources (`cli_test.go`, `install_test.go`, `mirror_test.go`, `update_test.go`, `url_test.go`) and use the standard `testing` package.

## Related pages

- [build.md](build.md) — the build the smoke test exercises
- [format.md](format.md) — the formatter behind check 7
- [scripts/entry.md](scripts/entry.md) · [scripts/env.md](scripts/env.md)
- [README.md](README.md) — the testing section
