# Removing the executable (`executable_unix.go` + `executable_windows.go`)

```mermaid
flowchart TD
    Uninst("<img src='barnacle:trash.svg' width='20' alt=''/><br/><u>mirror-clone uninstall</u>") --> Rem("<img src='barnacle:file-code.svg' width='20' alt=''/><br/>removeExecutable(path)")
    Rem -->|"!windows build tag"| Unix("<img src='barnacle:file-code.svg' width='20' alt=''/><br/>os.Remove — unlink a running binary is fine")
    Rem -->|"windows build tag"| Win("<img src='barnacle:file-code.svg' width='20' alt=''/><br/>os.Remove")
    Win -->|"ERROR_SHARING_VIOLATION · ERROR_LOCK_VIOLATION"| Old("<img src='barnacle:file-diff.svg' width='20' alt=''/><br/><u>rename to path.old<br/>delete by hand after exit</u>")
    Win -->|"any other error"| Fail("<img src='barnacle:circle-exclamation-point.svg' width='20' alt=''/><br/><u>return the error unchanged</u>")
    Unix --> Done("<img src='barnacle:check.svg' width='20' alt=''/><br/>removed")
    Old --> Done
    click Uninst href "install.go.md"
    click Old href "update.go.md"
    click Fail href "install.go.md"
    class Done checkNode
    class Fail errNode
    classDef checkNode fill:#9fe8c9,stroke:#0f766e,color:#052e22
    classDef errNode fill:#f6b8b8,stroke:#b91c1c,color:#450a0a
```

`removeExecutable(path)` deletes the installed executable. It is the one piece of the self-management flow that differs between platforms, so it lives in two files selected by build tag.

## `executable_unix.go` (`//go:build !windows`)

Just `os.Remove(path)`. On Unix systems a running executable can be removed — the file is unlinked and stays usable until the process ends.

## `executable_windows.go` (`//go:build windows`)

Windows locks a running executable, so `os.Remove` can fail with `ERROR_SHARING_VIOLATION` (32) or `ERROR_LOCK_VIOLATION` (33) — matched by `isFileLocked` via `errors.As` on `syscall.Errno`. In that case the file is renamed to `path + backupSuffix` (the shared `backupSuffix` constant from [install.go.md](install.go.md), `.old`); a leftover `.old` is removed first, and the function returns an error message telling the user the file was moved aside and has to be removed by hand once the program is closed. Any other error is returned unchanged.

The split exists for the uninstall path; the update path handles the same locking case in `replaceFile` ([install.go.md](install.go.md)). Uninstall also removes a leftover `.old` file.

One page covers both files because the contract (`removeExecutable(path string) error`) is identical and the Windows file is the only difference; see AGENTS.md.

## Related pages

- [install.go.md](install.go.md) — the uninstall flow that calls this
- [update.go.md](update.go.md) — the update flow with its own locking workaround
