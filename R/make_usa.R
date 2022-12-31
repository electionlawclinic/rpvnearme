if (FALSE) {
  usa <- tigris::states(year = 2020) %>%
    dplyr::filter(STUSPS %in% state.abb) %>%
    tigris::shift_geometry() |>
    rmapshaper::ms_simplify(keep = 0.1) %>%
    dplyr::mutate(link = 'https://www.hlselectionlaw.org/')

  cntrd <- sf::st_centroid(sf::st_geometry(usa))

  {(sf::st_geometry(usa) - cntrd) * 0.8 + cntrd} |> ggplot() + geom_sf()

  saveRDS(usa, 'docs/usa_shp.rds', compress = 'xz')


} else {
  usa <- readRDS('docs/usa_shp.rds')
}
