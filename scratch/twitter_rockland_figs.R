library(tidyverse)
library(alarmdata)
library(wacolors)
library(ggredist)

ny <- alarm_census_vest('NY', geometry = TRUE)
rc <- ny |>
  filter(county == 'Rockland County')
prec <- read_csv('https://raw.githubusercontent.com/electionlawclinic/rpvnearme/main/data/NY_county_2020_precinct.csv',
                 col_types = c(GEOID = 'c')) |>
  filter(county == 'Rockland County')
rc <- rc |>
  left_join(prec, by = c('county', 'GEOID20' = 'GEOID')) |>
  mutate(across(starts_with('vap'), \(x) replace_na(x, 0)))

rc |>
  ggplot() +
  geom_sf(aes(fill = vap_white.pre_16_rep_tru), color = NA) +
  scale_fill_wa_c(name = 'White Vote\nfor Trump\n(2016)', palette = 'stuart', labels = scales::label_percent(),
                  limits = c(0, 1), midpoint = 0.5) +
  theme_map() +
  labs(title = 'Precinct Estimates')

rc |>
  ggplot() +
  geom_sf(aes(fill = vap_white.pre_20_rep_tru), color = NA) +
  scale_fill_wa_c(name = 'White Vote\nfor Trump\n(2020)', palette = 'stuart', labels = scales::label_percent(),
                  limits = c(0, 1), midpoint = 0.5) +
  theme_map() +
  labs(title = 'Precinct Estimates')
