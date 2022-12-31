elc_pal <- c(
  indigo_dye = '#004877',
  cultured = '#F8F8FA',
  old_mauve = '#642340',
  rebecca_purple = '#593196',
  rocket_metallic = '#857E7B',
  golden_brown = '#A76819',
  shimmering_blush = '#E5778C',
  ruby_red = '#98171A',
  forest_green_crayola = '#62A670'
)

elc_pal |>
  scales::show_col()


poss <- c(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'A', 'B', 'C', 'D', 'E', 'F')

random_color <- function() {
  paste0(c('#', sample(poss, 6, TRUE)), collapse = '')
}

scales::show_col(sapply(1:6, \(x) random_color()))

random_palette <- function(n) {
  x <- vapply(seq_len(n), function(x) random_color(), FUN.VALUE = character(1))
  rlang::inform(x)
  x
}

build <- c(elc_pal[1:5], '#A76819', '#E5778C', '#98171A', '#62A670') #42AF68
scales::show_col(c(build, random_palette(9 - length(build))))

