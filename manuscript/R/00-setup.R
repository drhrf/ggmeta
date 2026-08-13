# manuscript/R/00-setup.R — install/load ggmeta + dependencies
#
# Run once before the other scripts. In practice the packages should already
# be installed; this script confirms availability and loads ggmeta from source.
#
# Usage: Rscript manuscript/R/00-setup.R

cat("=== ggmeta PoC setup ===\n")

# Check required packages
required <- c("meta", "metafor", "ggplot2", "rlang", "scales", "cli",
              "patchwork", "here", "pkgload")

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Package '", pkg, "' is not installed. Run:\n",
         'install.packages("', pkg, '", repos = "https://cloud.r-project.org")')
  }
}

cat("All required packages available.\n")
cat("meta:", as.character(packageVersion("meta")), "\n")
cat("metafor:", as.character(packageVersion("metafor")), "\n")
cat("ggplot2:", as.character(packageVersion("ggplot2")), "\n")
cat("patchwork:", as.character(packageVersion("patchwork")), "\n")

cat("\nSetup complete. Ready to gather datasets and generate figures.\n")
