# Tests for the aligned text-column geom and the effect-formatting helper.

test_that("format_effect renders estimate and CI, blanking NA", {
  out <- format_effect(c(1.4, 0.9), c(0.65, 0.6), c(3.0, 1.35))
  expect_equal(out, c("1.40 (0.65 to 3.00)", "0.90 (0.60 to 1.35)"))

  # digits and separator are configurable
  expect_equal(
    format_effect(1.234, 1.0, 1.5, digits = 1, sep = ", "),
    "1.2 (1.0, 1.5)"
  )
  # NA estimate -> empty string (so the summary/header rows stay blank)
  expect_equal(format_effect(NA, 1, 2), "")
})

test_that("geom_forest_text builds a text layer that does not inherit x aes", {
  layer <- geom_forest_text(ggplot2::aes(y = study, label = n), x = 1.1)
  expect_s3_class(layer, "LayerInstance")
  expect_equal(class(layer$geom)[1], "GeomText")
  expect_false(layer$inherit.aes)
  expect_equal(layer$aes_params$x, 1.1)
})

test_that("a forest plot with text columns builds without error", {
  df <- data.frame(
    study = c("A", "B", "C"),
    estimate = c(0.5, 0.8, 0.3),
    lower = c(0.2, 0.6, 0.1),
    upper = c(0.8, 1.0, 0.5),
    n = c(120, 240, 90)
  )
  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(y = study, x = estimate, xmin = lower, xmax = upper)
  ) +
    geom_forest_ci() +
    geom_forest_text(ggplot2::aes(y = study, label = n), x = 1.15) +
    ggplot2::expand_limits(x = 1.25)

  built <- ggplot2::ggplot_build(p)
  # Find the text layer by its `label` column (expand_limits() also adds an
  # invisible geom_blank layer, so it is not simply the last one).
  text_layer <- Filter(function(d) "label" %in% names(d), built$data)[[1]]
  expect_true(all(c("120", "240", "90") %in% as.character(text_layer$label)))
})
