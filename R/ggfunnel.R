#' Funnel plot from a meta-analysis
#'
#' `ggfunnel()` draws a funnel plot: each study's effect estimate against its
#' standard error (a measure of precision), with pseudo confidence-interval
#' contours around the pooled effect. Asymmetry can signal small-study effects
#' or publication bias. Like [ggforest()], it accepts a \pkg{meta} object or a
#' tidy data frame and returns an ordinary `ggplot`, so a forest and a funnel
#' plot compose on one canvas with, for example, \pkg{patchwork}.
#'
#' @param x A \pkg{meta} object, or a data frame with `estimate` and `se`
#'   columns (study effects and standard errors on the analysis scale).
#' @param ... Additional arguments passed to methods.
#'
#' @return A `ggplot` object.
#' @export
#'
#' @examples
#' \donttest{
#' library(meta)
#' m <- metabin(event.e, n.e, event.c, n.c,
#'   data = data.frame(
#'     event.e = c(12, 8, 25, 18, 30, 15), n.e = c(120, 90, 200, 150, 250, 130),
#'     event.c = c(20, 14, 30, 28, 35, 25), n.c = c(118, 92, 205, 148, 245, 128)
#'   ),
#'   studlab = paste("Study", 1:6), sm = "RR"
#' )
#' ggfunnel(m)
#' }
ggfunnel <- function(x, ...) {
  UseMethod("ggfunnel")
}

#' @export
#' @rdname ggfunnel
ggfunnel.default <- function(x, ...) {
  cli::cli_abort(c(
    "{.arg x} must be a {.pkg meta} object or a data frame.",
    i = "For a data frame, supply {.field estimate} and {.field se} columns on the analysis scale."
  ))
}

#' @export
#' @rdname ggfunnel
#'
#' @param ref Which pooled estimate to centre the funnel on: `"common"` (fixed
#'   effect, default) or `"random"`.
#' @param level Confidence level(s) for the funnel contours, e.g. `0.95` or
#'   `c(0.95, 0.99)`. Default `0.95`.
ggfunnel.meta <- function(x, ..., ref = c("common", "random"), level = 0.95) {
  check_meta_installed()
  ref <- match.arg(ref)

  te <- x$TE
  se <- x$seTE
  keep <- is.finite(te) & is.finite(se) & se > 0
  df <- data.frame(
    studlab  = as.character(x$studlab)[keep],
    estimate = te[keep],
    se       = se[keep],
    stringsAsFactors = FALSE
  )
  centre <- switch(ref,
    common = x$TE.common %||% x$TE.fixed %||% x$TE.random,
    random = x$TE.random %||% x$TE.common
  )
  ggfunnel.data.frame(df, centre = centre, sm = x$sm, level = level, ...)
}

#' @export
#' @rdname ggfunnel
#'
#' @param centre Effect the funnel is centred on. Defaults to the
#'   inverse-variance (common-effect) estimate of the supplied studies.
#' @param sm Summary measure (e.g. `"RR"`, `"PLOGIT"`), used to label the x-axis
#'   and, for transformed measures (ratios, proportions, rates, correlations),
#'   to show back-transformed axis labels. Optional.
#' @param xlab,ylab Axis labels. `ylab` defaults to `"Standard error"`.
#' @param title Plot title. Default `NULL`.
ggfunnel.data.frame <- function(x,
                                centre = NULL,
                                sm = NULL,
                                level = 0.95,
                                xlab = NULL,
                                ylab = "Standard error",
                                title = NULL,
                                ...) {
  if (is.null(sm)) sm <- attr(x, "sm")

  missing_cols <- setdiff(c("estimate", "se"), names(x))
  if (length(missing_cols) > 0) {
    cli::cli_abort("Data frame must contain columns: {.val {missing_cols}}")
  }

  d <- x[is.finite(x$estimate) & is.finite(x$se) & x$se > 0, , drop = FALSE]
  if (nrow(d) == 0) {
    cli::cli_abort(
      "No studies with a finite {.field estimate} and positive {.field se}."
    )
  }

  if (is.null(centre)) {
    pe <- pool_effects(d$estimate, d$se, method = "common")
    centre <- if (!is.null(pe)) {
      pe$estimate[1L]
    } else {
      stats::weighted.mean(d$estimate, 1 / d$se^2)
    }
  }

  z_max  <- stats::qnorm(1 - (1 - max(level)) / 2)
  se_max <- max(d$se, na.rm = TRUE) * 1.15
  if (is.null(xlab)) {
    xlab <- if (!is.null(sm)) default_effect_label(sm) else "Effect estimate"
  }

  p <- ggplot(d, aes(x = .data$estimate, y = .data$se)) +
    geom_funnel_contour(centre = centre, se_max = se_max, level = level) +
    geom_vline(xintercept = centre, colour = "grey30", linewidth = 0.5) +
    geom_point(
      shape = 21, fill = "#264B63", colour = "white",
      size = 2.6, stroke = 0.6, alpha = 0.9
    ) +
    scale_y_reverse() +
    labs(x = xlab, y = ylab, title = title) +
    theme_funnel()

  # Transformed measures (ratios, proportions, rates, correlations) are analysed
  # on a transformed scale; keep the funnel straight by plotting on that scale
  # but labelling the axis with back-transformed values.
  sc <- funnel_x_scale(
    sm, c(centre - z_max * se_max, centre + z_max * se_max),
    x_obs = d$estimate
  )
  if (!is.null(sc)) {
    p <- p + scale_x_continuous(breaks = sc$breaks, labels = sc$labels)
  }

  p
}

#' Back-transformed x-axis breaks for a funnel plot
#'
#' For a transformed summary measure, picks nice breaks in the natural
#' (back-transformed) space and maps them to analysis-scale positions via
#' [meta::backtransf()], so a funnel plotted on the analysis scale shows readable
#' axis labels (risk ratios, proportions, rates, correlations). Returns `NULL`
#' for linear measures (MD, SMD, RD, raw means) and when `meta` is unavailable.
#' @noRd
funnel_x_scale <- function(sm, rng, x_obs = numeric(0)) {
  if (is.null(sm)) return(NULL)
  transformed <- c(.ratio_measures, .prop_measures, .rate_measures, "ZCOR")
  if (!(sm %in% transformed) || !requireNamespace("meta", quietly = TRUE)) {
    return(NULL)
  }

  rng <- range(c(rng, x_obs), na.rm = TRUE)
  grid_a <- seq(rng[1], rng[2], length.out = 512L)
  grid_o <- suppressWarnings(meta::backtransf(grid_a, sm = sm))
  ok <- is.finite(grid_a) & is.finite(grid_o)
  grid_a <- grid_a[ok]
  grid_o <- grid_o[ok]
  if (length(grid_o) < 2L || diff(range(grid_o)) <= 0) return(NULL)

  o_range  <- range(grid_o)
  log_like <- sm %in% c(.ratio_measures, .rate_measures)
  breaks_o <- if (log_like) scales::breaks_log()(o_range) else pretty(o_range)
  breaks_o <- breaks_o[breaks_o >= o_range[1] & breaks_o <= o_range[2]]
  if (length(breaks_o) < 2L) return(NULL)

  breaks_a <- suppressWarnings(stats::approx(grid_o, grid_a, xout = breaks_o)$y)
  keep <- is.finite(breaks_a)
  if (sum(keep) < 2L) return(NULL)
  list(breaks = breaks_a[keep], labels = breaks_o[keep])
}

#' Funnel plot theme
#'
#' A light ggplot2 theme for [ggfunnel()] plots.
#'
#' @param base_size Base font size in pts. Default `11`.
#' @param base_family Base font family. Default `""`.
#'
#' @return A ggplot2 theme.
#' @export
#'
#' @examples
#' library(ggplot2)
#' df <- data.frame(estimate = c(-0.3, 0.1, -0.2), se = c(0.1, 0.3, 0.2))
#' ggplot(df, aes(estimate, se)) +
#'   geom_point() +
#'   scale_y_reverse() +
#'   theme_funnel()
theme_funnel <- function(base_size = 11, base_family = "") {
  theme_minimal(base_size = base_size, base_family = base_family) %+replace%
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = "grey92", linewidth = 0.3),
      axis.text  = element_text(colour = "black"),
      axis.ticks = element_line(colour = "grey75"),
      axis.title = element_text(colour = "black"),
      plot.title = element_text(face = "bold", size = rel(1.05), hjust = 0),
      legend.position = "bottom",
      complete = TRUE
    )
}
