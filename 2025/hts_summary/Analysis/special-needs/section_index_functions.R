normalize_safety_source <- function(dt) {
  if ("hh_id" %in% names(dt) && !"hhid" %in% names(dt)) {
    setnames(dt, "hh_id", "hhid")
  }

  for (id_name in c("person_id", "hhid")) {
    if (id_name %in% names(dt) && inherits(dt[[id_name]], "integer64")) {
      dt[, (id_name) := as.numeric(as.character(get(id_name)))]
    }
  }

  dt
}

filter_completed_responses <- function(dt) {
  if (!"complete" %in% names(dt)) {
    return(dt)
  }

  dt[as.character(complete) %in% c("2", "Complete", "complete")]
}

income_floor_from_label <- function(values) {
  data.table::fcase(
    trimws(as.character(values)) == "Under $10,000", 0,
    trimws(as.character(values)) == "$10,000-$24,999", 10000,
    trimws(as.character(values)) == "$25,000-$34,999", 25000,
    trimws(as.character(values)) == "$35,000-$49,999", 35000,
    trimws(as.character(values)) == "$50,000-$74,999", 50000,
    trimws(as.character(values)) == "$75,000-$99,999", 75000,
    trimws(as.character(values)) == "$100,000-$149,999", 100000,
    trimws(as.character(values)) == "$150,000-$199,999", 150000,
    trimws(as.character(values)) == "$200,000-$249,999", 200000,
    trimws(as.character(values)) == "$250,000 or more", 250000,
    default = NA_real_
  )
}

derive_demographic_flags <- function(dt) {
  hhsize_values <- if ("hhsize" %in% names(dt)) dt[["hhsize"]] else NA_character_
  income_values <- if ("hhincome_detailed" %in% names(dt)) dt[["hhincome_detailed"]] else NA_character_
  age_values <- if ("age" %in% names(dt)) dt[["age"]] else NA_real_
  race_values <- if ("race_5" %in% names(dt)) dt[["race_5"]] else NA_character_
  vehicle_values <- if ("vehicle_count" %in% names(dt)) dt[["vehicle_count"]] else NA_character_

  hhsize_int <- suppressWarnings(as.integer(sub("^([0-9]+).*$", "\\1", as.character(hhsize_values))))
  hhsize_int[!grepl("^[0-9]+", as.character(hhsize_values))] <- NA_integer_
  min_income <- income_floor_from_label(income_values)
  income_threshold <- hhsize_int * 11000 + 20300

  dt[, age65plus := fifelse(
    is.na(age_values),
    "Missing Response",
    fifelse(age_values > 64, "Yes", "No")
  )]

  dt[, low_income := fifelse(
    is.na(min_income) | is.na(income_threshold),
    "Missing Response",
    fifelse(min_income < income_threshold, "Yes", "No")
  )]

  dt[, race_poc := fifelse(
    is.na(race_values) | race_values == "Missing Response",
    "Missing Response",
    fifelse(race_values == "Not Selected", "Yes", fifelse(race_values == "Selected", "No", "Missing Response"))
  )]

  dt[, zero_vehicles := fifelse(
    is.na(vehicle_values) | vehicle_values == "Missing Response",
    "Missing Response",
    fifelse(vehicle_values == "0 (no vehicles in my household)", "Yes", "No")
  )]

  dt
}

get_ordered_label_map <- function(codebook, variable_name) {
  label_map <- copy(codebook[variable == variable_name, .(label, value)])
  label_map[, value := suppressWarnings(as.integer(value))]
  label_map <- label_map[
    !is.na(value) & !is.na(label) & label != "" & value < 900
  ][order(value)]
  label_map <- unique(label_map, by = "label")

  if (nrow(label_map) == 0L) {
    return(data.table(label = character(), value = integer()))
  }

  label_map
}

encode_ordered_values <- function(values, variable_name, codebook) {
  label_map <- get_ordered_label_map(codebook, variable_name)

  if (nrow(label_map) == 0L) {
    return(suppressWarnings(as.integer(values)))
  }

  if (is.numeric(values) || is.integer(values)) {
    return(as.integer(values))
  }

  value_lookup <- stats::setNames(label_map$value, label_map$label)
  suppressWarnings(as.integer(unname(value_lookup[as.character(values)])))
}

apply_direction_rule <- function(values, variable_name, direction_rule, codebook) {
  numeric_values <- encode_ordered_values(values, variable_name, codebook)

  if (!identical(direction_rule, "reverse")) {
    return(as.integer(numeric_values))
  }

  labeled_values <- get_ordered_label_map(codebook, variable_name)$value
  labeled_values <- labeled_values[is.finite(labeled_values)]

  if (length(labeled_values) < 2L) {
    return(as.integer(numeric_values))
  }

  min_value <- min(labeled_values)
  max_value <- max(labeled_values)

  as.integer(ifelse(is.na(numeric_values), NA, max_value + min_value - numeric_values))
}

safe_quantile <- function(x, prob) {
  if (all(is.na(x))) {
    return(NA_real_)
  }

  as.numeric(stats::quantile(x, probs = prob, na.rm = TRUE, names = FALSE, type = 7))
}

compute_standardized_alpha <- function(correlation_matrix) {
  if (is.null(correlation_matrix) || ncol(correlation_matrix) < 2L) {
    return(NA_real_)
  }

  lower_values <- correlation_matrix[lower.tri(correlation_matrix)]
  lower_values <- lower_values[is.finite(lower_values)]

  if (length(lower_values) == 0L) {
    return(NA_real_)
  }

  item_count <- ncol(correlation_matrix)
  mean_inter_item_correlation <- mean(lower_values)

  (item_count * mean_inter_item_correlation) / (1 + (item_count - 1) * mean_inter_item_correlation)
}

compute_omega_total <- function(correlation_matrix, n_obs) {
  if (is.null(correlation_matrix) || ncol(correlation_matrix) < 3L || is.na(n_obs) || n_obs < 2L) {
    return(list(value = NA_real_, note = "omega_not_available"))
  }

  tryCatch(
    {
      omega_fit <- suppressWarnings(
        psych::omega(
          m = correlation_matrix,
          n.obs = n_obs,
          plot = FALSE,
          warnings = FALSE,
          fm = "minres"
        )
      )

      list(value = as.numeric(omega_fit$omega.tot), note = "omega_total_polychoric")
    },
    error = function(e) {
      list(value = NA_real_, note = paste("omega_error:", conditionMessage(e)))
    }
  )
}

compute_polychoric_matrix <- function(item_data) {
  valid_items <- names(item_data)[vapply(item_data, function(values) {
    non_missing <- values[!is.na(values)]
    length(non_missing) > 1L && data.table::uniqueN(non_missing) > 1L
  }, logical(1))]

  if (length(valid_items) < 2L) {
    return(list(rho = NULL, item_names = valid_items, note = "fewer_than_two_variable_items"))
  }

  ordered_data <- lapply(item_data[, ..valid_items], function(values) {
    ordered(values, levels = sort(unique(values[!is.na(values)])))
  })
  ordered_data <- as.data.frame(ordered_data)

  tryCatch(
    {
      polychoric_fit <- suppressWarnings(psych::polychoric(ordered_data))
      list(
        rho = psych::cor.smooth(polychoric_fit$rho),
        item_names = valid_items,
        note = "polychoric"
      )
    },
    error = function(e) {
      list(rho = NULL, item_names = valid_items, note = paste("polychoric_error:", conditionMessage(e)))
    }
  )
}

compute_numeric_alpha <- function(item_data) {
  if (ncol(item_data) < 2L) {
    return(NA_real_)
  }

  tryCatch(
    {
      alpha_fit <- psych::alpha(as.data.frame(item_data), check.keys = FALSE, warnings = FALSE)
      as.numeric(alpha_fit$total$raw_alpha)
    },
    error = function(e) NA_real_
  )
}

compute_corrected_item_rest <- function(item_data, item_name) {
  other_items <- setdiff(names(item_data), item_name)

  if (length(other_items) == 0L) {
    return(NA_real_)
  }

  other_matrix <- as.matrix(item_data[, ..other_items])
  other_counts <- rowSums(!is.na(other_matrix))
  other_mean <- rowMeans(other_matrix, na.rm = TRUE)
  other_mean[other_counts == 0L] <- NA_real_

  suppressWarnings(stats::cor(item_data[[item_name]], other_mean, use = "pairwise.complete.obs"))
}

compute_alpha_if_dropped <- function(item_data, item_name) {
  remaining_items <- setdiff(names(item_data), item_name)

  if (length(remaining_items) < 2L) {
    return(NA_real_)
  }

  reduced_data <- item_data[, ..remaining_items]
  polychoric_result <- compute_polychoric_matrix(reduced_data)

  if (!is.null(polychoric_result$rho)) {
    return(compute_standardized_alpha(polychoric_result$rho))
  }

  compute_numeric_alpha(reduced_data)
}

compute_reliability <- function(item_data) {
  complete_case_n <- sum(stats::complete.cases(item_data))
  polychoric_result <- compute_polychoric_matrix(item_data)

  if (!is.null(polychoric_result$rho)) {
    ordinal_alpha <- compute_standardized_alpha(polychoric_result$rho)
    omega_result <- compute_omega_total(polychoric_result$rho, complete_case_n)

    return(list(
      alpha = ordinal_alpha,
      omega_total = omega_result$value,
      reliability_method = ifelse(
        is.na(omega_result$value),
        "ordinal_alpha_polychoric_only",
        "ordinal_alpha_polychoric_and_omega_total_polychoric"
      ),
      reliability_note = paste(polychoric_result$note, omega_result$note, sep = " | "),
      complete_case_n = complete_case_n,
      item_names = polychoric_result$item_names
    ))
  }

  list(
    alpha = compute_numeric_alpha(item_data),
    omega_total = NA_real_,
    reliability_method = "numeric_alpha_fallback",
    reliability_note = polychoric_result$note,
    complete_case_n = complete_case_n,
    item_names = names(item_data)
  )
}

weighted_var <- function(x, w) {
  keep <- !is.na(x) & !is.na(w) & w > 0

  if (!any(keep)) {
    return(NA_real_)
  }

  x <- x[keep]
  w <- w[keep]
  mean_x <- stats::weighted.mean(x, w)
  sum_w <- sum(w)

  if (sum_w <= 0) {
    return(NA_real_)
  }

  sum(w * (x - mean_x)^2) / sum_w
}

compute_weighted_smd <- function(dt, score_var, respondent_dichotomy, comparison_groups) {
  if (length(comparison_groups) != 2L) {
    return(NA_real_)
  }

  group_1 <- dt[get(respondent_dichotomy) == comparison_groups[1]]
  group_2 <- dt[get(respondent_dichotomy) == comparison_groups[2]]

  if (nrow(group_1) == 0L || nrow(group_2) == 0L) {
    return(NA_real_)
  }

  mean_1 <- stats::weighted.mean(group_1[[score_var]], group_1[["person_weight"]])
  mean_2 <- stats::weighted.mean(group_2[[score_var]], group_2[["person_weight"]])
  var_1 <- weighted_var(group_1[[score_var]], group_1[["person_weight"]])
  var_2 <- weighted_var(group_2[[score_var]], group_2[["person_weight"]])
  pooled_sd <- sqrt(mean(c(var_1, var_2), na.rm = TRUE))

  if (!is.finite(pooled_sd) || pooled_sd == 0) {
    return(NA_real_)
  }

  (mean_1 - mean_2) / pooled_sd
}

classify_effect_size <- function(weighted_smd) {
  data.table::fcase(
    is.na(weighted_smd), NA_character_,
    abs(weighted_smd) < 0.2, "negligible",
    abs(weighted_smd) < 0.5, "small",
    abs(weighted_smd) < 0.8, "moderate",
    default = "large"
  )
}

classify_significance <- function(p_value) {
  data.table::fcase(
    is.na(p_value), NA_character_,
    p_value < 0.001, "very strong evidence",
    p_value < 0.05, "clear evidence",
    default = "no clear evidence"
  )
}

build_section_index_ranked_dotplot <- function(demographic_results, preferred_order = c("disability_person", "low_income")) {
  dt_plot <- copy(demographic_results)

  if (nrow(dt_plot) == 0L) {
    message("No demographic comparison rows were available for plotting.")
    return(NULL)
  }

  dt_plot[, `:=`(
    weighted_smd = fifelse(is.finite(weighted_smd), weighted_smd, NA_real_),
    index_label = fcoalesce(index_label, index_id)
  )]

  dt_plot[, `:=`(
    neg_log10_p = -log10(p_value),
    significant = p_value < 0.05
  )]

  dt_plot <- dt_plot[
    !is.na(respondent_dichotomy) &
      !is.na(index_label) &
      !is.na(weighted_smd) &
      is.finite(weighted_smd)
  ]

  if (nrow(dt_plot) == 0L) {
    message("No valid demographic comparison rows remained after plot filtering.")
    return(NULL)
  }

  resp_ranked <- dt_plot[
    , .(max_val = max(abs(weighted_smd), na.rm = TRUE)),
    by = respondent_dichotomy
  ][order(-max_val), as.character(respondent_dichotomy)]
  resp_top_to_bottom <- c(preferred_order[preferred_order %chin% resp_ranked], setdiff(resp_ranked, preferred_order))
  index_order <- dt_plot[
    , .(max_val = max(abs(weighted_smd), na.rm = TRUE)),
    by = index_label
  ][order(-max_val), index_label]

  dt_plot[, `:=`(
    respondent_dichotomy = factor(as.character(respondent_dichotomy), levels = rev(resp_top_to_bottom)),
    index_label = factor(index_label, levels = index_order)
  )]

  color_ramp <- c("#ffffcc", "#a1dab4", "#41b6c4", "#2c7fb8", "#253494")
  max_abs_smd <- max(abs(dt_plot$weighted_smd), na.rm = TRUE)
  x_limit <- max(0.25, ceiling(max_abs_smd * 4) / 4)

  p_breaks <- c(0, -log10(0.05), 2, 3, 5)
  actual_breaks <- p_breaks[p_breaks <= max(dt_plot$neg_log10_p, na.rm = TRUE)]
  if (length(actual_breaks) < 2L) {
    actual_breaks <- unique(c(0, max(dt_plot$neg_log10_p, na.rm = TRUE)))
  }

  ggplot2::ggplot(dt_plot, ggplot2::aes(x = weighted_smd, y = respondent_dichotomy)) +
    ggplot2::geom_vline(xintercept = 0, color = "grey55", linewidth = 0.5, linetype = "dashed") +
    ggplot2::geom_point(
      data = dt_plot[significant == FALSE],
      shape = 21,
      fill = NA,
      size = 4.1,
      color = "grey20",
      stroke = 0.45,
      alpha = 0.95
    ) +
    ggplot2::geom_point(
      data = dt_plot[significant == TRUE],
      ggplot2::aes(fill = neg_log10_p),
      shape = 21,
      color = "grey20",
      size = 4.1,
      stroke = 0.45,
      alpha = 0.95
    ) +
    ggplot2::facet_wrap(ggplot2::vars(index_label), ncol = 1) +
    ggplot2::scale_y_discrete(limits = rev(resp_top_to_bottom)) +
    ggplot2::scale_x_continuous(
      limits = c(-x_limit, x_limit),
      breaks = scales::pretty_breaks(n = 5),
      expand = ggplot2::expansion(mult = c(0.02, 0.04))
    ) +
    ggplot2::scale_fill_gradientn(
      name = "p-value\n(darker = lower)",
      colours = color_ramp,
      breaks = actual_breaks,
      labels = function(x) {
        val <- 10^(-x)
        ifelse(val < 0.001, formatC(val, format = "e", digits = 1), formatC(val, format = "f", digits = 3))
      },
      guide = ggplot2::guide_colorbar(
        order = 1,
        title.position = "top",
        barwidth = grid::unit(7, "cm"),
        barheight = grid::unit(0.45, "cm")
      )
    ) +
    ggplot2::labs(
      title = "Weighted section-index differences across respondent groups",
      x = "Weighted standardized mean difference",
      y = "Respondent dichotomy"
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      panel.spacing.y = grid::unit(0.55, "lines"),
      strip.text = ggplot2::element_text(face = "bold"),
      legend.position = "bottom",
      legend.box = "vertical",
      legend.title.align = 0.5,
      axis.text.y = ggplot2::element_text(face = "bold"),
      plot.title.position = "plot"
    )
}
