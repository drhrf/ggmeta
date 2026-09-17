# ggmeta 0.1.0.9000

* Development version. Post-release touches: a package hex-sticker logo and a
  CRAN status badge in the README.

## Bug fixes

* On-the-fly pooling of a data frame (`add_summary = TRUE`) now works on the
  log scale for ratio measures. `ggforest(df, add_summary = TRUE,
  null_effect = 1)` log-transforms the estimates and confidence limits before
  inverse-variance / DerSimonian-Laird pooling and exponentiates the summary
  back; `tidy_meta()` gains `log_scale` for the same purpose. Previously ratio
  values were pooled on the natural scale and their standard errors were
  recovered from asymmetric intervals, which gave wrong summaries.
* The heterogeneity caption of `ggforest()` prints `p < 0.001` instead of
  `p = 0.000` for very small p-values.
* Table columns (`columns = TRUE`) no longer print a negative zero (`-0.00`)
  for values that round to zero.
* `geom_forest_ci()` square sizes now follow the documented mapping
  `min + (max - min) * sqrt(weight / max(weight))`. The computed sizes were
  previously mapped with `after_stat()` and therefore rescaled a second time by
  ggplot2's default size scale, which compressed the differences between
  studies. A constant or mapped `size` still overrides the weight-based size.

## Minor improvements

* `ggforest()`/`tidy_meta()` pooling and `ggfunnel()` now report how many
  studies were left out (missing or non-finite estimate, or a standard error
  that is not positive) instead of dropping them silently.
* New tests document the behaviour at boundary conditions (missing or
  non-positive weights, missing confidence limits or estimates, single-study
  pooling, funnel plots without usable studies, single-group measures).

# ggmeta 0.1.0

First CRAN release.

`ggmeta` extends 'ggplot2' to build publication-quality forest and funnel plots
from `meta` objects or tidy data frames. Every plot is an ordinary `ggplot`, so
it can be themed, composed (for example a forest and a funnel plot side by side
with patchwork), and saved like any other.

## Forest plots

* `ggforest()` draws a forest plot from a `meta` object or a tidy data frame,
  with study confidence intervals and weight-proportional squares, common- and
  random-effects summary diamonds, prediction intervals, and null-effect and
  consensus reference lines.
* `columns = TRUE` adds a `meta::forest()`-style table of effect-estimate, 95%
  CI, and weight columns (or a chosen subset), aligned on both linear and log
  axes.
* `add_summary = TRUE` pools a tidy data frame of effect sizes on the fly
  (inverse-variance common effect and DerSimonian-Laird random effects), so a
  summary diamond can be drawn without the `meta` package.
* Journal presets `layout_jama()`, `layout_bmj()`, and `layout_revman5()`.

## Funnel plots

* `ggfunnel()` draws a funnel plot (study effect against standard error) with
  pseudo confidence-interval contours, from a `meta` object or a tidy data
  frame. Ratio, proportion, rate, and correlation measures are drawn on their
  analysis scale but labelled with back-transformed values.

## Building blocks and customisation

* Composable geometries: `geom_forest_ci()`, `geom_forest_diamond()`,
  `geom_forest_ref()`, `geom_forest_predict()`, `geom_forest_text()`, and
  `geom_funnel_contour()`; helpers `tidy_meta()`, `fortify.meta()`, and
  `format_effect()`; themes `theme_forest()` and `theme_funnel()`.
* `ggforest()` and `ggfunnel()` take per-element styling arguments (for example
  `predict_args`, `diamond_colours`, `ci_args`, `ref_args`, `point_args`,
  `contour_args`) to restyle any built-in layer.
* Every summary measure is back-transformed with its correct inverse
  (exponentiation for ratios, inverse-logit for logit proportions, Fisher's *z*
  for correlations, and so on).
