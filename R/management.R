#' Initialize a new analysis
#'
#' @param state the state abbreviation for the analysis, e.g. `NY`.
#' @param type the type of districts: `county`.
#' @param year the analysis year
#' @param overwrite whether to overwrite an existing analysis
#'
#' @return NULL, invisibly
#'
init_analysis <- function(state, type = 'county', year = 2020, overwrite = FALSE) {
  cli::cli_alert("Code template adapted from Cory McCartan's fifty-states template.")
  state <- stringr::str_to_upper(state)
  year <- as.character(as.integer(year))
  slug <- stringr::str_glue('{state}_{type}_{year}')
  copyright <- format(Sys.Date(), '\u00A9 Election Law Clinic, Harvard Law School, %B %Y')

  path_r <- stringr::str_glue('analyses/{slug}/')
  if (fs::dir_exists(path_r) & !overwrite) {
    cli::cli_abort('Analysis {.pkg {slug}} already exists.
                   Pass {.code overwrite = TRUE} to overwrite.')
  }
  fs::dir_create(path_r)
  cli::cli_alert_success('Creating {.file {path_r}}')
  fs::dir_create(path_data <- stringr::str_glue('data-out/{state}_{year}/'))
  cli::cli_alert_success('Creating {.file {path_data}}')
  fs::dir_create(path_raw <- stringr::str_glue('data-raw/{state}/'))
  cli::cli_alert_success('Creating {.file {path_raw}}')

  templates <- Sys.glob(here::here('R/template/*.R'))

  proc_template <- function(path) {
    new_basename <- stringr::str_replace(basename(path), '.R', stringr::str_c('_', slug, '.R'))
    new_path <- here::here(path_r, new_basename)
    readr::read_file(path) %>%
      stringr::str_replace_all('``SLUG``', slug) %>%
      stringr::str_replace_all('``STATE``', state) %>%
      stringr::str_replace_all('``YEAR``', year) %>%
      stringr::str_replace_all('``YR``', stringr::str_sub(year, 3)) %>%
      stringr::str_replace_all('``state``', stringr::str_to_lower(state)) %>%
      stringr::str_replace_all(
        '``state_name``',
        stringr::str_to_lower(state.name[state.abb == state])
      ) %>%
      stringr::str_replace_all('``TYPE``', toupper(type)) %>%
      stringr::str_replace_all('``type``', type) %>%
      stringr::str_replace_all('``COPYRIGHT``', copyright) %>%
      write_file(new_path)
    cli::cli_li("Creating {.file {path_r}{new_basename}}'")
    new_path
  }

  cli::cli_alert_info('Copying scripts from templates...')
  cli::cli_ul()
  new_paths <- purrr::map(templates, proc_template)
  cli::cli_end()

  doc_path <- stringr::str_c(path_r, 'doc_', slug, '.md')
  read_file(here::here('R/template/documentation.md')) %>%
    stringr::str_replace_all('``SLUG``', slug) %>%
    stringr::str_replace_all('``STATE``', state) %>%
    stringr::str_replace_all('``STATE NAME``', censable::match_name(state)) %>%
    stringr::str_replace_all('``STATE``', state) %>%
    stringr::str_replace_all('``YEAR``', year) %>%
    stringr::str_replace_all('``TYPE``', toupper(type)) %>%
    stringr::str_replace_all('``type``', type) %>%
    stringr::str_replace_all('``state``', stringr::str_to_lower(state)) %>%
    write_file(here::here(doc_path))
  cli::cli_alert_success('Creating {.file {doc_path}}')

  cli::cli_alert_success('Initialization complete.')

  if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {
    purrr::map(new_paths, rstudioapi::navigateToFile)
    rstudioapi::navigateToFile(doc_path)
  }
  invisible(NULL)
}

open_state <- function(state, type = 'county', year = 2020) {
  state <- stringr::str_to_upper(state)
  year <- as.character(as.integer(year))
  slug <- stringr::str_glue('{state}_{type}_{year}')

  if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {
    rstudioapi::navigateToFile(stringr::str_glue('analyses/{slug}/01_prep_{slug}.R'))
    rstudioapi::navigateToFile(stringr::str_glue('analyses/{slug}/02_run_ei_{slug}.R'))
    rstudioapi::navigateToFile(stringr::str_glue('analyses/{slug}/doc_{slug}.md'))
    rstudioapi::navigateToFile(stringr::str_glue('analyses/{slug}/02_run_ei_{slug}.R'))
    rstudioapi::navigateToFile(stringr::str_glue('analyses/{slug}/01_prep_{slug}.R'))
  }
  invisible(NULL)
}
