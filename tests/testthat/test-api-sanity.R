test_that("exported plotting helpers compose on standalone data", {
  df <- data.frame(
    studlab = c("Study A", "Study B", "Study C"),
    estimate = c(0.80, 1.10, 1.35),
    ci_lower = c(0.55, 0.78, 0.90),
    ci_upper = c(1.18, 1.56, 2.03),
    se = c(0.20, 0.18, 0.24),
    weight = c(2.0, 3.0, 1.5),
    n = c(120, 150, 90)
  )
  attr(df, "sm") <- "RR"

  tidy_df <- tidy_meta(df, add_summary = TRUE)
  expect_true(any(tidy_df$is_summary))

  plot_data <- ggforest(
    tidy_df,
    null_effect = 1,
    columns = TRUE,
    effect_header = "RR"
  ) +
    geom_forest_text(
      ggplot2::aes(
        y = .data$studlab,
        label = format_effect(.data$estimate, .data$ci_lower, .data$ci_upper)
      ),
      data = tidy_df,
      x = 2.6,
      hjust = 0,
      size = 2.8
    )

  expect_s3_class(ggplot2::ggplot_build(plot_data), "ggplot_built")
  expect_s3_class(layout_jama(plot_data), "ggplot")
  expect_s3_class(layout_bmj(plot_data), "ggplot")
  expect_s3_class(layout_revman5(plot_data), "ggplot")
})

test_that("exported meta wrappers compose with ggplot2", {
  skip_if_not_installed("meta")

  m <- meta::metabin(
    event.e = c(14, 30, 15, 22),
    n.e = c(100, 150, 100, 120),
    event.c = c(10, 25, 12, 18),
    n.c = c(100, 150, 100, 120),
    studlab = c("Study A", "Study B", "Study C", "Study D"),
    sm = "RR"
  )

  tidy_m <- tidy_meta(m)
  fort_m <- ggplot2::fortify(m)
  plot_m <- ggforest(m, columns = TRUE)

  expect_s3_class(tidy_m, "ggmeta_tidy")
  expect_equal(nrow(fort_m), nrow(tidy_m))
  expect_s3_class(ggplot2::ggplot_build(plot_m), "ggplot_built")
})
