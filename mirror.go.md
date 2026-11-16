# The mirror cloner (`mirror.go`)

```mermaid
flowchart TD
    Req["CloneRequest<br/>Name · URL · Dest · Ref"] --> Val["validate URL + dest"]
    Val --> Ensure["ensureMirror<br/>git clone --mirror · or fetch --prune<br/>cache: &lt;cache&gt;/&lt;name&gt;.git<br/>name clash → &lt;name&gt;-&lt;shorthash&gt;.git"]
    Ensure --> From["cloneFromMirror<br/>git clone --reference --dissociate<br/>existing dest: fetch --prune + ff-only<br/>(never discards local changes)"]
    From --> Checkout["checkout Ref<br/>fallback: fetch mirror refs → refs/remotes/mirror/* and retry"]
    Checkout -->|"<a href='url.go.md'>relative URLs vs superproject</a>"| Subs["cloneSubmodules<br/>parallel, recursive, bounded by --jobs"]
    Subs --> Done["working copy ready"]
    click Ensure href "git.go.md"
    click From href "git.go.md"
    click Checkout href "git.go.md"
```

`mirror.go` implements the core of the tool: cloning through a local mirror cache, including recursive submodule cloning.

## Types

`CloneRequest` (`Name`, `URL`, `Dest`, `Ref`) describes one clone operation. `Submodule` (`Name`, `Path`, `URL`, `SHA`) is one `.gitmodules` entry. `MirrorCloner` holds the `Git` runner, the `Logger`, the cache directory and a `workers` channel used as a semaphore to limit parallel submodule clones (`NewMirrorCloner` clamps `jobs` to ≥ 1).

## Clone flow

`Clone` validates the URL and destination, creates the destination (and its parent) with mode `0755`, then:

1. `ensureMirror` — returns the path of the mirror, creating or refreshing it. The cache entry is `<cache>/<name>.git`; when that exists but points at a different URL, a disambiguated `<name>-<shorthash>.git` is used instead, so two repositories sharing a name cannot steal each other's cache. A mirror whose `origin` cannot be read is removed and re-created; an existing usable mirror is refreshed with `git fetch --prune`. New mirrors are made with `git clone --mirror`.
2. `cloneFromMirror` — clones with `--reference <mirror> --dissociate <url> <dest>`, so objects are not downloaded twice and the clone keeps working when the cache is removed. If `dest` already holds a clone of the same origin, it is refreshed instead: `git fetch --prune` plus `fastForward` (a `--ff-only` merge to `origin/HEAD`, or `origin/<branch>`; local changes are never discarded, a failure only logs a warning). A non-git, non-empty destination is an error.
3. `checkout` — when `Ref` is set, checks it out; if that fails, fetches the mirror's refs into `refs/remotes/mirror/*` and retries, so commits not reachable from any remote branch still resolve.
4. `cloneSubmodules` — reads `.gitmodules` via `git config --file .gitmodules --get-regexp` and the recorded gitlink SHAs via `git ls-files --stage` (mode `160000`), then clones each submodule recursively through the same cache, in parallel (bounded by `jobs`), with relative URLs resolved against the superproject URL ([url.go.md](url.go.md)). Submodule errors are collected with `errors.Join`.

`isDir`, `isEmptyDir` and `isGitRepo` are small helpers used by the flow.

## Related pages

- [main.go.md](main.go.md) — how the cloner is wired up
- [git.go.md](git.go.md) — the subprocess runner it uses
- [url.go.md](url.go.md) — URL derivation and relative submodule resolution
- [logger.go.md](logger.go.md)
