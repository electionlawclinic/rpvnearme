###############################################################################
# Download and prepare data for `NJ_county_2020` analysis
# © Election Law Clinic, Harvard Law School, November 2022
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
cli_process_start('Downloading files for {.pkg NJ_county_2020}...')

path_data <- download_state_file('NJ', 'data-raw/NJ')

cli_process_done()

# Compile raw data into a final data file for analysis -----
state_path <- 'data-out/NJ_2020/state_data.rds'
state_md_path <- 'analyses/NJ_county_2020/doc_NJ_county_2020.md'

if (!file_exists(here(state_path))) {
  nj <- read_csv(here(path_data), col_types = cols(GEOID20 = 'c')) |>
    rename_with(function(x) gsub('[0-9.]', '', x), starts_with('GEOID')) |>
    mutate(vap_oth = vap - vap_white - vap_black - vap_hisp)

  md <- read_lines(file = here(state_md_path))
  if (md[length(md)] == '### Elections Included in Analysis') {
    md <- c(md, paste0('  - ', list_elections(nj)))
    write_lines(md, file = here(state_md_path))
  }

  write_rds(nj, here(state_path), compress = 'gz')
  cli_process_done()

} else {
  nj <- read_rds(here(state_path))
  cli_alert_success('Loaded {.strong NJ} data.')
}
