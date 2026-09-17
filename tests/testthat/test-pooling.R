# Tests for on-the-fly inverse-variance / DerSimonian-Laird pooling of a tidy
# data frame (add_summary), which lets users draw a summary diamond without the
# meta package. Correctness is anchored against meta::metagen.

test_that("pool_effects matches meta::metagen (common and DL random)", {
  skip_if_not_installed("meta")

  te <- c(0.1, 0.9, 0.3, 1.2, -0.2)
  se <- c(0.15, 0.18, 0.12, 0.25, 0.14)
  pe <- pool_effects(te, se, method = c("common", "random"))
  m  <- meta::metagen(TE = te, seTE = se, sm = "MD", method.tau = "DL")

  # common effect
  expect_equal(pe$estimate[1], m$TE.common, tolerance = 1e-8)
  expect_equal(pe$ci_lower[1], m$lower.common, tolerance = 1e-6)
  expect_equal(pe$ci_upper[1], m$upper.common, tolerance = 1e-6)
  # random effect + between-study variance
  expect_equal(pe$estimate[2], m$TE.random, tolerance = 1e-8)
  expect_equal(pe$tau2[2], m$tau2, tolerance = 1e-6)
  expect_equal(pe$ci_lower[2], m$lower.random, tolerance = 1e-6)
  expect_equal(pe$ci_upper[2], m$upper.random, tolerance = 1e-6)
})

test_that("pool_effects honours the method argument and needs >= 1 study", {
  pe <- pool_effects(c(0.2, 0.4), c(0.1, 0.2), method = "common")
  expect_equal(nrow(pe), 1)
  expect_equal(pe$summary_type, "common")

  expect_null(pool_effects(numeric(0), numeric(0)))
  # non-finite / non-positive se are dropped
  expect_null(pool_effects(c(0.2, NA), c(0, NA)))
})

test_that("tidy_meta(add_summary) appends common + random summary rows", {
  df <- data.frame(
    studlab = paste("Study", LETTERS[1:4]),
    estimate = c(0.30, 0.50, 0.40, 0.20),
    ci_lower = c(0.10, 0.11, 0.11, -0.04),
    ci_upper = c(0.50, 0.89, 0.69, 0.44),
    se = c(0.10, 0.20, 0.15, 0.12)
  )
  td <- tidy_meta(df, add_summary = TRUE)
  expect_equal(nrow(td), 6)
  expect_equal(sum(td$is_summary), 2)
  expect_setequal(td$summary_type[td$is_summary], c("common", "random"))
})

test_that("se is recovered from the CI when no se column is present", {
  # With no se column, se is inferred from the 95% CI half-width.
  df <- data.frame(
    studlab = c("A", "B", "C"),
    estimate = c(0.2, 0.5, 0.3),
    ci_lower = c(0.0, 0.3, 0.1),
    ci_upper = c(0.4, 0.7, 0.5)
  )
  td <- tidy_meta(df, add_summary = TRUE, summary_method = "common")
  summ <- td[td$is_summary, ]
  expect_equal(nrow(summ), 1)

  # Compare to pooling with se derived the same way.
  se <- (df$ci_upper - df$ci_lower) / (2 * stats::qnorm(0.975))
  expect_equal(summ$estimate, pool_effects(df$estimate, se, "common")$estimate,
    tolerance = 1e-8)
})

test_that("ggforest(df, add_summary = TRUE) draws a summary diamond", {
  df <- data.frame(
    studlab = paste("Study", LETTERS[1:4]),
    estimate = c(0.30, 0.50, 0.40, 0.20),
    ci_lower = c(0.10, 0.11, 0.11, -0.04),
    ci_upper = c(0.50, 0.89, 0.69, 0.44),
    se = c(0.10, 0.20, 0.15, 0.12)
  )
  p <- ggforest(df, add_summary = TRUE)
  expect_s3_class(p, "ggplot")
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_true("GeomForestDiamond" %in% geoms)

  # The plotted data gained the two pooled summary rows.
  built <- ggplot2::ggplot_build(p)$plot$data
  expect_equal(sum(built$is_summary), 2)
})

test_that("ratio measures are pooled on the log scale (null_effect = 1)", {
  skip_if_not_installed("meta")

  lte <- c(-0.9, -1.6, -1.4, -0.2, -0.3, -1.6, -0.5)
  lse <- c(0.57, 0.44, 0.15, 0.11, 0.22, 0.24, 0.06)
  z   <- stats::qnorm(0.975)
  m   <- meta::metagen(TE = lte, seTE = lse, sm = "RR", method.tau = "DL")

  df <- data.frame(
    studlab  = paste("Study", seq_along(lte)),
    estimate = exp(lte),
    ci_lower = exp(lte - z * lse),
    ci_upper = exp(lte + z * lse)
  )

  # data-frame method of tidy_meta()
  td   <- tidy_meta(df, add_summary = TRUE, log_scale = TRUE)
  summ <- td[td$is_summary, ]
  expect_equal(summ$estimate[summ$summary_type == "common"], exp(m$TE.common),
    tolerance = 1e-8)
  expect_equal(summ$estimate[summ$summary_type == "random"], exp(m$TE.random),
    tolerance = 1e-8)
  expect_equal(summ$ci_lower[summ$summary_type == "random"], exp(m$lower.random),
    tolerance = 1e-6)
  expect_equal(summ$ci_upper[summ$summary_type == "random"], exp(m$upper.random),
    tolerance = 1e-6)

  # ggforest() pools on the log scale when null_effect = 1
  p <- ggforest(df, add_summary = TRUE, null_effect = 1)
  built <- ggplot2::ggplot_build(p)$plot$data
  est <- built$estimate[built$is_summary & built$summary_type == "common"]
  expect_equal(est, exp(m$TE.common), tolerance = 1e-8)

  # a supplied se is read as the SE of the log estimate
  df$se <- lse
  td2 <- tidy_meta(df, add_summary = TRUE, log_scale = TRUE,
    summary_method = "random")
  expect_equal(td2$estimate[td2$is_summary], exp(m$TE.random), tolerance = 1e-8)
})

test_that("difference measures are still pooled on the natural scale", {
  df <- data.frame(
    studlab  = c("A", "B", "C"),
    estimate = c(0.2, 0.5, 0.3),
    ci_lower = c(0.0, 0.3, 0.1),
    ci_upper = c(0.4, 0.7, 0.5)
  )
  p <- ggforest(df, add_summary = TRUE, summary_method = "common")
  built <- ggplot2::ggplot_build(p)$plot$data
  se <- (df$ci_upper - df$ci_lower) / (2 * stats::qnorm(0.975))
  expect_equal(built$estimate[built$is_summary],
    pool_effects(df$estimate, se, "common")$estimate, tolerance = 1e-10)
})

test_that("studies excluded from pooling are reported", {
  df <- data.frame(
    studlab  = c("A", "B", "C"),
    estimate = c(0.2, NA, 0.4),
    ci_lower = c(0.1, NA, 0.1),
    ci_upper = c(0.3, NA, 0.7)
  )
  expect_message(tidy_meta(df, add_summary = TRUE), "Excluded 1 study")

  # non-positive values cannot be pooled on the log scale
  df2 <- data.frame(
    studlab  = c("A", "B", "C"),
    estimate = c(0.8, 0, 1.2),
    ci_lower = c(0.6, 0, 0.9),
    ci_upper = c(1.1, 0.5, 1.6)
  )
  expect_message(td <- tidy_meta(df2, add_summary = TRUE, log_scale = TRUE),
    "Excluded 1 study")
  expect_equal(sum(td$is_summary), 2)

  # nothing to report when every study is usable
  df3 <- df2[-2, ]
  expect_no_message(tidy_meta(df3, add_summary = TRUE, log_scale = TRUE))
})
