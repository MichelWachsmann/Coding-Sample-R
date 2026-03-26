# Coding Sample (R)
# Author: Michel Wachsmann (FGV EESP)
# Last Modification: 2026-03-24
# Description: This script estimates the event study / dynamic difference-in-
#              differences of the effect of democratic transitions on log GDP
#              per capita (Task 1). Item 2 uses the de Chaisemartin and
#              D'Haultfoeuille (2020) estimator separately for transitions into
#              and out of democracy. Item 3 constructs stacked DID event studies
#              as a comparison, following Cengiz et al. (2019). Both approaches
#              are motivated by Roth et al. (2023).

# References:
#   - de Chaisemartin, Clément, and Xavier D'Haultfœuille. 2020. "Two-Way Fixed 
#     Effects Estimators with Heterogeneous Treatment Effects." American 
#     Economic Review 110 (9): 2964–96.
#   - de Chaisemartin, C. and D'Haultfoeuille, X. (2024). "Difference-in-
#     Differences Estimators of Intertemporal Treatment Effects." Review of
#     Economics and Statistics, 1-45.
#   - Cengiz, D., Dube, A., Lindner, A. and Zipperer, B. (2019). "The Effect
#     of Minimum Wages on Low-Wage Jobs." Quarterly Journal of Economics,
#     134(3), 1405-1454.
#   - Roth, J., Sant'Anna, P.H.C., Bilinski, A. and Poe, J. (2023). "What's
#     Trending in Difference-in-Differences? A Synthesis of the Recent
#     Econometrics Literature." Journal of Econometrics, 235, 2218-2244.

################################################################################
# Packages
################################################################################

# Vector of required packages
packages <- c("here", "readr", "dplyr", "tidyr", "ggplot2", "fixest",
              "DIDmultiplegt", "knitr", "kableExtra")

# Additional packages from non-CRAN repositories
if (!requireNamespace("polars", quietly = TRUE)) {
  install.packages("polars", repos = "https://rpolars.r-universe.dev")
}
library(polars)

# Install any packages that are not already installed
install_if_missing <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p)
  }
}

# Apply installation check to each package
invisible(lapply(packages, install_if_missing))

# Fix for macOS Tahoe: disable OpenGL requirement for rgl
options(rgl.useNULL = TRUE)

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
# Colorblind-Safe Palette
################################################################################

safe_palette <- c(
  "#88CCEE", "#CC6677", "#DDCC77", "#117733",
  "#332288", "#AA4499", "#44AA99", "#999933",
  "#882255", "#661100", "#6699CC", "#888888"
)

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
# Helper: Extract dCDH plot data
################################################################################

extract_dcdh <- function(est) {
  est$plot$data %>%
    mutate(
      rel_time = Time,
      estimate = Estimate,
      ci_lower = LB.CI,
      ci_upper = UB.CI
    ) %>%
    filter(!(rel_time == 0 & estimate == 0 & ci_lower == 0 & ci_upper == 0)) %>%
    select(rel_time, estimate, ci_lower, ci_upper) %>%
    arrange(rel_time)
}

################################################################################
# Load Data
################################################################################

data_democracy <- readRDS(file.path(clean_path, "data_democracy.rds"))

################################################################################
# Item 2a: dCDH Event Study — Transitions INTO Democracy (Switchers-In)
################################################################################

# We estimate the effect of transitioning into democracy (switchers = "in")
# separately from the effect of transitioning out (switchers = "out"). This
# separation is important because the two types of transitions have opposite
# expected effects on GDP, and pooling them would obscure the interpretation.

dcdh_in <- did_multiplegt(
  mode        = "dyn",
  df          = as.data.frame(data_democracy),
  outcome     = "lgdp_pc",
  group       = "wbcode",
  time        = "year",
  treatment   = "dem",
  effects     = 10,
  placebo     = 5,
  cluster     = "wbcode",
  ci_level    = 95,
  switchers   = "in",
  graph_off   = TRUE
)

dcdh_in_df <- extract_dcdh(dcdh_in)

# Plot: Switchers-In
fig_dcdh_in <- ggplot(dcdh_in_df, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = safe_palette[1], alpha = 0.25) +
  geom_point(color = safe_palette[5], size = 2) +
  geom_line(color = safe_palette[5], linewidth = 0.6) +
  labs(
    title    = "Effect of Transitioning Into Democracy on Log GDP per Capita",
    subtitle = "de Chaisemartin and D'Haultfoeuille (2020), switchers-in",
    x        = "Years relative to democratization",
    y        = "Estimate (log GDP per capita)",
    caption  = paste0("Notes: Point estimates with 95% CI. Analytical SEs ",
                      "clustered at the country level. Placebos: -5 to -1; ",
                      "dynamic effects: 1 to 10.")
  ) +
  scale_x_continuous(breaks = seq(-5, 10, 1)) +
  theme_pub

ggsave(file.path(figures_path, "fig_dcdh_in.pdf"),
       fig_dcdh_in, width = 10, height = 6)

################################################################################
# Item 2b: dCDH Event Study — Transitions OUT of Democracy (Switchers-Out)
################################################################################

dcdh_out <- did_multiplegt(
  mode        = "dyn",
  df          = as.data.frame(data_democracy),
  outcome     = "lgdp_pc",
  group       = "wbcode",
  time        = "year",
  treatment   = "dem",
  effects     = 10,
  placebo     = 5,
  cluster     = "wbcode",
  ci_level    = 95,
  switchers   = "out",
  graph_off   = TRUE
)

dcdh_out_df <- extract_dcdh(dcdh_out)

# Plot: Switchers-Out
fig_dcdh_out <- ggplot(dcdh_out_df, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = safe_palette[2], alpha = 0.25) +
  geom_point(color = safe_palette[6], size = 2) +
  geom_line(color = safe_palette[6], linewidth = 0.6) +
  labs(
    title    = "Effect of Transitioning Out of Democracy on Log GDP per Capita",
    subtitle = "de Chaisemartin and D'Haultfoeuille (2020), switchers-out",
    x        = "Years relative to loss of democracy",
    y        = "Estimate (log GDP per capita)",
    caption  = paste0("Notes: Point estimates with 95% CI. Analytical SEs ",
                      "clustered at the country level. Placebos: -5 to -1; ",
                      "dynamic effects: 1 to 10.")
  ) +
  scale_x_continuous(breaks = seq(-5, 10, 1)) +
  theme_pub

ggsave(file.path(figures_path, "fig_dcdh_out.pdf"),
       fig_dcdh_out, width = 10, height = 6)

################################################################################
# Item 2c: Combined dCDH Plot (Both Directions)
################################################################################

dcdh_combined <- bind_rows(
  dcdh_in_df %>% mutate(direction = "Transition into democracy"),
  dcdh_out_df %>% mutate(direction = "Transition out of democracy")
)

fig_dcdh_combined <- ggplot(dcdh_combined,
                            aes(x = rel_time, y = estimate,
                                color = direction, fill = direction)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              alpha = 0.15, color = NA) +
  geom_point(size = 2, position = position_dodge(width = 0.4)) +
  geom_line(linewidth = 0.6, position = position_dodge(width = 0.4)) +
  scale_color_manual(values = safe_palette[c(5, 6)]) +
  scale_fill_manual(values = safe_palette[c(5, 6)]) +
  labs(
    title    = "Effect of Democratic Transitions on Log GDP per Capita",
    subtitle = "de Chaisemartin and D'Haultfoeuille (2020)",
    x        = "Years relative to transition",
    y        = "Estimate (log GDP per capita)",
    color    = NULL,
    fill     = NULL,
    caption  = paste0("Notes: Point estimates with 95% CI. Analytical SEs ",
                      "clustered at the country level.")
  ) +
  scale_x_continuous(breaks = seq(-5, 10, 1)) +
  theme_pub

ggsave(file.path(figures_path, "fig_dcdh_combined.pdf"),
       fig_dcdh_combined, width = 10, height = 6)

################################################################################
# Item 3a: Stacked DID — Transitions INTO Democracy
################################################################################

# The stacked DID approach follows Cengiz et al. (2019) and is described in
# Roth et al. (2023, Section 3.3). For each cohort of countries that first
# democratize in year g, we define an event window [g - W, g + W], keep the
# treated cohort and clean controls (countries untreated throughout the window),
# and stack all sub-experiments with cohort-specific fixed effects.

W <- 10

# All democratization events (not just first), to match dCDH which uses all
# switches. Each country-year with trans_in == 1 defines a separate cohort.
all_dem_events <- data_democracy %>%
  filter(trans_in == 1) %>%
  select(wbcode, cohort_year = year)

# Build stacked dataset for transitions IN
stacked_in_list <- list()

for (i in seq_len(nrow(all_dem_events))) {
  
  g           <- all_dem_events$cohort_year[i]
  treated_wbc <- all_dem_events$wbcode[i]
  year_min    <- g - W
  year_max    <- g + W
  
  # Clean controls: no regime switch of any kind inside the event window
  clean_controls <- data_democracy %>%
    group_by(wbcode) %>%
    summarise(
      any_switch_window = any(
        year >= year_min & year <= year_max &
          (trans_in == 1 | trans_out == 1),
        na.rm = TRUE
      ),
      .groups = "drop"
    ) %>%
    filter(!any_switch_window) %>%
    pull(wbcode)
  
  # Stack identifier: unique per event (country x cohort year)
  stack_label <- paste0(treated_wbc, "_", g)
  
  stack_data <- data_democracy %>%
    filter(wbcode %in% c(treated_wbc, clean_controls),
           year >= year_min, year <= year_max) %>%
    mutate(
      stack_id   = stack_label,
      rel_time   = year - g,
      treated    = as.integer(wbcode == treated_wbc),
      stack_unit = paste0(wbcode, "_", stack_label),
      stack_year = paste0(year, "_", stack_label)
    )
  
  stacked_in_list[[stack_label]] <- stack_data
}

stacked_in_df <- bind_rows(stacked_in_list)

# Check support across relative time periods
stacked_in_df %>% count(rel_time) %>% print()
saveRDS(stacked_in_df, file.path(clean_path, "data_stacked_in.rds"))

# Estimate
stacked_in_df <- stacked_in_df %>%
  mutate(rel_time_factor = relevel(factor(rel_time), ref = as.character(-1)))

stacked_in_est <- feols(
  lgdp_pc ~ i(rel_time_factor, treated, ref = "-1") |
    stack_unit + stack_year,
  data    = stacked_in_df,
  cluster = ~wbcode
)

# Extract coefficients
stacked_in_coefs <- as.data.frame(summary(stacked_in_est)$coeftable)
stacked_in_coefs$term <- rownames(stacked_in_coefs)

stacked_in_plot <- stacked_in_coefs %>%
  filter(grepl("rel_time_factor", term)) %>%
  mutate(
    rel_time = as.numeric(gsub(".*rel_time_factor::(-?\\d+):treated", "\\1", term)),
    estimate = Estimate,
    se       = `Std. Error`,
    ci_lower = estimate - 1.96 * se,
    ci_upper = estimate + 1.96 * se
  ) %>%
  bind_rows(data.frame(rel_time = -1, estimate = 0, se = 0,
                       ci_lower = 0, ci_upper = 0)) %>%
  select(rel_time, estimate, se, ci_lower, ci_upper) %>%
  arrange(rel_time)

# Plot
fig_stacked_in <- ggplot(stacked_in_plot, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = safe_palette[1], alpha = 0.25) +
  geom_point(color = safe_palette[5], size = 2) +
  geom_line(color = safe_palette[5], linewidth = 0.6) +
  labs(
    title    = "Effect of Transitioning Into Democracy on Log GDP per Capita",
    subtitle = "Stacked DID estimator (Cengiz et al., 2019)",
    x        = "Years relative to democratization",
    y        = "Estimate (log GDP per capita)",
    caption  = paste0("Notes: Point estimates with 95% CI. Cluster-robust SEs ",
                      "at the country level. Reference: t = -1. Window: [-",
                      W, ", +", W, "].")
  ) +
  scale_x_continuous(breaks = seq(-W, W, 2)) +
  theme_pub

ggsave(file.path(figures_path, "fig_stacked_in.pdf"),
       fig_stacked_in, width = 10, height = 6)

################################################################################
# Item 3b: Stacked DID — Transitions OUT of Democracy
################################################################################

# All reversal events (not just first)
all_rev_events <- data_democracy %>%
  filter(trans_out == 1) %>%
  select(wbcode, cohort_year = year)

# Build stacked dataset for transitions OUT
stacked_out_list <- list()

for (i in seq_len(nrow(all_rev_events))) {
  
  g           <- all_rev_events$cohort_year[i]
  treated_wbc <- all_rev_events$wbcode[i]
  year_min    <- g - W
  year_max    <- g + W
  
  # Clean controls: no regime switch of any kind inside the event window
  clean_controls <- data_democracy %>%
    group_by(wbcode) %>%
    summarise(
      any_switch_window = any(
        year >= year_min & year <= year_max &
          (trans_in == 1 | trans_out == 1),
        na.rm = TRUE
      ),
      .groups = "drop"
    ) %>%
    filter(!any_switch_window) %>%
    pull(wbcode)
  
  stack_label <- paste0(treated_wbc, "_", g)
  
  stack_data <- data_democracy %>%
    filter(wbcode %in% c(treated_wbc, clean_controls),
           year >= year_min, year <= year_max) %>%
    mutate(
      stack_id   = stack_label,
      rel_time   = year - g,
      treated    = as.integer(wbcode == treated_wbc),
      stack_unit = paste0(wbcode, "_", stack_label),
      stack_year = paste0(year, "_", stack_label)
    )
  
  stacked_out_list[[stack_label]] <- stack_data
}

stacked_out_df <- bind_rows(stacked_out_list)

# Check support across relative time periods
stacked_out_df %>% count(rel_time) %>% print()
saveRDS(stacked_out_df, file.path(clean_path, "data_stacked_out.rds"))

# Estimate
stacked_out_df <- stacked_out_df %>%
  mutate(rel_time_factor = relevel(factor(rel_time), ref = as.character(-1)))

stacked_out_est <- feols(
  lgdp_pc ~ i(rel_time_factor, treated, ref = "-1") |
    stack_unit + stack_year,
  data    = stacked_out_df,
  cluster = ~wbcode
)

# Extract coefficients
stacked_out_coefs <- as.data.frame(summary(stacked_out_est)$coeftable)
stacked_out_coefs$term <- rownames(stacked_out_coefs)

stacked_out_plot <- stacked_out_coefs %>%
  filter(grepl("rel_time_factor", term)) %>%
  mutate(
    rel_time = as.numeric(gsub(".*rel_time_factor::(-?\\d+):treated", "\\1", term)),
    estimate = Estimate,
    se       = `Std. Error`,
    ci_lower = estimate - 1.96 * se,
    ci_upper = estimate + 1.96 * se
  ) %>%
  bind_rows(data.frame(rel_time = -1, estimate = 0, se = 0,
                       ci_lower = 0, ci_upper = 0)) %>%
  select(rel_time, estimate, se, ci_lower, ci_upper) %>%
  arrange(rel_time)

# Plot
fig_stacked_out <- ggplot(stacked_out_plot, aes(x = rel_time, y = estimate)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              fill = safe_palette[2], alpha = 0.25) +
  geom_point(color = safe_palette[6], size = 2) +
  geom_line(color = safe_palette[6], linewidth = 0.6) +
  labs(
    title    = "Effect of Transitioning Out of Democracy on Log GDP per Capita",
    subtitle = "Stacked DID estimator (Cengiz et al., 2019)",
    x        = "Years relative to loss of democracy",
    y        = "Estimate (log GDP per capita)",
    caption  = paste0("Notes: Point estimates with 95% CI. Cluster-robust SEs ",
                      "at the country level. Reference: t = -1. Window: [-",
                      W, ", +", W, "].")
  ) +
  scale_x_continuous(breaks = seq(-W, W, 2)) +
  theme_pub

ggsave(file.path(figures_path, "fig_stacked_out.pdf"),
       fig_stacked_out, width = 10, height = 6)

################################################################################
# Comparison Plots: dCDH vs Stacked DID
################################################################################

# Transitions IN: dCDH vs Stacked
compare_in <- bind_rows(
  dcdh_in_df %>% mutate(estimator = "dCDH (2020)"),
  stacked_in_plot %>%
    select(rel_time, estimate, ci_lower, ci_upper) %>%
    mutate(estimator = "Stacked DID")
)

fig_compare_in <- ggplot(compare_in,
                         aes(x = rel_time, y = estimate,
                             color = estimator, fill = estimator)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              alpha = 0.15, color = NA) +
  geom_point(size = 2, position = position_dodge(width = 0.4)) +
  geom_line(linewidth = 0.6, position = position_dodge(width = 0.4)) +
  scale_color_manual(values = safe_palette[c(5, 4)]) +
  scale_fill_manual(values = safe_palette[c(5, 4)]) +
  labs(
    title    = "Transitions Into Democracy: dCDH vs Stacked DID",
    x        = "Years relative to democratization",
    y        = "Estimate (log GDP per capita)",
    color    = NULL, fill = NULL,
    caption  = paste0("Notes: 95% CI. dCDH uses analytical SEs; Stacked DID ",
                      "uses cluster-robust SEs. Both cluster at country level.")
  ) +
  scale_x_continuous(breaks = seq(-10, 10, 1)) +
  theme_pub

ggsave(file.path(figures_path, "fig_compare_in.pdf"),
       fig_compare_in, width = 10, height = 6)

# Transitions OUT: dCDH vs Stacked
compare_out <- bind_rows(
  dcdh_out_df %>% mutate(estimator = "dCDH (2020)"),
  stacked_out_plot %>%
    select(rel_time, estimate, ci_lower, ci_upper) %>%
    mutate(estimator = "Stacked DID")
)

fig_compare_out <- ggplot(compare_out,
                          aes(x = rel_time, y = estimate,
                              color = estimator, fill = estimator)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey50") +
  geom_vline(xintercept = -0.5, linetype = "dotted", color = "grey50") +
  geom_ribbon(aes(ymin = ci_lower, ymax = ci_upper),
              alpha = 0.15, color = NA) +
  geom_point(size = 2, position = position_dodge(width = 0.4)) +
  geom_line(linewidth = 0.6, position = position_dodge(width = 0.4)) +
  scale_color_manual(values = safe_palette[c(6, 4)]) +
  scale_fill_manual(values = safe_palette[c(6, 4)]) +
  labs(
    title    = "Transitions Out of Democracy: dCDH vs Stacked DID",
    x        = "Years relative to loss of democracy",
    y        = "Estimate (log GDP per capita)",
    color    = NULL, fill = NULL,
    caption  = paste0("Notes: 95% CI. dCDH uses analytical SEs; Stacked DID ",
                      "uses cluster-robust SEs. Both cluster at country level.")
  ) +
  scale_x_continuous(breaks = seq(-10, 10, 1)) +
  theme_pub

ggsave(file.path(figures_path, "fig_compare_out.pdf"),
       fig_compare_out, width = 10, height = 6)

################################################################################
# Tables for Report
################################################################################

# Table: dCDH Estimates — Transitions In
dcdh_in_table <- dcdh_in$plot$data %>%
  filter(!(Time == 0 & Estimate == 0)) %>%
  mutate(
    Type   = ifelse(Time < 0, "Placebo", "Effect"),
    Period = Time
  ) %>%
  select(Type, Period, Estimate, LB.CI, UB.CI) %>%
  rename(`Lower 95% CI` = LB.CI, `Upper 95% CI` = UB.CI) %>%
  arrange(Period)

rownames(dcdh_in_table) <- NULL

kable(dcdh_in_table,
      format    = "latex",
      digits    = 4,
      booktabs  = TRUE,
      row.names = FALSE,
      align     = c("l", "r", "r", "r", "r"),
      caption   = "dCDH Estimates: Transitions Into Democracy",
      label     = "dcdh-in-table") %>%
  kable_styling(latex_options = c("HOLD_position")) %>%
  footnote(
    general = paste0(
      "Estimates from the de Chaisemartin and D'Haultf\\\\oe uille (2020, 2024) ",
      "estimator with switchers = ``in''. Analytical standard errors clustered ",
      "at the country level. 67 switchers. Joint test of effects: $p = ",
      round(dcdh_in$results$p_jointeffects, 4), "$. Joint test of placebos: $p = ",
      round(dcdh_in$results$p_jointplacebo, 4), "$."
    ),
    general_title = "",
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  save_kable(file.path(tables_path, "tab_dcdh_in.tex"))

# Table: dCDH Estimates — Transitions Out
dcdh_out_table <- dcdh_out$plot$data %>%
  filter(!(Time == 0 & Estimate == 0)) %>%
  mutate(
    Type   = ifelse(Time < 0, "Placebo", "Effect"),
    Period = Time
  ) %>%
  select(Type, Period, Estimate, LB.CI, UB.CI) %>%
  rename(`Lower 95% CI` = LB.CI, `Upper 95% CI` = UB.CI) %>%
  arrange(Period)

rownames(dcdh_out_table) <- NULL

kable(dcdh_out_table,
      format    = "latex",
      digits    = 4,
      booktabs  = TRUE,
      row.names = FALSE,
      align     = c("l", "r", "r", "r", "r"),
      caption   = "dCDH Estimates: Transitions Out of Democracy",
      label     = "dcdh-out-table") %>%
  kable_styling(latex_options = c("HOLD_position")) %>%
  footnote(
    general = paste0(
      "Estimates from the de Chaisemartin and D'Haultf\\\\oe uille (2020, 2024) ",
      "estimator with switchers = ``out''. Analytical standard errors clustered ",
      "at the country level. 16 switchers. Joint test of effects: $p = ",
      round(dcdh_out$results$p_jointeffects, 4), "$. Joint test of placebos: $p = ",
      round(dcdh_out$results$p_jointplacebo, 4), "$."
    ),
    general_title = "",
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  save_kable(file.path(tables_path, "tab_dcdh_out.tex"))

# Table: Stacked DID — Transitions In
stacked_in_table <- stacked_in_plot %>%
  mutate(
    Type = ifelse(rel_time < 0, "Pre-treatment",
                  ifelse(rel_time == 0, "Treatment", "Post-treatment"))
  ) %>%
  select(Type, Period = rel_time, Estimate = estimate, SE = se,
         `Lower 95% CI` = ci_lower, `Upper 95% CI` = ci_upper) %>%
  as.data.frame()

rownames(stacked_in_table) <- NULL

kable(stacked_in_table,
      format    = "latex",
      digits    = 4,
      booktabs  = TRUE,
      row.names = FALSE,
      align     = c("l", "r", "r", "r", "r", "r"),
      caption   = "Stacked DID Estimates: Transitions Into Democracy",
      label     = "stacked-in-table") %>%
  kable_styling(latex_options = c("HOLD_position"), font_size = 9) %>%
  footnote(
    general = paste0(
      "Stacked DID following Cengiz et al.\\ (2019). Each transition event ",
      "defines a cohort-specific sub-experiment with event window $[-10, +10]$. ",
      "Controls have no regime switch of any kind inside the window. ",
      "Cluster-robust standard errors at the country level. ",
      "Reference period: $t = -1$."
    ),
    general_title = "",
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  save_kable(file.path(tables_path, "tab_stacked_in.tex"))

# Table: Stacked DID — Transitions Out
stacked_out_table <- stacked_out_plot %>%
  mutate(
    Type = ifelse(rel_time < 0, "Pre-treatment",
                  ifelse(rel_time == 0, "Treatment", "Post-treatment"))
  ) %>%
  select(Type, Period = rel_time, Estimate = estimate, SE = se,
         `Lower 95% CI` = ci_lower, `Upper 95% CI` = ci_upper) %>%
  as.data.frame()

rownames(stacked_out_table) <- NULL

kable(stacked_out_table,
      format    = "latex",
      digits    = 4,
      booktabs  = TRUE,
      row.names = FALSE,
      align     = c("l", "r", "r", "r", "r", "r"),
      caption   = "Stacked DID Estimates: Transitions Out of Democracy",
      label     = "stacked-out-table") %>%
  kable_styling(latex_options = c("HOLD_position"), font_size = 9) %>%
  footnote(
    general = paste0(
      "Stacked DID following Cengiz et al.\\ (2019). Each transition event ",
      "defines a cohort-specific sub-experiment with event window $[-10, +10]$. ",
      "Controls have no regime switch of any kind inside the window. ",
      "Cluster-robust standard errors at the country level. ",
      "Reference period: $t = -1$."
    ),
    general_title = "",
    threeparttable = TRUE,
    escape = FALSE
  ) %>%
  save_kable(file.path(tables_path, "tab_stacked_out.tex"))