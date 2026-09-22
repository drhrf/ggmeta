## R CMD check results

0 errors | 0 warnings | 1 note

* The NOTE reports possibly misspelled words in the DESCRIPTION -- "BMJ",
  "JAMA", and "RevMan". These are correct: they name the journals and software
  (British Medical Journal, the Journal of the American Medical Association, and
  the Cochrane Review Manager) whose layout presets the package provides.

## Summary of changes

This is a bug-fix update to the 0.1.0 release. The main changes align the
display of single-group measures and of generalised linear mixed models with
`meta::forest()`:

* Study estimates of `meta::metaprop()` and `meta::metarate()` objects are now
  the observed proportion or rate. The stored effect of a study with zero or
  all events is continuity-corrected, so back-transforming it placed the point
  outside its own exact confidence interval.
* Studies of a `method = "GLMM"` fit no longer receive inverse-variance weights,
  which that model does not use.
* The heterogeneity caption reports the Wald test instead of printing `p = NA`,
  because a GLMM stores its heterogeneity statistics as a Wald and a
  likelihood-ratio pair.

See NEWS.md for the full list.

## Test environments

* Local macOS Tahoe 26.6.2 (aarch64), R 4.5.3, `R CMD check --as-cran --run-donttest`
* win-builder, R-devel (2026-09-21 r90579, ucrt) -- OK
* mac-builder, r-release-macosx-arm64, R 4.6.1 -- OK
* R-hub v2 (GitHub Actions), R-devel:
  * linux -- OK
  * windows -- OK
  * macos-arm64 -- OK
  * donttest (`--run-donttest` re-check) -- OK
  * vnu (W3C HTML validation) -- OK
  * nosuggests (all Suggests removed) -- vignette rebuild fails because
    `rmarkdown` itself is unavailable to render any `.Rmd` file, not because
    of unconditional `meta` usage; every vignette already gates its
    `meta`-dependent chunks with `eval = requireNamespace("meta", quietly = TRUE)`.
    CRAN's own check machines always have Suggests installed, so this
    cannot occur there.
* `urlchecker::url_check()` -- no issues
* `spelling::spell_check_package()` -- no issues

## Notes for the reviewer

* `meta` is a Suggested (not Imported) dependency: `ggforest()` / `ggfunnel()`
  work on `meta` objects when `meta` is installed, and equally on tidy data
  frames without it. Examples that need `meta` are wrapped in `\donttest{}`, and
  `meta`-dependent code paths are guarded with `requireNamespace()`. The package
  also checks cleanly with `_R_CHECK_DEPENDS_ONLY_=true`.

## Downstream dependencies

There are no reverse dependencies on CRAN.
