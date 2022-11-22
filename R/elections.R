list_elections <- function(tb) {
  elecs <- tb |>
    dplyr::as_tibble() |>
    dplyr::select(tidyselect::matches('_\\d\\d_')) |>
    colnames() |>
    stringr::str_sub(start = 1, end = 6) |>
    unique() |>
    stringr::str_replace(pattern = '_', replacement = ' ')

  el_expanded <- dplyr::tibble(
    a = stringr::str_sub(string = elecs, start = 1, end = 3)
  )
  el_expanded <- dplyr::left_join(
    x = el_expanded, y = alarm_abb(), by = 'a'
  )

  for (i in seq_along(elecs)) {
    elecs[i] <- paste0(el_expanded$b[i], ' 20', stringr::str_sub(elecs[i], start = 5))
  }

  elecs
}

alarm_abb <- function() {
  tibble::tribble(
    ~a, ~b,
    'pre', 'President',
    'uss', 'US Senate',
    'gov', 'Governor',
    'atg', 'Attorney General',
    'sos', 'Secretary of State'
  )
}
