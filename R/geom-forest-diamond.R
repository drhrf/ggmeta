#' Summary effect diamond for forest plots
#'
#' `geom_forest_diamond()` draws a diamond (lozenge) shape representing
#' a summary effect estimate in a forest plot. The left and right tips
#' mark the confidence limits and the widest point marks the estimate.
#'
#' @section Aesthetics:
#' `geom_forest_diamond()` understands the following aesthetics
#' (required aesthetics are in **bold**):
#' \itemize{
#'   \item \strong{\code{x}} — point estimate (diamond center)
#'   \item \strong{\code{xmin}} — lower confidence limit (left tip)
#'   \item \strong{\code{xmax}} — upper confidence limit (right tip)
#'   \item \strong{\code{y}} — vertical position
#'   \item \code{colour} — diamond border colour (default: "black")
#'   \item \code{fill} — diamond fill colour (default: "black")
#'   \item \code{alpha} — fill transparency (default: 0.5)
#'   \item \code{linewidth} — border width (default: 0.5)
#'   \item \code{linetype} — border line type (default: "solid")
#' }
#'
#' @inheritParams ggplot2::layer
#' @param ... Other arguments passed on to [ggplot2::layer()].
#' @param na.rm If `FALSE` (default), missing values are removed with
#'   a warning. If `TRUE`, missing values are silently removed.
#' @param diamond_height Height of the diamond as a proportion of the
#'   spacing between study rows. Default: `0.4`.
#'
#' @return A ggplot2 layer.
#' @export
#'
#' @examples
#' library(ggplot2)
#' df <- data.frame(
#'   model = c("Common effect", "Random effects"),
#'   estimate = c(0.22, 0.22),
#'   lower = c(-0.08, -0.08),
#'   upper = c(0.52, 0.52)
#' )
#' ggplot(df, aes(y = model, x = estimate, xmin = lower, xmax = upper)) +
#'   geom_forest_diamond(aes(fill = model))
geom_forest_diamond <- function(
  mapping = NULL,
  data = NULL,
  stat = "forest_diamond",
  position = "identity",
  ...,
  diamond_height = 0.4,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
) {
  ggplot2::layer(
    geom = GeomForestDiamond,
    stat = StatForestDiamond,
    data = data,
    mapping = mapping,
    position = position,
    params = list(
      diamond_height = diamond_height,
      na.rm = na.rm,
      ...
    ),
    show.legend = show.legend,
    inherit.aes = inherit.aes
  )
}

# ---- StatForestDiamond ----

#' @export
#' @rdname geom_forest_diamond
#' @format NULL
#' @usage NULL
StatForestDiamond <- ggproto("StatForestDiamond", Stat,

  required_aes = c("x", "xmin", "xmax", "y"),

  setup_params = function(data, params) {
    params
  },

  compute_panel = function(data, scales,
                           diamond_height = 0.4) {
    if (nrow(data) == 0) return(data.frame())

    # Compute y-spacing from unique y positions
    y_vals <- sort(unique(data$y))
    if (length(y_vals) > 1) {
      y_spacing <- min(diff(y_vals))
    } else {
      y_spacing <- 1  # single summary: use unit spacing
    }
    half_h <- diamond_height / 2 * y_spacing

    # For each row, generate 5 diamond corner points
    # (closing the polygon: 5th point = 1st point)
    rows <- lapply(seq_len(nrow(data)), function(i) {
      d <- data[i, , drop = FALSE]
      data.frame(
        x         = c(d$xmin, d$x, d$xmax, d$x, d$xmin),
        y         = c(d$y, d$y + half_h, d$y, d$y - half_h, d$y),
        group     = d$group %||% (i + 1000L),
        PANEL     = d$PANEL,
        colour    = d$colour %||% "black",
        fill      = d$fill %||% "black",
        alpha     = d$alpha %||% 0.5,
        linewidth = d$linewidth %||% 0.5,
        linetype  = d$linetype %||% "solid",
        stringsAsFactors = FALSE
      )
    })

    do.call(rbind, rows)
  }
)

# ---- GeomForestDiamond ----

#' @export
#' @rdname geom_forest_diamond
#' @format NULL
#' @usage NULL
GeomForestDiamond <- ggproto("GeomForestDiamond", Geom,

  required_aes = c("x", "y"),

  default_aes = aes(
    colour    = "black",
    fill      = "black",
    alpha     = 0.5,
    linewidth = 0.5,
    linetype  = "solid"
  ),

  draw_key = function(data, params, size) {
    # Diamond legend key glyph
    grid::polygonGrob(
      x = c(0.1, 0.5, 0.9, 0.5),
      y = c(0.5, 0.9, 0.5, 0.1),
      gp = grid::gpar(
        col = data$colour %||% "black",
        fill = alpha(data$fill %||% "black", data$alpha %||% 0.5),
        lwd = (data$linewidth %||% 0.5) * .pt,
        lty = data$linetype %||% "solid"
      )
    )
  },

  draw_panel = function(data, panel_params, coord) {
    if (nrow(data) == 0) return(grid::nullGrob())

    # Delegate to GeomPolygon for rendering
    GeomPolygon$draw_panel(data, panel_params, coord)
  }
)
