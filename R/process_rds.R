# for (state in state.abb) {
#   process_rds(state)
# }

process_rds <- function(state, version = '') {
  l <- readr::read_rds(stringr::str_glue('data-out/{state}_2020/{state}_county_2020_ei{version}.rds'))
  l |>
    lapply(function(w) {
      dplyr::bind_rows(lapply(w, FUN = function(x) x$estimate))
    }) |>
    dplyr::bind_rows(.id = 'county') |>
    readr::write_csv(stringr::str_glue('data/{state}_county_2020_summary{version}.csv'))

  l |>
    purrr::discard(.p = function(x) all(sapply(x, purrr::is_null))) |>
    lapply(function(w) {
      lapply(w, FUN = function(x) x$precinct) |>
        purrr::discard(purrr::is_null) |>
        purrr::reduce(dplyr::left_join, by = c('GEOID', '.rn'))
    }) |>
    dplyr::bind_rows(.id = 'county') |>
    dplyr::select(-.rn) |>
    readr::write_csv(stringr::str_glue('data/{state}_county_2020_precinct{version}.csv'))

  list(
    summary = stringr::str_glue('data/{state}_county_2020_summary{version}.csv'),
    precinct = stringr::str_glue('data/{state}_county_2020_precinct{version}.csv')
  )
}

process_national_csv <- function(type = 'county', version = '') {
  purrr::map_dfr(
    fs::dir_ls(path = 'data', regexp = stringr::str_glue('.+{type}.+summary\\.csv')),
    readr::read_csv,
    col_types = readr::cols(
      county = readr::col_character(),
      race = readr::col_character(),
      cand = readr::col_character(),
      mean        = readr::col_number(),
      sd          = readr::col_number(),
      ci_95_lower = readr::col_number(),
      ci_95_upper = readr::col_number(),
    ),
    .id = 'state'
  ) |>
    dplyr::mutate(state = stringr::str_sub(state, 6, 7)) |>
    readr::write_csv(stringr::str_sub('data/national_summary_2020{version}.csv'))
}
