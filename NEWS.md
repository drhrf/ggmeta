# ggmeta 0.1.1

Bug-fix release. The display of single-group measures (proportions and rates)
and of generalised linear mixed models now follows `meta::forest()`.

## Bug fixes

* The heterogeneity caption no longer prints `p = NA` for a generalised linear
  mixed model. A GLMM tests heterogeneity twice, so `meta` stores `Q`, `df.Q`
  and `pval.Q` as a Wald and a likelihood-ratio pair; the whole pair reached
  the caption, which printed both Q values and lost the p-value.
  `ggforest()` now takes the first element of each, the Wald test, as
  `meta::forest()` does for its own one-line caption.
* Study estimates of single-group measures are now the observed values, as in
  `meta::forest()`. `meta::metaprop()` and `meta::metarate()` store a
  continuity-corrected `TE` for studies with zero or all events, so
  back-transforming it put the point outside its own exact interval: 12 of 12
  events was drawn at 0.96 against an upper limit of 1.00. `tidy_meta()` now
  uses `event / n` and `event / time` for every study of these types,
  independently of whether a correction was applied. The analysis scale
  (`back_trans = "none"`) is unaffected.
* Studies of a generalised linear mixed model (`method = "GLMM"`) no longer get
  invented weights. `meta` leaves `w.common` and `w.random` empty for such fits
  because the model does not weight studies by inverse variance, and
  `meta::forest()` drops the weight column accordingly; `tidy_meta()` used to
  fall back to `1 / seTE^2`, so `ggforest()` printed percentages the model
  never used. The weight cells are now blank and the squares are equally sized.
* `geom_forest_ci()` draws equal, mid-sized squares when no study has a usable
  weight, instead of shrinking every square to the minimum size. Mixed weights
  are unaffected: a missing weight alongside usable ones still gets the
  minimum.
* Zero and unusable study weights are now formatted sensibly in the table
  columns. A zero weight prints as `0.0%`; a negative or infinite weight is
  reported once with a message and left blank instead of printing e.g.
  `-25.0%` and rescaling another study to `125.0%`. Percentages are computed
  from the positive weights only.
* `tidy_meta()` and `ggforest()` no longer fail on `meta` objects that contain
  studies excluded from pooling, such as double-zero studies in
  `meta::metabin()`. The number of study rows was taken from `x$k`, which
  counts only contributing studies, so building the tidy data frame stopped
  with "arguments imply differing number of rows". Such studies are now shown
  with their label and no interval, as in `meta::forest()`.
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
* The README gained a package hex-sticker logo and a CRAN status badge.

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
