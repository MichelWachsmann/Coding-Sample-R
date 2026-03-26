# Coding Sample (R)
# Author: Michel Wachsmann (FGV EESP)
# Last Modification: 2026-03-24
# Description: This script produces descriptive statistics and figures for the
#              democracy and GDP per capita panel dataset (Task 1).

################################################################################
# Packages
################################################################################

# Vector of required packages
packages <- c("here", "readr", "dplyr", "tidyr", "ggplot2", "knitr",
              "kableExtra")

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
# Load Data
################################################################################

data_democracy <- readRDS(file.path(clean_path, "data_democracy.rds"))

################################################################################
# Colorblind-Safe Palette
################################################################################

safe_palette <- c(
  "#88CCEE", "#CC6677", "#DDCC77", "#117733",
  "#332288", "#AA4499", "#44AA99", "#999933",
  "#882255", "#661100", "#6699CC", "#888888"
)

################################################################################
# Panel Structure
################################################################################

# Number of countries, time span, and panel balance
n_countries <- n_distinct(data_democracy$wbcode)
year_range  <- range(data_democracy$year)
n_years     <- n_distinct(data_democracy$year)

cat("Countries:", n_countries, "\n")
cat("Years:", year_range[1], "-", year_range[2], "(", n_years, "years)\n")

# Check balance: how many years does each country have?
panel_balance <- data_democracy %>%
  group_by(wbcode) %>%
  summarise(
    n_obs        = n(),
    n_obs_gdp    = sum(!is.na(lgdp_pc)),
    first_year   = min(year),
    last_year    = max(year),
    .groups = "drop"
  )

summary(panel_balance$n_obs)
summary(panel_balance$n_obs_gdp)

################################################################################
# Treatment Variation
################################################################################

# Number of transitions into and out of democracy per country
transitions <- data_democracy %>%
  group_by(wbcode) %>%
  summarise(
    n_trans_in   = sum(trans_in, na.rm = TRUE),
    n_trans_out  = sum(trans_out, na.rm = TRUE),
    ever_treated = as.integer(any(trans_in == 1, na.rm = TRUE)),
    .groups = "drop"
  )

cat("Countries with at least one democratization:", sum(transitions$ever_treated), "\n")
cat("Countries never treated:", sum(transitions$ever_treated == 0), "\n")

# Distribution of number of transitions (reversal patterns)
transitions %>%
  count(n_trans_in, name = "n_countries") %>%
  print()

# Share of democracies over time
dem_share <- data_democracy %>%
  group_by(year) %>%
  summarise(share_dem = mean(dem), .groups = "drop")

################################################################################
# Summary Statistics Table
################################################################################

summary_stats <- data_democracy %>%
  summarise(
    across(
      c(lgdp_pc, dem),
      list(
        N    = ~sum(!is.na(.)),
        Mean = ~mean(., na.rm = TRUE),
        SD   = ~sd(., na.rm = TRUE),
        Min  = ~min(., na.rm = TRUE),
        Max  = ~max(., na.rm = TRUE)
      ),
      .names = "{.col}__{.fn}"
    )
  ) %>%
  pivot_longer(everything(),
               names_to = c("variable", "stat"),
               names_sep = "__",
               values_to = "value") %>%
  pivot_wider(names_from = stat, values_from = value) %>%
  mutate(variable = case_when(
    variable == "lgdp_pc" ~ "Log GDP per capita",
    variable == "dem"     ~ "Democracy"
  ))

rownames(summary_stats) <- NULL

kable(summary_stats,
      format    = "latex",
      digits    = 3,
      booktabs  = TRUE,
      row.names = FALSE,
      align     = c("l", "r", "r", "r", "r", "r"),
      col.names = c("Variable", "N", "Mean", "SD", "Min", "Max"),
      caption   = "Summary Statistics",
      label     = "summary-stats") %>%
  kable_styling(latex_options = c("HOLD_position")) %>%
  footnote(
    general = paste0(
      "Country-year panel of 184 countries observed from 1970 to 2010 ",
      "(41 years). Democracy is a binary indicator equal to 1 if the country ",
      "is classified as a democracy. Log GDP per capita has 1,373 missing ",
      "observations (78 countries with at least one missing year). ",
      "91 countries experience at least one transition into democracy; ",
      "19 of these also experience reversals."
    ),
    general_title = "",
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  save_kable(file.path(tables_path, "summary_stats.tex"))

################################################################################
# Publication Theme
################################################################################

theme_pub <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor   = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.title         = element_text(size = 11),
    plot.title         = element_text(size = 13, face = "bold"),
    plot.caption       = element_text(size = 8, hjust = 0, color = "grey40"),
    legend.position    = "bottom"
  )

################################################################################
# Figure 1: Share of Democracies Over Time
################################################################################

fig_dem_share <- ggplot(dem_share, aes(x = year, y = share_dem)) +
  geom_line(linewidth = 0.8, color = safe_palette[1]) +
  geom_point(size = 1.2, color = safe_palette[1]) +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, 1)) +
  labs(
    title   = "Share of Democracies Over Time",
    x       = "Year",
    y       = "Share of countries classified as democracies",
    caption = "Source: demo_gdp_data.csv"
  ) +
  theme_pub

ggsave(file.path(figures_path, "fig_dem_share.pdf"),
       fig_dem_share, width = 8, height = 5)

################################################################################
# Figure 2: Mean Log GDP per Capita by Democracy Status
################################################################################

gdp_by_dem <- data_democracy %>%
  filter(!is.na(lgdp_pc)) %>%
  group_by(year, dem) %>%
  summarise(mean_lgdp = mean(lgdp_pc), .groups = "drop") %>%
  mutate(dem = factor(dem, labels = c("Non-democracy", "Democracy")))

fig_gdp_dem <- ggplot(gdp_by_dem, aes(x = year, y = mean_lgdp,
                                      color = dem, linetype = dem)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = safe_palette[c(1, 2)]) +
  labs(
    title    = "Mean Log GDP per Capita by Democracy Status",
    x        = "Year",
    y        = "Mean log GDP per capita",
    color    = NULL,
    linetype = NULL,
    caption  = "Source: demo_gdp_data.csv"
  ) +
  theme_pub

ggsave(file.path(figures_path, "fig_gdp_by_dem.pdf"),
       fig_gdp_dem, width = 8, height = 5)

################################################################################
# Figure 3: Distribution of First Democratization Year
################################################################################

first_trans <- data_democracy %>%
  filter(trans_in == 1) %>%
  group_by(wbcode) %>%
  slice_min(year, n = 1) %>%
  ungroup()

fig_first_trans <- ggplot(first_trans, aes(x = year)) +
  geom_histogram(binwidth = 2, fill = safe_palette[5], color = "white") +
  labs(
    title   = "Distribution of First Democratization Year",
    x       = "Year",
    y       = "Number of countries",
    caption = "Source: demo_gdp_data.csv"
  ) +
  theme_pub

ggsave(file.path(figures_path, "fig_first_trans.pdf"),
       fig_first_trans, width = 8, height = 5)
