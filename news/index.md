# Changelog

## ggmeta 0.1.0.9000

- Development version. Post-release touches: a package hex-sticker logo
  and a CRAN status badge in the README.

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
