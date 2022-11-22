###############################################################################
# Download and prepare data for ```SLUG``` analysis
# ``COPYRIGHT``
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
cli_process_start('Downloading files for {.pkg ``SLUG``}...')

path_data <- download_state_file('``STATE``', 'data-raw/``STATE``')

cli_process_done()

# Compile raw data into a final data file for analysis -----
state_path <- 'data-out/``STATE``_``YEAR``/state_data.rds'
state_md_path <- 'analyses/``STATE``_``type``_``YEAR``/doc_``STATE``_``type``_``YEAR``.md'

if (!file_exists(here(state_path))) {
  ``state`` <- read_csv(here(path_data), col_types = cols(GEOID``YR`` = 'c')) |>
    rename_with(function(x) gsub('[0-9.]', '', x), starts_with('GEOID')) |>
    mutate(vap_oth = vap - vap_white - vap_black - vap_hisp)

  md <- read_lines(file = here(state_md_path))
  if (md[length(md)] == '### Elections Included in Analysis') {
    md <- c(md, paste0('  - ', list_elections(``state``)))
    write_lines(md, file = here(state_md_path))
  }

  write_rds(``state``, here(state_path), compress = 'gz')
  cli_process_done()

} else {
  ``state`` <- read_rds(here(state_path))
  cli_alert_success('Loaded {.strong ``STATE``} data.')
}
