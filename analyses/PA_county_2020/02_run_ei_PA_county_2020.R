###############################################################################
# Run EI for `PA_county_2020`
# © Election Law Clinic, Harvard Law School, December 2022
###############################################################################

# Run the simulation -----
cli_process_start('Running EI analysis for {.pkg PA_county_2020}...')

elecs <- pa |>
  dplyr::select(matches('*_\\d\\d_')) |>
  names() |>
  stringr::str_sub(1, 6) |>
  unique()

county_list <- pa |>
  group_by(county) |>
  group_split()

races <- c('vap_white', 'vap_black', 'vap_hisp', 'vap_oth')
id <- 'GEOID'

ei_l <- lapply(
  county_list,
  function(cty) {
    lapply(
      elecs,
      function(total) {
        cli::cli_alert_info('Running {total} in {cty$county[1]}:')
        run_rxc(df = cty, total = total)
      }
    )
  }
)

names(ei_l) <- sapply(county_list, \(cty) cty$county[1])

cli_process_done()

# Output the `ei` objects. Do not edit this path.
cli_process_start('Saving {.cls ei} outputs.')

write_rds(ei_l, here('data-out/PA_2020/PA_county_2020_ei.rds'), compress = 'xz')

cli_process_done()
