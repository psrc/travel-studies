library(tidyverse)

pairwise_triprate_tests <- function(hts_data, group_var, age_adjust = TRUE,
                                    confidence = 0.90) {
  z_critical <- qnorm((1 + confidence) / 2)
  alpha <- 1 - confidence

  triprates <- if (age_adjust) {
    age_specific_rates <- psrc_hts_triprate(
      hts_data,
      group_vars = c(group_var, "age_bin5")
    ) |>
      filter(!is.na(.data[[group_var]]), !is.na(age_bin5))

    group_coverage <- age_specific_rates |>
      count(survey_year, .data[[group_var]], name = "age_cells") |>
      group_by(survey_year) |>
      filter(age_cells == max(age_cells)) |>
      ungroup()

    common_age_levels <- age_specific_rates |>
      inner_join(
        group_coverage |> select(survey_year, all_of(group_var)),
        by = c("survey_year", group_var)
      ) |>
      count(survey_year, age_bin5, name = "groups_with_age") |>
      left_join(
        group_coverage |> count(survey_year, name = "groups_compared"),
        by = "survey_year"
      ) |>
      filter(groups_with_age == groups_compared) |>
      select(survey_year, age_bin5)

    age_weights <- psrc_hts_stat(
      df_hts,
      analysis_unit = "person",
      group_vars = "age_bin5",
      incl_na = FALSE
    ) |>
      inner_join(common_age_levels, by = c("survey_year", "age_bin5")) |>
      group_by(survey_year) |>
      mutate(age_weight = prop / sum(prop)) |>
      ungroup() |>
      select(survey_year, age_bin5, age_weight)

    age_specific_rates |>
      inner_join(
        group_coverage |> select(survey_year, all_of(group_var)),
        by = c("survey_year", group_var)
      ) |>
      inner_join(age_weights, by = c("survey_year", "age_bin5")) |>
      group_by(survey_year, .data[[group_var]]) |>
      summarise(
        age_cells = n(),
        mean = sum(mean * age_weight),
        mean_moe = z_critical * sqrt(sum((mean_moe / z_critical * age_weight)^2)),
        .groups = "drop"
      ) |>
      left_join(
        common_age_levels |> count(survey_year, name = "required_age_cells"),
        by = "survey_year"
      ) |>
      filter(age_cells == required_age_cells) |>
      select(-age_cells, -required_age_cells)
  } else {
    psrc_hts_triprate(hts_data, group_vars = group_var)
  }

  triprates |>
    filter(!is.na(.data[[group_var]]), !is.na(mean), !is.na(mean_moe)) |>
    group_by(survey_year) |>
    group_modify(\(year_data, key) {
      comparisons <- combn(seq_len(nrow(year_data)), 2, simplify = FALSE)

      map_dfr(comparisons, \(indices) {
        first <- year_data[indices[1], ]
        second <- year_data[indices[2], ]
        difference <- first$mean - second$mean
        difference_se <- sqrt((first$mean_moe / z_critical)^2 +
                                (second$mean_moe / z_critical)^2)

        tibble(
          group_1 = as.character(first[[group_var]]),
          group_2 = as.character(second[[group_var]]),
          difference = difference,
          difference_moe = z_critical * difference_se,
          p_value = 2 * pnorm(-abs(difference / difference_se)),
          statistically_different = p_value < alpha
        )
      })
    }) |>
    ungroup()
}

summarize_consistent_differences <- function(test_results) {
  test_results |>
    group_by(group_1, group_2) |>
    summarise(
      years_tested = n(),
      significant_every_year = all(statistically_different),
      same_direction_every_year = n_distinct(sign(difference)) == 1,
      average_triprate_difference = if (n_distinct(sign(difference)) == 1) {
        mean(difference)
      } else {
        NA_real_
      },
      consistent_difference = significant_every_year & same_direction_every_year,
      .groups = "drop"
    )
}

triprate_palette <- function(group_var) {
  switch(
    group_var,
    age_bin5 = psrc_colors$pgnobgy_5,
    gender2 = c("#91268F", "#00A7A0", "#F05A28"),
    low_income = c("#91268F", "#8CC63E"),
    race_simpler = psrc_colors$gnbopgy_5,
    psrc_colors$pognbgy_5
  )
}

format_triprate_table <- function(.data, group_var = NULL) {
  table_columns <- c(
    "survey_year", group_var, "mean", "mean_moe", "count",
    "all_trip_rate", "overall_trip_rate", "difference_from_overall"
  )
  table_names <- c(
    survey_year = "survey year",
    mean = "trip rate",
    mean_moe = "trip rate moe",
    count = "sample",
    all_trip_rate = "all trips rate",
    overall_trip_rate = "overall trip rate",
    difference_from_overall = "difference from overall"
  )

  .data |>
    select(any_of(table_columns)) |>
    mutate(
      mean = scales::number(mean, accuracy = 0.01),
      mean_moe = scales::number(mean_moe, accuracy = 0.01),
      count = scales::number(count, accuracy = 1, big.mark = ","),
      across(
        any_of(c("all_trip_rate", "overall_trip_rate", "difference_from_overall")),
        ~ scales::number(.x, accuracy = 0.01)
      )
    ) |>
    rename_with(~ unname(table_names[.x]), any_of(names(table_names))) |>
    knitr::kable()
}

table_triprate_comparison <- function(all_trips, caregiving_trips, group_var, year = 2025) {
  all_year <- all_trips |>
    filter(survey_year == year) |>
    select(all_of(group_var), all_trip_rate = mean)

  caregiving_trips |>
    filter(survey_year == year) |>
    left_join(all_year, by = group_var) |>
    format_triprate_table(group_var)
}

table_difference_trend <- function(group_trend, overall_trend, group_var, years) {
  group_trend |>
    filter(survey_year %in% years, !is.na(.data[[group_var]])) |>
    left_join(
      overall_trend |>
        filter(survey_year %in% years) |>
        select(survey_year, overall_trip_rate = mean),
      by = "survey_year"
    ) |>
    mutate(difference_from_overall = mean - overall_trip_rate) |>
    format_triprate_table(group_var)
}

plot_triprate_comparison <- function(all_trips, caregiving_trips, group_var, title,
                                     year = 2025, errorbar = FALSE,
                                     color_pal = triprate_palette(group_var)) {
  # psrc_hts_triprate() drops factor levels, so restore the source ordering
  group_levels <- levels(df_hts$person[[group_var]])

  all_year <- all_trips |>
    filter(survey_year == year) |>
    select(all_of(group_var), all_mean = mean)

  plot_data <- caregiving_trips |>
    filter(survey_year == year) |>
    left_join(all_year, by = group_var) |>
    mutate(across(all_of(group_var), \(x) if (is.null(group_levels)) x else factor(x, levels = group_levels)))

  plot_data |>
    ggplot(aes(x = .data[[group_var]], y = mean, fill = .data[[group_var]])) +
    geom_col(width = 0.7) +
    errorbar_switch(
      geom_errorbar(aes(ymin = mean - mean_moe, ymax = mean + mean_moe), width = 0.15),
      on = errorbar
    ) +
    # tick mark showing the all-trips rate for reference, without the visual weight of a full bar
    geom_errorbar(aes(ymin = all_mean, ymax = all_mean),
                  width = 0.7, linewidth = 1, color = "#666666") +
    scale_fill_manual(values = color_pal) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.1))) +
    labs(x = NULL, y = NULL, title = title,
         caption = paste0(year, " caregiving trip rate; all-trip rate shown as a reference mark")) +
    coord_flip() +
    psrc_style() +
    theme(
      legend.position = "none",
      panel.grid.major.x = element_blank()
    )
}

plot_aggregate_trend <- function(overall_trend, years, title,
                                 color = psrc_colors$pognbgy_5[1]) {
  overall_trend |>
    filter(survey_year %in% years) |>
    ggplot(aes(x = factor(survey_year), y = mean, group = 1)) +
    geom_line(color = color, linewidth = 1) +
    geom_point(color = color, size = 2) +
    geom_text(aes(label = scales::number(mean, accuracy = 0.01)), vjust = -0.7) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, 0.1))) +
    labs(x = NULL, y = NULL, title = title) +
    psrc_style() +
    theme(panel.grid.major.y = element_blank())
}

plot_difference_trend <- function(group_trend, overall_trend, group_var, years, title,
                                  color_pal = triprate_palette(group_var)) {
  # psrc_hts_triprate() drops factor levels, so restore the source ordering
  group_levels <- levels(df_hts$person[[group_var]])

  diff_data <- group_trend |>
    filter(survey_year %in% years, !is.na(.data[[group_var]])) |>
    left_join(overall_trend |> filter(survey_year %in% years) |> select(survey_year, overall_mean = mean),
              by = "survey_year") |>
    mutate(difference = mean - overall_mean,
           across(all_of(group_var), \(x) if (is.null(group_levels)) x else factor(x, levels = group_levels)))

  diff_data |>
    ggplot(aes(x = factor(survey_year), y = difference,
               color = .data[[group_var]], group = .data[[group_var]])) +
    geom_line(linewidth = 1) +
    geom_point(size = 2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    scale_y_continuous(limits = c(-1, 1), labels = scales::number) +
    labs(x = NULL, y = NULL, color = NULL, title = title) +
    scale_color_manual(values = color_pal) +
    psrc_style() +
    theme(panel.grid.major.y = element_blank())
}
