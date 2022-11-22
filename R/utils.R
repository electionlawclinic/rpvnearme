#' Download state data file
#'
#' @param abb the state to download
#' @param folder will be downloaded to `folder/{abb}_{year}.csv`
#' @param overwrite if TRUE, download even if a file exists
#' @param year currently ignored. Only option is 2020.
#'
#' @returns the path to file
#' @export
download_state_file <- function(abb, folder, overwrite = FALSE, year = 2020) {

  if (year != 2020) {
    cli::cli_warn('{.arg year} is currently ignored.')
  }

  abb <- censable::match_abb(abb)

  path <- fs::path(folder, stringr::str_glue('{abb}_{year}.csv'))

  if (!file.exists(path) || overwrite) {
    data <- geomander::get_alarm(state = abb, geometry = FALSE)

    readr::write_csv(data, file = path)
  }

  path
}
