#' Create a forest plot
#'
#' The primary function for creating publication-quality forest plots.
#' Accepts a \pkg{meta} object (created by [meta::metabin()],
#' [meta::metacont()], etc.) or a tidy data frame (as returned by
#' [tidy_meta()] or constructed manually).
#'
#' @param x A \pkg{meta} object or a tidy data frame with columns
#'   `estimate`, `ci_lower`, `ci_upper`, `studlab`, and optionally
#'   `weight`, `is_summary`, `summary_type`, `subgroup`.
#' @param ... Additional arguments passed to methods.
#'
#' @return A `ggplot` object. Add standard ggplot2 layers (themes,
#'   scales, labels) to further customize.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(meta)
#' m <- metabin(event.e, n.e, event.c, n.c,
#'   data = data.frame(
#'     event.e = c(14, 30, 15, 22),
#'     n.e     = c(100, 150, 100, 120),
#'     event.c = c(10, 25, 12, 18),
#'     n.c     = c(100, 150, 100, 120)
#'   ),
#'   studlab = c("Study A", "Study B", "Study C", "Study D"),
#'   sm = "RR"
#' )
#' ggforest(m)
#' }
ggforest <- function(x, ...) {
  UseMethod("ggforest")
}

#' @export
#' @rdname ggforest
ggforest.default <- function(x, ...) {
  cli::cli_abort(
    c("{.arg x} must be a {.pkg meta} object or a tidy data frame.",
      i = "If you have a {.pkg meta} object, ensure the {.pkg meta} package is installed.",
      i = "If you have a data frame, ensure it has columns: estimate, ci_lower, ci_upper, studlab.")
  )
}

#' @export
#' @rdname ggforest
#'
#' @param back_trans Back-transform ratio measures? `"auto"` (default),
#'   `"exp"`, or `"none"`.
#' @param sort_studies Sort studies by effect estimate? Default: `TRUE`.
#' @param show_summary Include summary effect rows? Default: `TRUE`.
#' @param show_predict Include prediction interval? Default: `TRUE`
#'   (only when random effects model is present).
#' @param show_hetstats Show heterogeneity statistics in plot caption?
#'   Default: `TRUE`.
#' @param null_effect Null effect value for reference line.
#'   If `NULL` (default), auto-detected from the summary measure.
#' @param xlab X-axis label. If `NULL` (default), auto-generated from
#'   the summary measure.
ggforest.meta <- function(
  x,
  ...,
  back_trans = c("auto", "exp", "none"),
  sort_studies = TRUE,
  show_summary = TRUE,
  show_predict = TRUE,
  show_hetstats = TRUE,
  null_effect = NULL,
  xlab = NULL
) {
  # 1. Convert meta object to tidy data frame
  data <- tidy_meta(
    x,
    back_trans = back_trans,
    sort_studies = sort_studies,
    add_summary = show_summary,
    add_predict = show_predict,
    add_subgroups = TRUE
  )

  # 2. Determine null effect
  if (is.null(null_effect)) {
    null_effect <- attr(data, "null_effect") %||% 0
  }

  # 3. Determine x-axis label
  if (is.null(xlab)) {
    sm  <- attr(data, "sm")
    xlab <- default_effect_label(sm)
  }

  # 4. Build caption with heterogeneity stats if requested
  caption <- NULL
  if (show_hetstats) {
    caption <- build_hetstats_caption(x, attr(data, "random"))
  }

  # 5. Build the plot via the data.frame method
  p <- ggforest.data.frame(
    data,
    null_effect = null_effect,
    xlab = xlab,
    ...
  )

  # Add caption
  if (!is.null(caption)) {
    p <- p + labs(caption = caption)
  }

  p
}

#' @export
#' @rdname ggforest
#'
#' @param null_effect Null effect value for the reference line.
#'   Default: `0`.
#' @param xlab X-axis label. Default: `"Effect (95% CI)"`.
#' @param ylab Y-axis label. Default: `NULL` (no label — study labels
#'   serve as the y-axis text).
#' @param title Plot title. Default: `NULL`.
#' @param caption Plot caption. Default: `NULL`.
#' @param add_summary For the data-frame method, if `TRUE` compute a pooled
#'   summary from the study rows (inverse-variance and/or DerSimonian-Laird)
#'   and draw it as a diamond — on-the-fly meta-analysis without the
#'   \pkg{meta} package. Needs a `se` column, or `ci_lower`/`ci_upper` to
#'   recover it. Default: `FALSE`.
#' @param summary_method Which pooled summaries to add when `add_summary =
#'   TRUE`: `"common"`, `"random"`, or both (default).
#' @param level Confidence level for the pooled summary interval. Default
#'   `0.95`.
#' @param columns Add a `meta::forest()`-style table of text columns to the
#'   right of the plot. `TRUE` shows the effect estimate, 95% CI, and weight;
#'   or pass a subset/order such as `c("estimate", "ci")`. `NULL` (default)
#'   draws no columns.
#' @param effect_header Header for the estimate column (e.g. `"Hedges' g"`).
#'   Defaults to the summary measure (e.g. `"SMD"`, `"RR"`).
#' @param ci_args,diamond_args,predict_args Lists of arguments used to restyle
#'   the study confidence intervals ([geom_forest_ci()]), the summary diamonds
#'   ([geom_forest_diamond()]), and the prediction interval
#'   ([geom_forest_predict()]). For example
#'   `predict_args = list(cap_width = 0.1, colour = "red")` or
#'   `ci_args = list(colour = "grey20", point_size_range = c(1, 5))`. This is the
#'   way to customise these elements: adding another `geom_forest_*()` layer to a
#'   `ggforest()` plot draws a *second* layer over every row rather than
#'   restyling the built-in one.
#' @param diamond_colours Optional named colours for the summary diamonds,
#'   overriding the default palette. Names are `"common"`, `"random"`,
#'   `"subgroup_common"`, and `"subgroup_random"`, e.g.
#'   `c(common = "black", random = "steelblue")`.
#' @param ref_args,consensus_args Lists of arguments for the null-effect
#'   reference line and the dotted "consensus" line (both [geom_forest_ref()]),
#'   e.g. `ref_args = list(linetype = "dashed", colour = "black")`.
#' @param consensus Draw the dotted consensus line at the pooled estimate?
#'   Default `TRUE` (only shown alongside a null line).
ggforest.data.frame <- function(
  x,
  null_effect = 0,
  xlab = "Effect (95% CI)",
  ylab = NULL,
  title = NULL,
  caption = NULL,
  add_summary = FALSE,
  summary_method = c("common", "random"),
  level = 0.95,
  columns = NULL,
  effect_header = NULL,
  ci_args = list(),
  diamond_args = list(),
  diamond_colours = NULL,
  predict_args = list(),
  ref_args = list(),
  consensus = TRUE,
  consensus_args = list(),
  ...
) {
  # Capture the summary measure (used for the estimate-column header) before any
  # column assignments below can strip data-frame attributes.
  sm <- attr(x, "sm")

  # Validate required columns
  required_cols <- c("estimate", "ci_lower", "ci_upper", "studlab")
  missing_cols <- setdiff(required_cols, names(x))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "Data frame must contain columns: {.val {missing_cols}}"
    )
  }

  # Resolve the requested table columns.
  show_cols <- !is.null(columns) && !isFALSE(columns)
  if (show_cols) {
    if (isTRUE(columns)) columns <- c("estimate", "ci", "weight")
    columns <- intersect(columns, c("estimate", "ci", "weight"))
    show_cols <- length(columns) > 0
  }

  # Ensure optional columns exist (before any pooling / factor ordering).
  if (is.null(x$is_summary)) {
    x$is_summary <- FALSE
  }
  if (is.null(x$summary_type)) {
    x$summary_type <- ifelse(x$is_summary, "common", "none")
  }
  if (is.null(x$weight)) {
    x$weight <- NA_real_
  }

  # On-the-fly pooling: append computed summary rows from the study rows so
  # they render as a diamond at the bottom (via the factor ordering below).
  if (isTRUE(add_summary)) {
    # Give studies inverse-variance weights for square sizing if none supplied.
    if (all(is.na(x$weight))) {
      se_x <- x$se
      if (is.null(se_x) || all(is.na(se_x))) {
        se_x <- (x$ci_upper - x$ci_lower) / (2 * stats::qnorm(0.975))
      }
      x$weight <- ifelse(is.finite(se_x) & se_x > 0, 1 / se_x^2, NA_real_)
    }
    summ <- build_summary_rows(x, method = summary_method, level = level)
    if (!is.null(summ)) {
      for (col in setdiff(names(x), names(summ))) summ[[col]] <- NA
      x <- rbind(x, summ[names(x)])
    }
  }

  # Ensure studlab is a factor for proper ordering (studies on top, summary
  # rows -- which come last in row order -- at the bottom).
  if (!is.factor(x$studlab)) {
    x$studlab <- factor(x$studlab, levels = unique(rev(x$studlab)))
  }

  # Split data into study rows, summary rows, and prediction rows
  study_rows   <- x[!x$is_summary, , drop = FALSE]
  summary_rows <- x[x$is_summary & x$summary_type != "predict" &
                      x$summary_type != "subgroup_header", , drop = FALSE]
  predict_rows <- x[x$summary_type == "predict", , drop = FALSE]

  # ---- Build the ggplot ----
  p <- ggplot(x, aes(
    x     = .data$estimate,
    xmin  = .data$ci_lower,
    xmax  = .data$ci_upper,
    y     = .data$studlab,
    weight = .data$weight
  ))

  # Pin the y-axis order to the studlab factor levels. Layers are drawn from
  # row subsets, and without an explicit scale the discrete axis is trained
  # from whichever layer comes first; a plot without a reference line would
  # otherwise train from a study-only subset and invert the row order. When
  # table columns are shown, expand the top so their headers have room.
  p <- p + scale_y_discrete(
    limits = levels(x$studlab),
    expand = expansion(add = c(0.6, if (show_cols) 1.7 else 0.6))
  )

  # Reference line at the null effect: a solid vertical line (skipped when
  # there is no meaningful null, e.g. single-group proportions/rates).
  has_null <- !is.null(null_effect) && !is.na(null_effect)
  if (has_null) {
    p <- p + do.call(geom_forest_ref, utils::modifyList(
      list(xintercept = null_effect, linetype = "solid", colour = "grey30"),
      ref_args
    ))
  }

  # Dotted "consensus" line at the pooled estimate (random, else common), as in
  # meta::forest(), spanning the full height behind the studies. Only drawn
  # alongside a null line (two-group measures); single-group proportions/rates
  # stay free of reference lines.
  consensus_x <- {
    r  <- x$estimate[x$summary_type == "random"]
    c0 <- x$estimate[x$summary_type == "common"]
    if (length(r) && is.finite(r[1])) {
      r[1]
    } else if (length(c0) && is.finite(c0[1])) {
      c0[1]
    } else {
      NA_real_
    }
  }
  if (isTRUE(consensus) && has_null && is.finite(consensus_x)) {
    p <- p + do.call(geom_forest_ref, utils::modifyList(
      list(xintercept = consensus_x, linetype = "dotted", colour = "grey30"),
      consensus_args
    ))
  }

  # Study-level CIs (skip rows where estimate is NA, like subgroup headers)
  if (nrow(study_rows) > 0) {
    valid_studies <- study_rows[!is.na(study_rows$estimate), , drop = FALSE]
    if (nrow(valid_studies) > 0) {
      p <- p + do.call(geom_forest_ci, utils::modifyList(
        list(data = valid_studies), ci_args
      ))
    }
  }

  # Summary diamonds, in a modern terracotta / dark-blue palette, with
  # human-readable legend labels (the summary_type keys are e.g.
  # "subgroup_common").
  if (nrow(summary_rows) > 0) {
    # Fill is mapped to summary_type and coloured by the palette below. If the
    # caller sets a constant `fill` via diamond_args, drop the mapping + scale.
    use_fill_aes <- !("fill" %in% names(diamond_args))
    d_args <- list(data = summary_rows, alpha = 0.9)
    if (use_fill_aes) {
      d_args$mapping <- aes(fill = .data$summary_type)
    }
    p <- p + do.call(geom_forest_diamond, utils::modifyList(d_args, diamond_args))

    if (use_fill_aes) {
      fill_values <- c(
        common          = "#BF5B3E",
        random          = "#264B63",
        subgroup_common = "#D79A82",
        subgroup_random = "#7C9DB8"
      )
      if (!is.null(diamond_colours)) {
        fill_values[names(diamond_colours)] <- diamond_colours
      }
      p <- p + scale_fill_manual(
        values = fill_values,
        labels = c(
          common          = "Common effect",
          random          = "Random effects",
          subgroup_common = "Subgroup (common)",
          subgroup_random = "Subgroup (random)"
        )
      )
    }
  }

  # Prediction interval
  if (nrow(predict_rows) > 0) {
    p <- p + do.call(geom_forest_predict, utils::modifyList(
      list(data = predict_rows), predict_args
    ))
  }

  # Table columns (effect / CI / weight) to the right of the plot, plus the
  # log x-axis for ratio measures. When columns are shown the x-axis breaks are
  # limited to the data region and the panel is widened to hold the columns.
  log_scale <- has_null && null_effect == 1
  title_hjust <- 0.5
  if (show_cols) {
    spec <- forest_columns_spec(x, columns, sm, effect_header, log_scale)
    for (ly in spec$layers) p <- p + ly
    if (log_scale) {
      p <- p + scale_x_log10(breaks = spec$x_breaks)
    } else {
      p <- p + scale_x_continuous(breaks = spec$x_breaks)
    }
    p <- p + coord_cartesian(xlim = c(spec$xmin, spec$xmax), clip = "off")
    title_hjust <- spec$title_hjust
  } else if (log_scale) {
    p <- p + scale_x_log10()
  }

  # Labels and theme. The square size encodes study weight visually, but its
  # legend (raw point sizes in mm) is not meaningful to readers, so hide it.
  p <- p +
    labs(
      x       = xlab,
      y       = ylab,
      title   = title,
      caption = caption
    ) +
    guides(size = "none") +
    theme_forest()

  # With columns, tuck the x-axis title under the plot region (not the full
  # width, which now includes the table columns).
  if (show_cols) {
    p <- p + theme(axis.title.x = element_text(hjust = title_hjust))
  }

  p
}

# ---- Internal helpers for ggforest ----

#' Build the layers and x-range for a meta::forest()-style column table
#'
#' Places right-hand text columns (effect estimate, CI, weight) aligned with the
#' study rows, with headers above the top row. Positions are computed in the
#' plotting scale's space (log10 for ratio measures) so the columns line up on
#' both linear and log axes.
#' @noRd
forest_columns_spec <- function(x, columns, sm, effect_header, log_scale) {
  # Study weight percentages (over the real study rows only).
  is_study <- !x$is_summary & x$summary_type == "none"
  wsum <- sum(x$weight[is_study], na.rm = TRUE)
  wpct <- rep(NA_real_, nrow(x))
  if (is.finite(wsum) && wsum > 0) {
    wpct[is_study] <- x$weight[is_study] / wsum * 100
  }

  f2 <- function(v) formatC(v, format = "f", digits = 2)
  cells <- list(
    estimate = ifelse(is.na(x$estimate), "", f2(x$estimate)),
    ci = ifelse(
      is.na(x$ci_lower) | is.na(x$ci_upper), "",
      paste0("[", f2(x$ci_lower), ", ", f2(x$ci_upper), "]")
    ),
    weight = ifelse(
      is.na(wpct), "",
      paste0(formatC(wpct, format = "f", digits = 1), "%")
    )
  )
  headers <- c(
    estimate = effect_header %||% (sm %||% "Estimate"),
    ci = "95% CI",
    weight = "Weight"
  )

  # Data range on the natural scale, mapped into the plotting scale's space.
  vals <- c(x$ci_lower, x$ci_upper, x$estimate)
  vals <- vals[is.finite(vals)]
  rng <- range(vals)
  to_t   <- function(v) if (log_scale) log10(v) else v
  from_t <- function(t) if (log_scale) 10^t else t
  tlo   <- to_t(rng[1])
  thi   <- to_t(rng[2])
  tspan <- max(thi - tlo, .Machine$double.eps)

  gap <- tspan * 0.10
  column_widths <- c(
    estimate = 0.18,
    ci = 0.50,
    weight = 0.30
  ) * tspan
  right_pad <- tspan * 0.12

  # `tpos` is the right edge of each right-justified column. Wider text
  # columns get more space without pushing every column equally far away from
  # the forest plot.
  tpos <- thi + gap + cumsum(unname(column_widths[columns]))
  xpos <- from_t(tpos)
  xmin <- from_t(tlo - tspan * 0.04)
  xmax <- from_t(thi + gap + sum(column_widths[columns]) + right_pad)

  n_lev    <- nlevels(x$studlab)
  header_y <- n_lev + 0.7

  layers <- list()
  for (i in seq_along(columns)) {
    # Map `x` through aes (not a fixed layer param) so it is transformed by the
    # scale -- a constant x param is not log-transformed on ratio-measure axes.
    dfc <- data.frame(
      studlab = x$studlab, x = xpos[i], label = cells[[columns[i]]],
      stringsAsFactors = FALSE
    )
    layers[[length(layers) + 1]] <- geom_forest_text(
      aes(x = .data$x, y = .data$studlab, label = .data$label),
      data = dfc, hjust = 1, size = 3.1
    )
  }
  hdr <- data.frame(
    x = xpos, y = header_y, label = unname(headers[columns]),
    stringsAsFactors = FALSE
  )
  layers[[length(layers) + 1]] <- geom_forest_text(
    aes(x = .data$x, y = .data$y, label = .data$label),
    data = hdr, hjust = 1, size = 3.3, fontface = "bold"
  )

  # x-axis breaks restricted to the data region (no ticks under the columns).
  br <- if (log_scale) scales::breaks_log()(rng) else pretty(rng)
  br <- br[br >= rng[1] & br <= rng[2]]

  # Fractional position of the data-region centre within the widened panel, so
  # the x-axis title can be centred under the plot rather than the columns.
  panel_lo_t  <- tlo - tspan * 0.04
  panel_hi_t  <- thi + gap + sum(column_widths[columns]) + right_pad
  title_hjust <- ((tlo + thi) / 2 - panel_lo_t) / (panel_hi_t - panel_lo_t)

  list(
    layers = layers, x_breaks = br, xmin = xmin, xmax = xmax,
    title_hjust = title_hjust
  )
}

#' Build a plotmath caption with heterogeneity statistics
#'
#' Returns a plotmath expression (not a character string) so that the
#' superscripts and the Greek letter tau render portably across graphics
#' devices and locales. Embedding raw UTF-8 (e.g. `I\\U00B2`, `\\U03C4`) in
#' on-plot text triggers a `mbcsToSbcs` conversion failure on non-UTF-8
#' devices such as the default `pdf()` device used by `R CMD check`, which
#' causes rendering to error rather than merely warn.
#' @noRd
build_hetstats_caption <- function(x, is_random) {
  if (is.null(x$tau2) || !isTRUE(is_random)) {
    return(NULL)
  }

  i2   <- sprintf("%.0f", (x$I2 %||% NA_real_) * 100)
  tau2 <- sprintf("%.4f", x$tau2)

  if (!is.null(x$Q) && !is.null(x$pval.Q)) {
    q  <- sprintf("%.2f", x$Q)
    pq <- sprintf("%.3f", x$pval.Q)
    bquote(
      "Heterogeneity:" ~ italic(I)^2 ~ "=" ~ .(i2) * "%;" ~
        tau^2 ~ "=" ~ .(tau2) * ";" ~ italic(Q) ~ "=" ~ .(q) * "," ~
        italic(p) ~ "=" ~ .(pq)
    )
  } else {
    bquote(
      "Heterogeneity:" ~ italic(I)^2 ~ "=" ~ .(i2) * "%;" ~
        tau^2 ~ "=" ~ .(tau2)
    )
  }
}
