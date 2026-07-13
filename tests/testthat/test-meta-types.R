# Tests covering tidy_meta() across the range of meta object types, focusing on
# correct back-transformation, weight extraction, null-effect detection, and
# display ordering. These lock in fixes for single-group measures (proportions,
# rates) and correlations, which use non-exponential inverse transforms.

test_that("metaprop back-transforms to the raw proportion (event / n)", {
  skip_if_not_installed("meta")

  mp <- meta::metaprop(
    event = c(15, 20, 12, 25), n = c(50, 60, 55, 70),
    studlab = paste0("S", 1:4), sm = "PLOGIT"
  )
  td <- tidy_meta(mp)
  study <- td[!td$is_summary, ]

  # Study rows are kept in input order, so estimates line up with event / n.
  expect_equal(study$estimate, c(15, 20, 12, 25) / c(50, 60, 55, 70),
    tolerance = 1e-6
  )
  # A logit proportion must never be back-transformed with exp().
  expect_true(all(study$estimate > 0 & study$estimate < 1))
})

test_that("tidy_meta back-transforms each measure like meta::backtransf", {
  skip_if_not_installed("meta")

  objs <- list(
    metacor  = meta::metacor(cor = c(0.5, 0.6, 0.55), n = c(50, 60, 55),
      studlab = paste0("S", 1:3)),
    metainc  = meta::metainc(event.e = c(10, 12, 8), time.e = c(100, 120, 90),
      event.c = c(6, 7, 5), time.c = c(100, 120, 90),
      studlab = paste0("S", 1:3), sm = "IRR"),
    metaprop_pas = meta::metaprop(event = c(15, 20, 12), n = c(50, 60, 55),
      studlab = paste0("S", 1:3), sm = "PAS"),
    metarate = meta::metarate(event = c(10, 12, 8), time = c(100, 120, 90),
      studlab = paste0("S", 1:3), sm = "IRLN"),
    metamean = meta::metamean(n = c(50, 60, 55), mean = c(20, 22, 21),
      sd = c(5, 6, 5.5), studlab = paste0("S", 1:3))
  )

  for (nm in names(objs)) {
    m  <- objs[[nm]]
    td <- tidy_meta(m)
    study <- td[!td$is_summary, ]
    expect_equal(study$estimate, as.numeric(meta::backtransf(m$TE, sm = m$sm)),
      tolerance = 1e-6, info = nm
    )
    expect_true(all(is.finite(study$estimate) &
      is.finite(study$ci_lower) & is.finite(study$ci_upper)), info = nm)
  }
})

test_that("study weights are always finite (inverse-variance fallback)", {
  skip_if_not_installed("meta")

  # metaprop leaves w.common/w.random as all-NA; extraction must fall back to
  # inverse-variance weights so no study CI is dropped by the stat.
  mp <- meta::metaprop(event = c(15, 20, 12, 25), n = c(50, 60, 55, 70),
    studlab = paste0("S", 1:4), sm = "PLOGIT")
  study <- tidy_meta(mp)[!tidy_meta(mp)$is_summary, ]
  expect_true(all(is.finite(study$weight) & study$weight > 0))
})

test_that("null effect: NA for single proportions/rates, 1 for ratios, 0 else", {
  expect_true(is.na(detect_null_effect("PLOGIT")))
  expect_true(is.na(detect_null_effect("PAS")))
  expect_true(is.na(detect_null_effect("IRLN")))
  expect_equal(detect_null_effect("IRR"), 1)
  expect_equal(detect_null_effect("OR"), 1)
  expect_equal(detect_null_effect("ZCOR"), 0)
  expect_equal(detect_null_effect("MD"), 0)
})

test_that("back_trans = 'none' keeps values on the analysis scale", {
  skip_if_not_installed("meta")

  mp <- meta::metaprop(event = c(15, 20, 12), n = c(50, 60, 55),
    studlab = paste0("S", 1:3), sm = "PLOGIT")
  study <- tidy_meta(mp, back_trans = "none")
  study <- study[!study$is_summary, ]
  expect_equal(study$estimate, as.numeric(mp$TE), tolerance = 1e-8)
})

test_that("proportion plots omit the null reference line", {
  skip_if_not_installed("meta")

  mp <- meta::metaprop(event = c(15, 20, 12, 25), n = c(50, 60, 55, 70),
    studlab = paste0("S", 1:4), sm = "PLOGIT")
  p <- ggforest(mp)
  expect_s3_class(p, "ggplot")
  geoms <- vapply(p$layers, function(l) class(l$geom)[1], "")
  expect_false("GeomForestRef" %in% geoms)
})

test_that("studies render on top with the summary diamond at the bottom", {
  skip_if_not_installed("meta")

  mp <- meta::metaprop(event = c(15, 20, 12, 25), n = c(50, 60, 55, 70),
    studlab = paste("Study", LETTERS[1:4]), sm = "PLOGIT")
  td <- tidy_meta(mp)
  lv <- levels(td$studlab) # ggplot draws level 1 at the bottom, last at the top
  expect_false(td$is_summary[td$studlab == lv[length(lv)]][1]) # study on top
  expect_true(td$is_summary[td$studlab == lv[1]][1])           # summary at bottom
})

test_that("subgroups keep studies grouped under clean (unmarked) headers", {
  skip_if_not_installed("meta")

  d <- data.frame(
    event.e = c(14, 30, 15, 22, 9, 18), n.e = c(100, 150, 100, 120, 80, 110),
    event.c = c(10, 25, 12, 18, 11, 20), n.c = c(100, 150, 100, 120, 80, 110),
    study = paste("Study", LETTERS[1:6]),
    region = c("EU", "EU", "EU", "US", "US", "US")
  )
  m <- meta::metabin(event.e, n.e, event.c, n.c, data = d, studlab = study,
    sm = "RR", subgroup = region)
  td <- tidy_meta(m)

  # Headers are plain text, not markdown ("**EU**").
  headers <- as.character(td$studlab[td$summary_type == "subgroup_header"])
  expect_true(all(c("EU", "US") %in% headers))
  expect_false(any(grepl("\\*", as.character(td$studlab))))

  # Top-to-bottom display order groups each subgroup's studies under its header.
  lv <- rev(levels(td$studlab)) # top -> bottom
  pos <- function(lab) match(lab, lv) # vectorised position lookup
  eu_studies <- pos(paste("Study", c("A", "B", "C")))
  us_studies <- pos(paste("Study", c("D", "E", "F")))
  expect_true(pos("EU") < min(eu_studies))
  expect_true(max(eu_studies) < pos("US"))
  expect_true(pos("US") < min(us_studies))
})
