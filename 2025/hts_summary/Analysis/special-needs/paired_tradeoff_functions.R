paired_tradeoff_domains <- data.table(
  domain_id = c(
    "longer_route",
    "different_mode",
    "no_travel",
    "more_expensive_mode",
    "drive_instead",
    "avoid_active_modes"
  ),
  domain_label = c(
    "Take a longer route",
    "Choose a different mode",
    "Do not travel at all",
    "Choose a more expensive mode",
    "Drive instead of a preferred mode",
    "Avoid walking or biking"
  ),
  safety_var = c(
    "shortest_path_fear",
    "traffic_crash_worry",
    "no_safe_travel",
    "feel_safe",
    "feel_safe_crash",
    "avoid_walk_1"
  ),
  security_var = c(
    "shortest_path_assault",
    "traffic_harrassment",
    "no_harm_travel",
    "fear_assault",
    "fear_assault_2",
    "avoid_walk_2"
  )
)

normalize_label_text <- function(values) {
  normalized <- tolower(trimws(as.character(values)))
  normalized <- gsub("[[:space:]]+", " ", normalized)
  normalized[normalized %chin% c("", "na", "n/a")] <- NA_character_
  normalized
}

decode_response_label <- function(values, variable_name, codebook) {
  label_map <- codebook[variable == variable_name, .(label, value)]
  label_map[, value := suppressWarnings(as.integer(value))]
  lookup <- stats::setNames(label_map$label, as.character(label_map$value))

  raw_values <- trimws(as.character(values))
  raw_values[raw_values %chin% c("", "NA", "N/A")] <- NA_character_

  numeric_mask <- !is.na(raw_values) & grepl("^-?[0-9]+$", raw_values)
  decoded <- raw_values
  decoded[numeric_mask] <- unname(lookup[raw_values[numeric_mask]])
  decoded
}

classify_concern_response <- function(labels) {
  normalized <- normalize_label_text(labels)

  response_bucket <- fcase(
    is.na(normalized), "Missing/other",
    normalized == "often", "Often",
    normalized == "sometimes", "Sometimes",
    normalized %chin% c("seldom/never", "seldom or never", "seldom", "never"), "Seldom/never",
    normalized == "not applicable", "Not applicable",
    normalized %chin% c("prefer not to say", "don't know", "dont know", "missing response"), "Missing/other",
    default = "Missing/other"
  )

  concern_score <- fcase(
    response_bucket == "Seldom/never", 1,
    response_bucket == "Sometimes", 2,
    response_bucket == "Often", 3,
    default = NA_real_
  )

  data.table(
    response_bucket = factor(
      response_bucket,
      levels = c("Often", "Sometimes", "Seldom/never", "Not applicable", "Missing/other")
    ),
    concern_score = concern_score,
    applicable = response_bucket %chin% c("Often", "Sometimes", "Seldom/never")
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

compute_weighted_smd <- function(dt, value_col, group_col = "disability_person", group_levels = c("Yes", "No")) {
  group_yes <- dt[get(group_col) == group_levels[1]]
  group_no <- dt[get(group_col) == group_levels[2]]

  if (nrow(group_yes) == 0L || nrow(group_no) == 0L) {
    return(NA_real_)
  }

  mean_yes <- stats::weighted.mean(group_yes[[value_col]], group_yes[["person_weight"]], na.rm = TRUE)
  mean_no <- stats::weighted.mean(group_no[[value_col]], group_no[["person_weight"]], na.rm = TRUE)
  var_yes <- weighted_var(group_yes[[value_col]], group_yes[["person_weight"]])
  var_no <- weighted_var(group_no[[value_col]], group_no[["person_weight"]])
  pooled_sd <- sqrt(mean(c(var_yes, var_no), na.rm = TRUE))

  if (!is.finite(pooled_sd) || pooled_sd == 0) {
    return(NA_real_)
  }

  (mean_yes - mean_no) / pooled_sd
}

safe_svyttest <- function(dt, outcome_col, group_col = "disability_person") {
  dt <- copy(dt[!is.na(get(outcome_col))])

  if (nrow(dt) == 0L || uniqueN(dt[[group_col]]) < 2L) {
    return(data.table(
      outcome = outcome_col,
      p_value = NA_real_,
      effect_size = NA_real_
    ))
  }

  old_options <- options(
    survey.lonely.psu = getOption("survey.lonely.psu"),
    survey.adjust.domain.lonely = getOption("survey.adjust.domain.lonely")
  )
  on.exit(options(old_options), add = TRUE)
  options(survey.lonely.psu = "adjust", survey.adjust.domain.lonely = TRUE)

  design <- survey::svydesign(
    ids = ~1,
    strata = ~sample_segment,
    weights = ~person_weight,
    data = dt,
    nest = TRUE
  )

  test_object <- tryCatch(
    survey::svyttest(as.formula(sprintf("`%s` ~ `%s`", outcome_col, group_col)), design),
    error = function(e) NULL
  )

  data.table(
    outcome = outcome_col,
    p_value = if (is.null(test_object)) NA_real_ else unname(test_object$p.value),
    effect_size = compute_weighted_smd(dt, outcome_col, group_col = group_col)
  )
}

classify_effect_size <- function(values) {
  magnitude <- abs(values)

  fcase(
    is.na(magnitude), NA_character_,
    magnitude >= 0.7, "Large",
    magnitude >= 0.4, "Moderate",
    magnitude >= 0.2, "Small",
    default = "Minimal"
  )
}

summarize_weighted_totals <- function(dt, group_vars, output_name = "weighted_n", incl_na = TRUE) {
  summary_dt <- psrc.travelsurvey::psrc_sss_stat(
    dt,
    group_vars = group_vars,
    incl_na = incl_na
  ) |> setDT()

  summary_dt[, (output_name) := est]
  summary_dt[, c("count", "prop", "prop_moe", "est", "est_moe") := NULL]
  summary_dt[]
}

summarize_weighted_means <- function(dt, group_vars, stat_var, output_name, incl_na = FALSE) {
  summary_dt <- psrc.travelsurvey::psrc_sss_stat(
    dt,
    group_vars = group_vars,
    stat_var = stat_var,
    incl_na = incl_na
  ) |> setDT()

  summary_dt[, (output_name) := mean]
  summary_dt[, c("count", "min", "max", "mean", "mean_moe", "median", "median_moe") := NULL]
  summary_dt[]
}

build_paired_tradeoff_results <- function() {
  codebook <- psrcelmer::get_query(
    "SELECT variable, label, value FROM safety_survey.value_labels_2025"
  ) |> setDT()

  responses <- psrc.travelsurvey::get_psrc_sss("*") |> setDT()
  responses <- normalize_safety_source(responses)
  responses <- filter_completed_responses(responses)
  responses <- derive_demographic_flags(responses)

  required_columns <- c(
    "disability_person",
    "person_weight",
    "sample_segment",
    paired_tradeoff_domains$safety_var,
    paired_tradeoff_domains$security_var
  )
  missing_columns <- setdiff(required_columns, names(responses))

  if (length(missing_columns) > 0L) {
    stop(sprintf("Missing required columns: %s", paste(missing_columns, collapse = ", ")))
  }

  analysis_dt <- copy(responses[
    trimws(as.character(disability_person)) %chin% c("Yes", "No") &
      !is.na(person_weight) & person_weight > 0 &
      !is.na(sample_segment),
    c(
      "person_id",
      "person_weight",
      "sample_segment",
      "disability_person",
      paired_tradeoff_domains$safety_var,
      paired_tradeoff_domains$security_var
    ),
    with = FALSE
  ])

  analysis_dt[, respondent_row_id := .I]
  analysis_dt[, disability_person := factor(trimws(as.character(disability_person)), levels = c("Yes", "No"))]

  long_dt <- rbindlist(lapply(seq_len(nrow(paired_tradeoff_domains)), function(i) {
    current_domain <- paired_tradeoff_domains[i]

    rbindlist(list(
      data.table(
        respondent_row_id = analysis_dt[["respondent_row_id"]],
        person_weight = analysis_dt[["person_weight"]],
        sample_segment = analysis_dt[["sample_segment"]],
        disability_person = analysis_dt[["disability_person"]],
        domain_id = current_domain[["domain_id"]],
        domain_label = current_domain[["domain_label"]],
        concern_type = "safety",
        variable = current_domain[["safety_var"]],
        response_label = decode_response_label(analysis_dt[[current_domain[["safety_var"]]]], current_domain[["safety_var"]], codebook)
      ),
      data.table(
        respondent_row_id = analysis_dt[["respondent_row_id"]],
        person_weight = analysis_dt[["person_weight"]],
        sample_segment = analysis_dt[["sample_segment"]],
        disability_person = analysis_dt[["disability_person"]],
        domain_id = current_domain[["domain_id"]],
        domain_label = current_domain[["domain_label"]],
        concern_type = "security",
        variable = current_domain[["security_var"]],
        response_label = decode_response_label(analysis_dt[[current_domain[["security_var"]]]], current_domain[["security_var"]], codebook)
      )
    ),
    fill = TRUE)
  }), fill = TRUE)

  long_dt <- cbind(long_dt, classify_concern_response(long_dt[["response_label"]]))
  long_dt[, concern_type := factor(concern_type, levels = c("safety", "security"))]

  domain_wide <- dcast(
    long_dt[, .(
      respondent_row_id,
      domain_id,
      domain_label,
      person_weight,
      sample_segment,
      disability_person,
      concern_type,
      concern_score
    )],
    respondent_row_id + domain_id + domain_label + person_weight + sample_segment + disability_person ~ concern_type,
    value.var = "concern_score"
  )

  overall_scores <- domain_wide[
    ,
    .(
      person_weight = person_weight[1],
      sample_segment = sample_segment[1],
      disability_person = disability_person[1],
      safety_domains_answered = sum(!is.na(safety)),
      security_domains_answered = sum(!is.na(security)),
      safety_score = if (all(is.na(safety))) NA_real_ else mean(safety, na.rm = TRUE),
      security_score = if (all(is.na(security))) NA_real_ else mean(security, na.rm = TRUE)
    ),
    by = respondent_row_id
  ]

  overall_summary <- summarize_weighted_totals(overall_scores, "disability_person")
  for (summary_spec in list(
    c("safety_score", "safety_score_mean"),
    c("security_score", "security_score_mean"),
    c("safety_domains_answered", "safety_domains_answered_mean"),
    c("security_domains_answered", "security_domains_answered_mean")
  )) {
    overall_summary <- merge(
      overall_summary,
      summarize_weighted_means(
        overall_scores,
        group_vars = "disability_person",
        stat_var = summary_spec[[1]],
        output_name = summary_spec[[2]]
      ),
      by = "disability_person",
      all = TRUE,
      sort = FALSE
    )
  }

  overall_tests <- rbindlist(list(
    safe_svyttest(overall_scores, "safety_score"),
    safe_svyttest(overall_scores, "security_score")
  ))
  overall_tests[, outcome_label := fcase(
    outcome == "safety_score", "Average safety tradeoff score",
    outcome == "security_score", "Average security tradeoff score",
    default = outcome
  )]
  overall_tests[, effect_band := classify_effect_size(effect_size)]

  applicable_dt <- long_dt[applicable == TRUE & !is.na(concern_score)]

  domain_summary <- merge(
    summarize_weighted_totals(
      applicable_dt,
      group_vars = c("domain_id", "domain_label", "concern_type", "disability_person"),
      incl_na = FALSE
    ),
    summarize_weighted_means(
      applicable_dt,
      group_vars = c("domain_id", "domain_label", "concern_type", "disability_person"),
      stat_var = "concern_score",
      output_name = "mean_score",
      incl_na = FALSE
    ),
    by = c("domain_id", "domain_label", "concern_type", "disability_person"),
    all = TRUE,
    sort = FALSE
  )

  domain_gaps <- dcast(
    domain_summary,
    domain_id + domain_label + concern_type ~ disability_person,
    value.var = "mean_score"
  )
  domain_gaps[, disability_gap := Yes - No]

  domain_tests <- applicable_dt[
    ,
    safe_svyttest(.SD, "concern_score"),
    by = .(domain_id, domain_label, concern_type)
  ]

  domain_findings <- merge(domain_gaps, domain_tests, by = c("domain_id", "domain_label", "concern_type"), all.x = TRUE)
  domain_findings[, effect_band := classify_effect_size(effect_size)]
  setorder(domain_findings, -effect_size, domain_label, concern_type)

  response_summary <- summarize_weighted_totals(
    long_dt,
    group_vars = c("domain_id", "domain_label", "concern_type", "disability_person", "response_bucket")
  )
  response_summary[, weighted_prop := weighted_n / sum(weighted_n), by = .(domain_id, concern_type, disability_person)]

  top_domains <- domain_findings[!is.na(p_value) & p_value < 0.05][order(-effect_size), unique(domain_id)]
  if (length(top_domains) == 0L) {
    top_domains <- paired_tradeoff_domains$domain_id
  }

  focus_response_summary <- response_summary[
    domain_id %chin% head(top_domains, 4L) &
      response_bucket %chin% c("Often", "Sometimes", "Seldom/never")
  ]

  list(
    overall_scores = overall_scores,
    overall_summary = overall_summary,
    overall_tests = overall_tests,
    domain_findings = domain_findings,
    response_summary = response_summary,
    focus_response_summary = focus_response_summary
  )
}