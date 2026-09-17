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
