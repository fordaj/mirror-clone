# Self install and uninstall (`install.go`)

```mermaid
flowchart TD
    Inst("<img src='barnacle:download.svg' width='20' alt=''/><br/>mirror-clone install") --> Dir("<img src='barnacle:folder.svg' width='20' alt=''/><br/>installDir<br/>~/.local/bin · %LOCALAPPDATA%\Programs\mirror-clone")
    Dir --> Copy("<img src='barnacle:copy.svg' width='20' alt=''/><br/>copyExecutable<br/>temp file in the target dir · chmod 0755")
    Copy --> Replace("<img src='barnacle:file-code.svg' width='20' alt=''/><br/><u>replaceFile — atomic rename<br/>Windows: locked target moved aside to .old first</u>")
    Replace --> Path{{"<img src='barnacle:hexagon.svg' width='20' alt=''/><br/>on PATH?"}}
    Path -->|"no"| Print("<img src='barnacle:terminal.svg' width='20' alt=''/><br/>print the line to add<br/>shell config never changed")
    Path -->|"yes"| Done("<img src='barnacle:check.svg' width='20' alt=''/><br/>installed")
    Un("<img src='barnacle:trash.svg' width='20' alt=''/><br/>mirror-clone uninstall") --> Rem("<img src='barnacle:file-x.svg' width='20' alt=''/><br/><u>removeExecutable + leftover .old</u>")
    Rem --> Rmdir("<img src='barnacle:folder-minus.svg' width='20' alt=''/><br/>removeDirIfEmpty — only when empty")
    click Replace href "update.go.md"
    click Rem href "executable.md"
    class Dir folder
    class Path hexNode
    class Done checkNode
    classDef folder fill:#f0c558,stroke:#8a6d1c,color:#332a05
    classDef hexNode fill:#ffe08a,stroke:#a16207,color:#422006
    classDef checkNode fill:#9fe8c9,stroke:#0f766e,color:#052e22
```

`install.go` implements `mirror-clone install` and `mirror-clone uninstall`: copying the running executable into a per-user directory and removing it again.

## Install location

`installDir(goos, home, localAppData)` maps the platform to the install directory — `~/.local/bin` on Linux and macOS, `%LOCALAPPDATA%\Programs\mirror-clone` on Windows — and errors on other platforms. `defaultInstallDir` resolves it for the running machine; `executableName` appends `.exe` on Windows; `installPath` joins the two.

## Install flow

`runInstall` resolves the directory, finds the running executable with `os.Executable()`, and calls `install(source, dir, name)`, which creates the directory (`0755`) and copies through `copyExecutable`: write to a temporary file in the target directory first, `chmod 0755`, then `replaceFile` into place atomically — a failed copy never leaves a broken executable. `replaceFile` renames in one step; on Windows a locked target is moved aside to `target.old` (or `target.<pid>.old`) first and restored if the replacement fails. The `.old` suffix is the shared `backupSuffix` constant used by `uninstall` and by the Windows path ([executable.md](executable.md)). After installing, the command warns when the directory is not on `PATH` and prints the line to add — the shell configuration is never changed (`pathInstructions`).

## Uninstall flow

`runUninstall` removes the installed executable (`uninstall`, which also removes a leftover `.old` from an earlier update) and then removes the directory **only when it is empty** (`removeDirIfEmpty`). A missing executable is not an error; the configuration and the mirror cache are never touched.

`pathContains` reports whether `dir` is on the `PATH` (case-insensitive on Windows).

`removeExecutable` lives in [executable.md](executable.md) (split per platform).

## Related pages

- [executable.md](executable.md) — platform-specific removal of the running binary
- [update.go.md](update.go.md) — the self update that shares `replaceFile`/`installPath`
- [main.go.md](main.go.md) — command dispatch
- [README.md](README.md) — the self-management section
