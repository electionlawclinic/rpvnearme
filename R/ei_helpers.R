make_proportions <- function(df, .cols) {
  .cols <- rlang::enquo(.cols)

  df %>%
    dplyr::ungroup() %>%
    dplyr::mutate(
      .total = rowSums(dplyr::select(dplyr::as_tibble(df), !!.cols)),
      across(!!.cols, .fns = function(x) x / .total, .names = 'prop_{.col}')
    )
}

run_rpv <- function(df, total, slug, county = NULL, ...) {
  cands <- df %>%
    as_tibble() %>%
    select(starts_with(total), -any_of(total)) %>%
    names()

  df_ei <- df %>%
    dplyr::mutate(.rn = dplyr::row_number()) %>%
    dplyr::as_tibble() %>%
    make_proportions(.cols = starts_with(paste0(total, '_'))) %>%
    dplyr::mutate({{ total }} := rowSums(dplyr::select(as_tibble(.),
                                                       starts_with(paste0(total, '_'))))) %>%
    make_proportions(.cols = dplyr::all_of(races)) %>%
    dplyr::select(starts_with('prop_'), {{ total }}) %>%
    rename_with(.fn = \(x) str_remove(x, 'prop_'))

  # iter <- NULL
  # try({
  #   iter <- eiCompare::ei_iter(
  #     data = df_ei,
  #     cand_cols = cands,
  #     race_cols = races,
  #     totals_col = total,
  #     name = "Iter",
  #     ...
  #   )
  # })
  # if (is.null(iter)) {
  #   cli::cli_alert_danger('Iterative EI failed for {.val {slug} {county}} .')
  # } else {
  #   cli::cli_alert_success('Iterative EI complete for {.val {slug} {county}}.')
  # }
  rxc <- NULL
  try({
    rxc <- eiCompare::ei_rxc(
      data = df_ei,
      cand_cols = cands,
      race_cols = races,
      totals_col = total,
      name = "RxC",
      ...
    )
  })
  if (is.null(rxc)) {
    cli::cli_alert_danger('RxC EI failed for {.val {slug} {county}}.')
  } else {
    cli::cli_alert_success('RxC EI complete for {.val {slug} {county}}.')
    rxc <- rxc$estimates
  }

  # list(
  #   iter = iter,
  #   rxc = rxc
  # )
  rxc
}

#' Compute RxC EI through `eiPack`
#'
#' @param df
#' @param total
#' @param ncores
#' @param ...
#' @param n_tunes
#' @param thin
#' @param total_draws
#' @param warmup
#' @param seed seed to set. Default is 2022.
#'
#' @return
#' @export
#'
#' @examples
run_rxc <- function(df, total, ncores = 1, n_tunes = 10, thin = 5, total_draws = 10000,
                    warmup = 10000, seed = 2022, ...) {
  cands <- df %>%
    as_tibble() %>%
    select(starts_with(total), -any_of(total)) %>%
    names()

  df_ei <- df %>%
    dplyr::mutate(.rn = dplyr::row_number()) %>%
    dplyr::as_tibble() %>%
    make_proportions(.cols = starts_with(paste0(total, '_'))) %>%
    dplyr::mutate({{ total }} := rowSums(dplyr::select(as_tibble(.),
                                                       starts_with(paste0(total, '_'))))) %>%
    make_proportions(.cols = dplyr::all_of(races)) %>%
    dplyr::select(starts_with('prop_'), {{ total }}, .rn) %>%
    dplyr::rename_with(.fn = \(x) str_remove(x, 'prop_')) %>%
    tidyr::drop_na()

  if (ncores == 1) {
    `%oper%` <- foreach::`%do%`
  } else {
    `%oper%` <- foreach::`%dopar%`
    cl <- parallel::makeCluster(ncores, setup_strategy = 'sequential', methods = FALSE)
    doParallel::registerDoParallel(cl)
    on.exit(parallel::stopCluster(cl))
  }

  form <- formula(
    paste0(
      'cbind(', paste0(cands, collapse = ', '), ') ~ cbind(', paste0(races, collapse = ', '), ')'
    )
  )

  set.seed(seed + 1)
  cli::cli_inform('Tuning...')
  tunes <- eiPack::tuneMD(
    formula = form,
    data = df_ei,
    ntunes = n_tunes,
    totaldraws = total_draws,
    total = total,
    ...
  ) %>%
    suppressWarnings()

  set.seed(seed)
  cli::cli_inform('Running EI...')
  rxc <- eiPack::ei.MD.bayes(
    formula = form,
    data = df_ei,
    thin = thin,
    sample = total_draws,
    tune.list = tunes,
    burnin = warmup,
    total = total,
    ...
  ) %>%
    suppressWarnings()

  vals <- tidyr::expand_grid(races, cands) |>
    dplyr::mutate(stub = paste0(races, '.', cands)) |>
    dplyr::pull(.data$stub)

  betas <- rxc$draws$Beta

  ext <- lapply(vals, function(val) which(str_detect(colnames(betas), val)))
  names(ext) <- vals

  sum_rxc <- function(m, w) {
    out <- apply(m, 1, function(x) {
      weighted.mean(x, w = w)
    })
    c(
      mean = mean(out),
      sd = stats::sd(out),
      ci_95_lower = unname(quantile(out, 0.025, na.rm = TRUE)),
      ci_95_upper = unname(quantile(out, 0.975, na.rm = TRUE))
    )
  }

  tibble::lst(
    precinct = tibble::tibble(
      .rn = df_ei$.rn
    ) |>
      dplyr::bind_cols(
        purrr::map_dfc(ext, function(i) {
          colMeans(betas[, i])
        })
      ) |>
      dplyr::mutate(GEOID = df$GEOID[.rn], .before = everything())
      ,
    estimates = dplyr::bind_cols(
      tidyr::expand_grid(race = races, cand = cands),
      purrr::map_dfr(vals, function(v) {
        sum_rxc(betas[, ext[[v]]], df_ei[[stringr::word(v, sep = stringr::fixed('.'))]])
      })
    )
  )
}
