#' Forest plot theme
#'
#' A complete ggplot2 theme optimized for forest plots. Removes
#' unnecessary grid lines, adjusts margins, and sets sensible
#' defaults for forest plot aesthetics.
#'
#' @param base_size Base font size in pts. Default: `11`.
#' @param base_family Base font family. Default: `""`.
#' @param base_line_size Base line size. Default: `base_size / 22`.
#' @param base_rect_size Base rect size. Default: `base_size / 22`.
#'
#' @return A ggplot2 theme object (a list of class `"theme"`).
#' @export
#'
#' @examples
#' library(ggplot2)
#' df <- data.frame(
#'   study = c("Study 1", "Study 2"),
#'   estimate = c(0.5, 0.3),
#'   lower = c(0.2, 0.1),
#'   upper = c(0.8, 0.5),
#'   weight = c(1, 2)
#' )
#' ggplot(df, aes(y = study, x = estimate, xmin = lower,
#'                xmax = upper, weight = weight)) +
#'   geom_forest_ref() +
#'   geom_forest_ci() +
#'   theme_forest()
theme_forest <- function(base_size = 11,
                         base_family = "",
                         base_line_size = base_size / 22,
                         base_rect_size = base_size / 22) {
  theme_minimal(
    base_size = base_size,
    base_family = base_family,
    base_line_size = base_line_size,
    base_rect_size = base_rect_size
  ) %+replace%
    theme(
      # Grid: none -- a clean plot area (as in classic forest plots)
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),

      # Axis: hide y-axis ticks (study labels are the text)
      axis.ticks.y = element_blank(),
      axis.ticks.x = element_line(colour = "gray50"),

      # Study labels: right-aligned, bold, slightly smaller
      axis.text.y = element_text(
        hjust  = 1,
        face   = "bold",
        size   = rel(0.85),
        colour = "black"
      ),

      # X-axis
      axis.text.x = element_text(colour = "black"),

      # No y-axis title (study labels are self-documenting)
      axis.title.y = element_blank(),

      # Legend
      legend.position = "bottom",
      legend.title    = element_blank(),
      legend.key.size = unit(0.5, "cm"),

      # Caption: heterogeneity stats sit below the centered legend.
      plot.caption = element_text(
        hjust  = 0.5,
        size   = rel(0.85),
        colour = "black",
        margin = margin(t = 3, unit = "pt")
      ),
      plot.caption.position = "plot",

      # Margins
      plot.margin = margin(t = 5.5, r = 5.5, b = 5.5, l = 5.5, "mm"),

      # Complete the theme
      complete = TRUE
    )
}

# ---- Layout presets ----

#' Apply JAMA-style formatting
#'
#' Modifies a forest plot to match JAMA (Journal of the American
#' Medical Association) style conventions.
#'
#' @param p A ggplot object (typically from [ggforest()]).
#' @return A ggplot object with JAMA-style formatting applied.
#' @export
layout_jama <- function(p) {
  p +
    theme_forest(base_size = 10) +
    theme(
      text           = element_text(family = "serif"),
      plot.title     = element_text(face = "bold", size = rel(1.2)),
      panel.border   = element_rect(
        colour = "black", fill = NA, linewidth = 0.5
      ),
      panel.grid.major.y = element_blank()
    )
}

#' Apply BMJ-style formatting
#'
#' Modifies a forest plot to match BMJ (British Medical Journal)
#' style conventions.
#'
#' @param p A ggplot object (typically from [ggforest()]).
#' @return A ggplot object with BMJ-style formatting applied.
#' @export
layout_bmj <- function(p) {
  p +
    theme_forest(base_size = 9) +
    theme(
      text       = element_text(family = "sans"),
      axis.text.y = element_text(size = rel(0.8), hjust = 1, face = "bold"),
      panel.grid.major.y = element_blank(),
      legend.position = "right"
    )
}

#' Apply RevMan5-style formatting
#'
#' Modifies a forest plot to match Cochrane RevMan 5 style conventions.
#'
#' @param p A ggplot object (typically from [ggforest()]).
#' @return A ggplot object with RevMan5-style formatting applied.
#' @export
layout_revman5 <- function(p) {
  p +
    theme_forest(base_size = 9) +
    theme(
      axis.text.y     = element_text(size = rel(0.85), hjust = 1, face = "bold"),
      legend.position = "none",
      panel.grid.major.y = element_line(colour = "gray90", linewidth = 0.3)
    )
}
