# Create a forest plot

The primary function for creating publication-quality forest plots.
Accepts a meta object (created by
[`meta::metabin()`](https://rdrr.io/pkg/meta/man/metabin.html),
[`meta::metacont()`](https://rdrr.io/pkg/meta/man/metacont.html), etc.)
or a tidy data frame (as returned by
[`tidy_meta()`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md)
or constructed manually).

## Usage

``` r
ggforest(x, ...)

# Default S3 method
ggforest(x, ...)

# S3 method for class 'meta'
ggforest(
  x,
  ...,
  back_trans = c("auto", "exp", "none"),
  sort_studies = TRUE,
  show_summary = TRUE,
  show_predict = TRUE,
  show_hetstats = TRUE,
  null_effect = NULL,
  xlab = NULL
)

# S3 method for class 'data.frame'
ggforest(
  x,
  null_effect = 0,
  xlab = "Effect (95% CI)",
  ylab = NULL,
  title = NULL,
  caption = NULL,
  add_summary = FALSE,
  summary_method = c("common", "random"),
  level = 0.95,
  columns = NULL,
  effect_header = NULL,
  ci_args = list(),
  diamond_args = list(),
  diamond_colours = NULL,
  predict_args = list(),
  ref_args = list(),
  consensus = TRUE,
  consensus_args = list(),
  ...
)
```

## Arguments

- x:

  A meta object or a tidy data frame with columns `estimate`,
  `ci_lower`, `ci_upper`, `studlab`, and optionally `weight`,
  `is_summary`, `summary_type`, `subgroup`.

- ...:

  Additional arguments passed to methods.

- back_trans:

  Back-transform ratio measures? `"auto"` (default), `"exp"`, or
  `"none"`.

- sort_studies:

  Sort studies by effect estimate? Default: `TRUE`.

- show_summary:

  Include summary effect rows? Default: `TRUE`.

- show_predict:

  Include prediction interval? Default: `TRUE` (only when random effects
  model is present).

- show_hetstats:

  Show heterogeneity statistics in plot caption? Default: `TRUE`.

- null_effect:

  Null effect value for the reference line. Default: `0`.

- xlab:

  X-axis label. Default: `"Effect (95% CI)"`.

- ylab:

  Y-axis label. Default: `NULL` (no label — study labels serve as the
  y-axis text).

- title:

  Plot title. Default: `NULL`.

- caption:

  Plot caption. Default: `NULL`.

- add_summary:

  For the data-frame method, if `TRUE` compute a pooled summary from the
  study rows (inverse-variance and/or DerSimonian-Laird) and draw it as
  a diamond — on-the-fly meta-analysis without the meta package. Needs a
  `se` column, or `ci_lower`/`ci_upper` to recover it. Default: `FALSE`.

- summary_method:

  Which pooled summaries to add when `add_summary = TRUE`: `"common"`,
  `"random"`, or both (default).

- level:

  Confidence level for the pooled summary interval. Default `0.95`.

- columns:

  Add a
  [`meta::forest()`](https://wviechtb.github.io/metafor/reference/forest.html)-style
  table of text columns to the right of the plot. `TRUE` shows the
  effect estimate, 95% CI, and weight; or pass a subset/order such as
  `c("estimate", "ci")`. `NULL` (default) draws no columns.

- effect_header:

  Header for the estimate column (e.g. `"Hedges' g"`). Defaults to the
  summary measure (e.g. `"SMD"`, `"RR"`).

- ci_args, diamond_args, predict_args:

  Lists of arguments used to restyle the study confidence intervals
  ([`geom_forest_ci()`](https://drhrf.github.io/ggmeta/reference/geom_forest_ci.md)),
  the summary diamonds
  ([`geom_forest_diamond()`](https://drhrf.github.io/ggmeta/reference/geom_forest_diamond.md)),
  and the prediction interval
  ([`geom_forest_predict()`](https://drhrf.github.io/ggmeta/reference/geom_forest_predict.md)).
  For example `predict_args = list(cap_width = 0.1, colour = "red")` or
  `ci_args = list(colour = "grey20", point_size_range = c(1, 5))`. This
  is the way to customise these elements: adding another
  `geom_forest_*()` layer to a `ggforest()` plot draws a *second* layer
  over every row rather than restyling the built-in one.

- diamond_colours:

  Optional named colours for the summary diamonds, overriding the
  default palette. Names are `"common"`, `"random"`,
  `"subgroup_common"`, and `"subgroup_random"`, e.g.
  `c(common = "black", random = "steelblue")`.

- ref_args, consensus_args:

  Lists of arguments for the null-effect reference line and the dotted
  "consensus" line (both
  [`geom_forest_ref()`](https://drhrf.github.io/ggmeta/reference/geom_forest_ref.md)),
  e.g. `ref_args = list(linetype = "dashed", colour = "black")`.

- consensus:

  Draw the dotted consensus line at the pooled estimate? Default `TRUE`
  (only shown alongside a null line).

## Value

A `ggplot` object. Add standard ggplot2 layers (themes, scales, labels)
to further customize.

## Examples

``` r
# \donttest{
library(meta)
m <- metabin(event.e, n.e, event.c, n.c,
  data = data.frame(
    event.e = c(14, 30, 15, 22),
    n.e     = c(100, 150, 100, 120),
    event.c = c(10, 25, 12, 18),
    n.c     = c(100, 150, 100, 120)
  ),
  studlab = c("Study A", "Study B", "Study C", "Study D"),
  sm = "RR"
)
ggforest(m)

# }
```
