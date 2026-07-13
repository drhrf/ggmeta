# Tests for restyling ggforest() graphical elements via the *_args parameters.

geom_names <- function(p) vapply(p$layers, function(l) class(l$geom)[1], "")

layer_params <- function(p, geom) {
  l <- p$layers[[which(geom_names(p) == geom)[1]]]
  c(l$stat_params, l$geom_params, l$aes_params)
}

test_that("predict_args restyles the built-in prediction interval", {
  skip_if_not_installed("meta")

  m <- meta::metagen(
    TE = c(0.3, 0.5, 0.4, 0.2), seTE = c(0.10, 0.20, 0.15, 0.12),
    studlab = paste0("S", 1:4), sm = "MD", prediction = TRUE
  )
  p  <- ggforest(m, predict_args = list(cap_width = 0.1, colour = "red"))
  pp <- layer_params(p, "GeomForestPredict")
  expect_equal(pp$cap_width, 0.1)
  expect_equal(pp$colour, "red")

  # The default is unchanged (regression guard).
  expect_equal(layer_params(ggforest(m), "GeomForestPredict")$cap_width, 0.32)
})

test_that("ci_args and ref_args are passed through", {
  skip_if_not_installed("meta")

  m <- meta::metabin(
    event.e = c(14, 30, 15, 22), n.e = c(100, 150, 100, 120),
    event.c = c(10, 25, 12, 18), n.c = c(100, 150, 100, 120),
    studlab = paste0("S", 1:4), sm = "RR"
  )
  p <- ggforest(m, ci_args = list(colour = "grey20"),
    ref_args = list(linetype = "dashed"))
  expect_equal(layer_params(p, "GeomForestCI")$colour, "grey20")
  # the first reference line (null) picks up the dashed linetype
  ref <- p$layers[[which(geom_names(p) == "GeomForestRef")[1]]]
  expect_equal(c(ref$stat_params, ref$geom_params, ref$aes_params)$linetype, "dashed")
})

test_that("consensus can be switched off", {
  skip_if_not_installed("meta")

  m <- meta::metabin(
    event.e = c(14, 30, 15, 22), n.e = c(100, 150, 100, 120),
    event.c = c(10, 25, 12, 18), n.c = c(100, 150, 100, 120),
    studlab = paste0("S", 1:4), sm = "RR"
  )
  expect_equal(sum(geom_names(ggforest(m)) == "GeomForestRef"), 2L)                # null + consensus
  expect_equal(sum(geom_names(ggforest(m, consensus = FALSE)) == "GeomForestRef"), 1L) # null only
})

test_that("diamond_colours overrides the summary palette", {
  skip_if_not_installed("meta")

  m <- meta::metabin(
    event.e = c(14, 30, 15, 22), n.e = c(100, 150, 100, 120),
    event.c = c(10, 25, 12, 18), n.c = c(100, 150, 100, 120),
    studlab = paste0("S", 1:4), sm = "RR"
  )
  p <- ggforest(m, diamond_colours = c(common = "black", random = "steelblue"))
  b <- ggplot2::ggplot_build(p)
  fills <- unique(unlist(lapply(b$data, function(d) {
    if ("fill" %in% names(d) && nrow(d) <= 12) d$fill
  })))
  expect_true("steelblue" %in% fills)      # random override applied
  expect_false("#BF5B3E" %in% fills)       # default terracotta replaced
})

test_that("restyling works with a constant diamond fill and with columns", {
  skip_if_not_installed("meta")

  m <- meta::metabin(
    event.e = c(14, 30, 15, 22), n.e = c(100, 150, 100, 120),
    event.c = c(10, 25, 12, 18), n.c = c(100, 150, 100, 120),
    studlab = paste0("S", 1:4), sm = "RR"
  )
  # constant fill drops the fill mapping (no scale needed) and still builds
  expect_no_error(ggplot2::ggplot_build(ggforest(m, diamond_args = list(fill = "grey50"))))
  # combining several arg lists, with columns, builds cleanly
  expect_no_error(ggplot2::ggplot_build(
    ggforest(m, columns = TRUE,
      predict_args = list(cap_width = 0.1),
      diamond_args = list(alpha = 1),
      ci_args = list(point_size_range = c(1, 5)))
  ))
})
