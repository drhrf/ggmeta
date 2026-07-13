#' Study-level confidence intervals and point estimates for forest plots
#'
#' `geom_forest_ci()` draws a confidence interval line and a
#' weight-proportional square for each study in a forest plot.
#' The square area scales with the study weight, making more precise
#' studies visually prominent.
#'
#' @section Aesthetics:
#' `geom_forest_ci()` understands the following aesthetics
#' (required aesthetics are in **bold**):
#' \itemize{
#'   \item \strong{\code{x}} — point estimate
#'   \item \strong{\code{xmin}} — lower confidence limit
#'   \item \strong{\code{xmax}} — upper confidence limit
#'   \item \strong{\code{y}} — study position (usually a factor)
#'   \item \strong{\code{weight}} — study weight for square sizing
#'   \item \code{colour} — line and square border colour (default: "black")
#'   \item \code{fill} — square fill colour (default: "black")
#'   \item \code{alpha} — transparency (default: 1)
#'   \item \code{linewidth} — CI line width (default: 0.5)
#'   \item \code{size} — override for square size; computed from weight by default
#'   \item \code{linetype} — CI line type (default: "solid")
#' }
#'
#' @inheritParams ggplot2::layer
#' @param ... Other arguments passed on to [ggplot2::layer()]. These are
#'   often aesthetics, used to set an aesthetic to a fixed value, like
#'   `colour = "red"` or `linewidth = 1`.
#' @param na.rm If `FALSE` (default), missing values are removed with
#'   a warning. If `TRUE`, missing values are silently removed.
#' @param ci_width Width of the CI line end-marks as a proportion of the
#'   spacing between study rows. Default: `0.3`.
#' @param point_size_range Minimum and maximum point size in mm.
#'   Default: `c(1, 6)`.
#'
#' @return A ggplot2 layer.
#' @export
#'
#' @examples
#' library(ggplot2)
#' df <- data.frame(
#'   study = c("Study 1", "Study 2", "Study 3"),
#'   estimate = c(0.5, 0.8, 0.3),
#'   lower = c(0.2, 0.6, 0.1),
#'   upper = c(0.8, 1.0, 0.5),
#'   weight = c(1, 2, 0.5)
#' )
#' ggplot(df, aes(y = study, x = estimate, xmin = lower, xmax = upper,
#'                weight = weight)) +
#'   geom_forest_ref() +
#'   geom_forest_ci()
geom_forest_ci <- function(
  mapping = NULL,
  data = NULL,
  stat = "forest_ci",
  position = "identity",
  ...,
  ci_width = 0.3,
  point_size_range = c(1, 6),
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE
) {
  ggplot2::layer(
    geom = GeomForestCI,
    stat = StatForestCI,
    data = data,
    mapping = mapping,
    position = position,
    params = list(
      ci_width = ci_width,
      point_size_range = point_size_range,
      na.rm = na.rm,
      ...
    ),
    show.legend = show.legend,
    inherit.aes = inherit.aes
  )
}

# ---- StatForestCI ----

#' @export
#' @rdname geom_forest_ci
#' @format NULL
#' @usage NULL
StatForestCI <- ggproto("StatForestCI", Stat,

  # `weight` is intentionally NOT required: a missing/NA weight should fall
  # back to the minimum square size rather than delete the study's CI row.
  required_aes = c("x", "xmin", "xmax", "y"),

  default_aes = aes(
    weight = NA_real_,
    size = after_stat(weight_sq)
  ),

  setup_params = function(data, params) {
    params
  },

  compute_panel = function(data, scales,
                           point_size_range = c(1, 6)) {
    if (nrow(data) == 0) return(data)

    # Compute square size from weight: area proportional to weight
    # Size (diameter) proportional to sqrt(weight)
    w <- data$weight
    if (is.null(w)) w <- rep(NA_real_, nrow(data))
    w[is.na(w) | w <= 0] <- 0

    if (max(w, na.rm = TRUE) > 0) {
      w_scaled <- sqrt(w / max(w, na.rm = TRUE))
      data$weight_sq <- scales::rescale(
        w_scaled,
        to = point_size_range,
        from = c(0, 1)
      )
    } else {
      data$weight_sq <- point_size_range[1]
    }

    data
  }
)

# ---- GeomForestCI ----

#' @export
#' @rdname geom_forest_ci
#' @format NULL
#' @usage NULL
GeomForestCI <- ggproto("GeomForestCI", Geom,

  required_aes = c("x", "xmin", "xmax", "y"),

  default_aes = aes(
    colour      = "black",
    fill        = "black",
    alpha       = 1,
    linewidth   = 0.5,
    size        = 2.5,
    linetype    = "solid",
    stroke      = 0.5
  ),

  draw_key = function(data, params, size) {
    # Legend key: CI line with a square at center
    grid::grobTree(
      grid::segmentsGrob(
        x0 = 0.1, x1 = 0.9, y0 = 0.5, y1 = 0.5,
        gp = grid::gpar(
          col = data$colour %||% "black",
          lwd = (data$linewidth %||% 0.5) * .pt,
          lty = data$linetype %||% "solid"
        )
      ),
      grid::pointsGrob(
        x = 0.5, y = 0.5, pch = 15,
        size = unit((data$size %||% 2.5) * .pt, "pt"),
        gp = grid::gpar(
          col = alpha(data$fill %||% "black", data$alpha %||% 1),
          fill = alpha(data$fill %||% "black", data$alpha %||% 1)
        )
      )
    )
  },

  draw_panel = function(data, panel_params, coord,
                        ci_width = 0.3,
                        point_size_range = c(1, 6)) {
    if (nrow(data) == 0) return(grid::nullGrob())

    # Transform data coordinates
    coords <- coord$transform(data, panel_params)

    # Compute y spacing from unique y positions
    y_vals <- sort(unique(coords$y))
    if (length(y_vals) > 1) {
      y_spacing <- min(diff(y_vals))
    } else {
      y_spacing <- 0.5
    }

    # ---- 1. CI horizontal lines ----
    ci_lines <- grid::segmentsGrob(
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

    # ---- 2. CI end-cap ticks ----
    cap_offset <- ci_width * y_spacing / 2

    left_caps <- grid::segmentsGrob(
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

    right_caps <- grid::segmentsGrob(
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

    # ---- 3. Point estimate squares ----
    point_grob <- grid::pointsGrob(
      x = unit(coords$x, "native"),
      y = unit(coords$y, "native"),
      pch = 15,  # filled square
      size = unit(coords$size, "mm"),
      gp = grid::gpar(
        col = alpha(coords$fill, coords$alpha),
        fill = alpha(coords$fill, coords$alpha),
        lwd = coords$stroke * .pt
      )
    )

    # ---- 4. Combine all grobs ----
    grid::grobTree(ci_lines, left_caps, right_caps, point_grob,
                   name = "geom_forest_ci")
  }
)
