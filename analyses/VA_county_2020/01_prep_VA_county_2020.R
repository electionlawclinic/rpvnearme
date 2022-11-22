###############################################################################
# Download and prepare data for `VA_county_2020` analysis
# © Election Law Clinic, Harvard Law School, October 2022
###############################################################################

suppressMessages({
  library(tidyverse)
  library(cli)
  library(here)
  library(fs)
  library(sf)
  library(geomander)
  library(eiCompare)
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start('Downloading files for {.pkg VA_county_2020}...')

path_data <- download_state_file('VA', 'data-raw/VA')

cli_process_done()

# Compile raw data into a final data file for analysis -----
state_path <- 'data-out/VA_2020/state_data.rds'
state_md_path <- 'analyses/VA_county_2020/doc_VA_county_2020.md'

if (!file_exists(here(state_path))) {
  va <- read_csv(here(path_data), col_types = cols(GEOID20 = 'c')) |>
    rename_with(function(x) gsub('[0-9.]', '', x), starts_with('GEOID')) |>
    mutate(vap_oth = vap - vap_white - vap_black - vap_hisp)

  md <- read_lines(file = here(state_md_path))
  if (md[length(md)] == '### Elections Included in Analysis') {
    md <- c(md, paste0('  - ', list_elections(va)))
    write_lines(md, file = here(state_md_path))
  }

  write_rds(va, here(state_path), compress = 'gz')
  cli_process_done()

} else {
  va <- read_rds(here(state_path))
  cli_alert_success('Loaded {.strong VA} shapefile.')
}
