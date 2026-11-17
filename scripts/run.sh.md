# Running the built binary (`scripts/run.sh`)

```mermaid
flowchart TD
    Args("<img src='barnacle:keyboard.svg' width='20' alt=''/><br/>run.sh ARGS…<br/>args pass straight through") --> Env("<img src='barnacle:square-terminal.svg' width='20' alt=''/><br/><u>PROJECT_PLATFORM<br/>from the environment cascade</u>")
    Env --> L1{{"<img src='barnacle:hexagon.svg' width='20' alt=''/><br/>MIRROR_CLONE_BIN set?"}}
    L1 -->|"yes"| Use("<img src='barnacle:check.svg' width='20' alt=''/><br/>use it (must be executable)")
    L1 -->|"no"| L2{{"<img src='barnacle:hexagon.svg' width='20' alt=''/><br/>binary in dist/?<br/>(dist/debug/… when DEBUG=true)"}}
    L2 -->|"yes"| Exec("<img src='barnacle:play.svg' width='20' alt=''/><br/>exec — signals and exit code<br/>are the binary's own")
    L2 -->|"no"| Fail("<img src='barnacle:circle-exclamation-point.svg' width='20' alt=''/><br/><u>print how to build · exit 1</u>")
    click Env href "env.sh.md"
    click Fail href "build.sh.md"
    class L1,L2 hexNode
    class Use checkNode
    class Fail errNode
    classDef hexNode fill:#ffe08a,stroke:#a16207,color:#422006
    classDef checkNode fill:#9fe8c9,stroke:#0f766e,color:#052e22
    classDef errNode fill:#f6b8b8,stroke:#b91c1c,color:#450a0a
```

`scripts/run.sh` runs the mirror-clone binary that was built for the current machine. The platform is resolved with the environment cascade ([scripts/env.sh.md](env.sh.md)), the same way the bundled tools are resolved, and every argument is passed straight to the binary.

```bash
./scripts/run.sh --branch main git@github.com:fordaj/AirFrame.git
./scripts/run.sh --help
DEBUG=true ./scripts/run.sh --help        # runs the debug build
```

## Lookup order

1. `$MIRROR_CLONE_BIN` — when set, this binary is used (and must be executable).
2. `dist/<platform>/mirror-clone[.exe]` — release build; `dist/debug/<platform>/mirror-clone[.exe]` when `DEBUG=true`.

`<platform>` comes from `PROJECT_PLATFORM` in the environment cascade; Windows builds use `mirror-clone.exe`. When no binary is found the script prints how to build it (and points at the debug build when one exists) and exits `1`.

The lookup log line goes to **stderr**, so the output of the binary itself stays untouched, and the binary is `exec`'d directly — signals and the exit code are those of the binary.

Prerequisites: a build (see [scripts/build.sh.md](build.sh.md)) and the environment cascade ([scripts/env.sh.md](env.sh.md)). `die` comes from [scripts/entry.sh.md](entry.sh.md).

## Related pages

- [scripts/build.sh.md](build.sh.md) — how the binary is produced
- [scripts/env.sh.md](env.sh.md) — where `PROJECT_PLATFORM` comes from
- [README.md](../README.md) — the running section
