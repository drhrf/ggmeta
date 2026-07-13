## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release, so the NOTE is the standard "New submission" note.

## Test environments

* Local macOS 15 (aarch64), R 4.6.1, `R CMD check --as-cran`
* GitHub Actions:
  * macOS-latest, R release
  * windows-latest, R release
  * ubuntu-latest, R devel, release, and oldrel-1

## Notes for the reviewer

* `meta` is a Suggested (not Imported) dependency: `ggforest()` / `ggfunnel()`
  work on `meta` objects when `meta` is installed, and equally on tidy data
  frames without it. Examples that need `meta` are wrapped in `\donttest{}`, and
  `meta`-dependent code paths are guarded with `requireNamespace()`.

## Downstream dependencies

This is a new package; there are no downstream dependencies.
