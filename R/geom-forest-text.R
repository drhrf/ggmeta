#' Add an aligned text column to a forest plot
#'
#' `geom_forest_text()` places a column of text labels aligned with the study
#' rows of a forest plot — for example event counts, sample sizes, weights, or
#' the effect estimate rendered as text. Rows align automatically through the
#' shared `y` (study) aesthetic; the horizontal position of the column is set
#' with the `x` argument. Place a column beside the data by widening the panel
#' with [ggplot2::expand_limits()].
#'
#' @section Aesthetics:
#' `geom_forest_text()` understands the following aesthetics
#' (required aesthetics are in **bold**):
#' \itemize{
#'   \item \strong{\code{y}} — row position (map to the same study variable as
#'     the forest layers)
#'   \item \strong{\code{label}} — text to display
#'   \item \code{colour} — text colour (default: "black")
#'   \item \code{size} — text size; set via the `size` argument
#'   \item \code{fontface}, \code{family}, \code{angle}, \code{alpha}
#' }
#'
#' @inheritParams ggplot2::layer
#' @param ... Other arguments passed on to [ggplot2::layer()], often used to set
#'   an aesthetic to a fixed value, e.g. `colour = "grey30"` or
#'   `fontface = "bold"`.
#' @param x Fixed horizontal position for the column, in x-axis data units. If
#'   `NULL`, `x` must be supplied through `mapping`.
#' @param hjust Horizontal justification. Default `0` (left-aligned), so a
#'   column reads cleanly from its `x` position rightward.
#' @param size Text size in millimetres. Default `3.2`.
#' @param na.rm If `TRUE` (default), missing labels are dropped silently.
#' @param inherit.aes If `FALSE` (default) the layer does not inherit the forest
#'   plot's `x`/`xmin`/`xmax`/`weight` mapping, so only `y` and `label` need to
#'   be supplied.
#'
#' @return A ggplot2 layer.
#' @export
#'
#' @examples
#' library(ggplot2)
#' df <- data.frame(
#'   study = c("A", "B", "C"),
#'   estimate = c(0.5, 0.8, 0.3),
#'   lower = c(0.2, 0.6, 0.1),
#'   upper = c(0.8, 1.0, 0.5),
#'   n = c(120, 240, 90)
#' )
#' ggplot(df, aes(y = study, x = estimate, xmin = lower, xmax = upper)) +
#'   geom_forest_ci() +
#'   geom_forest_text(aes(y = study, label = n), x = 1.15) +
#'   expand_limits(x = 1.25)
geom_forest_text <- function(
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
) {
  params <- list(hjust = hjust, size = size, na.rm = na.rm, ...)
  if (!is.null(x)) {
    params$x <- x
  }
  ggplot2::layer(
    geom = GeomText,
    mapping = mapping,
    data = data,
    stat = stat,
    position = position,
    params = params,
    show.legend = show.legend,
    inherit.aes = inherit.aes
  )
}

#' Format an effect estimate and confidence interval as text
#'
#' A small helper for building the label of a `geom_forest_text()` column,
#' producing strings such as `"1.40 (0.65 to 3.00)"`.
#'
#' @param estimate,ci_lower,ci_upper Numeric vectors of equal length.
#' @param digits Number of decimal places. Default `2`.
#' @param sep Separator between the confidence limits. Default `" to "`.
#'
#' @return A character vector; `NA` estimates become empty strings.
#' @export
#'
#' @examples
#' format_effect(c(1.4, 0.9), c(0.65, 0.6), c(3.0, 1.35))
format_effect <- function(estimate, ci_lower, ci_upper,
                          digits = 2, sep = " to ") {
  out <- sprintf(
    "%.*f (%.*f%s%.*f)",
    digits, estimate, digits, ci_lower, sep, digits, ci_upper
  )
  out[is.na(estimate)] <- ""
  out
}
