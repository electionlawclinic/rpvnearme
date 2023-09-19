###############################################################################
# Download and prepare data for `CT_county_2020` analysis
# © Election Law Clinic, Harvard Law School, September 2023
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
cli_process_start('Downloading files for {.pkg CT_county_2020}...')

path_data <- download_state_file('CT', 'data-raw/CT')

cli_process_done()

# Compile raw data into a final data file for analysis -----
state_path <- 'data-out/CT_2020/state_data.rds'
state_md_path <- 'analyses/CT_county_2020/doc_CT_county_2020.md'

if (!file_exists(here(state_path))) {
  ct <- read_csv(here(path_data), col_types = cols(GEOID20 = 'c')) |>
    rename_with(function(x) gsub('[0-9.]', '', x), starts_with('GEOID')) |>
    mutate(
      vap_oth = vap - vap_white - vap_black - vap_hisp,
      vap_oth_b = vap_oth - vap_asian - vap_aian
    )

  md <- read_lines(file = here(state_md_path))
  if (md[length(md)] == '### Elections Included in Analysis') {
    md <- c(md, paste0('  - ', list_elections(ct)))
    write_lines(md, file = here(state_md_path))
  }

  write_rds(ct, here(state_path), compress = 'gz')
  cli_process_done()

} else {
  ct <- read_rds(here(state_path))
  cli_alert_success('Loaded {.strong CT} data.')
}
