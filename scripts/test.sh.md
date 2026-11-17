# The check suite (`scripts/test.sh`)

```mermaid
flowchart LR
    Start("<img src='barnacle:terminal.svg' width='20' alt=''/><br/>test.sh<br/>exit 1 if any check fails") --> G("<img src='barnacle:check.svg' width='20' alt=''/><br/>1 · gofmt -l .")
    G --> V("<img src='barnacle:check.svg' width='20' alt=''/><br/>2 · go vet ./...")
    V --> B("<img src='barnacle:hammer.svg' width='20' alt=''/><br/><u>3 · go build ./...</u>")
    B --> T("<img src='barnacle:flask-conical.svg' width='20' alt=''/><br/>4 · go test -count=1 ./...<br/>(-race with CGO · --quick skips)")
    T --> S("<img src='barnacle:check.svg' width='20' alt=''/><br/>5 · smoke: --version --help")
    S --> SC("<img src='barnacle:check.svg' width='20' alt=''/><br/>6 · shellcheck (skip if absent)")
    SC --> F("<img src='barnacle:check.svg' width='20' alt=''/><br/><u>7 · format.sh --check (skip if no uv)</u>")
    F --> R{{"<img src='barnacle:hexagon.svg' width='20' alt=''/><br/>all green?"}}
    R -->|"yes"| Ok("<img src='barnacle:check.svg' width='20' alt=''/><br/>exit 0")
    R -->|"no"| Bad("<img src='barnacle:circle-exclamation-point.svg' width='20' alt=''/><br/>exit 1")
    click F href "format.sh.md"
    click B href "build.sh.md"
    class Start shFile
    class G,V,T,S,SC,F,Ok checkNode
    class R hexNode
    class Bad errNode
    classDef shFile fill:#abe07a,stroke:#3f6212,color:#16280a
    classDef checkNode fill:#9fe8c9,stroke:#0f766e,color:#052e22
    classDef hexNode fill:#ffe08a,stroke:#a16207,color:#422006
    classDef errNode fill:#f6b8b8,stroke:#b91c1c,color:#450a0a
```

`scripts/test.sh` runs every check of the project and exits `1` when at least one of them failed. The checks, in order:

1. **gofmt** — `gofmt -l .` must report nothing (excluding `vendor/`).
2. **go vet** — `go vet ./...`.
3. **go build** — `go build -o <tmp>/ ./...`.
4. **go test** — `go test -count=1 ./...`; `-race` when CGO is enabled (skipped by `--quick`); `--coverage` adds `-coverprofile=coverage.out -covermode=atomic`; extra flags via `GO_TEST_FLAGS`.
5. **smoke test** — builds the binary in a temporary directory and runs `--version` and `--help`.
6. **shellcheck** — `shellcheck -x` on `scripts/build.sh`, `scripts/release.sh`, `scripts/test.sh`, `scripts/run.sh`, `scripts/format.sh` and `scripts/entry.sh`, `scripts/env.sh`, `scripts/version.sh` (skipped when shellcheck is not installed or `SKIP_SHELLCHECK=true`).
7. **formatting** — `./scripts/format.sh --check` (skipped when `uv` is not installed or `SKIP_FORMATTING=true`).

Usage: `./scripts/test.sh`, `./scripts/test.sh --coverage`, `./scripts/test.sh --quick`. The script requires the Go toolchain; it sources [scripts/entry.sh.md](entry.sh.md) for the environment cascade and `log()`.

Tests live next to the sources (`cli_test.go`, `install_test.go`, `mirror_test.go`, `update_test.go`, `url_test.go`) and use the standard `testing` package.

## Related pages

- [scripts/build.sh.md](build.sh.md) — the build the smoke test exercises
- [scripts/format.sh.md](format.sh.md) — the formatter behind check 7
- [scripts/entry.sh.md](entry.sh.md) · [scripts/env.sh.md](env.sh.md)
- [README.md](../README.md) — the testing section
