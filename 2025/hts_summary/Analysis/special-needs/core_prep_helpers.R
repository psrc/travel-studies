normalize_safety_source <- function(.data) {
  if ("hh_id" %in% names(.data) && !"hhid" %in% names(.data)) {
    names(.data)[names(.data) == "hh_id"] <- "hhid"
  }

  for (id_name in c("person_id", "hhid")) {
    if (id_name %in% names(.data) && "integer64" %in% class(.data[[id_name]])) {
      .data[[id_name]] <- as.numeric(as.character(.data[[id_name]]))
    }
  }

  .data
}

filter_completed_responses <- function(.data) {
  if (!"complete" %in% names(.data)) {
    return(.data)
  }

  .data[as.character(.data[["complete"]]) %in% c("2", "Complete", "complete"), , drop = FALSE]
}

income_floor_from_label <- function(values) {
  dplyr::case_when(
    stringr::str_trim(as.character(values)) == "Under $10,000" ~ 0,
    stringr::str_trim(as.character(values)) == "$10,000-$24,999" ~ 10000,
    stringr::str_trim(as.character(values)) == "$25,000-$34,999" ~ 25000,
    stringr::str_trim(as.character(values)) == "$35,000-$49,999" ~ 35000,
    stringr::str_trim(as.character(values)) == "$50,000-$74,999" ~ 50000,
    stringr::str_trim(as.character(values)) == "$75,000-$99,999" ~ 75000,
    stringr::str_trim(as.character(values)) == "$100,000-$149,999" ~ 100000,
    stringr::str_trim(as.character(values)) == "$150,000-$199,999" ~ 150000,
    stringr::str_trim(as.character(values)) == "$200,000-$249,999" ~ 200000,
    stringr::str_trim(as.character(values)) == "$250,000 or more" ~ 250000,
    TRUE ~ NA_real_
  )
}

derive_demographic_flags <- function(.data) {
  hhsize_int <- suppressWarnings(as.integer(stringr::str_extract(as.character(.data[["hhsize"]]), "^\\d+")))
  min_income <- income_floor_from_label(.data[["hhincome_detailed"]])
  income_threshold <- hhsize_int * 11000 + 20300
  age_values <- .data[["age"]]
  race_values <- .data[["race_5"]]
  vehicle_values <- .data[["vehicle_count"]]

  .data[["age65plus"]] <- ifelse(
    is.na(age_values),
    "Missing Response",
    ifelse(age_values > 64, "Yes", "No")
  )

  .data[["low_income"]] <- ifelse(
    is.na(min_income) | is.na(income_threshold),
    "Missing Response",
    ifelse(min_income < income_threshold, "Yes", "No")
  )

  .data[["race_poc"]] <- ifelse(
    is.na(race_values) | race_values == "Missing Response",
    "Missing Response",
    ifelse(race_values == "Not Selected", "Yes", ifelse(race_values == "Selected", "No", "Missing Response"))
  )

  .data[["zero_vehicles"]] <- ifelse(
    is.na(vehicle_values) | vehicle_values == "Missing Response",
    "Missing Response",
    ifelse(vehicle_values == "0 (no vehicles in my household)", "Yes", "No")
  )

  .data
}

load_safety_responses <- function(project_dir, source_view = "Elmer.safety_survey.v_responses_2025") {
  source_cache_path <- file.path(project_dir, "safety_responses.RDS")

  if (file.exists(source_cache_path)) {
    return(readRDS(source_cache_path))
  }

  library(psrcelmer)
  get_query(paste("SELECT * FROM", source_view))
}

get_ordered_label_map <- function(codebook, variable_name) {
  label_map <- codebook[codebook$variable == variable_name, c("label", "value"), drop = FALSE]
  label_map$value <- suppressWarnings(as.integer(label_map$value))
  label_map <- label_map[
    !is.na(label_map$value) & !is.na(label_map$label) & label_map$label != "" & label_map$value < 900,
    ,
    drop = FALSE
  ]
  label_map <- label_map[order(label_map$value), , drop = FALSE]
  label_map <- label_map[!duplicated(label_map$label), , drop = FALSE]

  if (nrow(label_map) == 0) {
    return(tibble::tibble(label = character(), value = integer()))
  }

  tibble::tibble(label = label_map$label, value = label_map$value)
}

encode_ordered_values <- function(values, variable_name, codebook) {
  label_map <- get_ordered_label_map(codebook, variable_name)

  if (nrow(label_map) == 0) {
    return(suppressWarnings(as.integer(values)))
  }

  if (is.numeric(values) || is.integer(values)) {
    return(as.integer(values))
  }

  value_lookup <- stats::setNames(label_map$value, label_map$label)
  encoded_values <- unname(value_lookup[as.character(values)])

  suppressWarnings(as.integer(encoded_values))
}

apply_direction_rule <- function(values, variable_name, direction_rule, codebook) {
  numeric_values <- encode_ordered_values(values, variable_name, codebook)

  if (direction_rule != "reverse") {
    return(as.integer(numeric_values))
  }

  labeled_values <- get_ordered_label_map(codebook, variable_name)$value
  labeled_values <- labeled_values[is.finite(labeled_values)]

  if (length(labeled_values) < 2) {
    return(as.integer(numeric_values))
  }

  min_value <- min(labeled_values)
  max_value <- max(labeled_values)

  as.integer(ifelse(is.na(numeric_values), NA, max_value + min_value - numeric_values))
}
