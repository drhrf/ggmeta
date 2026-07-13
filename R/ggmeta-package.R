#' ggmeta: Publication-Quality Forest Plots with 'ggplot2'
#'
#' @description
#' A 'ggplot2' extension for creating publication-quality forest plots
#' from \pkg{meta} package objects or tidy data frames. Provides custom
#' \code{ggproto} geometries for study-level confidence intervals,
#' summary diamonds, prediction intervals, and null-effect reference lines.
#'
#' @section Main function:
#' \code{\link{ggforest}} is the primary entry point. Pass either a
#' \code{meta} object (from \pkg{meta}) or a tidy data frame.
#'
#' @section Custom geoms:
#' \itemize{
#'   \item \code{\link{geom_forest_ci}} — study-level CI with weight-proportional squares
#'   \item \code{\link{geom_forest_diamond}} — summary effect diamond polygon
#'   \item \code{\link{geom_forest_ref}} — vertical null-effect reference line
#'   \item \code{\link{geom_forest_predict}} — prediction interval display
#' }
#'
#' @section Data conversion:
#' \code{\link{tidy_meta}} converts \pkg{meta} objects to tidy data frames
#' suitable for use with ggmeta geoms or direct ggplot2 plotting.
#'
#' @keywords internal
"_PACKAGE"
NULL

## usethis namespace: start
#' @importFrom rlang %||% .data .env
## usethis namespace: end
NULL
