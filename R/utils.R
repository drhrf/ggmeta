# Internal utility functions for ggmeta

# Check if meta package is installed, with informative error
check_meta_installed <- function() {
  if (!requireNamespace("meta", quietly = TRUE)) {
    cli::cli_abort(
      c("The {.pkg meta} package is required to convert {.cls meta} objects.",
        i = "Install it with: {.code install.packages(\"meta\")}",
        i = "Or supply a tidy data frame directly to {.fun ggforest}."))
  }
}

# Detect whether to use common effect (preferred in meta >= 8.0)
# or fixed effect (legacy) terminology
use_common <- function(x) {
  !is.null(x$common) && isTRUE(x$common)
}

use_random <- function(x) {
  !is.null(x$random) && isTRUE(x$random)
}

# Detect which effect models are present
detect_models <- function(x) {
  common <- use_common(x)
  random <- use_random(x)
  if (!common && !is.null(x$comb.fixed)) common <- isTRUE(x$comb.fixed)
  if (!random && !is.null(x$comb.random)) random <- isTRUE(x$comb.random)
  list(common = common, random = random)
}

# Ratio measures compared on the log scale (null effect at 1).
.ratio_measures  <- c("RR", "OR", "HR", "IRR", "DOR", "ROM")
# Single-group proportion measures (no two-group "null effect").
.prop_measures   <- c("PLOGIT", "PLN", "PAS", "PFT", "PRAW")
# Single-group rate measures (no two-group "null effect").
.rate_measures   <- c("IR", "IRLN", "IRS", "IRFT")

#' Detect the null effect value from the summary measure
#'
#' @param sm Summary measure string (e.g. "RR", "OR", "MD")
#' @return Null effect value: `1` for ratio measures, `0` for difference and
#'   correlation measures, and `NA` for single-group proportions/rates (which
#'   have no meaningful null-effect reference line).
#' @noRd
detect_null_effect <- function(sm) {
  if (is.null(sm)) return(0)
  if (sm %in% .ratio_measures) return(1)
  if (sm %in% c(.prop_measures, .rate_measures)) return(NA_real_)
  # Differences (MD, SMD, RD), correlations (ZCOR, COR), raw means: null at 0.
  0
}

#' Back-transform effect estimates to the natural scale
#'
#' Delegates to [meta::backtransf()] so every summary measure is
#' back-transformed with the correct inverse: exponentiation for ratios (RR,
#' OR, HR, IRR), inverse-logit for `PLOGIT`, arcsine/Freeman-Tukey inverses for
#' `PAS`/`PFT`, Fisher's z to correlation for `ZCOR`, and so on. Linear measures
#' (MD, SMD, RD, raw means) are returned unchanged.
#'
#' @param data Data frame with columns estimate, ci_lower, ci_upper.
#' @param sm Summary measure.
#' @param back_trans `"auto"` (measure-appropriate inverse via
#'   [meta::backtransf()]), `"exp"` (force exponentiation), or `"none"` (leave
#'   on the analysis scale).
#' @param n,time Optional per-row sample size / person-time, used only for the
#'   Freeman-Tukey measures (`PFT`, `IRFT`) that require them.
#' @return Data frame with back-transformed values.
#' @noRd
back_transform <- function(data, sm, back_trans = c("auto", "exp", "none"),
                           n = NULL, time = NULL) {
  back_trans <- match.arg(back_trans)
  if (back_trans == "none" || is.null(sm)) return(data)

  cols <- intersect(c("estimate", "ci_lower", "ci_upper"), names(data))

  if (back_trans == "exp") {
    for (col in cols) data[[col]] <- exp(data[[col]])
    return(data)
  }

  # back_trans == "auto": use meta's own back-transformation.
  if (!requireNamespace("meta", quietly = TRUE)) return(data)

  # n / time are only consumed by the Freeman-Tukey inverses.
  extra <- list()
  if (identical(sm, "PFT")  && !is.null(n))    extra$n    <- n
  if (identical(sm, "IRFT") && !is.null(time)) extra$time <- time

  for (col in cols) {
    data[[col]] <- tryCatch(
      do.call(meta::backtransf, c(list(x = data[[col]], sm = sm), extra)),
      error = function(e) data[[col]]
    )
  }
  data
}

#' Default effect label from summary measure
#' @noRd
default_effect_label <- function(sm) {
  if (is.null(sm)) return("Effect (95% CI)")
  if (sm %in% c("ZCOR", "COR"))   return("Correlation (95% CI)")
  if (sm %in% .prop_measures)     return("Proportion (95% CI)")
  if (sm %in% .rate_measures)     return("Rate (95% CI)")
  switch(sm,
    RR  = "Risk Ratio (95% CI)",
    OR  = "Odds Ratio (95% CI)",
    HR  = "Hazard Ratio (95% CI)",
    IRR = "Incidence Rate Ratio (95% CI)",
    ROM = "Ratio of Means (95% CI)",
    MD  = "Mean Difference (95% CI)",
    SMD = "Standardized Mean Difference (95% CI)",
    RD  = "Risk Difference (95% CI)",
    ASD = "Arcsine Difference (95% CI)",
    paste0(sm, " (95% CI)")
  )
}

#' Inverse-variance pooling of study effects
#'
#' Computes a fixed-effect (inverse-variance) and/or random-effects
#' (DerSimonian-Laird) summary from per-study effects and standard errors.
#' This is the engine behind on-the-fly meta-analysis of a tidy data frame,
#' so a pooled summary can be added without the \pkg{meta} package.
#'
#' @param te Numeric vector of study effect estimates (analysis scale).
#' @param se Numeric vector of study standard errors (same length as `te`).
#' @param method Character vector: any of `"common"` and `"random"`.
#' @param level Confidence level for the summary interval.
#' @return A data frame with one row per requested method and columns
#'   `summary_type`, `estimate`, `ci_lower`, `ci_upper`, `se`, `tau2`, or
#'   `NULL` if there are no usable studies. Rows follow the order of `method`.
#' @noRd
pool_effects <- function(te, se, method = c("common", "random"), level = 0.95) {
  method <- match.arg(method, c("common", "random"), several.ok = TRUE)
  ok <- is.finite(te) & is.finite(se) & se > 0
  te <- te[ok]
  se <- se[ok]
  k  <- length(te)
  if (k < 1) return(NULL)

  w    <- 1 / se^2
  te_c <- sum(w * te) / sum(w)
  se_c <- sqrt(1 / sum(w))

  # DerSimonian-Laird between-study variance
  Q    <- sum(w * (te - te_c)^2)
  C    <- sum(w) - sum(w^2) / sum(w)
  tau2 <- if (k > 1 && C > 0) max(0, (Q - (k - 1)) / C) else 0
  wr   <- 1 / (se^2 + tau2)
  te_r <- sum(wr * te) / sum(wr)
  se_r <- sqrt(1 / sum(wr))

  z <- stats::qnorm(1 - (1 - level) / 2)
  rows <- list(
    common = data.frame(
      summary_type = "common", estimate = te_c,
      ci_lower = te_c - z * se_c, ci_upper = te_c + z * se_c,
      se = se_c, tau2 = 0, stringsAsFactors = FALSE
    ),
    random = data.frame(
      summary_type = "random", estimate = te_r,
      ci_lower = te_r - z * se_r, ci_upper = te_r + z * se_r,
      se = se_r, tau2 = tau2, stringsAsFactors = FALSE
    )
  )
  do.call(rbind, rows[method])
}

#' Build tidy summary rows by pooling the study rows of a tidy data frame
#'
#' @param df A tidy data frame with `estimate` and either `se` or
#'   `ci_lower`/`ci_upper` columns; only non-summary rows are pooled.
#' @param method,level Passed to `pool_effects()`.
#' @param log_scale If `TRUE` (ratio measures), `estimate`, `ci_lower` and
#'   `ci_upper` are on the natural (ratio) scale: they are log-transformed
#'   before pooling, a supplied `se` is taken to be the standard error of the
#'   log estimate, and the pooled estimate and limits are exponentiated back.
#' @return A data frame of summary rows matching the tidy layout, or `NULL`.
#' @noRd
build_summary_rows <- function(df, method = c("common", "random"), level = 0.95,
                               log_scale = FALSE) {
  is_sum <- if (!is.null(df$is_summary)) df$is_summary else rep(FALSE, nrow(df))
  study  <- df[!is_sum, , drop = FALSE]
  if (nrow(study) == 0) return(NULL)

  te <- to_pooling_scale(study$estimate, log_scale)

  # Standard errors: use `se` when supplied, else recover from the 95% CI
  # (on the pooling scale, i.e. log limits for ratio measures).
  se <- study$se
  if (is.null(se) || all(is.na(se))) {
    se <- se_from_ci(study$ci_lower, study$ci_upper, log_scale)
  }

  ok <- is.finite(te) & is.finite(se) & se > 0
  n_drop <- sum(!ok)
  if (n_drop > 0) {
    cli::cli_inform(c(
      "i" = "Excluded {n_drop} stud{?y/ies} from the pooled summary: missing or non-finite estimate, or standard error not positive."
    ))
  }

  pooled <- pool_effects(te, se, method = method, level = level)
  if (is.null(pooled)) return(NULL)
  if (log_scale) {
    for (v in c("estimate", "ci_lower", "ci_upper")) {
      pooled[[v]] <- exp(pooled[[v]])
    }
  }

  labels <- c(common = "Common effect", random = "Random effects")
  data.frame(
    studlab      = unname(labels[pooled$summary_type]),
    estimate     = pooled$estimate,
    ci_lower     = pooled$ci_lower,
    ci_upper     = pooled$ci_upper,
    se           = pooled$se,
    weight       = NA_real_,
    p_value      = NA_real_,
    is_summary   = TRUE,
    summary_type = pooled$summary_type,
    subgroup     = NA_character_,
    stringsAsFactors = FALSE
  )
}

#' Map effects to the pooling scale (log for ratio measures)
#'
#' Non-positive values on a ratio scale become `NaN` (and are then excluded
#' from pooling) without an R warning.
#' @noRd
to_pooling_scale <- function(v, log_scale = FALSE) {
  if (!log_scale) return(v)
  out <- rep(NaN, length(v))
  pos <- !is.na(v) & v > 0
  out[pos] <- log(v[pos])
  out[is.na(v)] <- NA_real_
  out
}

#' Recover a standard error from a 95% confidence interval
#'
#' Assumes a symmetric Wald interval on the pooling scale:
#' `se = (upper - lower) / (2 * qnorm(0.975))`, with log limits for ratio
#' measures.
#' @noRd
se_from_ci <- function(lower, upper, log_scale = FALSE) {
  (to_pooling_scale(upper, log_scale) - to_pooling_scale(lower, log_scale)) /
    (2 * stats::qnorm(0.975))
}
