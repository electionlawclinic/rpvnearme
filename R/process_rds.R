# for (state in state.abb) {
#   process_rds(state)
# }

process_rds <- function(state) {
  l <- readr::read_rds(stringr::str_glue('data-out/{state}_2020/{state}_county_2020_ei.rds'))
  l |>
    lapply(function(w) {
      lapply(w, FUN = function(x) dplyr::bind_rows(x$estimate))
    })|>
    dplyr::bind_rows(.id = 'county') |>
    dplyr::mutate(county = names(l)[as.integer(county)]) |>
    suppressWarnings() |>
    readr::write_csv(stringr::str_glue('data/{state}_county_2020_summary.csv'))

  l |>
    purrr::discard(.p = function(x) all(sapply(x, purrr::is_null))) |>
    lapply(function(w) {
      lapply(w, FUN = function(x) x$precinct) |>
        purrr::discard(purrr::is_null) |>
        purrr::reduce(dplyr::left_join, by = c('GEOID', '.rn'))
    }) |>
    dplyr::bind_rows(.id = 'county') |>
    dplyr::select(-.rn) |>
    readr::write_csv(stringr::str_glue('data/{state}_county_2020_precinct.csv'))

  list(
    summary = stringr::str_glue('data/{state}_county_2020_summary.csv'),
    precinct = stringr::str_glue('data/{state}_county_2020_precinct.csv')
  )
}
