#' Reference line at null effect for forest plots
#'
#' `geom_forest_ref()` draws a vertical reference line at the null effect
#' value — typically 0 for difference measures (MD, SMD) or 1 for ratio
#' measures (RR, OR, HR). The line indicates where no treatment effect exists.
#'
#' @section Aesthetics:
#' `geom_forest_ref()` understands the following aesthetics:
#' \itemize{
#'   \item \code{colour} — line colour (default: "gray50")
#'   \item \code{linewidth} — line width (default: 0.5)
#'   \item \code{linetype} — line type (default: "dashed")
#'   \item \code{alpha} — transparency (default: 0.8)
#' }
#'
#' @inheritParams ggplot2::layer
#' @param ... Other arguments passed on to [ggplot2::layer()].
#' @param na.rm If `FALSE` (default), missing values are removed with
#'   a warning. If `TRUE`, missing values are silently removed.
#' @param xintercept X-axis intercept for the reference line.
#'   Default: `0` (null effect for difference measures).
#'
#' @return A ggplot2 layer.
#' @export
#'
#' @examples
#' library(ggplot2)
#' df <- data.frame(
#'   study = c("Study 1", "Study 2"),
#'   estimate = c(0.5, 0.8),
#'   lower = c(0.2, 0.6),
#'   upper = c(0.8, 1.0),
#'   weight = c(1, 2)
#' )
#' ggplot(df, aes(y = study, x = estimate, xmin = lower,
#'                xmax = upper, weight = weight)) +
#'   geom_forest_ref(xintercept = 0) +
#'   geom_forest_ci()
geom_forest_ref <- function(
  mapping = NULL,
  data = NULL,
  ...,
  xintercept = 0,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
) {
  ggplot2::layer(
    geom = GeomForestRef,
    stat = StatForestRef,
    data = data,
    mapping = mapping,
    position = "identity",
    params = list(
      xintercept = xintercept,
      na.rm = na.rm,
      ...
    ),
    show.legend = show.legend,
    inherit.aes = inherit.aes
  )
}

# ---- StatForestRef ----

#' @export
#' @rdname geom_forest_ref
#' @format NULL
#' @usage NULL
StatForestRef <- ggproto("StatForestRef", Stat,

  required_aes = c("y"),

  setup_params = function(data, params) {
    params
  },

  compute_panel = function(data, scales, xintercept = 0) {
    if (nrow(data) == 0) return(data.frame())

    y_range <- range(as.numeric(data$y), na.rm = TRUE)
    y_pad <- diff(y_range) * 0.05

    # Map the intercept into the x scale's space (identity for a linear axis,
    # log10 for a ratio-measure axis) so the line aligns with the other layers,
    # whose x values are already transformed by the scale.
    x_pos <- xintercept
    if (!is.null(scales$x) && !is.null(scales$x$trans)) {
      x_pos <- scales$x$trans$transform(xintercept)
    }

    # Line aesthetics come from the geom's default_aes (and may be overridden
    # by layer parameters such as `linetype`), so they are not fixed here.
    data.frame(
      x     = x_pos,
      xend  = x_pos,
      y     = y_range[1] - y_pad,
      yend  = y_range[2] + y_pad,
      PANEL = data$PANEL[1],
      group = 1,
      stringsAsFactors = FALSE
    )
  }
)

# ---- GeomForestRef ----

#' @export
#' @rdname geom_forest_ref
#' @format NULL
#' @usage NULL
GeomForestRef <- ggproto("GeomForestRef", Geom,

  required_aes = c("x", "xend", "y", "yend"),

  default_aes = aes(
    colour    = "gray50",
    linewidth = 0.5,
    linetype  = "dashed",
    alpha     = 0.8
  ),

  draw_key = function(data, params, size) {
    grid::segmentsGrob(
      x0 = 0.2, x1 = 0.8, y0 = 0.5, y1 = 0.5,
      gp = grid::gpar(
        col = data$colour %||% "gray50",
        lwd = (data$linewidth %||% 0.5) * .pt,
        lty = data$linetype %||% "dashed"
      )
    )
  },

  draw_panel = function(data, panel_params, coord) {
    if (nrow(data) == 0) return(grid::nullGrob())
    GeomSegment$draw_panel(data, panel_params, coord)
  }
)
