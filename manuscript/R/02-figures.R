# manuscript/R/02-figures.R — generates every figure in the manuscript
#
# Regenerates all seven figures (Figures 1-7) from the serialised meta objects
# written by 01-gather-datasets.R. Every figure written here is referenced in
# the manuscript, and every figure referenced in the manuscript is written here.
# Figure 7 (the subgroup forest) uses the stratified BCG object, not the plain
# one used for Figure 1.
#
# Usage: Rscript manuscript/R/02-figures.R

suppressPackageStartupMessages({ library(ggplot2); library(patchwork) })
pkgload::load_all(here::here())

fig <- here::here("manuscript", "figures")
dir.create(fig, showWarnings = FALSE, recursive = TRUE)

rds <- function(key) readRDS(here::here("manuscript", "data", paste0(key, ".rds")))

save_fig <- function(plot, file, w = 9, h = 5) {
  ggsave(file.path(fig, file), plot, width = w, height = h, device = cairo_pdf)
  cat("  ->", file, sprintf("(%.1f x %.1f in)\n", w, h))
}

m_bcg    <- rds("bcg_tuberculosis")
m_bcg_sg <- rds("bcg_tuberculosis_subgroup")
m_asp    <- rds("aspirin_mi")
m_aml    <- rds("amlodipine_capacity")
m_cor    <- rds("conscientiousness_adherence")
m_pr     <- rds("pritz_recurrence")

cat("Generating figures...\n")

# Fig 1 — binary RR forest with meta::forest()-style table columns.
# Caption promises: study CIs with weight-proportional squares, common-effect
# and random-effects diamonds, prediction interval, reference line at RR = 1,
# dotted line at the pooled estimate, and estimate/CI/weight columns.
save_fig(ggforest(m_bcg, columns = TRUE), "fig1-bcg-forest.pdf", 9, 5)

# Fig 2 — forest + funnel on one canvas (patchwork).
# The forest panel deliberately omits table columns: the caption describes only
# per-study and summary estimates, and columns would crowd the funnel panel.
save_fig((ggforest(m_bcg) | ggfunnel(m_bcg)) +
           plot_layout(widths = c(2, 1)) + plot_annotation(tag_levels = "A"),
         "fig2-bcg-forest-funnel.pdf", 11, 5)

# Fig 3 — continuous mean difference forest (8 studies, includes a negative
# point estimate: Protocol 162A, cited in Section 3.3).
save_fig(ggforest(m_aml, columns = TRUE), "fig3-amlodipine-forest.pdf", 9, 4.5)

# Fig 4 — correlation forest (Fisher-z analysis, back-transformed to r on the
# axis). 16 studies, so slightly taller than Fig 3.
save_fig(ggforest(m_cor, columns = TRUE), "fig4-correlation-forest.pdf", 9, 5.5)

# Fig 5 — the same 7-study analysis restyled for three journals.
save_fig(layout_jama(ggforest(m_asp, columns = TRUE)),    "fig5a-jama.pdf",    9, 4.5)
save_fig(layout_bmj(ggforest(m_asp, columns = TRUE)),     "fig5b-bmj.pdf",     9, 4.5)
save_fig(layout_revman5(ggforest(m_asp, columns = TRUE)), "fig5c-revman5.pdf", 9, 4.5)

# Fig 6 — single-group proportions (PLOGIT, inverse-logit back-transform,
# no null-effect reference line).
save_fig(ggforest(m_pr, columns = TRUE), "fig6-pritz-forest.pdf", 9, 5)

# Fig 7 — subgroup forest, BCG stratified by allocation method.
# Uses m_bcg_sg, NOT m_bcg. Taller than Fig 1 because subgroup headers and
# three pairs of within-subgroup diamonds add roughly nine extra rows.
save_fig(ggforest(m_bcg_sg, columns = TRUE), "fig7-bcg-subgroup.pdf", 9, 8)

cat("Figures written to", fig, "\n")
