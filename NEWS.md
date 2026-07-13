# ggmeta 0.1.0.9000

## New features

* New `ggfunnel()` draws a funnel plot (study effect vs. standard error with
  pseudo confidence-interval contours) from a `meta` object or a tidy data
  frame, returning an ordinary `ggplot`. Ratio, proportion, rate, and
  correlation measures are drawn on their analysis scale but labelled with
  back-transformed values. Because both `ggforest()` and `ggfunnel()` are
  ggplots, a forest and funnel plot compose on one canvas with \pkg{patchwork}
  — e.g. `ggforest(m) | ggfunnel(m)`. Comes with `geom_funnel_contour()` and
  `theme_funnel()`.
* `ggforest()` gains `columns` to draw a `meta::forest()`-style table of text
  columns (effect estimate, 95% CI, weight) with headers to the right of the
  plot: `ggforest(m, columns = TRUE)`, or a subset such as
  `columns = c("estimate", "ci")`. The estimate header can be set with
  `effect_header`. Positions are computed in the axis's own space, so columns
  line up on both linear and log (ratio) axes.
* `ggforest()` and `tidy_meta()` gain `add_summary` (with `summary_method` and
  `level`) to pool a tidy data frame of effect sizes on the fly — an
  inverse-variance common effect and a DerSimonian–Laird random effect — so a
  summary diamond can be drawn without the **meta** package.
* New `geom_forest_text()` adds a custom text column aligned with the study
  rows, plus `format_effect()` to build `"estimate (low to high)"` labels.

## Improvements

* Refreshed default look: a solid null-effect line with a dotted "consensus"
  line at the pooled estimate (as in `meta::forest()`), terracotta / dark-blue
  summary diamonds, no panel gridlines, and (with `columns`) bold headers and an
  x-axis title centred under the plot region.
* Summary-diamond legends now read "Common effect" / "Random effects" /
  "Subgroup (common)" / "Subgroup (random)" instead of raw keys, and the
  non-informative square-size legend is hidden.
* Getting-started and "Coming from `meta::forest()`" vignettes added.

## Bug fixes

* `geom_forest_ref()` now maps its intercept through the x-axis transformation,
  so the null-effect and consensus lines land at the correct place on ratio
  (log) axes — previously the null line for `RR`/`OR`/`HR` rendered at ten times
  the intended value.
* Back-transformation delegates to `meta::backtransf()`, so every summary
  measure gets its correct inverse (inverse-logit for `PLOGIT`, arcsine for
  `PAS`, Fisher's *z* for `ZCOR`, exp for rates such as `IRLN`). Previously
  proportions, rates, and correlations were exponentiated incorrectly.
* Single-group proportions and rates no longer draw a null-effect reference
  line or a log x-axis (`detect_null_effect()` now returns `NA` for them).
* Subgroup forest plots keep each study grouped under its subgroup header, and
  headers render as plain text instead of literal `**markdown**`.
* Study confidence intervals are no longer dropped for object types whose
  weights are unavailable (e.g. `metaprop`, `metarate`); weights fall back to
  the inverse variance and `weight` is no longer a required aesthetic.
* Forest plots use a stable, conventional orientation (studies on top, summary
  diamond at the bottom) regardless of which optional layers are present.
* The heterogeneity caption is drawn as a plotmath expression, fixing an
  example-rendering error under non-UTF-8 graphics devices.
