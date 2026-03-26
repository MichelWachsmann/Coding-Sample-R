# Coding Sample (R)
# Author: Michel Wachsmann (FGV EESP)
# Last Modification: 2026-03-24
# Description: This script runs all steps of the Coding Sample (R) pipeline. It 
#              sources the data cleaning, descriptive, and results scripts, and 
#              then renders the final PDF report. The report is first compiled 
#              inside reports/intermediate so that all LaTeX logs and auxiliary 
#              files remain there. The final PDF is then copied to the project 
#              root.

################################################################################
# Packages
################################################################################

# Vector of required packages
packages <- c("here", "rmarkdown")

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
# Ensure Directory Structure
################################################################################

# List of all required directories in the project
required_dirs <- c(
  # Reports
  here("reports"),
  here("reports", "intermediate"),
  here("reports", "templates"),
  
  # Task 1
  here("task1"),
  here("task1", "input"),
  here("task1", "input", "raw"),
  here("task1", "input", "clean"),
  here("task1", "output"),
  here("task1", "output", "figures"),
  here("task1", "output", "tables"),
  here("task1", "script"),
  here("task1", "script", "data"),
  here("task1", "script", "descriptives"),
  here("task1", "script", "results"),
  
  # Task 2
  here("task2"),
  here("task2", "input"),
  here("task2", "input", "raw"),
  here("task2", "output"),
  here("task2", "output", "tables"),
  here("task2", "script")
)

# Create directories if they do not exist
for (dir in required_dirs) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
}

################################################################################
# Directory
################################################################################

reports_path      <- here("reports")
intermediate_path <- here("reports", "intermediate")
output_file_name  <- "report.pdf"

################################################################################
# Pipeline
################################################################################

#########################################
# TASK 1
#########################################

# Step 1: Load, inspect, clean, and save democracy panel data
source(here("task1", "script", "data", "democracy_cleaning.R"))

# Step 2: Produce descriptive statistics, diagnostic outputs, and figures
source(here("task1", "script", "descriptives", "democracy_descriptives.R"))

# Step 3: Estimate event-study specifications and export tables and figures
source(here("task1", "script", "results", "democracy_results.R"))

#########################################
# TASK 2
#########################################

# Step 4: Run data audit pipeline for elections dataset
source(here("task2", "script", "elections_audit.R"))

#########################################
# REPORT
#########################################

# Step 5: Render final PDF report inside intermediate folder
rendered_file <- render(
  input             = here("reports", "report.Rmd"),
  output_file       = output_file_name,
  output_dir        = intermediate_path,
  intermediates_dir = intermediate_path,
  clean             = FALSE,
  envir             = new.env(parent = globalenv())
)

# Step 6: Copy final PDF to project root
file.copy(from = rendered_file, to = here(output_file_name), overwrite = TRUE)

# Step 7: Remove duplicate PDF from intermediate folder
if (file.exists(rendered_file)) {
  file.remove(rendered_file)
}

################################################################################
# Clean LaTeX auxiliary files
################################################################################

aux_extensions <- c("log", "aux", "out", "toc", "fls", "fdb_latexmk")

files_root <- list.files(reports_path, full.names = TRUE, all.files = TRUE)

aux_files <- files_root[
  tools::file_ext(files_root) %in% aux_extensions
]

if (length(aux_files) > 0) {
  file.rename(
    from = aux_files,
    to   = file.path(intermediate_path, basename(aux_files))
  )
}