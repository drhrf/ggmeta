# Add an aligned text column to a forest plot

`geom_forest_text()` places a column of text labels aligned with the
study rows of a forest plot — for example event counts, sample sizes,
weights, or the effect estimate rendered as text. Rows align
automatically through the shared `y` (study) aesthetic; the horizontal
position of the column is set with the `x` argument. Place a column
beside the data by widening the panel with
[`ggplot2::expand_limits()`](https://ggplot2.tidyverse.org/reference/expand_limits.html).

## Usage

``` r
geom_forest_text(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  ...,
  x = NULL,
  hjust = 0,
  size = 3.2,
  na.rm = TRUE,
  show.legend = FALSE,
  inherit.aes = FALSE
)
```

## Arguments

- mapping:

  Set of aesthetic mappings created by
  [`aes()`](https://ggplot2.tidyverse.org/reference/aes.html). If
  specified and `inherit.aes = TRUE` (the default), it is combined with
  the default mapping at the top level of the plot. You must supply
  `mapping` if there is no plot mapping.

- data:

  The data to be displayed in this layer. There are three options:

  If `NULL`, the default, the data is inherited from the plot data as
  specified in the call to
  [`ggplot()`](https://ggplot2.tidyverse.org/reference/ggplot.html).

  A `data.frame`, or other object, will override the plot data. All
  objects will be fortified to produce a data frame. See
  [`fortify()`](https://ggplot2.tidyverse.org/reference/fortify.html)
  for which variables will be created.

  A `function` will be called with a single argument, the plot data. The
  return value must be a `data.frame`, and will be used as the layer
  data. A `function` can be created from a `formula` (e.g.
  `~ head(.x, 10)`).

- stat:

  The statistical transformation to use on the data for this layer. When
  using a `geom_*()` function to construct a layer, the `stat` argument
  can be used to override the default coupling between geoms and stats.
  The `stat` argument accepts the following:

  - A `Stat` ggproto subclass, for example `StatCount`.

  - A string naming the stat. To give the stat as a string, strip the
    function name of the `stat_` prefix. For example, to use
    [`stat_count()`](https://ggplot2.tidyverse.org/reference/geom_bar.html),
    give the stat as `"count"`.

  - For more information and other ways to specify the stat, see the
    [layer
    stat](https://ggplot2.tidyverse.org/reference/layer_stats.html)
    documentation.

- position:

  A position adjustment to use on the data for this layer. This can be
  used in various ways, including to prevent overplotting and improving
  the display. The `position` argument accepts the following:

  - The result of calling a position function, such as
    [`position_jitter()`](https://ggplot2.tidyverse.org/reference/position_jitter.html).
    This method allows for passing extra arguments to the position.

  - A string naming the position adjustment. To give the position as a
    string, strip the function name of the `position_` prefix. For
    example, to use
    [`position_jitter()`](https://ggplot2.tidyverse.org/reference/position_jitter.html),
    give the position as `"jitter"`.

  - For more information and other ways to specify the position, see the
    [layer
    position](https://ggplot2.tidyverse.org/reference/layer_positions.html)
    documentation.

- ...:

  Other arguments passed on to
  [`ggplot2::layer()`](https://ggplot2.tidyverse.org/reference/layer.html),
  often used to set an aesthetic to a fixed value, e.g.
  `colour = "grey30"` or `fontface = "bold"`.

- x:

  Fixed horizontal position for the column, in x-axis data units. If
  `NULL`, `x` must be supplied through `mapping`.

- hjust:

  Horizontal justification. Default `0` (left-aligned), so a column
  reads cleanly from its `x` position rightward.

- size:

  Text size in millimetres. Default `3.2`.

- na.rm:

  If `TRUE` (default), missing labels are dropped silently.

- show.legend:

  logical. Should this layer be included in the legends? `NA`, the
  default, includes if any aesthetics are mapped. `FALSE` never
  includes, and `TRUE` always includes. It can also be a named logical
  vector to finely select the aesthetics to display. To include legend
  keys for all levels, even when no data exists, use `TRUE`. If `NA`,
  all levels are shown in legend, but unobserved levels are omitted.

- inherit.aes:

  If `FALSE` (default) the layer does not inherit the forest plot's
  `x`/`xmin`/`xmax`/`weight` mapping, so only `y` and `label` need to be
  supplied.

## Aesthetics

`geom_forest_text()` understands the following aesthetics (required
aesthetics are in **bold**):

- **`y`** — row position (map to the same study variable as the forest
  layers)

- **`label`** — text to display

- `colour` — text colour (default: "black")

- `size` — text size; set via the `size` argument

- `fontface`, `family`, `angle`, `alpha`

## Examples

``` r
library(ggplot2)
df <- data.frame(
  study = c("A", "B", "C"),
  estimate = c(0.5, 0.8, 0.3),
  lower = c(0.2, 0.6, 0.1),
  upper = c(0.8, 1.0, 0.5),
  n = c(120, 240, 90)
)
ggplot(df, aes(y = study, x = estimate, xmin = lower, xmax = upper)) +
  geom_forest_ci() +
  geom_forest_text(aes(y = study, label = n), x = 1.15) +
  expand_limits(x = 1.25)
```
