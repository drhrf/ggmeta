# Boundary conditions documented in the package manuscript. Each test pins
# down what happens (drawn, dropped, message, warning, error), so that the
# documentation stays true in later releases.

build_quietly <- function(p) {
  suppressWarnings(ggplot2::ggplot_build(p))
}
ci_layer <- function(p) {
  which(vapply(p$layers, function(l) inherits(l$geom, "GeomForestCI"), NA))
}

test_that("missing or non-positive weights fall back to the minimum square", {
  df <- data.frame(
    studlab = c("A", "B", "C", "D"),
    estimate = c(0.2, 0.4, 0.3, 0.5),
    ci_lower = c(0.1, 0.2, 0.1, 0.3),
    ci_upper = c(0.3, 0.6, 0.5, 0.7),
    weight = c(NA, 0, -1, 10)
  )
  p <- ggforest(df)
  expect_no_warning(ld <- ggplot2::layer_data(p, ci_layer(p)))
  expect_equal(nrow(ld), 4)
  expect_equal(ld$size[1:3], rep(1, 3))
  expect_equal(ld$size[4], 6)
})

test_that("a missing confidence limit drops that interval with a warning", {
  df <- data.frame(
    studlab = c("A", "B"), estimate = c(0.2, 0.4),
    ci_lower = c(0.1, NA), ci_upper = c(0.3, 0.6)
  )
  p <- ggforest(df)
  expect_warning(ld <- ggplot2::layer_data(p, ci_layer(p)), "Removed 1 row")
  expect_equal(nrow(ld), 1)
  # the study label stays on the axis
  b <- build_quietly(p)
  expect_true("B" %in% b$layout$panel_params[[1]]$y$get_labels())
})

test_that("a missing estimate keeps the label but draws no interval", {
  df <- data.frame(
    studlab = c("A", "B"), estimate = c(0.2, NA),
    ci_lower = c(0.1, NA), ci_upper = c(0.3, NA)
  )
  p <- ggforest(df)
  expect_no_warning(ld <- ggplot2::layer_data(p, ci_layer(p)))
  expect_equal(nrow(ld), 1)
  b <- build_quietly(p)
  expect_true("B" %in% b$layout$panel_params[[1]]$y$get_labels())
})

test_that("pooling a single study gives tau^2 = 0 and equal summaries", {
  pe <- pool_effects(0.3, 0.1)
  expect_equal(pe$tau2[2], 0)
  expect_equal(pe$estimate[1], pe$estimate[2])
})

test_that("no usable study means no summary diamond", {
  df <- data.frame(
    studlab = c("A", "B"), estimate = c(NA, 0.2),
    ci_lower = c(NA, 0.2), ci_upper = c(NA, 0.2)   # zero-width CI -> se = 0
  )
  expect_message(p <- ggforest(df, add_summary = TRUE), "Excluded 2 studies")
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_false("GeomForestDiamond" %in% geoms)
})

test_that("funnel plots omit unusable studies and fail when none remain", {
  df <- data.frame(estimate = c(0.1, 0.3, 0.2), se = c(0.1, 0, NA))
  expect_message(ggfunnel(df), "Omitted 2 studies")
  expect_error(
    suppressMessages(ggfunnel(data.frame(estimate = NA_real_, se = 0.1))),
    "No studies"
  )
})

test_that("single-group measures get no reference lines", {
  skip_if_not_installed("meta")
  m <- meta::metaprop(c(4, 9, 12), c(20, 30, 25), sm = "PLOGIT")
  p <- ggforest(m)
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_false("GeomForestRef" %in% geoms)
})

test_that("missing required columns raise an informative error", {
  expect_error(ggforest(data.frame(estimate = 1, ci_lower = 0, ci_upper = 2)),
    "studlab")
})

test_that("meta objects with non-contributing (double-zero) studies work", {
  skip_if_not_installed("meta")
  dz <- data.frame(
    ev.e = c(3, 0, 5, 7), n.e = c(40, 30, 50, 60),
    ev.c = c(6, 0, 9, 8), n.c = c(40, 30, 50, 60),
    study = c("A", "B", "C", "D")
  )
  m <- suppressWarnings(meta::metabin(ev.e, n.e, ev.c, n.c,
    studlab = study, data = dz, sm = "RR"))
  expect_lt(m$k, length(m$studlab))

  td <- tidy_meta(m)
  expect_equal(sum(!td$is_summary), 4)
  expect_true(is.na(td$estimate[td$studlab == "B"]))

  p <- ggforest(m, columns = TRUE)
  expect_no_warning(ld <- ggplot2::layer_data(p, ci_layer(p)))
  expect_equal(nrow(ld), 3)
  b <- build_quietly(p)
  expect_true("B" %in% b$layout$panel_params[[1]]$y$get_labels())
})
