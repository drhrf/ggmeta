# ggmeta: Publication-Quality Forest Plots with 'ggplot2'

A 'ggplot2' extension for creating publication-quality forest plots from
meta package objects or tidy data frames. Provides custom `ggproto`
geometries for study-level confidence intervals, summary diamonds,
prediction intervals, and null-effect reference lines.

## Main function

[`ggforest`](https://drhrf.github.io/ggmeta/reference/ggforest.md) is
the primary entry point. Pass either a `meta` object (from meta) or a
tidy data frame.

## Custom geoms

- [`geom_forest_ci`](https://drhrf.github.io/ggmeta/reference/geom_forest_ci.md)
  — study-level CI with weight-proportional squares

- [`geom_forest_diamond`](https://drhrf.github.io/ggmeta/reference/geom_forest_diamond.md)
  — summary effect diamond polygon

- [`geom_forest_ref`](https://drhrf.github.io/ggmeta/reference/geom_forest_ref.md)
  — vertical null-effect reference line

- [`geom_forest_predict`](https://drhrf.github.io/ggmeta/reference/geom_forest_predict.md)
  — prediction interval display

## Data conversion

[`tidy_meta`](https://drhrf.github.io/ggmeta/reference/tidy_meta.md)
converts meta objects to tidy data frames suitable for use with ggmeta
geoms or direct ggplot2 plotting.

## See also

Useful links:

- <https://github.com/drhrf/ggmeta>

- <https://drhrf.github.io/ggmeta/>

- Report bugs at <https://github.com/drhrf/ggmeta/issues>

## Author

**Maintainer**: Hercules R. Freitas <hercules.freitas@uerj.br>
([ORCID](https://orcid.org/0000-0003-1584-9157)) \[copyright holder\]

Authors:

- Hercules R. Freitas <hercules.freitas@uerj.br>
  ([ORCID](https://orcid.org/0000-0003-1584-9157)) \[copyright holder\]
