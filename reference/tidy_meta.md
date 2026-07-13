# Tidy a 'meta' object into a plottable data frame

Converts objects of class `meta` (from the meta package) into a tidy
data frame suitable for use with ggmeta geometries and
[`ggforest()`](https://drhrf.github.io/ggmeta/reference/ggforest.md).
The returned data frame has one row per study or summary.

## Usage

``` r
tidy_meta(x, ...)

# Default S3 method
tidy_meta(x, ...)

# S3 method for class 'data.frame'
tidy_meta(
  x,
  add_summary = FALSE,
  summary_method = c("common", "random"),
  level = 0.95,
  ...
)

# S3 method for class 'meta'
tidy_meta(
  x,
  back_trans = c("auto", "exp", "none"),
  sort_studies = TRUE,
  add_summary = TRUE,
  add_predict = TRUE,
  add_subgroups = TRUE,
  ...
)
```

## Arguments

- x:

  An object of class `meta`, e.g. created by
  [`meta::metabin()`](https://rdrr.io/pkg/meta/man/metabin.html),
  [`meta::metacont()`](https://rdrr.io/pkg/meta/man/metacont.html), or
  [`meta::metagen()`](https://rdrr.io/pkg/meta/man/metagen.html).

- ...:

  Additional arguments passed to methods.

- add_summary:

  For the data-frame method, if `TRUE` compute an inverse-variance /
  DerSimonian-Laird pooled summary from the study rows and append it
  (on-the-fly meta-analysis, no meta package required). Needs a `se`
  column, or `ci_lower`/`ci_upper` to recover it. Default `FALSE`.

- summary_method:

  Which pooled summaries to add when `add_summary = TRUE`: `"common"`,
  `"random"`, or both (default).

- level:

  Confidence level for the pooled summary interval. Default `0.95`.

- back_trans:

  Should the estimate and confidence limits be back-transformed to the
  natural scale? If `"auto"` (default), each summary measure is
  back-transformed with its correct inverse via
  [`meta::backtransf()`](https://rdrr.io/pkg/meta/man/meta-transf.html)
  (exponentiation for ratios, inverse-logit for `PLOGIT`, Fisher's z to
  correlation for `ZCOR`, etc.); linear measures are left unchanged. Use
  `"exp"` to force exponentiation or `"none"` to keep the analysis
  scale.

- sort_studies:

  If `TRUE` (default), sort studies by effect estimate (most favorable
  at top).

- add_predict:

  If `TRUE` (default), include prediction interval row when available.

- add_subgroups:

  If `TRUE` (default), include subgroup headers and within-group summary
  rows when subgroups are present.

## Value

A `data.frame` with one row per study or summary, with columns:

- studlab:

  Study label (character)

- estimate:

  Point estimate (numeric)

- ci_lower:

  Lower confidence limit (numeric)

- ci_upper:

  Upper confidence limit (numeric)

- se:

  Standard error (numeric)

- weight:

  Study weight (numeric, `NA` for summaries)

- p_value:

  P-value (numeric)

- n:

  Sample size or person-time (numeric, optional)

- event:

  Number of events (numeric, optional)

- is_summary:

  Logical, `TRUE` for summary rows

- summary_type:

  Character: `"none"`, `"common"`, `"random"`, `"subgroup"`, or
  `"predict"`

- subgroup:

  Subgroup label (character or `NA`)

The returned data frame has the following attributes:

- `sm`:

  summary measure type (e.g. `"RR"`, `"OR"`, `"MD"`)

- `null_effect`:

  null effect value for reference line

- `method`:

  meta-analysis method

- `common`:

  logical, TRUE if common effect model was used

- `random`:

  logical, TRUE if random effects model was used

- `tau`:

  heterogeneity estimate tau

- `k`:

  number of studies

## Examples

``` r
# \donttest{
library(meta)
m <- metabin(event.e, n.e, event.c, n.c,
  data = data.frame(
    event.e = c(14, 30), n.e = c(100, 150),
    event.c = c(10, 25), n.c = c(100, 150)
  ),
  studlab = c("Study A", "Study B"),
  sm = "RR"
)
tidy_meta(m)
#>                    studlab estimate   ci_lower  ci_upper        se    weight
#> 1                  Study A 1.400000 0.65296960  3.001671 0.3891382  6.603774
#> 2                  Study B 1.200000 0.74247238  1.939466 0.2449490 16.666667
#> common       Common effect 1.257143 0.83734105  1.887413 0.2073331        NA
#> random      Random effects 1.253660 0.83507644  1.882058 0.2072992        NA
#> 11     Prediction interval 1.253660 0.09000235 17.462462 0.2072992        NA
#>          p_value is_summary summary_type subgroup
#> 1      0.3872255      FALSE         none     <NA>
#> 2      0.4566801      FALSE         none     <NA>
#> common 0.2697065       TRUE       common     <NA>
#> random 0.2754777       TRUE       random     <NA>
#> 11            NA       TRUE      predict     <NA>
# }
```
