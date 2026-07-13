#' Fortify a 'meta' object for use with 'ggplot2'
#'
#' This S3 method for [ggplot2::fortify()] converts \pkg{meta} objects to
#' a tidy data frame. It is a wrapper around [tidy_meta()].
#'
#' @param model An object of class `meta`.
#' @param data Ignored. Included for S3 generic compatibility.
#' @param ... Additional arguments passed to [tidy_meta()].
#'
#' @return A `data.frame` as returned by [tidy_meta()].
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(meta)
#' library(ggplot2)
#' m <- metabin(event.e, n.e, event.c, n.c,
#'   data = data.frame(
#'     event.e = c(14, 30), n.e = c(100, 150),
#'     event.c = c(10, 25), n.c = c(100, 150)
#'   ),
#'   studlab = c("Study A", "Study B"),
#'   sm = "RR"
#' )
#' library(ggmeta)
#' ggplot(fortify(m), aes(x = estimate, y = studlab)) +
#'   geom_point()
#' }
fortify.meta <- function(model, data, ...) {
  tidy_meta(model, ...)
}
