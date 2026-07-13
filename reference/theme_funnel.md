# Funnel plot theme

A light ggplot2 theme for
[`ggfunnel()`](https://drhrf.github.io/ggmeta/reference/ggfunnel.md)
plots.

## Usage

``` r
theme_funnel(base_size = 11, base_family = "")
```

## Arguments

- base_size:

  Base font size in pts. Default `11`.

- base_family:

  Base font family. Default `""`.

## Value

A ggplot2 theme.

## Examples

``` r
library(ggplot2)
df <- data.frame(estimate = c(-0.3, 0.1, -0.2), se = c(0.1, 0.3, 0.2))
ggplot(df, aes(estimate, se)) +
  geom_point() +
  scale_y_reverse() +
  theme_funnel()
```
