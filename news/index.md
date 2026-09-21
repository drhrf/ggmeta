# Changelog

## ggmeta 0.1.0.9000

- Development version. Post-release touches: a package hex-sticker logo
  and a CRAN status badge in the README.

### Bug fixes

- Study estimates of single-group measures are now the observed values,
  as in
  [`meta::forest()`](https://wviechtb.github.io/metafor/reference/forest.html).
  [`meta::metaprop()`](https://rdrr.io/pkg/meta/man/metaprop.html) and
  [`meta::metarate()`](https://rdrr.io/pkg/meta/man/metarate.html) store
  a continuity-corrected `TE` for studies with zero or all events, so
  back-transforming it put the point outside its own exact interval: 12
  of 12 events was drawn at 0.96 against an upper limit of 1.00.
  [`tidy_meta()`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md)
  now uses `event / n` and `event / time` for every study of these
  types, independently of whether a correction was applied. The analysis
  scale (`back_trans = "none"`) is unaffected.
- Studies of a generalised linear mixed model (`method = "GLMM"`) no
  longer get invented weights. `meta` leaves `w.common` and `w.random`
  empty for such fits because the model does not weight studies by
  inverse variance, and
  [`meta::forest()`](https://wviechtb.github.io/metafor/reference/forest.html)
  drops the weight column accordingly;
  [`tidy_meta()`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md)
  used to fall back to `1 / seTE^2`, so
  [`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md)
  printed percentages the model never used. The weight cells are now
  blank and the squares are equally sized.
- [`geom_forest_ci()`](https://drhrf.github.io/ggmeta/reference/geom_forest_ci.md)
  draws equal, mid-sized squares when no study has a usable weight,
  instead of shrinking every square to the minimum size. Mixed weights
  are unaffected: a missing weight alongside usable ones still gets the
  minimum.
- Zero and unusable study weights are now formatted sensibly in the
  table columns. A zero weight prints as `0.0%`; a negative or infinite
  weight is reported once with a message and left blank instead of
  printing e.g. `-25.0%` and rescaling another study to `125.0%`.
  Percentages are computed from the positive weights only.
- [`tidy_meta()`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md)
  and
  [`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md)
  no longer fail on `meta` objects that contain studies excluded from
  pooling, such as double-zero studies in
  [`meta::metabin()`](https://rdrr.io/pkg/meta/man/metabin.html). The
  number of study rows was taken from `x$k`, which counts only
  contributing studies, so building the tidy data frame stopped with
  “arguments imply differing number of rows”. Such studies are now shown
  with their label and no interval, as in
  [`meta::forest()`](https://wviechtb.github.io/metafor/reference/forest.html).
- On-the-fly pooling of a data frame (`add_summary = TRUE`) now works on
  the log scale for ratio measures.
  `ggforest(df, add_summary = TRUE, null_effect = 1)` log-transforms the
  estimates and confidence limits before inverse-variance /
  DerSimonian-Laird pooling and exponentiates the summary back;
  [`tidy_meta()`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md)
  gains `log_scale` for the same purpose. Previously ratio values were
  pooled on the natural scale and their standard errors were recovered
  from asymmetric intervals, which gave wrong summaries.
- The heterogeneity caption of
  [`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md)
  prints `p < 0.001` instead of `p = 0.000` for very small p-values.
- Table columns (`columns = TRUE`) no longer print a negative zero
  (`-0.00`) for values that round to zero.
- [`geom_forest_ci()`](https://drhrf.github.io/ggmeta/reference/geom_forest_ci.md)
  square sizes now follow the documented mapping
  `min + (max - min) * sqrt(weight / max(weight))`. The computed sizes
  were previously mapped with
  [`after_stat()`](https://ggplot2.tidyverse.org/reference/aes_eval.html)
  and therefore rescaled a second time by ggplot2’s default size scale,
  which compressed the differences between studies. A constant or mapped
  `size` still overrides the weight-based size.

### Minor improvements

- [`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md)/[`tidy_meta()`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md)
  pooling and
  [`ggfunnel()`](https://drhrf.github.io/ggmeta/reference/ggfunnel.md)
  now report how many studies were left out (missing or non-finite
  estimate, or a standard error that is not positive) instead of
  dropping them silently.
- New tests document the behaviour at boundary conditions (missing or
  non-positive weights, missing confidence limits or estimates,
  single-study pooling, funnel plots without usable studies,
  single-group measures).

## ggmeta 0.1.0

CRAN release: 2026-07-22

First CRAN release.

`ggmeta` extends ‘ggplot2’ to build publication-quality forest and
funnel plots from `meta` objects or tidy data frames. Every plot is an
ordinary `ggplot`, so it can be themed, composed (for example a forest
and a funnel plot side by side with patchwork), and saved like any
other.

### Forest plots

- [`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md)
  draws a forest plot from a `meta` object or a tidy data frame, with
  study confidence intervals and weight-proportional squares, common-
  and random-effects summary diamonds, prediction intervals, and
  null-effect and consensus reference lines.
- `columns = TRUE` adds a
  [`meta::forest()`](https://wviechtb.github.io/metafor/reference/forest.html)-style
  table of effect-estimate, 95% CI, and weight columns (or a chosen
  subset), aligned on both linear and log axes.
- `add_summary = TRUE` pools a tidy data frame of effect sizes on the
  fly (inverse-variance common effect and DerSimonian-Laird random
  effects), so a summary diamond can be drawn without the `meta`
  package.
- Journal presets
  [`layout_jama()`](https://drhrf.github.io/ggmeta/reference/layout_jama.md),
  [`layout_bmj()`](https://drhrf.github.io/ggmeta/reference/layout_bmj.md),
  and
  [`layout_revman5()`](https://drhrf.github.io/ggmeta/reference/layout_revman5.md).

### Funnel plots

- [`ggfunnel()`](https://drhrf.github.io/ggmeta/reference/ggfunnel.md)
  draws a funnel plot (study effect against standard error) with pseudo
  confidence-interval contours, from a `meta` object or a tidy data
  frame. Ratio, proportion, rate, and correlation measures are drawn on
  their analysis scale but labelled with back-transformed values.

### Building blocks and customisation

- Composable geometries:
  [`geom_forest_ci()`](https://drhrf.github.io/ggmeta/reference/geom_forest_ci.md),
  [`geom_forest_diamond()`](https://drhrf.github.io/ggmeta/reference/geom_forest_diamond.md),
  [`geom_forest_ref()`](https://drhrf.github.io/ggmeta/reference/geom_forest_ref.md),
  [`geom_forest_predict()`](https://drhrf.github.io/ggmeta/reference/geom_forest_predict.md),
  [`geom_forest_text()`](https://drhrf.github.io/ggmeta/reference/geom_forest_text.md),
  and
  [`geom_funnel_contour()`](https://drhrf.github.io/ggmeta/reference/geom_funnel_contour.md);
  helpers
  [`tidy_meta()`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md),
  [`fortify.meta()`](https://drhrf.github.io/ggmeta/reference/fortify.meta.md),
  and
  [`format_effect()`](https://drhrf.github.io/ggmeta/reference/format_effect.md);
  themes
  [`theme_forest()`](https://drhrf.github.io/ggmeta/reference/theme_forest.md)
  and
  [`theme_funnel()`](https://drhrf.github.io/ggmeta/reference/theme_funnel.md).
- [`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md)
  and
  [`ggfunnel()`](https://drhrf.github.io/ggmeta/reference/ggfunnel.md)
  take per-element styling arguments (for example `predict_args`,
  `diamond_colours`, `ci_args`, `ref_args`, `point_args`,
  `contour_args`) to restyle any built-in layer.
- Every summary measure is back-transformed with its correct inverse
  (exponentiation for ratios, inverse-logit for logit proportions,
  Fisher’s *z* for correlations, and so on).
