###############################################################################
# Download and prepare data for `VT_county_2020` analysis
# © Election Law Clinic, Harvard Law School, December 2022
###############################################################################

suppressMessages({
  library(tidyverse)
  library(cli)
  library(here)
  library(fs)
  library(sf)
  library(geomander)
  devtools::load_all() # load utilities
})

# Download necessary files for analysis -----
cli_process_start('Downloading files for {.pkg VT_county_2020}...')

path_data <- download_state_file('VT', 'data-raw/VT')

cli_process_done()

# Compile raw data into a final data file for analysis -----
state_path <- 'data-out/VT_2020/state_data.rds'
state_md_path <- 'analyses/VT_county_2020/doc_VT_county_2020.md'

if (!file_exists(here(state_path))) {
  vt <- read_csv(here(path_data), col_types = cols(GEOID20 = 'c')) |>
    rename_with(function(x) gsub('[0-9.]', '', x), starts_with('GEOID')) |>
    mutate(vap_oth = vap - vap_white - vap_black - vap_hisp)

  md <- read_lines(file = here(state_md_path))
  if (md[length(md)] == '### Elections Included in Analysis') {
    md <- c(md, paste0('  - ', list_elections(vt)))
    write_lines(md, file = here(state_md_path))
  }

  write_rds(vt, here(state_path), compress = 'gz')
  cli_process_done()

} else {
  vt <- read_rds(here(state_path))
  cli_alert_success('Loaded {.strong VT} data.')
}
