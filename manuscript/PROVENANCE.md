# Dataset provenance — ggmeta proof-of-concept manuscript

| Key | Source package | Version | Dataset object | Original publication | Effect measure (`sm`) | Analysis type | License |
|-----|---------------|---------|---------------|----------------------|----------------------|---------------|---------|
| `bcg_tuberculosis` | `metafor` (metadat) | 5.0-1 | `dat.bcg` | Colditz GA, Brewer TF, Berkey CS, Wilson ME, Burdick E, Fineberg HV, Mosteller F. Efficacy of BCG vaccine in the prevention of tuberculosis: meta-analysis of the published literature. *JAMA* 1994; 271(9): 698–702. | `RR` (risk ratio) | Binary outcomes, subgroups by allocation | GPL-2 |
| `aspirin_mi` | `meta` | 8.5-0 | `Fleiss1993bin` | Fleiss JL. The statistical basis of meta-analysis. *Statistical Methods in Medical Research* 1993; 2: 121–145. | `OR` (odds ratio) | Binary outcomes | GPL (>= 2) |
| `amlodipine_capacity` | `meta` | 8.5-0 | `amlodipine` | Hartung J, Knapp G. On tests of the overall treatment effect in meta-analysis with normally distributed responses. *Statistics in Medicine* 2001; 20: 1771–1782. | `MD` (mean difference) | Continuous outcomes | GPL (>= 2) |
| `conscientiousness_adherence` | `metafor` (metadat) | 5.0-1 | `dat.molloy2014` | Molloy GJ, O'Carroll RE, Ferguson E. Conscientiousness and medication adherence: a meta-analysis. *Annals of Behavioral Medicine* 2014; 47(1): 92–101. | `ZCOR` (Fisher-z correlation) | Correlations | GPL-2 |
| `pritz_recurrence` | `metafor` (metadat) | 5.0-1 | `dat.pritz1997` | Pritz MB. Treatment of cerebral vasospasm due to aneurysmal subarachnoid hemorrhage: past, present, and future of hyperdynamic therapy. *Neurosurgery Quarterly* 1997; 7(4): 273–285. See also Zhou X-H, Brizendine EJ, Pritz MB. Methods for combining rates from several studies. *Statistics in Medicine* 1999; 18(5): 557–566. | `PLOGIT` (logit proportion) | Single-group proportions | GPL-2 |

## Effect measure families exercised

These five datasets span the main families supported by `ggmeta`:

| Family | Measure(s) | Dataset |
|--------|-----------|---------|
| Binary (ratio) | `RR` | `bcg_tuberculosis` |
| Binary (ratio) | `OR` | `aspirin_mi` |
| Continuous (difference) | `MD` | `amlodipine_capacity` |
| Correlation (transformed) | `ZCOR` | `conscientiousness_adherence` |
| Single-group proportion (transformed) | `PLOGIT` | `pritz_recurrence` |

## Raw → ggmeta column mapping

All datasets were converted to the canonical tidy data frame via `ggmeta::tidy_meta()`, which extracts:
- `studlab` (study label, factor with display-order levels)
- `estimate`, `ci_lower`, `ci_upper` (on the natural scale after back-transformation)
- `se`, `weight`, `p_value`
- `is_summary`, `summary_type`, `subgroup`

The raw CSV files preserve the verbatim source data frames as distributed by `meta` and `metafor`.

## Redistribution

The `meta` package is GPL (>= 2) and the `metafor` package (including the `metadat` datasets) is GPL-2. Both licences permit redistribution of the datasets for research purposes. The raw CSV files in `data/raw/` are verbatim copies of the datasets as distributed by those packages.
