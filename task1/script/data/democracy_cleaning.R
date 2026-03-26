# Coding Sample (R)
# Author: Michel Wachsmann (FGV EESP)
# Last Modification: 2026-03-24
# Description: This script loads and cleans the country-year panel dataset on
#              democracy and GDP per capita for the event study / dynamic
#              difference-in-differences analysis (Task 1).

################################################################################
# Packages
################################################################################

# Vector of required packages
packages <- c("here", "readr", "tibble", "dplyr")

# Install any packages that are not already installed
install_if_missing <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p)
  }
}

# Apply installation check to each package
invisible(lapply(packages, install_if_missing))

# Load all packages
invisible(lapply(packages, library, character.only = TRUE))

################################################################################
# Directory
################################################################################

raw_path       <- here("task1", "input", "raw")
clean_path     <- here("task1", "input", "clean")
figures_path   <- here("task1", "output", "figures")
tables_path    <- here("task1", "output", "tables")

################################################################################
# Democracy Database
################################################################################

# The raw data (demo_gdp_data.csv) is a country-year panel with four variables: 
# `wbcode` (World Bank country code), `year` (year of observation), `dem` (a 
# dummy equal to 1 if the country is classified as a democracy in that year), and 
# `lgdp_pc` (log GDP per capita). The treatment of interest is transitions into 
# and out of democracy and the outcome is log GDP per capita.
data_democracy_raw <- read_csv(file.path(raw_path, "demo_gdp_data.csv"))

################################################################################
# Inspect
################################################################################

# Check structure and summary statistics
glimpse(data_democracy_raw)
summary(data_democracy_raw)

# Check for missing values
colSums(is.na(data_democracy_raw))

# Check pattern of missing outcome
data_democracy_raw %>%
  filter(is.na(lgdp_pc)) %>%
  count(wbcode, name = "n_missing")

# Check for duplicates (each country-year pair should be unique)
data_democracy_raw %>%
  group_by(wbcode, year) %>%
  filter(n() > 1) %>%
  nrow()

################################################################################
# Clean
################################################################################

# Ensure correct variable types and sort the panel
data_democracy <- data_democracy_raw %>%
  mutate(
    wbcode  = as.character(wbcode),
    year    = as.integer(year),
    dem     = as.integer(dem),
    lgdp_pc = as.numeric(lgdp_pc)
  ) %>%
  arrange(wbcode, year)

################################################################################
# Treatment Timing Variables
################################################################################

# Construct lagged democracy status and indicators for transitions into and out
# of democracy: if `dem` == 0 at time t, but `dem` == 1 at time t+1, then that
# country i faced a transition into democracy (the other way around for a 
# transition out of democracy).
data_democracy <- data_democracy %>%
  group_by(wbcode) %>%
  mutate(
    dem_lag   = lag(dem, order_by = year),
    trans_in  = as.integer(dem == 1 & dem_lag == 0),
    trans_out = as.integer(dem == 0 & dem_lag == 1)
  ) %>%
  ungroup()

################################################################################
# Save
################################################################################

saveRDS(data_democracy, file.path(clean_path, "data_democracy.rds"))
