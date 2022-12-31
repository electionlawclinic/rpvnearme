# library(tidyverse)
#
# i <- 1
# state <- state.abb[i]
# l <- read_rds(str_glue('data-out/{state}_2020/{state}_county_2020_ei.rds'))
# l |>
#   pluck(1) |>
#   lapply(FUN = \(x) x$estimate) |>
#   bind_rows(.id = 'county')
