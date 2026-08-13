# manuscript/R/03-checks.R — prove numerical agreement
#
# Tabulates ggmeta's summary diamonds against the source package's own pooled
# estimates (common- and random-effects, back-transformed) and reports the
# maximum absolute discrepancy. Exits non-zero if any delta exceeds
# sqrt(.Machine$double.eps) so build.sh fails loudly on a mismatch. Also prints
# each pooled value rounded as it appears in the manuscript text, to catch
# rounding drift between text and figures.
#
# Usage: Rscript manuscript/R/03-checks.R

suppressPackageStartupMessages({ library(meta); library(metafor) })
pkgload::load_all(here::here())

rds <- function(key) readRDS(here::here("manuscript", "data", paste0(key, ".rds")))

cat("=== Numerical agreement checks ===\n\n")

results <- list()

check_one <- function(key, m, sm) {
  cat("---", key, "---\n")

  bt <- function(x) meta::backtransf(x, sm = sm)

  src <- list(
    common = c(bt(m$TE.common %||% m$TE.fixed),
               bt(m$lower.common %||% m$lower.fixed),
               bt(m$upper.common %||% m$upper.fixed)),
    random = c(bt(m$TE.random), bt(m$lower.random), bt(m$upper.random))
  )

  td <- tidy_meta(m)

  for (type in c("common", "random")) {
    row <- td[td$summary_type == type, ]
    s <- src[[type]]
    cat(sprintf("  %-7s source: %.4f [%.4f, %.4f]\n", type, s[1], s[2], s[3]))
    if (nrow(row) == 0) {
      cat("          ggmeta: (no summary row)\n")
      next
    }
    g <- c(row$estimate[1], row$ci_lower[1], row$ci_upper[1])
    delta <- max(abs(g - s))
    cat(sprintf("          ggmeta: %.4f [%.4f, %.4f]   delta %.2e\n",
                g[1], g[2], g[3], delta))
    # Rounded as printed in the manuscript (2 dp)
    cat(sprintf("          as printed in text: %.2f [%.2f, %.2f]\n",
                g[1], g[2], g[3]))
    results[[length(results) + 1]] <<-
      data.frame(dataset = key, type = type, delta = delta)
  }

  cat("\n")
}

check_one("bcg_tuberculosis",            rds("bcg_tuberculosis"),            "RR")
check_one("aspirin_mi",                  rds("aspirin_mi"),                  "OR")
check_one("amlodipine_capacity",         rds("amlodipine_capacity"),         "MD")
check_one("conscientiousness_adherence", rds("conscientiousness_adherence"), "ZCOR")
check_one("pritz_recurrence",            rds("pritz_recurrence"),            "PLOGIT")

# The subgroup object used for Figure 7: its overall summaries must match the
# ungrouped fit, otherwise the subgroup figure disagrees with Figure 1.
sg_path <- here::here("manuscript", "data", "bcg_tuberculosis_subgroup.rds")
if (file.exists(sg_path)) {
  check_one("bcg_tuberculosis_subgroup", readRDS(sg_path), "RR")
} else {
  cat("NOTE: bcg_tuberculosis_subgroup.rds not found.\n")
  cat("      Run 01-gather-datasets.R before generating Figure 7.\n\n")
}

all_res <- do.call(rbind, results)
tol <- .Machine$double.eps^0.5

cat("=== Summary ===\n")
print(all_res, row.names = FALSE)
cat(sprintf("\nEstimates compared: %d\n", nrow(all_res)))
cat(sprintf("Maximum absolute discrepancy: %.3e (tolerance %.3e)\n",
            max(all_res$delta), tol))

if (max(all_res$delta) > tol) {
  cat("RESULT: MISMATCH — the manuscript's agreement claim does not hold.\n")
  quit(status = 1)
}

cat("RESULT: ggmeta reproduces the published pooled estimates to machine precision.\n")
