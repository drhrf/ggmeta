test_that("ggforest works with meta objects", {
  skip_if_not_installed("meta")

  m <- meta::metagen(TE = c(0.3, 0.5, 0.4, 0.2),
    seTE = c(0.1, 0.2, 0.15, 0.12),
    studlab = c("A", "B", "C", "D"),
    sm = "MD")

  p <- ggforest(m)

  # Verify it is a ggplot object
  expect_s3_class(p, "ggplot")

  # Verify layers are present
  expect_true(length(p$layers) >= 3)  # ref + CI + diamond at minimum

  # Check layer types
  geom_classes <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_true("GeomForestRef" %in% geom_classes)
  expect_true("GeomForestCI" %in% geom_classes)
  expect_true("GeomForestDiamond" %in% geom_classes)
})

test_that("ggforest works with data frames", {
  df <- data.frame(
    studlab = c("Study X", "Study Y", "Summary"),
    estimate = c(0.5, 0.3, 0.4),
    ci_lower = c(0.2, 0.1, 0.25),
    ci_upper = c(0.8, 0.5, 0.55),
    weight = c(5, 3, NA),
    is_summary = c(FALSE, FALSE, TRUE),
    summary_type = c("none", "none", "common"),
    stringsAsFactors = FALSE
  )

  p <- ggforest(df)
  expect_s3_class(p, "ggplot")
  expect_true(length(p$layers) >= 2)  # ref + CI + diamond
})

test_that("ggforest errors on invalid input", {
  expect_error(ggforest("not valid"))
  expect_error(ggforest(42))
})

test_that("ggforest errors on data frame missing required columns", {
  bad_df <- data.frame(x = 1:3, y = 4:6)
  expect_error(ggforest(bad_df))
})

test_that("theme_forest returns a complete theme", {
  th <- theme_forest()
  expect_s3_class(th, "theme")
  expect_s3_class(th, "gg")
  expect_true(attr(th, "complete"))

  axis_text_y <- ggplot2::calc_element("axis.text.y", th)
  expect_equal(axis_text_y$face, "bold")

  caption <- ggplot2::calc_element("plot.caption", th)
  expect_equal(caption$hjust, 0.5)
})

test_that("layout presets are plottable", {
  df <- data.frame(
    studlab = c("Study X", "Study Y"),
    estimate = c(0.5, 0.3),
    ci_lower = c(0.2, 0.1),
    ci_upper = c(0.8, 0.5),
    weight = c(5, 3),
    is_summary = c(FALSE, FALSE),
    summary_type = c("none", "none"),
    stringsAsFactors = FALSE
  )

  p <- ggforest(df)

  expect_s3_class(layout_jama(p), "ggplot")
  expect_s3_class(layout_bmj(p), "ggplot")
  expect_s3_class(layout_revman5(p), "ggplot")
})

test_that("layout presets keep study labels bold", {
  df <- data.frame(
    studlab = c("Study X", "Study Y"),
    estimate = c(0.5, 0.3),
    ci_lower = c(0.2, 0.1),
    ci_upper = c(0.8, 0.5),
    stringsAsFactors = FALSE
  )
  p <- ggforest(df)
  layouts <- list(layout_jama(p), layout_bmj(p), layout_revman5(p))
  y_faces <- vapply(layouts, function(plot) {
    ggplot2::calc_element("axis.text.y", plot$theme)$face
  }, character(1))

  expect_true(all(y_faces == "bold"))
})

test_that("ggforest.data.frame handles missing optional columns", {
  # Minimal data: only required columns
  df <- data.frame(
    studlab = c("A", "B"),
    estimate = c(0.5, 0.3),
    ci_lower = c(0.2, 0.1),
    ci_upper = c(0.8, 0.5),
    stringsAsFactors = FALSE
  )
  p <- ggforest(df)
  expect_s3_class(p, "ggplot")
})

test_that("reference lines sit in the axis's transformed space on a log axis", {
  skip_if_not_installed("meta")

  m <- meta::metabin(
    event.e = c(14, 30, 15, 22), n.e = c(100, 150, 100, 120),
    event.c = c(10, 25, 12, 18), n.c = c(100, 150, 100, 120),
    studlab = paste0("S", 1:4), sm = "RR"
  )
  b <- ggplot2::ggplot_build(ggforest(m))
  geoms <- vapply(b$plot$layers, function(l) class(l$geom)[1], "")
  ref_x <- unlist(lapply(which(geoms == "GeomForestRef"),
    function(i) unique(b$data[[i]]$x)))

  # Null RR = 1 must map to log10(1) = 0, not to raw x = 1 (which would render
  # at RR = 10). Both null and consensus lines stay near the data.
  expect_true(any(abs(ref_x) < 1e-8))
  expect_true(all(ref_x < 0.5))
})
