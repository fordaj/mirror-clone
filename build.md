# Cross compilation (`build.bash`)

`build.bash` cross compiles the mirror-clone binary for the supported platforms. Release builds are the default (stripped, optimized, version stamped); debug builds keep the compiler's symbols and debug information.

## Usage

```bash
./build.bash                        # release build for the host platform
./build.bash --debug                # debug build for the host platform
./build.bash --all                  # release build for every platform
./build.bash --platform linux-arm64 # one platform (repeatable)
```

Options: `--debug`/`--release`, `--all`, `--platform PLATFORM` (repeatable), `--output DIR` (default `dist`), `--clean`, `--help`. Environment: `DEBUG=true` (same as `--debug`), `BUILD_MODE` (`release` or `debug`), `PLATFORMS` (space separated), `OUTPUT_DIR`. Output layout: `<output>/<platform>/mirror-clone[.exe]`, debug builds under `<output>/debug/<platform>/`.

The six supported platforms are `linux-x86_64`, `linux-arm64`, `macos-x86_64`, `macos-arm64`, `windows-x86_64`, `windows-arm64` (`go_target` maps them to `GOOS`/`GOARCH`/extension; `detect_host_platform` resolves the host).

## Version stamping

When the bundled [versioner](tools/versioner/update.md) is available, the version comes from [scripts/version.bash](scripts/version.md); otherwise the build warns and stamps `dev`. The commit and the build date come from git (`rev-parse --short HEAD`, `show -s --format=%cI`). Everything is stamped with `-ldflags "-X main.version=... -X main.commit=... -X main.date=... -X main.mode=..."` (see [version.md](version.md)); release mode adds `-s -w` and `-trimpath`, debug mode uses `-gcflags "all=-N -l"`. `CGO_ENABLED=0` for every build.

Sources [scripts/entry.md](scripts/entry.md) for the environment cascade and `log()`. Requires `go` and `git` on `PATH`.

## Related pages

- [version.md](version.md) — the ldflags variables and `versionString`
- [release.md](release.md) — the release pipeline that calls this script
- [run.md](run.md) — running what this builds
- [test.md](test.md) — the checks the sources must pass
