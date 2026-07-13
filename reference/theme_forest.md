# Forest plot theme

A complete ggplot2 theme optimized for forest plots. Removes unnecessary
grid lines, adjusts margins, and sets sensible defaults for forest plot
aesthetics.

## Usage

``` r
theme_forest(
  base_size = 11,
  base_family = "",
  base_line_size = base_size/22,
  base_rect_size = base_size/22
)
```

## Arguments

- base_size:

  Base font size in pts. Default: `11`.

- base_family:

  Base font family. Default: `""`.

- base_line_size:

  Base line size. Default: `base_size / 22`.

- base_rect_size:

  Base rect size. Default: `base_size / 22`.

## Examples

``` r
library(ggplot2)
df <- data.frame(
  study = c("Study 1", "Study 2"),
  estimate = c(0.5, 0.3),
  lower = c(0.2, 0.1),
  upper = c(0.8, 0.5),
  weight = c(1, 2)
)
ggplot(df, aes(y = study, x = estimate, xmin = lower,
               xmax = upper, weight = weight)) +
  geom_forest_ref() +
  geom_forest_ci() +
  theme_forest()
```
