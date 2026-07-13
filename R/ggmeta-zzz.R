# Package startup and teardown hooks

.onLoad <- function(libname, pkgname) {
  # Nothing to do at load time.
  # S3 method registration is handled via NAMESPACE (importFrom + S3method).
}

.onUnload <- function(libpath) {
  # No cleanup needed
}

# Global variables used in tidy evaluation to avoid R CMD check NOTES
utils::globalVariables(c(
  ".data", ".env",
  "estimate", "ci_lower", "ci_upper", "studlab",
  "weight", "se", "p_value", "is_summary",
  "summary_type", "subgroup", ".meta_rownum"
))
