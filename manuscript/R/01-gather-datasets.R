# manuscript/R/01-gather-datasets.R — reproducible PoC dataset extraction
#
# Reads the five source datasets from meta and metafor, builds the meta
# objects, and exports for each:
#   - raw CSV (verbatim source dataset)
#   - tidy CSV (ggmeta's tidy_meta() output)
#   - .rds  (the serialised meta object, reloaded by 02-figures.R / 03-checks.R)
#
# A sixth object, bcg_tuberculosis_subgroup, is the BCG analysis stratified by
# allocation method; it backs the subgroup forest (Figure 7).
#
# Usage: Rscript manuscript/R/01-gather-datasets.R

library(meta)
library(metadat)                 # source of dat.bcg, dat.molloy2014, dat.pritz1997
pkgload::load_all(here::here())  # load ggmeta from source

base <- here::here("manuscript", "data")
for (d in c("raw", "tidy")) dir.create(file.path(base, d), recursive = TRUE, showWarnings = FALSE)

save_poc <- function(key, raw, m) {
  write.csv(raw, file.path(base, "raw",  paste0(key, ".csv")), row.names = FALSE)
  td <- tidy_meta(m)
  td$sm <- attr(td, "sm")  # CSV can't hold the attribute
  write.csv(td,  file.path(base, "tidy", paste0(key, ".csv")), row.names = FALSE)
  saveRDS(m,     file.path(base, paste0(key, ".rds")))
  invisible(td)
}

# 1. BCG tuberculosis — binary RR (dat.bcg, metafor)
data("dat.bcg", package = "metadat")
cat("dat.bcg columns:", paste(names(dat.bcg), collapse = ", "), "\n")
m_bcg <- metabin(tpos, tpos + tneg, cpos, cpos + cneg,
                 studlab = paste(author, year), data = dat.bcg, sm = "RR")
save_poc("bcg_tuberculosis", dat.bcg, m_bcg)
cat("  bcg_tuberculosis: saved\n")

# 1b. Same analysis, stratified by allocation method — used for Figure 7.
# dat.bcg$alloc has three levels: alternate, random, systematic.
m_bcg_sg <- metabin(tpos, tpos + tneg, cpos, cpos + cneg,
                    studlab = paste(author, year), data = dat.bcg, sm = "RR",
                    subgroup = dat.bcg$alloc, subgroup.name = "Allocation")
save_poc("bcg_tuberculosis_subgroup", dat.bcg, m_bcg_sg)
cat("  bcg_tuberculosis_subgroup: saved (subgroups:",
    paste(levels(factor(dat.bcg$alloc)), collapse = ", "), ")\n")

# 2. Aspirin for death after MI — binary OR (Fleiss1993bin, meta)
data("Fleiss1993bin", package = "meta")
cat("Fleiss1993bin columns:", paste(names(Fleiss1993bin), collapse = ", "), "\n")
m_asp <- metabin(d.asp, n.asp, d.plac, n.plac,
                 studlab = paste(study, year), data = Fleiss1993bin, sm = "OR")
save_poc("aspirin_mi", Fleiss1993bin, m_asp)
cat("  aspirin_mi: saved\n")

# 3. Amlodipine & work capacity — continuous MD (amlodipine, meta)
data("amlodipine", package = "meta")
cat("amlodipine columns:", paste(names(amlodipine), collapse = ", "), "\n")
m_aml <- metacont(n.amlo, mean.amlo, sqrt(var.amlo),
                  n.plac, mean.plac, sqrt(var.plac),
                  studlab = study, data = amlodipine, sm = "MD")
save_poc("amlodipine_capacity", amlodipine, m_aml)
cat("  amlodipine_capacity: saved\n")

# 4. Conscientiousness & medication adherence — ZCOR (dat.molloy2014, metafor)
data("dat.molloy2014", package = "metadat")
cat("dat.molloy2014 columns:", paste(names(dat.molloy2014), collapse = ", "), "\n")
m_cor <- metacor(ri, ni, studlab = paste(authors, year),
                 data = dat.molloy2014, sm = "ZCOR")
save_poc("conscientiousness_adherence", dat.molloy2014, m_cor)
cat("  conscientiousness_adherence: saved\n")

# 5. Single-group proportions (dat.pritz1997, metafor)
# NOTE: dat.pritz1997$study is a numeric row ID, not a label — use the authors
# column as studlab so this figure carries author labels like the others. There
# is no year column in this dataset, so labels are author-only.
data("dat.pritz1997", package = "metadat")
cat("dat.pritz1997 columns:", paste(names(dat.pritz1997), collapse = ", "), "\n")
m_pr <- metaprop(xi, ni, studlab = authors, data = dat.pritz1997, sm = "PLOGIT")
save_poc("pritz_recurrence", dat.pritz1997, m_pr)
cat("  pritz_recurrence: saved\n")

cat("\nPoC datasets written under", base, "\n")
cat("Files:\n")
system(paste("find", base, "-type f | sort"))
