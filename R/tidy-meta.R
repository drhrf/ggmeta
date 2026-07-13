#' Tidy a 'meta' object into a plottable data frame
#'
#' Converts objects of class `meta` (from the \pkg{meta} package) into
#' a tidy data frame suitable for use with ggmeta geometries and
#' [ggforest()]. The returned data frame has one row per study or summary.
#'
#' @param x An object of class `meta`, e.g. created by
#'   [meta::metabin()], [meta::metacont()], or [meta::metagen()].
#' @param ... Additional arguments passed to methods.
#' @param back_trans Should the estimate and confidence limits be
#'   back-transformed to the natural scale? If `"auto"` (default), each summary
#'   measure is back-transformed with its correct inverse via
#'   [meta::backtransf()] (exponentiation for ratios, inverse-logit for
#'   `PLOGIT`, Fisher's z to correlation for `ZCOR`, etc.); linear measures are
#'   left unchanged. Use `"exp"` to force exponentiation or `"none"` to keep
#'   the analysis scale.
#' @param sort_studies If `TRUE` (default), sort studies by effect estimate
#'   (most favorable at top).
#' @param add_summary If `TRUE` (default), include fixed and/or random
#'   effects summary rows.
#' @param add_predict If `TRUE` (default), include prediction interval row
#'   when available.
#' @param add_subgroups If `TRUE` (default), include subgroup headers and
#'   within-group summary rows when subgroups are present.
#'
#' @return A `data.frame` with one row per study or summary, with columns:
#' \describe{
#'   \item{studlab}{Study label (character)}
#'   \item{estimate}{Point estimate (numeric)}
#'   \item{ci_lower}{Lower confidence limit (numeric)}
#'   \item{ci_upper}{Upper confidence limit (numeric)}
#'   \item{se}{Standard error (numeric)}
#'   \item{weight}{Study weight (numeric, \code{NA} for summaries)}
#'   \item{p_value}{P-value (numeric)}
#'   \item{n}{Sample size or person-time (numeric, optional)}
#'   \item{event}{Number of events (numeric, optional)}
#'   \item{is_summary}{Logical, \code{TRUE} for summary rows}
#'   \item{summary_type}{Character: \code{"none"}, \code{"common"},
#'     \code{"random"}, \code{"subgroup"}, or \code{"predict"}}
#'   \item{subgroup}{Subgroup label (character or \code{NA})}
#' }
#'
#' The returned data frame has the following attributes:
#' \describe{
#'   \item{\code{sm}}{summary measure type (e.g. \code{"RR"}, \code{"OR"}, \code{"MD"})}
#'   \item{\code{null_effect}}{null effect value for reference line}
#'   \item{\code{method}}{meta-analysis method}
#'   \item{\code{common}}{logical, TRUE if common effect model was used}
#'   \item{\code{random}}{logical, TRUE if random effects model was used}
#'   \item{\code{tau}}{heterogeneity estimate tau}
#'   \item{\code{k}}{number of studies}
#' }
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(meta)
#' m <- metabin(event.e, n.e, event.c, n.c,
#'   data = data.frame(
#'     event.e = c(14, 30), n.e = c(100, 150),
#'     event.c = c(10, 25), n.c = c(100, 150)
#'   ),
#'   studlab = c("Study A", "Study B"),
#'   sm = "RR"
#' )
#' tidy_meta(m)
#' }
tidy_meta <- function(x, ...) {
  UseMethod("tidy_meta")
}

#' @export
#' @rdname tidy_meta
tidy_meta.default <- function(x, ...) {
  cli::cli_abort(
    "{.arg x} must be a {.pkg meta} object, not {.cls {class(x)}}."
  )
}

#' @export
#' @rdname tidy_meta
#'
#' @param add_summary For the data-frame method, if `TRUE` compute an
#'   inverse-variance / DerSimonian-Laird pooled summary from the study rows
#'   and append it (on-the-fly meta-analysis, no \pkg{meta} package required).
#'   Needs a `se` column, or `ci_lower`/`ci_upper` to recover it. Default
#'   `FALSE`.
#' @param summary_method Which pooled summaries to add when `add_summary =
#'   TRUE`: `"common"`, `"random"`, or both (default).
#' @param level Confidence level for the pooled summary interval. Default
#'   `0.95`.
tidy_meta.data.frame <- function(x,
                                 add_summary = FALSE,
                                 summary_method = c("common", "random"),
                                 level = 0.95,
                                 ...) {
  # If already a data frame (from standalone usage), validate and pass through
  required <- c("estimate", "ci_lower", "ci_upper", "studlab")
  missing <- setdiff(required, names(x))
  if (length(missing) > 0) {
    cli::cli_abort(
      "Data frame must contain columns: {.val {missing}}"
    )
  }

  # Ensure expected columns exist
  if (is.null(x$is_summary))  x$is_summary  <- FALSE
  if (is.null(x$summary_type)) x$summary_type <- "none"
  if (is.null(x$subgroup))   x$subgroup    <- NA_character_
  if (is.null(x$se))         x$se          <- NA_real_
  if (is.null(x$weight))     x$weight      <- NA_real_
  if (is.null(x$p_value))    x$p_value     <- NA_real_

  # On-the-fly pooling: append summary rows computed from the study rows.
  if (isTRUE(add_summary)) {
    summ <- build_summary_rows(x, method = summary_method, level = level)
    if (!is.null(summ)) {
      # Carry any extra user columns onto the summary rows as NA before binding.
      for (col in setdiff(names(x), names(summ))) summ[[col]] <- NA
      x <- rbind(x, summ[names(x)])
    }
  }

  x
}

#' @export
#' @rdname tidy_meta
tidy_meta.meta <- function(x,
                           back_trans = c("auto", "exp", "none"),
                           sort_studies = TRUE,
                           add_summary = TRUE,
                           add_predict = TRUE,
                           add_subgroups = TRUE,
                           ...) {
  check_meta_installed()
  back_trans <- match.arg(back_trans)

  # Detect models and summary measure
  models <- detect_models(x)
  sm <- x$sm

  # ---- 1. Extract study-level data ----
  studies <- extract_studies(x, models)

  # ---- 2. Extract summary rows ----
  summaries <- if (add_summary) {
    extract_summaries(x, models)
  } else {
    NULL
  }

  # ---- 3. Extract prediction interval ----
  predicts <- if (add_predict && add_summary && models$random) {
    extract_predict(x)
  } else {
    NULL
  }

  # ---- 4. Handle subgroups ----
  has_subgroups <- !is.null(x$byvar) && add_subgroups
  if (has_subgroups) {
    result <- add_subgroup_structure(studies, summaries, predicts, x, models)
    studies   <- result$studies
    summaries <- result$summaries
    predicts  <- result$predicts
  }

  # ---- 5. Combine all rows ----
  # Row order is left as-is (studies, then overall summaries, then the
  # prediction interval; studies already interleaved under subgroup headers
  # when present) so the returned data frame stays stable for inspection.
  all_rows <- rbind(studies, summaries, predicts)

  # ---- 6. Set display order via factor levels ----
  # The plot order is carried entirely by the `studlab` factor levels, not by
  # row order. With subgroups we follow the interleaved block order so each
  # study stays under its header; otherwise, when `sort_studies` is TRUE, the
  # studies are ordered by effect estimate with the summaries kept below them.
  if (has_subgroups || !sort_studies) {
    lev <- unique(as.character(all_rows$studlab))
  } else {
    is_sum    <- all_rows$is_summary
    study_lab <- as.character(all_rows$studlab)[!is_sum]
    study_est <- all_rows$estimate[!is_sum]
    study_lab <- study_lab[order(study_est, decreasing = TRUE)]
    summ_lab  <- as.character(all_rows$studlab)[is_sum]
    lev <- unique(c(study_lab, summ_lab))
  }
  # ggplot2 draws the first factor level at the bottom of the panel, so reverse
  # to place the first display row at the top (conventional forest-plot layout,
  # with the summary diamond at the bottom).
  all_rows$studlab <- factor(all_rows$studlab, levels = rev(lev))

  # ---- 7. Back-transform to the natural scale ----
  # The Freeman-Tukey inverses (PFT, IRFT) need a per-row sample size /
  # person-time; align study rows by label and use the harmonic mean for
  # summary rows (matching how meta pools them). Other measures ignore these.
  n_row <- time_row <- NULL
  if (identical(sm, "PFT") && !is.null(x$n)) {
    hm  <- 1 / mean(1 / x$n, na.rm = TRUE)
    idx <- match(as.character(all_rows$studlab), as.character(x$studlab))
    n_row <- ifelse(is.na(idx), hm, x$n[idx])
  }
  if (identical(sm, "IRFT") && !is.null(x$time)) {
    hm  <- 1 / mean(1 / x$time, na.rm = TRUE)
    idx <- match(as.character(all_rows$studlab), as.character(x$studlab))
    time_row <- ifelse(is.na(idx), hm, x$time[idx])
  }
  all_rows <- back_transform(all_rows, sm, back_trans, n = n_row, time = time_row)

  # ---- 8. Set attributes ----
  attr(all_rows, "sm")    <- sm
  attr(all_rows, "null_effect") <- detect_null_effect(sm)
  attr(all_rows, "method")       <- x$method
  attr(all_rows, "common")       <- models$common
  attr(all_rows, "random")       <- models$random
  attr(all_rows, "tau")          <- x$tau
  attr(all_rows, "k")            <- x$k
  attr(all_rows, "I2")           <- x$I2
  attr(all_rows, "Q")            <- x$Q
  attr(all_rows, "pval.Q")       <- x$pval.Q

  # Return as plain data.frame (users can tibble::as_tibble() if desired)
  class(all_rows) <- c("ggmeta_tidy", "data.frame")
  all_rows
}

# ---- Internal extraction helpers ----

#' Extract study-level rows from a meta object
#' @noRd
extract_studies <- function(x, models) {
  k <- x$k
  if (is.null(k) || k == 0) {
    return(data.frame(
      studlab     = character(0),
      estimate    = numeric(0),
      ci_lower    = numeric(0),
      ci_upper    = numeric(0),
      se          = numeric(0),
      weight      = numeric(0),
      p_value     = numeric(0),
      is_summary  = logical(0),
      summary_type = character(0),
      subgroup    = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Study weights (used only for square sizing). meta stores per-study weights
  # in w.random / w.common / w.fixed, but some single-group types (e.g.
  # metaprop, metarate) leave these as an all-NA vector. Pick the first usable
  # numeric vector matching the fitted model, otherwise fall back to
  # inverse-variance weights derived from seTE.
  usable <- function(v) is.numeric(v) && length(v) == k && any(is.finite(v))
  w_candidates <- if (models$random) {
    list(x$w.random, x$w.common, x$w.fixed)
  } else {
    list(x$w.common, x$w.fixed, x$w.random)
  }
  w <- Find(usable, w_candidates)
  if (is.null(w) && is.numeric(x$seTE) && any(is.finite(x$seTE))) {
    w <- 1 / x$seTE^2
  }
  if (is.null(w)) {
    w <- rep(NA_real_, k)
  }

  # Use TE (common slot for all meta types)
  te    <- x$TE
  se_te <- x$seTE
  lower <- x$lower
  upper <- x$upper
  pval  <- x$pval

  # Ensure all are length k
  if (is.null(te))    te    <- rep(NA_real_, k)
  if (is.null(se_te)) se_te <- rep(NA_real_, k)
  if (is.null(lower)) lower <- rep(NA_real_, k)
  if (is.null(upper)) upper <- rep(NA_real_, k)
  if (is.null(pval))  pval  <- rep(NA_real_, k)
  if (is.null(w))     w     <- rep(NA_real_, k)

  subgroup <- if (!is.null(x$byvar)) {
    as.character(x$byvar)
  } else {
    rep(NA_character_, k)
  }

  data.frame(
    studlab      = as.character(x$studlab),
    estimate     = te,
    ci_lower     = lower,
    ci_upper     = upper,
    se           = se_te,
    weight       = w,
    p_value      = pval,
    is_summary   = FALSE,
    summary_type = "none",
    subgroup     = subgroup,
    stringsAsFactors = FALSE
  )
}

#' Extract summary rows (common + random effects) from a meta object
#' @noRd
extract_summaries <- function(x, models) {
  summaries <- list()

  # Common effect summary
  if (models$common) {
    te_common <- x$TE.common %||% x$TE.fixed
    summaries[["common"]] <- data.frame(
      studlab      = "Common effect",
      estimate     = te_common,
      ci_lower     = x$lower.common %||% x$lower.fixed,
      ci_upper     = x$upper.common %||% x$upper.fixed,
      se           = x$seTE.common %||% x$seTE.fixed,
      weight       = NA_real_,
      p_value      = x$pval.common %||% x$pval.fixed,
      is_summary   = TRUE,
      summary_type = "common",
      subgroup     = NA_character_,
      stringsAsFactors = FALSE
    )
  }

  # Random effects summary
  if (models$random) {
    summaries[["random"]] <- data.frame(
      studlab      = "Random effects",
      estimate     = x$TE.random,
      ci_lower     = x$lower.random,
      ci_upper     = x$upper.random,
      se           = x$seTE.random,
      weight       = NA_real_,
      p_value      = x$pval.random,
      is_summary   = TRUE,
      summary_type = "random",
      subgroup     = NA_character_,
      stringsAsFactors = FALSE
    )
  }

  if (length(summaries) == 0) return(NULL)
  do.call(rbind, summaries)
}

#' Extract prediction interval row
#' @noRd
extract_predict <- function(x) {
  if (is.null(x$lower.predict) || is.null(x$upper.predict)) return(NULL)
  if (all(is.na(x$lower.predict)) || all(is.na(x$upper.predict))) return(NULL)

  data.frame(
    studlab      = "Prediction interval",
    estimate     = x$TE.random %||% x$TE,
    ci_lower     = x$lower.predict,
    ci_upper     = x$upper.predict,
    se           = x$seTE.predict %||% NA_real_,
    weight       = NA_real_,
    p_value      = NA_real_,
    is_summary   = TRUE,
    summary_type = "predict",
    subgroup     = NA_character_,
    stringsAsFactors = FALSE
  )
}

#' Add subgroup structure: headers and within-group summaries
#' @noRd
add_subgroup_structure <- function(studies, summaries, predicts, x, models) {
  byvar  <- as.character(x$byvar)
  bylevs <- x$bylevs

  if (is.null(byvar) || is.null(bylevs)) {
    return(list(studies = studies, summaries = summaries, predicts = predicts))
  }

  # Assign subgroups to studies
  studies$subgroup <- byvar

  # Create subgroup header rows
  header_rows <- lapply(seq_along(bylevs), function(i) {
    data.frame(
      studlab      = as.character(bylevs[i]),
      estimate     = NA_real_,
      ci_lower     = NA_real_,
      ci_upper     = NA_real_,
      se           = NA_real_,
      weight       = NA_real_,
      p_value      = NA_real_,
      is_summary   = TRUE,
      summary_type = "subgroup_header",
      subgroup     = bylevs[i],
      stringsAsFactors = FALSE
    )
  })

  # Create within-group summary rows
  within_rows <- list()
  if (models$common && !is.null(x$TE.common.w)) {
    for (i in seq_along(bylevs)) {
      within_rows[[paste0("common_", i)]] <- data.frame(
        studlab      = paste0("  Common (", bylevs[i], ")"),
        estimate     = x$TE.common.w[i],
        ci_lower     = x$lower.common.w[i],
        ci_upper     = x$upper.common.w[i],
        se           = x$seTE.common.w[i] %||% NA_real_,
        weight       = NA_real_,
        p_value      = x$pval.common.w[i] %||% NA_real_,
        is_summary   = TRUE,
        summary_type = "subgroup_common",
        subgroup     = bylevs[i],
        stringsAsFactors = FALSE
      )
    }
  }
  if (models$random && !is.null(x$TE.random.w)) {
    for (i in seq_along(bylevs)) {
      within_rows[[paste0("random_", i)]] <- data.frame(
        studlab      = paste0("  Random (", bylevs[i], ")"),
        estimate     = x$TE.random.w[i],
        ci_lower     = x$lower.random.w[i],
        ci_upper     = x$upper.random.w[i],
        se           = x$seTE.random.w[i] %||% NA_real_,
        weight       = NA_real_,
        p_value      = x$pval.random.w[i] %||% NA_real_,
        is_summary   = TRUE,
        summary_type = "subgroup_random",
        subgroup     = bylevs[i],
        stringsAsFactors = FALSE
      )
    }
  }

  # Build the result: interleave headers, studies, and within-group summaries
  result_parts <- list()
  for (i in seq_along(bylevs)) {
    # Subgroup header
    result_parts[[length(result_parts) + 1]] <- header_rows[[i]]

    # Studies in this subgroup (preserve original order within subgroup)
    sub_studies <- studies[studies$subgroup == bylevs[i], , drop = FALSE]
    if (nrow(sub_studies) > 0) {
      result_parts[[length(result_parts) + 1]] <- sub_studies
    }

    # Within-group summaries
    wkey_common <- paste0("common_", i)
    wkey_random <- paste0("random_", i)
    if (wkey_common %in% names(within_rows)) {
      result_parts[[length(result_parts) + 1]] <- within_rows[[wkey_common]]
    }
    if (wkey_random %in% names(within_rows)) {
      result_parts[[length(result_parts) + 1]] <- within_rows[[wkey_random]]
    }
  }

  # Combine
  new_studies <- do.call(rbind, result_parts)

  # Overall summaries and prediction interval go at the very bottom
  list(
    studies   = new_studies,
    summaries = summaries,
    predicts  = predicts
  )
}
