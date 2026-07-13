# Test data
make_test_data <- function() {
  data.frame(
    x     = c(0.5, 0.8, 0.3),
    xmin  = c(0.2, 0.6, 0.1),
    xmax  = c(0.8, 1.0, 0.5),
    y     = factor(c("A", "B", "C"), levels = c("C", "B", "A")),
    weight = c(1, 4, 0.25),
    PANEL = factor(rep(1L, 3)),
    group = c(-1L, -1L, -1L),
    stringsAsFactors = FALSE
  )
}

test_that("StatForestCI computes weight-proportional sizes", {
  df <- make_test_data()
  result <- StatForestCI$compute_panel(df, list())

  expect_true("weight_sq" %in% names(result))
  expect_equal(length(result$weight_sq), 3)

  # Higher weight = larger square
  expect_true(result$weight_sq[2] >= result$weight_sq[1])
  expect_true(result$weight_sq[1] >= result$weight_sq[3])
})

test_that("StatForestCI handles zero-weight edge case", {
  df <- data.frame(
    x = 0.5, xmin = 0.2, xmax = 0.8,
    y = factor("A"), weight = 0,
    PANEL = factor(1L), group = -1L
  )
  result <- StatForestCI$compute_panel(df, list())
  expect_true("weight_sq" %in% names(result))
  expect_false(is.na(result$weight_sq[1]))
})

test_that("StatForestDiamond generates polygon coordinates", {
  df <- data.frame(
    x = 0.5, xmin = 0.3, xmax = 0.7,
    # Positional aesthetics reach a Stat as numerics (the discrete scale maps
    # factor levels to integer positions before compute_panel runs).
    y = 1, weight = NA,
    PANEL = factor(1L), group = 1001L
  )
  result <- StatForestDiamond$compute_panel(df, list(), diamond_height = 0.4)

  # Should have 5 rows (4 corners + closing)
  expect_equal(nrow(result), 5)
  expect_equal(result$x[1], df$xmin[1])  # left tip
  expect_equal(result$x[3], df$xmax[1])  # right tip
  expect_equal(result$x[c(1,5)], result$x[c(5,1)])  # polygon closed
})

test_that("geom_forest_predict defaults are visually subdued", {
  df <- data.frame(
    x = 0.5,
    xmin = 0.2,
    xmax = 0.8,
    y = "Prediction interval"
  )

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(x = x, xmin = xmin, xmax = xmax, y = y)
  ) +
    geom_forest_predict()
  built <- ggplot2::ggplot_build(p)

  expect_equal(built$data[[1]]$linewidth, 0.45)
  expect_equal(built$data[[1]]$alpha, 0.55)
  expect_equal(unique(built$data[[1]]$colour), "#6F9FBE")
})

test_that("geom_forest_predict uses compact caps by default", {
  layer <- geom_forest_predict()

  expect_equal(layer$geom_params$cap_width, 0.32)
})

test_that("StatForestRef computes full-height vertical line", {
  df <- data.frame(
    y = factor(c("A", "B", "C")),
    PANEL = factor(1L),
    group = -1L
  )
  result <- StatForestRef$compute_panel(df, list(), xintercept = 0)

  expect_equal(nrow(result), 1)
  expect_equal(result$x, 0)
  expect_equal(result$xend, 0)
  expect_true(result$y < result$yend)  # y < yend (spanning full range)
})
