# URL handling (`url.go`)

`url.go` derives repository names and resolves submodule URLs. It understands the three URL shapes that show up in practice: `https://host/org/repo.git`, scp-like `git@host:org/repo.git`, and local paths like `/srv/git/repo.git`.

## Functions

- `repoNameFromURL(raw)` — strips query strings/fragments and trailing slashes, detects scp-like syntax (a `:` before any `/` whose prefix has no `/`, and no `://`), keeps the last path segment, drops a `.git` or `.bundle` suffix, and sanitizes the result.
- `sanitizeName(name)` — maps every rune outside `[a-zA-Z0-9._-]` to `-`, trims leading/trailing `.-`, and returns `repo` when nothing usable remains. Used for directory names on every supported platform.
- `shortHash(s)` — the first 8 hex characters of the SHA-256 of `s`; used to disambiguate mirror cache entries that share a name ([mirror.go.md](mirror.go.md)).
- `isRelativeURL(u)` — reports whether `u` starts with `./` or `../`.
- `resolveSubmoduleURL(parentURL, subURL)` — absolute URLs pass through unchanged; relative URLs are resolved against the parent like git does it (`../lib.git` next to `https://host/org/proj.git` becomes `https://host/org/lib.git`).
- `resolveRelativeURL(base, rel)` — lexical join and normalization of the path (no filesystem access); `..` past the root is an error.
- `splitURLHead(u)` — splits off the part that must never be resolved away: `scheme://authority/` for absolute URLs, `[user@]host:` for scp-like URLs, or `/` for local paths.
- `sameURL(a, b)` — compares two repository URLs after trimming whitespace and trailing slashes and normalizing a leading `file:` prefix (case-insensitively). Used to decide whether an existing clone/mirror matches a URL.

## Related pages

- [mirror.go.md](mirror.go.md) — caller of `repoNameFromURL`, `shortHash`, `resolveSubmoduleURL` and `sameURL`
- [main.go.md](main.go.md)
