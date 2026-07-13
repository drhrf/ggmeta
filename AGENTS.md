# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with
code in this repository.

## About this package

This directory is the source tree of **`ggmeta`**, an R package that
extends ‘ggplot2’ to build publication-quality forest plots from
[`meta`](https://cran.r-project.org/package=meta) objects or tidy data
frames. The package root is this directory (not a subfolder).

`meta` is a **Suggests** dependency, not Imports:
[`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md)
works on a `meta` object when `meta` is installed, or on a plain tidy
data frame standalone.
[`requireNamespace("meta")`](https://github.com/guido-s/meta/) guards
protect the meta-dependent code paths.

> The `Get_started_with_rcompendium.md` and `Developing_an_R_package.md`
> files are unrelated reference clippings that happen to live here; they
> are not part of the package.

## Architecture (3 layers)

    Layer 3  ggforest()                      high-level S3 generic (meta / data.frame)
             theme_forest(), layout_jama(), layout_bmj(), layout_revman5()
    Layer 2  geom_forest_ci()      study CIs + weight-proportional squares
             geom_forest_diamond() summary diamond (delegates to GeomPolygon)
             geom_forest_ref()     vertical null-effect line
             geom_forest_predict() prediction interval with caps
    Layer 1  tidy_meta()           meta object -> tidy data frame
             fortify.meta()        ggplot2 S3 method wrapping tidy_meta()

### Source map (`R/`)

| File | Purpose |
|----|----|
| `imports.R` | Central `@importFrom` tags for NAMESPACE generation |
| `ggmeta-package.R` | Package-level docs (`"_PACKAGE"`) |
| `ggmeta-zzz.R` | `.onLoad()`, global variable declarations |
| `utils.R` | `back_transform()`, `detect_null_effect()`, `default_effect_label()`, measure-class vectors |
| `tidy-meta.R` | [`tidy_meta()`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md) generic + `meta`/`data.frame` methods and extraction helpers |
| `fortify.R` | [`fortify.meta()`](https://drhrf.github.io/ggmeta/reference/fortify.meta.md) |
| `geom-forest-*.R` | one Stat + Geom + constructor per geom |
| `ggforest.R` | [`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md) generic + methods + heterogeneity caption |
| `lay-forest.R` | [`theme_forest()`](https://drhrf.github.io/ggmeta/reference/theme_forest.md) and `layout_*()` presets |

## Key implementation notes

- **Display order lives in the `studlab` factor levels**, not row order.
  Rows stay in extraction order (stable for inspection); the factor
  levels encode the top-to-bottom plot order (studies on top, summary
  diamond at the bottom).
  [`ggforest.data.frame()`](https://drhrf.github.io/ggmeta/reference/ggforest.md)
  pins the y axis with `scale_y_discrete(limits = ...)` so the order
  does not depend on which optional layers are present.
- **Back-transformation delegates to
  [`meta::backtransf()`](https://rdrr.io/pkg/meta/man/meta-transf.html)**
  so every summary measure gets its correct inverse (exp for ratios,
  inverse-logit for `PLOGIT`, Fisher-z for `ZCOR`, etc.). Do not
  hard-code [`exp()`](https://rdrr.io/r/base/Log.html) for
  proportions/rates.
- **`detect_null_effect()`** returns `1` for ratios, `0` for
  differences/ correlations, and `NA` for single-group proportions/rates
  (no reference line, no log axis).
- **Study weights** use `meta`’s `w.*` slots when usable, else fall back
  to inverse-variance (`1 / seTE^2`); `weight` is a non-required
  aesthetic so a missing weight never deletes a study’s CI.
- **On-plot text must avoid raw non-ASCII.** The heterogeneity caption
  is built as a plotmath expression (`italic(I)^2`, `tau^2`) — embedding
  literal `τ`/`²` crashes `R CMD check` example rendering under
  non-UTF-8 devices.

## Common commands

``` r

devtools::load_all()                 # load for interactive work
devtools::test()                     # run testthat suite (tests/testthat/)
devtools::document()                 # regenerate man/*.Rd + NAMESPACE from roxygen
```

``` bash
R CMD build .                        # build source tarball
_R_CHECK_FORCE_SUGGESTS_=false \
  R CMD check --as-cran --run-donttest ggmeta_*.tar.gz
```

`covr`, `vdiffr`, and `spelling` are optional (Suggests) and may not be
installed locally; `_R_CHECK_FORCE_SUGGESTS_=false` lets the check run
without them. `R CMD check` should be run on the built tarball, not the
directory.

## Key references

- meta package: <https://cran.r-project.org/package=meta>
- ggplot2 extension guide: <https://ggplot2-book.org/extensions>
- R Packages book: <https://r-pkgs.org/>
