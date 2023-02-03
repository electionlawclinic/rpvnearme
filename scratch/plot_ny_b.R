library(ggdist)
library(officer)
library(wacolors)
library(ggredist)
library(patchwork)

shp <- get_alarm('NY')
shp <- rmapshaper::ms_simplify(shp, 0.10, keep_shapes = TRUE)

ei_l <- read_rds('data-out/NY_2020/NY_county_2020_ei2.rds')
ei_tb <- bind_rows(lapply(lapply(ei_l, \(x) lapply(x, \(y) pluck(y, 'estimates'))), bind_rows), .id = 'county')

ei_tb <- ei_tb |>
  mutate(
    race = recode(
      race,
      'vap_black' = 'Black',
      'vap_hisp' = 'Hispanic',
      'vap_oth' = 'Other',
      'vap_white' = 'White'
    ),
    race = factor(race, levels = c('White', 'Black', 'Hispanic', 'Other'))
  ) |>
  filter(str_detect(cand, '_dem')) |>
  mutate(election = word(cand, sep = fixed('_')),
         election = recode(election, !!!deframe(alarm_abb())),
         year = 2000 + as.integer(str_sub(cand, 5, 6)),
         election = paste(election, year)) |>
  arrange(year, election) |>
  mutate(election = fct_inorder(election))

counties <- unique(ei_tb$county)


ppt <- read_pptx('scratch/2022-10-05_va_rpv.pptx')

for (cty in counties) {
  ppt <- add_slide(ppt, layout = 'Two Content')
  ppt <- ph_with(x = ppt, cty, location = ph_location_type(type = 'title'))
  gg <- ei_tb |>
    filter(county == cty) |>
    ggplot() +
    geom_interval(aes(y = election, x = mean, xmin = ci_95_lower, xmax = ci_95_upper, color = race),
                  position = position_dodge(width = .5)) +
    geom_pointinterval(aes(y = election, x = mean, xmin = mean, xmax = mean, group = race),
                       position = position_dodge(width = .5), color = 'black') +
    scale_x_continuous(name = 'Estimated Support for Democrats', labels = scales::percent, limits = c(0, 1)) +
    scale_y_discrete(name = 'Contest', limits = rev) +
    theme_bw()
  print(gg)
  ppt <- ph_with(x = ppt, value = gg, location = ph_location_label(ph_label = 'Content Placeholder 3'))

  shpsub <- shp |>
    filter(county == cty)

  gg <- shpsub |>
    ggplot(aes(fill = vap_white / vap)) +
    geom_sf(color = NA) +
    scale_fill_wa_c(name = 'VAP White', palette = 'ferries', labels = scales::percent, limits = c(0, 1)) +
    theme_void() +
    shpsub |>
    ggplot(aes(fill = vap_black / vap)) +
    geom_sf(color = NA) +
    scale_fill_wa_c(name = 'VAP Black', palette = 'ferries', labels = scales::percent, limits = c(0, 1)) +
    theme_void() +
    plot_spacer() + plot_spacer() +
    shpsub |>
    ggplot(aes(fill = vap_hisp / vap)) +
    geom_sf(color = NA) +
    scale_fill_wa_c(name = 'VAP Hispanic', palette = 'ferries', labels = scales::percent, limits = c(0, 1)) +
    theme_void() +
    shpsub |>
    ggplot(aes(fill = ndv / (ndv + nrv))) +
    geom_sf(color = NA) +
    scale_fill_party_c() +
    theme_void() +
    plot_layout(ncol = 2, heights = c(1, 0.1, 1))

  print(gg)
  ppt <- ph_with(x = ppt, value = gg, location = ph_location_label(ph_label = 'Content Placeholder 2'))

}

print(ppt, 'scratch/2022-11-02_ny_rpv-auto.pptx')
fs::file_show('scratch/2022-11-02_ny_rpv-auto.pptx')

prec <- ei_l |> pluck('Rockland County', 6, 'precinct')

df <- ny |>
  filter(county == 'Rockland County') |>
  mutate(.rn = row_number())



vap <- df |>
  as_tibble() |>
  mutate(.rn = row_number()) |>
  select(.rn, vap_white, vap_black, vap_hisp, vap_oth)

cts <- prec %>%
    complete(.rn = seq_len(nrow(vap))) %>%
    mutate(across(starts_with('vap'), \(x) replace_na(x, 0))) %>%
    transmute(
      .rn = .rn,
      white_dem = .[[2]] * vap$vap_white,
      white_rep = .[[3]] * vap$vap_white,
      black_dem = .[[4]] * vap$vap_black,
      black_rep = .[[5]] * vap$vap_black,
      hisp_dem =  .[[6]] * vap$vap_hisp,
      hisp_rep =  .[[7]] * vap$vap_hisp,
      oth_dem =   .[[8]] * vap$vap_oth,
      oth_rep =   .[[9]] * vap$vap_oth,
    )
#
# df2 <- df |>
#   left_join(
#     cts, by = '.rn'
#   ) |>
#   left_join(
#     shp |> filter(county == 'Rockland County') |> select(vtd)
#   ) |>
#   st_as_sf()

# qp <- function(qty) {
#   df2 |>
#     ggplot() +
#     geom_sf(aes(fill = {{ qty }}), color = NA) +
#     scale_fill_wa_c(name = 'Est.') + #, limits = c(0, 2525)
#     theme_map() +
#     labs(title = str_to_title(str_replace(rlang::as_name(rlang::enquo(qty)), '_', ' ')))
# }
#
# qp(white_dem) +
#   qp(black_dem) +
#   qp(hisp_dem) +
#   qp(oth_dem) +
#   qp(white_rep) +
#   qp(black_rep) +
#   qp(hisp_rep) +
#   qp(oth_rep) +
#   plot_layout(nrow = 2)



