make_state_page <- function(abb) {
  if (missing(abb)) {
    cli::cli_abort('{.arg abb} is missing.')
  }
  state <- censable::match_name(abb)

  x <- readr::read_lines('docs/state_template.txt')

  x <- x |>
    stringr::str_replace_all(pattern = '``STATE``', replacement = state) |>
    stringr::str_replace_all(pattern = '``ABB``', replacement = abb)

  readr::write_lines(x, stringr::str_glue('docs/analyses/{abb}_2020.qmd'))

  stringr::str_glue('docs/analyses/{abb}_2020.qmd')
}
