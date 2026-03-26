# Coding Sample (R)
# Author: Michel Wachsmann (FGV EESP)
# Last Modification: 2026-03-24
# Description: This script loads, inspects, and audits the municipality-election
#              dataset for Puglia (Task 2). The data were digitized via OCR from
#              original paper files and are expected to contain errors. The audit
#              checks for structural, logical, and OCR-related issues, classifies
#              problems by severity, and produces a structured output file
#              flagging all problematic observations.

################################################################################
# Packages
################################################################################

packages <- c("here", "readr", "dplyr", "tidyr", "stringr", "lubridate",
              "ggplot2", "knitr", "kableExtra")

install_if_missing <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p)
  }
}

invisible(lapply(packages, install_if_missing))
invisible(lapply(packages, library, character.only = TRUE))

################################################################################
# Directory
################################################################################

raw_path       <- here("task2", "input", "raw")
clean_path     <- here("task2", "input", "clean")
tables_path    <- here("task2", "output", "tables")

################################################################################
# Load Data
################################################################################

# The file elections.csv is a municipality-election dataset covering municipal
# elections in Puglia, Italy, over several decades (1951-1973). It contains
# 577 observations and 19 variables: region, province, municipality (comune),
# standardized municipality code (PRO_COM2011), election date, registered
# voters, actual voters, invalid ballots, blank ballots, total valid list
# votes, total council seats, and votes/seats for DC, PSI, PCI, and other
# parties. The data were digitized via OCR from original paper files.
data_elections_raw <- read_csv(file.path(raw_path, "elections.csv"), show_col_types = FALSE)

################################################################################
# Inspect
################################################################################

glimpse(data_elections_raw)
summary(data_elections_raw)
colSums(is.na(data_elections_raw))

################################################################################
# Audit Log: Initialize
################################################################################

# Each issue is recorded as a row with: row_id, comune, data_elezioni,
# check_category, check_name, severity, description, recommended_action.
# Severity levels:
#   - critical: logically impossible values
#   - high:     accounting identity failures or duplicates
#   - medium:   plausible but suspicious values requiring review
#   - low:      cosmetic or structural issues correctable automatically
audit_log <- tibble(
  row_id             = integer(),
  comune             = character(),
  data_elezioni      = character(),
  check_category     = character(),
  check_name         = character(),
  severity           = character(),
  description        = character(),
  recommended_action = character()
)

# Helper to append flags
flag <- function(log, rows_df, category, name, sev, desc, action) {
  if (nrow(rows_df) == 0) return(log)
  new_flags <- tibble(
    row_id             = rows_df$row_id,
    comune             = rows_df$comune,
    data_elezioni      = rows_df$data_elezioni,
    check_category     = category,
    check_name         = name,
    severity           = sev,
    description        = desc,
    recommended_action = action
  )
  bind_rows(log, new_flags)
}

# Add row IDs to the data for tracking
data_elections_raw <- data_elections_raw %>% mutate(row_id = row_number())

################################################################################
# CHECK 1: Duplicate Observations
################################################################################

# Exact duplicates (identical on all columns except row_id)
exact_dups <- data_elections_raw %>%
  group_by(across(-row_id)) %>%
  filter(n() > 1) %>%
  ungroup() %>%
  slice(-1, .by = c(PRO_COM2011, data_elezioni))

audit_log <- flag(audit_log, exact_dups,
                  category = "Duplicates",
                  name     = "exact_duplicate",
                  sev      = "high",
                  desc     = "Exact duplicate row (all columns identical). Likely OCR double-scan.",
                  action   = "auto_drop"
)

# Near-duplicates: same PRO_COM2011 and data_elezioni but different values
near_dups <- data_elections_raw %>%
  group_by(PRO_COM2011, data_elezioni) %>%
  filter(n() > 1) %>%
  ungroup() %>%
  anti_join(exact_dups, by = "row_id")

audit_log <- flag(audit_log, near_dups,
                  category = "Duplicates",
                  name     = "near_duplicate",
                  sev      = "high",
                  desc     = "Same municipality code and election date but differing values.",
                  action   = "manual_review"
)

################################################################################
# CHECK 2: Municipality Name Standardization (OCR artifacts)
################################################################################

# 2a: Capitalization inconsistency (ALL CAPS vs title case)
all_caps <- data_elections_raw %>%
  filter(comune == toupper(comune) & comune != str_to_title(comune))

audit_log <- flag(audit_log, all_caps,
                  category = "OCR_name",
                  name     = "all_caps_comune",
                  sev      = "low",
                  desc     = "Municipality name in ALL CAPS, likely OCR artifact.",
                  action   = "auto_correct_to_title_case"
)

# 2b: Capitalization of prepositions (di/Di, dei/Dei, della/Della, in/In)
# Italian convention: lowercase prepositions in municipality names
preposition_issues <- data_elections_raw %>%
  filter(str_detect(comune, "\\b(Di|Dei|Della|Delle|Del|In|Al)\\b") &
           comune != toupper(comune))

audit_log <- flag(audit_log, preposition_issues,
                  category = "OCR_name",
                  name     = "preposition_capitalization",
                  sev      = "low",
                  desc     = "Preposition incorrectly capitalized (e.g., 'Di' instead of 'di').",
                  action   = "auto_correct_prepositions"
)

# 2c: Spaces in names that shouldn't be there (OCR artifact)
space_issues <- data_elections_raw %>%
  filter(str_detect(comune, "\\s{2,}") |
           str_detect(comune, "maggio re|Val maggio"))

audit_log <- flag(audit_log, space_issues,
                  category = "OCR_name",
                  name     = "spurious_spaces",
                  sev      = "low",
                  desc     = "Municipality name contains spurious spaces (OCR line break).",
                  action   = "auto_correct_merge_words"
)

# 2d: Same PRO_COM2011 maps to multiple comune names (residual after 2a-2c)
name_inconsistency <- data_elections_raw %>%
  group_by(PRO_COM2011) %>%
  mutate(n_names = n_distinct(comune)) %>%
  ungroup() %>%
  filter(n_names > 1)

remaining_name_issues <- name_inconsistency %>%
  anti_join(all_caps, by = "row_id") %>%
  anti_join(preposition_issues, by = "row_id") %>%
  anti_join(space_issues, by = "row_id")

audit_log <- flag(audit_log, remaining_name_issues,
                  category = "OCR_name",
                  name     = "name_code_mismatch",
                  sev      = "medium",
                  desc     = "Same PRO_COM2011 code maps to multiple municipality names.",
                  action   = "manual_review_name"
)

################################################################################
# CHECK 3: Date Validation
################################################################################

data_elections_raw <- data_elections_raw %>%
  mutate(date_parsed = dmy(data_elezioni))

invalid_dates <- data_elections_raw %>% filter(is.na(date_parsed))

audit_log <- flag(audit_log, invalid_dates,
                  category = "Date",
                  name     = "invalid_date",
                  sev      = "high",
                  desc     = "Election date could not be parsed.",
                  action   = "manual_review"
)

################################################################################
# CHECK 4: Logical Impossibilities in Vote Counts
################################################################################

# 4a: Votanti > Elettori (more voters than registered)
impossible_turnout <- data_elections_raw %>%
  filter(votanti > elettori)

audit_log <- flag(audit_log, impossible_turnout,
                  category = "Vote_logic",
                  name     = "votanti_gt_elettori",
                  sev      = "critical",
                  desc     = "Voters exceed registered voters. Likely OCR digit error in elettori.",
                  action   = "manual_review"
)

# 4b: Turnout outliers (excluding impossible cases)
data_elections_raw <- data_elections_raw %>%
  mutate(turnout = votanti / elettori)

turnout_outliers <- data_elections_raw %>%
  filter(turnout <= 1) %>%
  filter(turnout < 0.30 | turnout > 0.99)

audit_log <- flag(audit_log, turnout_outliers,
                  category = "Vote_logic",
                  name     = "extreme_turnout",
                  sev      = "medium",
                  desc     = "Turnout below 30% or above 99%. May indicate OCR digit errors.",
                  action   = "manual_review"
)

################################################################################
# CHECK 5: Vote Accounting Identity
################################################################################

# Expected: votanti = voti_non_validi + schede_bianche + totalevotilista
# But in many cases: votanti = voti_non_validi + totalevotilista
# (schede_bianche may be included in voti_non_validi in some election years)
data_elections_raw <- data_elections_raw %>%
  mutate(
    vote_check_3way = votanti - (voti_non_validi + schede_bianche + totalevotilista),
    vote_check_2way = votanti - (voti_non_validi + totalevotilista)
  )

# Cases where 3-way fails but 2-way holds (coding convention, not error)
schede_in_invalidi <- data_elections_raw %>%
  filter(!is.na(voti_non_validi) & !is.na(schede_bianche) & !is.na(totalevotilista)) %>%
  filter(vote_check_3way != 0 & vote_check_2way == 0)

audit_log <- flag(audit_log, schede_in_invalidi,
                  category = "Vote_accounting",
                  name     = "schede_bianche_in_invalidi",
                  sev      = "low",
                  desc     = "Schede bianche appear included in voti_non_validi. The 2-way identity (votanti = voti_non_validi + totalevotilista) holds.",
                  action   = "note_coding_convention"
)

# Cases where neither identity holds
vote_accounting <- data_elections_raw %>%
  filter(!is.na(voti_non_validi) & !is.na(schede_bianche) & !is.na(totalevotilista)) %>%
  filter(vote_check_3way != 0 & vote_check_2way != 0)

audit_log <- flag(audit_log, vote_accounting,
                  category = "Vote_accounting",
                  name     = "vote_total_mismatch",
                  sev      = "high",
                  desc     = "Votanti does not equal voti_non_validi + schede_bianche + totalevotilista, nor voti_non_validi + totalevotilista. Likely OCR error in one or more fields.",
                  action   = "manual_review"
)

################################################################################
# CHECK 6: Seat Accounting Identity
################################################################################

# Expected: totaleseggi = DC + PSI + PCI + OtherParties seats
data_elections_raw <- data_elections_raw %>%
  mutate(seat_check = totaleseggi - (DCtotaleseggi + PSItotaleseggi +
                                       PCItotaleseggi + OtherParties_seggi))

seat_mismatch <- data_elections_raw %>%
  filter(!is.na(totaleseggi) & seat_check != 0)

audit_log <- flag(audit_log, seat_mismatch,
                  category = "Seat_accounting",
                  name     = "seat_total_mismatch",
                  sev      = "high",
                  desc     = "Party seats do not sum to total seats. Likely missing party data for early elections.",
                  action   = "manual_review"
)

################################################################################
# CHECK 7: List Vote Accounting Identity
################################################################################

# Expected: totalevotilista = DC + PSI + PCI + OtherParties votes
data_elections_raw <- data_elections_raw %>%
  mutate(listvote_check = totalevotilista - (DCtotalevoti + PSItotalevoti +
                                               PCItotalevoti + OtherParties_voti))

listvote_mismatch <- data_elections_raw %>%
  filter(!is.na(totalevotilista) & listvote_check != 0)

audit_log <- flag(audit_log, listvote_mismatch,
                  category = "Vote_accounting",
                  name     = "listvote_total_mismatch",
                  sev      = "high",
                  desc     = "Party votes do not sum to total list votes. Likely missing party or OCR error.",
                  action   = "manual_review"
)

################################################################################
# CHECK 8: Missing Values
################################################################################

# Structural missingness: voti_non_validi and schede_bianche
structural_na <- data_elections_raw %>%
  filter(is.na(voti_non_validi) | is.na(schede_bianche))

audit_log <- flag(audit_log, structural_na,
                  category = "Missing",
                  name     = "structural_na_ballot_detail",
                  sev      = "low",
                  desc     = "Missing voti_non_validi or schede_bianche. Likely not recorded in source document for this election year.",
                  action   = "note_structural_missing"
)

# Missing totals (more concerning)
missing_totals <- data_elections_raw %>%
  filter(is.na(totalevotilista) | is.na(totaleseggi))

audit_log <- flag(audit_log, missing_totals,
                  category = "Missing",
                  name     = "missing_totals",
                  sev      = "medium",
                  desc     = "Missing totalevotilista or totaleseggi.",
                  action   = "manual_review"
)

################################################################################
# CHECK 9: Implausible Values
################################################################################

# 9a: Party votes exceed total list votes
party_exceed <- data_elections_raw %>%
  filter(!is.na(totalevotilista)) %>%
  filter(DCtotalevoti > totalevotilista |
           PSItotalevoti > totalevotilista |
           PCItotalevoti > totalevotilista |
           OtherParties_voti > totalevotilista)

audit_log <- flag(audit_log, party_exceed,
                  category = "Vote_logic",
                  name     = "party_votes_exceed_total",
                  sev      = "critical",
                  desc     = "A single party's votes exceed total list votes.",
                  action   = "manual_review"
)

# 9b: Party seats exceed total seats
party_seats_exceed <- data_elections_raw %>%
  filter(!is.na(totaleseggi)) %>%
  filter(DCtotaleseggi > totaleseggi |
           PSItotaleseggi > totaleseggi |
           PCItotaleseggi > totaleseggi |
           OtherParties_seggi > totaleseggi)

audit_log <- flag(audit_log, party_seats_exceed,
                  category = "Seat_accounting",
                  name     = "party_seats_exceed_total",
                  sev      = "critical",
                  desc     = "A single party's seats exceed total council seats.",
                  action   = "manual_review"
)

# 9c: Zero or negative registered voters / actual voters
zero_negative <- data_elections_raw %>%
  filter(elettori <= 0 | votanti <= 0)

audit_log <- flag(audit_log, zero_negative,
                  category = "Vote_logic",
                  name     = "zero_or_negative_counts",
                  sev      = "critical",
                  desc     = "Zero or negative registered voters or actual voters.",
                  action   = "manual_review"
)

# 9d: Totaleseggi not in expected set {15, 20, 30, 40, 50, 60}
# Italian municipal councils have legally defined sizes based on population
unexpected_seats <- data_elections_raw %>%
  filter(!is.na(totaleseggi) & !(totaleseggi %in% c(15, 20, 30, 40, 50, 60)))

audit_log <- flag(audit_log, unexpected_seats,
                  category = "Seat_accounting",
                  name     = "unexpected_council_size",
                  sev      = "medium",
                  desc     = "Total council seats not in expected set {15, 20, 30, 40, 50, 60}.",
                  action   = "manual_review"
)

################################################################################
# CHECK 10: Province-Code Consistency
################################################################################

# PRO_COM2011 codes encode the province: 71=Foggia, 72=Bari, 73=Taranto,
# 74=Brindisi, 75=Lecce, 110=Barletta-Andria-Trani (carved from Bari in 2004)
data_elections_raw <- data_elections_raw %>%
  mutate(
    code_prefix = case_when(
      PRO_COM2011 >= 110000 ~ "110",
      TRUE ~ as.character(floor(PRO_COM2011 / 1000))
    ),
    expected_province = case_when(
      code_prefix == "71"  ~ "Foggia",
      code_prefix == "72"  ~ "Bari",
      code_prefix == "73"  ~ "Taranto",
      code_prefix == "74"  ~ "Brindisi",
      code_prefix == "75"  ~ "Lecce",
      code_prefix == "110" ~ "Barletta-Andria-Trani",
      TRUE                 ~ "Unknown"
    )
  )

# BAT was carved from Bari in 2004, so historical data may list "Bari"
province_mismatch <- data_elections_raw %>%
  filter(provincia != expected_province &
           !(provincia == "Bari" & expected_province == "Barletta-Andria-Trani"))

audit_log <- flag(audit_log, province_mismatch,
                  category = "Geography",
                  name     = "province_code_mismatch",
                  sev      = "medium",
                  desc     = "Province name does not match expected province from PRO_COM2011 code.",
                  action   = "manual_review"
)

################################################################################
# Audit Summary
################################################################################

audit_summary <- audit_log %>%
  count(check_category, check_name, severity, recommended_action) %>%
  arrange(
    factor(severity, levels = c("critical", "high", "medium", "low")),
    check_category, desc(n)
  )

cat("\n===== AUDIT SUMMARY =====\n\n")
cat("Total flags:", nrow(audit_log), "\n")
cat("Unique rows flagged:", n_distinct(audit_log$row_id), "\n")
cat("Total rows in dataset:", nrow(data_elections_raw), "\n\n")
print(audit_summary)

################################################################################
# Save Audit Output
################################################################################

# Full audit log (CSV for portability — reviewable without R)
write_csv(audit_log, file.path(tables_path, "audit_log.csv"))

# Summary table (LaTeX for report)
rownames(audit_summary) <- NULL

kable(audit_summary,
      format    = "latex",
      booktabs  = TRUE,
      row.names = FALSE,
      col.names = c("Category", "Check", "Severity", "Action", "N"),
      caption   = "Data Audit Summary: Flagged Issues by Category and Severity",
      label     = "audit-summary") %>%
  kable_styling(latex_options = c("HOLD_position", "scale_down")) %>%
  footnote(
    general = paste0(
      "Severity levels: critical (logically impossible values), ",
      "high (accounting identity failures or duplicates), ",
      "medium (plausible but suspicious values requiring review), ",
      "low (cosmetic or structural issues correctable automatically). ",
      "N = number of flagged observations per check."
    ),
    general_title = "",
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  save_kable(file.path(tables_path, "tab_audit_summary.tex"))

################################################################################
# Apply Auto-Corrections and Save Clean Data
################################################################################

data_elections_clean <- data_elections_raw %>%
  # Remove exact duplicates (keep first occurrence per group)
  distinct(across(c(-row_id, -date_parsed, -turnout, -vote_check_3way,
                    -vote_check_2way, -seat_check, -listvote_check,
                    -code_prefix, -expected_province)),
           .keep_all = TRUE) %>%
  # Standardize municipality names to title case
  mutate(
    comune = str_to_title(comune),
    # Fix Italian prepositions back to lowercase
    comune = str_replace_all(comune, "\\bDi\\b", "di"),
    comune = str_replace_all(comune, "\\bDei\\b", "dei"),
    comune = str_replace_all(comune, "\\bDella\\b", "della"),
    comune = str_replace_all(comune, "\\bDelle\\b", "delle"),
    comune = str_replace_all(comune, "\\bDel\\b", "del"),
    comune = str_replace_all(comune, "\\bIn\\b", "in"),
    comune = str_replace_all(comune, "\\bAl\\b", "al"),
    # Fix spurious spaces
    comune = str_replace(comune, "Maggio Re", "Maggiore"),
    comune = str_replace(comune, "Val Maggio", "Valmaggiore"),
    comune = str_squish(comune)
  ) %>%
  # Parse date
  mutate(date_parsed = dmy(data_elezioni)) %>%
  # Drop auxiliary audit columns
  select(-turnout, -vote_check_3way, -vote_check_2way, -seat_check,
         -listvote_check, -code_prefix, -expected_province)

saveRDS(data_elections_clean, file.path(clean_path, "data_elections.rds"))

################################################################################
# Report Table
################################################################################

audit_overview <- tibble(
  metric = c("Total flags", "Unique rows flagged", "Total rows in dataset"),
  value  = c(
    nrow(audit_log),
    n_distinct(audit_log$row_id),
    nrow(data_elections_raw)
  )
)

kable(audit_overview,
      format    = "latex",
      booktabs  = TRUE,
      row.names = FALSE,
      col.names = c("Metric", "Value"),
      caption   = "Audit Overview",
      label     = "audit-overview") %>%
  kable_styling(latex_options = c("HOLD_position")) %>%
  save_kable(file.path(tables_path, "tab_audit_overview.tex"))

