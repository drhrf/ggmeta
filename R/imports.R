# Central imports for package-level NAMESPACE generation.
# roxygen2 will process these tags and generate the appropriate
# importFrom() or import() directives.

# ---- ggplot2 core ggproto system ----
#' @importFrom ggplot2 ggproto
#' @importFrom ggplot2 Geom
#' @importFrom ggplot2 Stat
#' @importFrom ggplot2 GeomPolygon
#' @importFrom ggplot2 GeomSegment
#' @importFrom ggplot2 GeomText
#' @importFrom ggplot2 GeomPath
#' @importFrom ggplot2 geom_point
#' @importFrom ggplot2 geom_vline
#' @importFrom ggplot2 layer
#' @importFrom ggplot2 fortify
#' @importFrom ggplot2 .pt

# ---- ggplot2 aesthetics and computed variables ----
#' @importFrom ggplot2 aes
#' @importFrom ggplot2 after_stat

# ---- ggplot2 theme infrastructure ----
#' @importFrom ggplot2 theme
#' @importFrom ggplot2 theme_minimal
#' @importFrom ggplot2 element_line
#' @importFrom ggplot2 element_blank
#' @importFrom ggplot2 element_text
#' @importFrom ggplot2 element_rect
#' @importFrom ggplot2 margin
#' @importFrom ggplot2 rel
#' @importFrom ggplot2 `%+replace%`

# ---- ggplot2 high-level functions ----
#' @importFrom ggplot2 ggplot
#' @importFrom ggplot2 labs
#' @importFrom ggplot2 guides
#' @importFrom ggplot2 scale_x_log10
#' @importFrom ggplot2 scale_x_continuous
#' @importFrom ggplot2 scale_y_discrete
#' @importFrom ggplot2 scale_y_reverse
#' @importFrom ggplot2 scale_fill_discrete
#' @importFrom ggplot2 scale_fill_manual
#' @importFrom ggplot2 coord_cartesian
#' @importFrom ggplot2 expansion

# ---- rlang ----
#' @importFrom rlang %||%
#' @importFrom rlang .data
#' @importFrom rlang .env

# ---- scales ----
#' @importFrom scales alpha
#' @importFrom scales rescale

# ---- grid ----
#' @importFrom grid unit

NULL
