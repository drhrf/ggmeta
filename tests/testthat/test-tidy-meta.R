test_that("tidy_meta works on metabin objects", {
  skip_if_not_installed("meta")

  m <- meta::metabin(event.e, n.e, event.c, n.c,
    data = data.frame(
      event.e = c(14, 30, 15, 22),
      n.e     = c(100, 150, 100, 120),
      event.c = c(10, 25, 12, 18),
      n.c     = c(100, 150, 100, 120)
    ),
    studlab = c("Study A", "Study B", "Study C", "Study D"),
    sm = "RR"
  )

  td <- tidy_meta(m)

  # Structure checks
  expect_s3_class(td, "data.frame")
  expect_true(all(c("studlab", "estimate", "ci_lower", "ci_upper",
                    "se", "weight", "p_value", "is_summary",
                    "summary_type", "subgroup") %in% names(td)))

  # Study count: 4 studies + 2 summaries (common, random) + 1 predict
  expect_true(nrow(td) >= 6)

  # Attributes
  expect_equal(attr(td, "sm"), "RR")
  expect_equal(attr(td, "null_effect"), 1)
  expect_equal(attr(td, "k"), 4)

  # Summaries should be at the end
  expect_true(all(td$is_summary[1:4] == FALSE))
})

test_that("tidy_meta handles back-transformation", {
  skip_if_not_installed("meta")

  m <- meta::metagen(TE = c(0.3, 0.5), seTE = c(0.1, 0.2),
    studlab = c("A", "B"), sm = "RR")

  td <- tidy_meta(m, back_trans = "auto")
  # RR auto back-transforms
  expect_true(all(td$estimate[1:2] > 0))
  expect_equal(td$estimate[1], exp(0.3), tolerance = 1e-10)

  td2 <- tidy_meta(m, back_trans = "none")
  expect_equal(td2$estimate[1], 0.3, tolerance = 1e-10)
})

test_that("tidy_meta handles prediction intervals", {
  skip_if_not_installed("meta")

  m <- meta::metagen(TE = c(0.3, 0.5, 0.4, 0.2),
    seTE = c(0.1, 0.2, 0.15, 0.12),
    studlab = c("A", "B", "C", "D"),
    sm = "MD",
    prediction = TRUE)

  td <- tidy_meta(m)
  predict_rows <- td[td$summary_type == "predict", ]
  expect_true(nrow(predict_rows) >= 1)
  expect_true(all(predict_rows$is_summary))
})

test_that("tidy_meta handles missing prediction interval gracefully", {
  skip_if_not_installed("meta")

  m <- meta::metagen(TE = c(0.3, 0.5), seTE = c(0.1, 0.2),
    studlab = c("A", "B"), sm = "MD",
    prediction = FALSE)

  td <- tidy_meta(m, add_predict = FALSE)
  predict_rows <- td[td$summary_type == "predict", ]
  expect_equal(nrow(predict_rows), 0)
})

test_that("tidy_meta.errors on non-meta objects", {
  expect_error(tidy_meta("not a meta object"))
  expect_error(tidy_meta(1:10))
})

test_that("tidy_meta.data.frame passes through valid data frames", {
  df <- data.frame(
    studlab = c("A", "B"),
    estimate = c(0.5, 0.3),
    ci_lower = c(0.2, 0.1),
    ci_upper = c(0.8, 0.5),
    stringsAsFactors = FALSE
  )
  td <- tidy_meta(df)
  expect_equal(nrow(td), 2)
  expect_true("is_summary" %in% names(td))
})
