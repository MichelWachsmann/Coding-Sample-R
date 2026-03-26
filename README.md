# Coding Sample (R)

**Author:** Michel Wachsmann (FGV EESP)
**Last Updated:** March 2026

## Overview

This repository contains the code, data, and output for the Coding Sample (R).

**Task 1** estimates the effect of democratic transitions (into and out of 
democracy) on log GDP per capita using a country-year panel of 184 countries from 1970 to 2010. The main estimator is de Chaisemartin and D'Haultfœuille (2020, 2024), chosen because treatment (democracy) is non-absorbing — countries can transition into and out of democracy multiple times. A stacked DID estimator (Cengiz et al., 2019) is constructed as a comparison.

**Task 2** designs and implements a data-audit pipeline for a historical 
municipality-election dataset from Apulia (Puglia), Italy. The dataset was
digitized via OCR from paper records and is therefore expected to contain 
formatting errors, duplicated entries, and accounting inconsistencies. The audit 
pipeline classifies all identified issues by category, severity, and recommended
action, and exports structured audit outputs for manual review and documentation.

## Folder Structure

```text
task1/
├── input/
│   ├── raw/
│   │   └── demo_gdp_data.csv           # Original dataset
│   └── clean/
│       ├── data_democracy_clean.rds    # Cleaned panel with transition indicators
│       ├── data_stacked_in.rds         # Stacked dataset: transitions into democracy
│       └── data_stacked_out.rds        # Stacked dataset: transitions out of democracy
├── output/
│   ├── figures/
│   │   ├── fig_dem_share.pdf           # Share of democracies over time
│   │   ├── fig_gdp_by_dem.pdf          # Mean log GDP by democracy status
│   │   ├── fig_first_trans.pdf         # Distribution of first democratization year
│   │   ├── fig_dcdh_in.pdf             # dCDH event study: transitions in
│   │   ├── fig_dcdh_out.pdf            # dCDH event study: transitions out
│   │   ├── fig_dcdh_combined.pdf       # dCDH: both directions overlaid
│   │   ├── fig_stacked_in.pdf          # Stacked DID: transitions in
│   │   ├── fig_stacked_out.pdf         # Stacked DID: transitions out
│   │   ├── fig_compare_in.pdf          # dCDH vs Stacked DID: transitions in
│   │   └── fig_compare_out.pdf         # dCDH vs Stacked DID: transitions out
│   └── tables/
│       ├── summary_stats.tex           # Summary statistics
│       ├── tab_dcdh_in.tex             # dCDH estimates: transitions in
│       ├── tab_dcdh_out.tex            # dCDH estimates: transitions out
│       ├── tab_stacked_in.tex          # Stacked DID estimates: transitions in
│       └── tab_stacked_out.tex         # Stacked DID estimates: transitions out
└── script/
    ├── data/
    │   └── democracy_cleaning.R        # Load, inspect, clean, and save panel data
    ├── descriptives/
    │   └── democracy_descriptives.R    # Summary statistics and descriptive figures
    └── results/
        └── democracy_results.R         # dCDH and stacked DID estimation
task2/
├── input/
│   ├── raw/
│   │   └── elections.csv               # Original OCR-digitized elections dataset
│   └── clean/
│       └── data_elections.rds          # Cleaned version with automatic corrections
├── output/
│   └── tables/
│       ├── audit_log.csv               # Observation-level audit log
│       ├── tab_audit_overview.tex      # Headline audit counts
│       └── tab_audit_summary.tex       # Audit summary by issue type
└── script/
    └── elections_audit.R               # Data-audit pipeline for historical elections data
reports/
├── report.Rmd                          # Report source (R Markdown)
└── intermediate/                       # LaTeX auxiliary files from compilation
└── template/                           # LaTeX template 
environment.Rproj
call_all.R                              # Master script: runs full pipeline
README.md
report.pdf                              # Final compiled report (deliverable)
```

## How to Run

### Prerequisites

- **R** (>= 4.3.0)
- **RStudio** (recommended, for `.Rproj` integration)
- **LaTeX distribution** (required to compile the PDF memo via R Markdown):
  - macOS: [MacTeX](https://tug.org/mactex/)
  - Windows: [MiKTeX](https://miktex.org/)
  - Cross-platform: `tinytex::install_tinytex()` from R
- The following R packages (installed automatically by each script if missing):
  - `here`, `readr`, `dplyr`, `tidyr`, `ggplot2`
  - `fixest`, `DIDmultiplegt`, `polars`
  - `knitr`, `kableExtra`, `rmarkdown`

**Note for macOS Tahoe users:** The `DIDmultiplegt` package depends on `rgl`, 
which requires OpenGL. The scripts set `options(rgl.useNULL = TRUE)` before 
loading to work around this. The `polars` package is installed from 
`https://rpolars.r-universe.dev`.

### One-Click Execution

Open `environment.Rproj` in RStudio and run:

```r
source("call_all.R")
```

This runs the full pipeline: data cleaning; descriptives; estimation; PDF report
compilation. The final `report.pdf` is placed in the project root.

### Step-by-Step Execution

Alternatively, run each script individually in order:

1. **`task1/script/data/democracy_cleaning.R`**
   Loads `demo_gdp_data.csv`, checks for missing values and duplicates, constructs 
   lagged democracy status and transition indicators (`trans_in`, `trans_out`),
   and saves the cleaned dataset.

2. **`task1/script/descriptives/democracy_descriptives.R`**
   Produces summary statistics, panel structure diagnostics, treatment variation 
   counts, and three descriptive figures (share of democracies, GDP by regime 
   type, distribution of first democratization year).

3. **`task1/script/results/democracy_results.R`**
   Estimates the event study using two approaches, separately for transitions 
   into and out of democracy:
   - **de Chaisemartin & D'Haultfœuille (2020):** uses 
   `did_multiplegt(mode = "dyn")` with `switchers = "in"` and `switchers = "out"`.
   - **Stacked DID (Cengiz et al., 2019):** constructs cohort-specific 
   sub-experiments with clean controls (no regime switch of any kind in the 
   event window) and estimates TWFE with stack-by-unit and stack-by-year fixed
   effects via `fixest::feols()`.

4. **`task2/script/elections_audit.R`**
   Loads `elections.csv`, applies logical, accounting, duplication, geographic, 
   and OCR-formatting checks, classifies all flagged issues by severity and 
   recommended action, and exports both the cleaned dataset and the structured 
   audit outputs.
   
5. **`reports/report.Rmd`**
   Compiled by `call_all.R` via `rmarkdown::render()`. Can also be knitted 
   manually in RStudio.

## Key Design Choices

### Task 1

- **Estimator selection:** de Chaisemartin & D'Haultfœuille (2020) is chosen 
because treatment is non-absorbing (19 of 91 democratizing countries experience
reversals). Estimators assuming absorbing treatment (Callaway & Sant'Anna, 2021; 
Sun & Abraham, 2021) are not applicable.

- **Separate estimation by direction:** Transitions into and out of democracy 
are estimated separately because their expected effects on GDP have opposite 
signs. Pooling would obscure interpretation.

- **Clean controls in stacked DID:** Control units in each stack have no regime
switch of any kind (neither `trans_in` nor `trans_out`) within the event window, 
ensuring uncontaminated counterfactuals.

- **All transitions stacked:** The stacked DID uses all transition events (not 
just first transitions), matching the dCDH estimator which uses all switches.

### Task 2

- **Priority ordering of checks:** The audit first targets logical 
impossibilities and accounting inconsistencies, then duplication and geographic
mismatches, and finally low-risk OCR-formatting issues.

- **Automatic corrections restricted to low-risk cases:** Only formatting 
inconsistencies such as capitalization, spacing, and standardized preposition
usage are corrected automatically with high confidence.

- **Manual review for substantively important discrepancies:** Vote mismatches,
seat mismatches, duplicate records, missing totals, and municipality name/code 
inconsistencies are flagged for manual validation.

- **Structured audit output:** All flagged observations are recorded in a 
unified audit log with a check category, check name, severity classification,
and recommended action.

## References

- Acemoglu, D. and Robinson, J.A. (2006). *Economic Origins of Dictatorship and Democracy.* 
Cambridge University Press.
- Acemoglu, D., Naidu, S., Restrepo, P. and Robinson, J.A. (2019). "Democracy 
Does Cause Growth." *Journal of Political Economy*, 127(1), 47–100.
- Callaway, B. and Sant'Anna, P.H.C. (2021). "Difference-in-Differences with 
Multiple Time Periods." *Journal of Econometrics*, 225(2), 200–230.
- Cengiz, D., Dube, A., Lindner, A. and Zipperer, B. (2019). "The Effect of 
Minimum Wages on Low-Wage Jobs." *Quarterly Journal of Economics*, 134(3), 
1405–1454.
- de Chaisemartin, C. and D'Haultfœuille, X. (2020). "Two-Way Fixed Effects 
Estimators with Heterogeneous Treatment Effects." *American Economic Review*, 
110(9), 2964–2996.
- de Chaisemartin, C. and D'Haultfœuille, X. (2024). "Difference-in-Differences 
Estimators of Intertemporal Treatment Effects." 
*Review of Economics and Statistics*, 1–45.
- Gardner, J. (2022). "Two-Stage Differences in Differences." Working Paper.
- Goodman-Bacon, A. (2021). "Difference-in-Differences with Variation in 
Treatment Timing." *Journal of Econometrics*, 225(2), 254–277.
- Haggard, S. and Kaufman, R.R. (2016). *Dictators and Democrats: Masses, 
Elites, and Regime Change.* Princeton University Press.
- Roth, J., Sant'Anna, P.H.C., Bilinski, A. and Poe, J. (2023). "What's Trending 
in Difference-in-Differences?" *Journal of Econometrics*, 235, 2218–2244.
- Sun, L. and Abraham, S. (2021). "Estimating Dynamic Treatment Effects in Event 
Studies with Heterogeneous Treatment Effects." *Journal of Econometrics*, 225(2), 
175–199.
