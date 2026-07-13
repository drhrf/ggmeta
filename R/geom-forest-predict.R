#' Prediction interval display for forest plots
#'
#' `geom_forest_predict()` draws a prediction interval around a random-effects
#' summary estimate. The prediction interval is wider than the confidence
#' interval and represents the range where the true effect in a new study
#' is expected to fall.
#'
#' @section Aesthetics:
#' `geom_forest_predict()` understands the following aesthetics
#' (required aesthetics are in **bold**):
#' \itemize{
#'   \item \strong{\code{x}} — point estimate (typically the random effects estimate)
#'   \item \strong{\code{xmin}} — lower prediction limit
#'   \item \strong{\code{xmax}} — upper prediction limit
#'   \item \strong{\code{y}} — vertical position
#'   \item \code{colour} — interval colour (default: "#6F9FBE")
#'   \item \code{linewidth} — interval line width (default: 0.45)
#'   \item \code{linetype} — interval line type (default: "dashed")
#'   \item \code{alpha} — transparency (default: 0.55)
#' }
#'
#' @inheritParams ggplot2::layer
#' @param ... Other arguments passed on to [ggplot2::layer()].
#' @param na.rm If `FALSE` (default), missing values are removed with
#'   a warning. If `TRUE`, missing values are silently removed.
#' @param cap_width Width of the capped end-marks as a proportion of
#'   row spacing. Default: `0.32`.
#'
#' @export
#'
#' @examples
#' library(ggplot2)
#' df <- data.frame(
#'   estimate = c(0.22),
#'   lower = c(-0.27),
#'   upper = c(0.70),
#'   model = c("Random effects")
#' )
#' ggplot(df, aes(y = model, x = estimate, xmin = lower, xmax = upper)) +
#'   geom_forest_diamond() +
#'   geom_forest_predict()
geom_forest_predict <- function(
  mapping = NULL,
  data = NULL,
  stat = "forest_predict",
  position = "identity",
  ...,
  cap_width = 0.32,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
) {
  ggplot2::layer(
    geom = GeomForestPredict,
    stat = StatForestPredict,
    data = data,
    mapping = mapping,
    position = position,
    params = list(
      cap_width = cap_width,
      na.rm = na.rm,
      ...
    ),
    show.legend = show.legend,
    inherit.aes = inherit.aes
  )
}

# ---- StatForestPredict ----

#' @export
#' @rdname geom_forest_predict
#' @format NULL
#' @usage NULL
StatForestPredict <- ggproto("StatForestPredict", Stat,

  required_aes = c("x", "xmin", "xmax", "y"),

  setup_params = function(data, params) {
    params
  },

  compute_panel = function(data, scales, cap_width = 0.32) {
    # Pass-through stat: data is already in the right format from tidy_meta
    # The geoms do the actual rendering
    data
  }
)

# ---- GeomForestPredict ----

#' @export
#' @rdname geom_forest_predict
#' @format NULL
#' @usage NULL
GeomForestPredict <- ggproto("GeomForestPredict", Geom,

  required_aes = c("x", "xmin", "xmax", "y"),

  default_aes = aes(
    colour    = "#6F9FBE",
    fill      = "#6F9FBE",
    linewidth = 0.45,
    linetype  = "dashed",
    alpha     = 0.55
  ),

  draw_key = function(data, params, size) {
    grid::grobTree(
      grid::segmentsGrob(
        x0 = 0.1, x1 = 0.9, y0 = 0.5, y1 = 0.5,
        gp = grid::gpar(
          col = data$colour %||% "#6F9FBE",
          lwd = (data$linewidth %||% 0.45) * .pt,
          lty = data$linetype %||% "dashed"
        )
      ),
      # Small end-caps in legend
      grid::segmentsGrob(
        x0 = c(0.1, 0.9), x1 = c(0.1, 0.9),
        y0 = c(0.3, 0.3), y1 = c(0.7, 0.7),
        gp = grid::gpar(
          col = data$colour %||% "#6F9FBE",
          lwd = (data$linewidth %||% 0.45) * .pt,
          lty = "solid"
        )
      )
    )
  },

  draw_panel = function(data, panel_params, coord,
                        cap_width = 0.32) {
    if (nrow(data) == 0) return(grid::nullGrob())

    coords <- coord$transform(data, panel_params)

    # Compute y spacing for cap sizes
    y_vals <- sort(unique(coords$y))
    y_spacing <- if (length(y_vals) > 1) min(diff(y_vals)) else 0.5
    cap_offset <- cap_width * y_spacing / 2

    # ---- 1. Main prediction interval line ----
    main_line <- grid::segmentsGrob(
      x0 = unit(coords$xmin, "native"),
      x1 = unit(coords$xmax, "native"),
      y0 = unit(coords$y, "native"),
      y1 = unit(coords$y, "native"),
      gp = grid::gpar(
        col = alpha(coords$colour, coords$alpha),
        lwd = coords$linewidth * .pt,
        lty = coords$linetype
      )
    )

    # ---- 2. Left end-cap ----
    left_cap <- grid::segmentsGrob(
      x0 = unit(coords$xmin, "native"),
      x1 = unit(coords$xmin, "native"),
      y0 = unit(coords$y - cap_offset, "native"),
      y1 = unit(coords$y + cap_offset, "native"),
      gp = grid::gpar(
        col = alpha(coords$colour, coords$alpha),
        lwd = coords$linewidth * .pt,
        lty = coords$linetype
      )
    )

    # ---- 3. Right end-cap ----
    right_cap <- grid::segmentsGrob(
      x0 = unit(coords$xmax, "native"),
      x1 = unit(coords$xmax, "native"),
      y0 = unit(coords$y - cap_offset, "native"),
      y1 = unit(coords$y + cap_offset, "native"),
      gp = grid::gpar(
        col = alpha(coords$colour, coords$alpha),
        lwd = coords$linewidth * .pt,
        lty = coords$linetype
      )
    )

    grid::grobTree(main_line, left_cap, right_cap,
                   name = "geom_forest_predict")
  }
)
