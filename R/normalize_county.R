#' Normalize string keys
#'
#' @param x a character vector of key(s) to normalize
#'
#' @return a character vector of length equal to `x`
#'
#' @noRd
normalize_key <- function(x) {
  stringr::str_to_lower(stringr::str_remove_all(x, '[^A-Za-z0-9]'))
}

#' Normalize county naming
#'
#' @param df data frame with a `county` column
#' @param abb state postal abbreviation
#'
#' @return `df` with a new `county_fips` column; `county` is left as the
#'   display name (re-derived from FIPS when the input was FIPS-coded)
#' @noRd
normalize_county <- function(df, abb) {
  county_name_aliases <- c(
    'Petersburg Census Area' = 'Petersburg Borough' # AK, reorganized 2013
  )

  fips_st <- censable::stata$fips[
    censable::stata$abb == censable::match_abb(abb)
  ]
  ref <- censable::fips_2020[
    censable::fips_2020$state == fips_st,
    c('county', 'name')
  ]
  ref$key <- normalize_key(ref$name)

  county_raw <- dplyr::recode(df$county, !!!county_name_aliases)
  county_key <- normalize_key(county_raw)

  by_fips <- county_raw %in% ref$county
  by_name <- county_key %in% ref$key

  if (all(by_fips)) {
    lookup <- ref[, c('county', 'name')] |>
      dplyr::rename(county_fips = county, county_name = name)
    df |>
      dplyr::left_join(lookup, by = c('county' = 'county_fips')) |>
      dplyr::mutate(county_fips = county, county = county_name) |>
      dplyr::select(-county_name)
  } else if (all(by_name)) {
    lookup <- ref[, c('key', 'county')] |>
      dplyr::rename(county_fips = county)
    df |>
      dplyr::mutate(.key = county_key) |>
      dplyr::left_join(lookup, by = c('.key' = 'key')) |>
      dplyr::select(-.key)
  } else {
    n_unmatched <- sum(!by_fips & !by_name)
    cli::cli_warn(
      '{.arg county} for {.val {abb}} could not be fully mapped to FIPS ({n_unmatched} of {length(county_raw)} rows unmatched); returning {.arg df} unchanged.'
    )
    df
  }
}
