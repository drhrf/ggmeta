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
