## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.
* The NOTE reports possibly misspelled words in the DESCRIPTION -- "BMJ",
  "JAMA", and "RevMan". These are correct: they name the journals and software
  (British Medical Journal, the Journal of the American Medical Association, and
  the Cochrane Review Manager) whose layout presets the package provides.

## Test environments

* Local macOS 15 (aarch64), R 4.6.1, `R CMD check --as-cran`
* win-builder, R-devel (R Under development, 2026-07-13 r90246 ucrt): 1 NOTE
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
