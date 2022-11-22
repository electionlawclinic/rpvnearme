
plot_raw_rxc <- function(df, cands, races, total, title = '') {
  df <- df %>%
    dplyr::select(dplyr::all_of(cands), dplyr::all_of(races), total = dplyr::all_of(total)) %>%
    tidyr::pivot_longer(
      cols = c(cands),
      names_to = c('candidate'),
      values_to = c('prop_candidate')
    ) %>%
    tidyr::pivot_longer(
      cols = c(races),
      names_to = c('race'),
      values_to = c('prop_race')
    )

  df <- df %>%
    dplyr::mutate(dem = stringr::str_detect(candidate, '_dem') & prop_candidate > 0.5)
  labs <- c(
    'vap_white' = 'White',
    'vap_black' = 'Black',
    'vap_hisp' = 'Hispanic',
    'vap_etc' = 'Other'
  )

  df %>%
    dplyr::filter(dplyr::if_all(starts_with('prop_'), \(x) !is.na(x))) %>%
    dplyr::mutate(race = factor(race, levels = c('vap_white', 'vap_black', 'vap_hisp', 'vap_etc'))) %>%
    ggplot2::ggplot(ggplot2::aes(x = prop_race, y = prop_candidate, color = dem, size = total)) +
    ggplot2::geom_point(alpha = 0.3) +
    ggplot2::scale_color_party_d(name = 'Party of\nCandidate') +
    ggplot2::facet_grid(~race, labeller = ggplot2::as_labeller(labs)) +
    ggplot2::scale_x_continuous(name = 'Race Percentage', labels = scales::percent) +
    ggplot2::scale_y_continuous(name = 'Candidate Percentage', labels = scales::percent) +
    ggplot2::scale_size(name = 'Total Votes') +
    ggplot2::theme_bw() +
    ggplot2::labs(title = title)
}

plot_ei_ests <- function(ei_out, title = '') {

  labs_race <- c(
    'vap_white' = 'White',
    'vap_black' = 'Black',
    'vap_hisp' = 'Hispanic',
    'vap_etc' = 'Other'
  )

  ei_out$estimates %>%
    tibble() %>%
    mutate(
      cand = str_to_title(str_sub(cand, 8, 10)) ,# (str_replace_all(cand, '_', ' ')),
      party = str_detect(cand, 'Dem'),
      race = factor(race, levels = c('vap_white', 'vap_black', 'vap_hisp', 'vap_etc'))
    ) %>%
    ggplot2::ggplot(aes(y = cand, color = party)) +
    ggplot2::geom_point(aes(x = mean)) +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = ci_95_lower, xmax = ci_95_upper), width = 0.2) +
    ggplot2::facet_grid(cols = dplyr::vars(race), labeller = ggplot2::as_labeller(labs_race)) +
    ggplot2::scale_x_continuous(name = 'Vote Percent', labels = scales::percent) +
    ggplot2::scale_y_discrete(name = 'Candidate') +
    ggredist::scale_color_party_d() +
    ggplot2::theme_bw() +
    ggplot2::labs(title = title)
}
