# Tests for the plotmath heterogeneity caption built by ggforest.meta().

test_that("format_pval_label() never prints p = 0.000", {
  expect_equal(format_pval_label(1e-10), "< 0.001")
  expect_equal(format_pval_label(0.0004), "< 0.001")
  expect_equal(format_pval_label(0.001), "= 0.001")
  expect_equal(format_pval_label(0.09), "= 0.090")
  expect_equal(format_pval_label(NA_real_), "= NA")
})

test_that("the caption shows p < 0.001 for strong heterogeneity", {
  skip_if_not_installed("meta")
  m <- meta::metagen(
    TE = c(-1.6, -0.2, 0.3, -1.4, 0.1, -0.9),
    seTE = c(0.10, 0.08, 0.09, 0.12, 0.05, 0.11),
    sm = "RR", method.tau = "DL"
  )
  expect_lt(m$pval.Q, 0.001)
  cap <- paste(deparse(ggforest(m)$labels$caption), collapse = "")
  expect_match(cap, "< 0.001", fixed = TRUE)
  expect_false(grepl("0.000", cap, fixed = TRUE))
})

test_that("the caption reports the Wald test for a GLMM fit", {
  skip_if_not_installed("meta")
  skip_if_not_installed("lme4")

  # A GLMM stores Q, df.Q and pval.Q as a (Wald, LRT) pair. Passing the pair
  # straight through printed "Q = c(25.10, 42.23)" and "p = NA"; meta::forest()
  # keeps the first element of each, which is the Wald test.
  m <- suppressWarnings(meta::metaprop(
    event = c(16, 10, 4, 43, 25, 13), n = c(17, 12, 8, 58, 42, 14),
    studlab = paste0("S", 1:6), sm = "PLOGIT"
  ))
  skip_if_not(any(m$method == "GLMM"))
  skip_if_not(length(unlist(m$Q)) > 1)

  wald <- sprintf("%.2f", unlist(m$Q)[[1]])
  lrt  <- sprintf("%.2f", unlist(m$Q)[[2]])
  skip_if_not(wald != lrt)

  cap <- paste(deparse(ggforest(m)$labels$caption), collapse = "")
  expect_false(grepl("NA", cap, fixed = TRUE))
  expect_match(cap, wald, fixed = TRUE)
  expect_false(grepl(lrt, cap, fixed = TRUE))    # the LRT statistic is not used
  expect_match(cap, format_pval_label(unlist(m$pval.Q)[[1]]), fixed = TRUE)
})

test_that("format_pval_label() stays strict about length", {
  # The element is chosen by the caption builder, not by the formatter.
  expect_equal(format_pval_label(c(0.02, 0.0001)), "= NA")
})
