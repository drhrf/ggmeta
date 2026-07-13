# Tests for the meta::forest()-style text-column table added by ggforest(columns=).

collect_labels <- function(p) {
  built <- ggplot2::ggplot_build(p)
  unlist(lapply(built$data, function(d) {
    if ("label" %in% names(d)) as.character(d$label)
  }))
}

test_that("columns = TRUE adds effect / CI / weight cells and headers", {
  df <- data.frame(
    studlab  = c("A", "B", "C"),
    estimate = c(0.59, 1.45, 0.16),
    ci_lower = c(-0.27, 0.21, -1.08),
    ci_upper = c(1.44, 2.70, 1.40)
  )
  p <- ggforest(df, add_summary = TRUE, columns = TRUE,
    effect_header = "Hedges' g")
  expect_s3_class(p, "ggplot")

  labs <- collect_labels(p)
  expect_true("0.59" %in% labs)                        # an estimate cell
  expect_true(any(grepl("\\[-0.27, 1.44\\]", labs)))   # a CI cell
  expect_true(all(c("Hedges' g", "95% CI", "Weight") %in% labs)) # headers
  expect_true(any(grepl("%$", labs)))                  # a weight percentage
})

test_that("columns can be a chosen subset", {
  df <- data.frame(
    studlab = c("A", "B"), estimate = c(0.5, 0.3),
    ci_lower = c(0.2, 0.1), ci_upper = c(0.8, 0.5)
  )
  labs <- collect_labels(ggforest(df, columns = c("estimate", "ci")))
  expect_true("95% CI" %in% labs)
  expect_false("Weight" %in% labs) # weight column not requested
})

test_that("columns default to no table (unchanged behaviour)", {
  df <- data.frame(
    studlab = c("A", "B"), estimate = c(0.5, 0.3),
    ci_lower = c(0.2, 0.1), ci_upper = c(0.8, 0.5)
  )
  # No label-bearing layers when columns is NULL.
  expect_null(collect_labels(ggforest(df)))
})

test_that("columns render on a ratio (log) axis with weights from meta", {
  skip_if_not_installed("meta")

  m <- meta::metabin(
    event.e = c(14, 30, 15, 22), n.e = c(100, 150, 100, 120),
    event.c = c(10, 25, 12, 18), n.c = c(100, 150, 100, 120),
    studlab = paste0("S", 1:4), sm = "RR"
  )
  labs <- collect_labels(ggforest(m, columns = TRUE))
  expect_true("RR" %in% labs)               # header defaults to the measure
  expect_true(any(grepl("^[0-9]\\.[0-9]{2}$", labs))) # numeric estimate cells
  expect_true(any(grepl("%$", labs)))       # weight cells present on log axis
})

test_that("right-hand columns stay close to the forest plot", {
  df <- data.frame(
    studlab  = c("Study A", "Study B", "Study C", "Study D"),
    estimate = c(1.40, 1.20, 1.25, 1.22),
    ci_lower = c(0.65, 0.74, 0.62, 0.69),
    ci_upper = c(3.00, 1.94, 2.53, 2.16),
    weight   = c(15.4, 38.9, 18.0, 27.7)
  )
  attr(df, "sm") <- "RR"

  p <- ggforest(df, null_effect = 1, columns = TRUE)
  built <- ggplot2::ggplot_build(p)
  label_layers <- Filter(function(d) "label" %in% names(d), built$data)
  column_x <- lapply(label_layers, function(layer_data) layer_data$x) |>
    unlist() |>
    unique() |>
    sort()

  expect_lt(min(column_x), 0.75)
  expect_lt(max(column_x), 1.30)
})
