# Tests for funnel plots: ggfunnel() and geom_funnel_contour().

test_that("ggfunnel builds a funnel from a meta object", {
  skip_if_not_installed("meta")

  m <- meta::metabin(
    event.e = c(12, 8, 25, 18, 30, 15), n.e = c(120, 90, 200, 150, 250, 130),
    event.c = c(20, 14, 30, 28, 35, 25), n.c = c(118, 92, 205, 148, 245, 128),
    studlab = paste0("S", 1:6), sm = "RR"
  )
  p <- ggfunnel(m)
  expect_s3_class(p, "ggplot")

  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_true(all(c("GeomPath", "GeomVline", "GeomPoint") %in% geoms))
  expect_no_error(ggplot2::ggplot_build(p))
})

test_that("ggfunnel accepts a data frame; bad input errors", {
  df <- data.frame(
    estimate = c(-0.5, -0.2, -0.4, 0.1),
    se = c(0.10, 0.30, 0.15, 0.35)
  )
  expect_s3_class(ggfunnel(df), "ggplot")
  expect_error(ggfunnel(data.frame(estimate = 1:3))) # no se column
  expect_error(ggfunnel(42))                         # not meta / data frame
})

test_that("geom_funnel_contour makes V-shaped paths centred at the apex", {
  p <- ggplot2::ggplot() +
    geom_funnel_contour(centre = 0.2, se_max = 0.4, level = c(0.95, 0.99))
  d <- ggplot2::ggplot_build(p)$data[[1]]

  expect_equal(nrow(d), 6L)                     # 3 points x 2 levels
  expect_equal(sort(unique(d$y)), c(0, 0.4))    # apex at se = 0, base at se_max
  expect_true(all(d$x[d$y == 0] == 0.2))        # both apexes at the centre
  # the 99% contour reaches further than the 95% contour at the base
  base_x <- d$x[d$y == 0.4]
  expect_gt(max(base_x) - 0.2, 1.96 * 0.4)
})

test_that("ggfunnel centres the reference line on the common-effect estimate", {
  skip_if_not_installed("meta")

  m <- meta::metagen(
    TE = c(-0.5, -0.2, -0.4, 0.1, -0.3),
    seTE = c(0.10, 0.30, 0.15, 0.35, 0.22), sm = "RR"
  )
  p <- ggfunnel(m)
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  vline <- p$layers[[which(geoms == "GeomVline")]]
  expect_equal(vline$data$xintercept, m$TE.common, tolerance = 1e-6)
})

test_that("ggfunnel plots on the analysis scale for both ratio and difference measures", {
  skip_if_not_installed("meta")

  rr <- meta::metagen(TE = c(-0.4, 0.1, -0.2), seTE = c(0.1, 0.3, 0.2), sm = "RR")
  md <- meta::metagen(TE = c(1.2, 0.4, 0.8), seTE = c(0.3, 0.5, 0.4), sm = "MD")
  expect_no_error(ggplot2::ggplot_build(ggfunnel(rr)))
  expect_no_error(ggplot2::ggplot_build(ggfunnel(md)))
})
