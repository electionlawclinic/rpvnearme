compile_reader <- function(
  source_dirs = fs::path('data', c('2020', '2024')),
  normalize_counties = FALSE
) {
  if (any(!fs::dir_exists(source_dirs))) {
    cli::cli_abort(
      'Data directory {.file {source_dirs[!fs::dir_exists(source_dirs)]}} does not exist.'
    )
  }

  files <- purrr::map(
    source_dirs,
    fs::dir_ls,
    regexp = '\\.[Cc][Ss][Vv]$',
    type = 'file'
  ) |>
    purrr::list_c()

  if (!length(files)) {
    cli::cli_abort('No CSV files found in {.file {source_dirs}}.')
  }

  output_names <- stringr::str_replace(
    fs::path_file(files),
    '_[0-9]{4}(?=_)',
    '_2020'
  )
  file_groups <- split(files, output_names)

  outputs <- purrr::imap(file_groups, function(files, output_name) {
    data <- purrr::map(files, function(file) {
      file_data <- readr::read_csv(
        file,
        col_types = readr::cols(
          .default = readr::col_guess(),
          state = readr::col_character(),
          county = readr::col_character(),
          GEOID = readr::col_character(),
          race = readr::col_character(),
          cand = readr::col_character()
        ),
        show_col_types = FALSE
      )

      if (normalize_counties) {
        abb <- stringr::str_extract(fs::path_file(file), '^[A-Za-z]+')
        file_data <- normalize_county(file_data, abb)
      }

      file_data
    }) |>
      purrr::list_rbind()

    output <- fs::path('data', output_name)
    readr::write_csv(data, output)
    output
  })

  cli::cli_alert_success(
    'Compiled {length(files)} source files into {length(outputs)} reader files.'
  )

  invisible(unname(unlist(outputs)))
}
