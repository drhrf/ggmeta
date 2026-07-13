# Format an effect estimate and confidence interval as text

A small helper for building the label of a
[`geom_forest_text()`](https://drhrf.github.io/ggmeta/reference/geom_forest_text.md)
column, producing strings such as `"1.40 (0.65 to 3.00)"`.

## Usage

``` r
format_effect(estimate, ci_lower, ci_upper, digits = 2, sep = " to ")
```

## Arguments

- estimate, ci_lower, ci_upper:

  Numeric vectors of equal length.

- digits:

  Number of decimal places. Default `2`.

- sep:

  Separator between the confidence limits. Default `" to "`.

## Value

A character vector; `NA` estimates become empty strings.

## Examples

``` r
format_effect(c(1.4, 0.9), c(0.65, 0.6), c(3.0, 1.35))
#> [1] "1.40 (0.65 to 3.00)" "0.90 (0.60 to 1.35)"
```
