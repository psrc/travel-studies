fit_caregiving_ols <- function(hts_data) {
  required_levels <- list(
    survey_year = "2025",
    gender2 = "Men",
    race_simpler = "White",
    age_bin4 = "25-64 Years",
    low_income = "No"
  )

  demographics <- hts_data$person |>
    select(person_id, gender2, race_simpler, age_bin4, low_income)

  caregiving_counts <- hts_data$trip |>
    filter(care_purpose_cat == "Care") |>
    count(day_id, name = "caregiving_trips")

  model_data <- hts_data$day |>
    select(day_id, person_id, survey_year, day_weight) |>
    left_join(demographics, by = "person_id") |>
    left_join(caregiving_counts, by = "day_id") |>
    mutate(
      caregiving_trips = replace_na(caregiving_trips, 0L),
      survey_year = factor(as.character(survey_year)),
      gender2 = factor(as.character(gender2)),
      race_simpler = factor(as.character(race_simpler)),
      age_bin4 = factor(as.character(age_bin4)),
      low_income = factor(as.character(low_income))
    ) |>
    filter(
      !is.na(survey_year),
      !is.na(gender2),
      !is.na(race_simpler),
      !is.na(age_bin4),
      !is.na(low_income),
      !is.na(day_weight)
    )

  candidate_predictors <- names(required_levels)
  factor_levels <- map_int(candidate_predictors, \(variable) {
    nlevels(droplevels(model_data[[variable]]))
  })

  valid_predictors <- candidate_predictors[factor_levels >= 2]
  dropped_predictors <- candidate_predictors[factor_levels < 2]

  if (length(dropped_predictors) > 0) {
    message(
      sprintf(
        "Dropping predictors with fewer than 2 observed levels: %s",
        paste(dropped_predictors, collapse = ", ")
      )
    )
  }

  for (variable in valid_predictors) {
    reference_level <- required_levels[[variable]]

    if (!reference_level %in% levels(model_data[[variable]])) {
      stop(sprintf("Reference level '%s' is not present in %s.",
                   reference_level, variable))
    }

    model_data[[variable]] <- relevel(model_data[[variable]], ref = reference_level)
  }

  model_formula <- if (length(valid_predictors) > 0) {
    reformulate(valid_predictors, response = "caregiving_trips")
  } else {
    caregiving_trips ~ 1
  }

  model <- lm(
    model_formula,
    data = model_data,
    weights = day_weight
  )

  list(
    model = model,
    coefficients = broom::tidy(model, conf.int = TRUE),
    model_data = model_data,
    included_predictors = valid_predictors,
    dropped_predictors = dropped_predictors
  )
}