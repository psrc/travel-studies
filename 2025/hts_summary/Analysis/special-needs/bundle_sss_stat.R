library(data.table)
library(psrc.travelsurvey)

var_desc <- psrcelmer::get_table(schema="safety_survey", tbl="variable_descriptions_2025")

# Resolve a vector of question numbers (or variable names) against the
# var_desc table, in the order given. Errors if an id is missing or
# ambiguous (a question number shared by multiple checkbox-item variables).
lookup_sss_questions <- function(question_ids, lookup = var_desc) {
  lookup <- data.table::as.data.table(lookup)
  if ("q_id" %in% names(lookup) && !"question_id" %in% names(lookup)) {
    data.table::setnames(lookup, "q_id", "question_id")
  }

  purrr::map_dfr(question_ids, function(id) {
    match_by_id <- lookup[question_id == id]
    if (nrow(match_by_id) == 1) {
      return(match_by_id)
    }
    if (nrow(match_by_id) > 1) {
      stop(sprintf(
        "Question number '%s' matches multiple variables (%s); pass the variable name(s) directly instead.",
        id, paste(match_by_id$variable, collapse = ", ")
      ))
    }
    match_by_var <- lookup[variable == id]
    if (nrow(match_by_var) == 1) {
      return(match_by_var)
    }
    stop(sprintf("Question number/variable '%s' not found in lookup table.", id))
  })
}

#' Bundle safety & security survey (SSS) summary statistics for a set of questions
#'
#' Wraps `psrc.travelsurvey::psrc_sss_stat()` to produce, for each question, a "share" of
#' respondents endorsing one or more response values (e.g. top-2-box "Agree"/"Strongly agree"
#' on a Likert item), optionally broken down by a single grouping variable.
#'
#' @param sss_data data.table at the person level with primary key `person_id`, including
#'   `person_weight` (post-stratification weight) and `sample_segment` (survey strata)
#' @param question_ids character vector of question numbers (e.g. `c("5.13", "5.05")`, matched
#'   against `question_id` in `var_desc`), or variable names directly
#' @param group_var optional string, name of a single grouping variable in `sss_data` for breakdowns
#' @param endorse_values character vector of response values to combine into `share`
#'   (e.g. `c("Agree", "Strongly agree")` for Likert items, `c("Sometimes", "Often")` for frequency items)
#' @param overall logical, whether to include an "Overall" row (unbroken by `group_var`) as the first row
#' @param lookup data.frame/data.table containing question lookup definitions (defaults to `var_desc`; see `lookup_sss_questions()`)
#' @param override_q_text optional character vector the same length as `question_ids`, used verbatim as
#'   the facet label instead of the looked-up question `description`. Use `NA` for elements that should
#'   keep the looked-up description.
#' @return named list (one element per question, named by `question_id`) of data.tables with
#'   the breakdown column (`group_var`, or `"group"` if `group_var` is NULL), `share`, `share_moe`,
#'   `count`, `question_id`, and `description`
bundle_sss_stat <- function(sss_data,
                            question_ids,
                            group_var = NULL,
                            endorse_values,
                            overall = TRUE,
                            lookup = var_desc,
                            override_q_text = NULL) {
  stopifnot(is.data.frame(sss_data))
  required_cols <- c("person_id", "person_weight", "sample_segment")
  missing_cols <- setdiff(required_cols, colnames(sss_data))
  if (length(missing_cols) > 0) {
    stop(sprintf("`sss_data` is missing required column(s): %s", paste(missing_cols, collapse = ", ")))
  }
  if (!is.null(group_var) && length(group_var) != 1) {
    stop("`group_var` must be a single variable name.")
  }
  if (missing(endorse_values) || length(endorse_values) == 0) {
    stop("`endorse_values` must specify one or more response values to combine into `share`.")
  }
  if (!isTRUE(overall) && is.null(group_var)) {
    stop("`overall = FALSE` requires `group_var` to be specified.")
  }
  if (!is.null(override_q_text) && length(override_q_text) != length(question_ids)) {
    stop("`override_q_text` must be the same length as `question_ids`.")
  }

  group_col <- if (is.null(group_var)) "group" else group_var
  questions <- lookup_sss_questions(question_ids, lookup = lookup)
  if (!is.null(override_q_text)) {
    keep <- !is.na(override_q_text)
    questions$description[keep] <- override_q_text[keep]
  }

  # Sum the per-level proportions (and combine MOEs assuming independence) across
  # the endorsed response levels, optionally by group_cols.
  summarize_share <- function(stat_dt, group_cols, question_var) {
    stat_dt <- stat_dt[as.character(get(question_var)) %in% endorse_values]
    by_cols <- if (length(group_cols) == 0) NULL else group_cols
    stat_dt[, .(share = sum(prop), share_moe = sqrt(sum(prop_moe^2)), count = sum(count)), by = by_cols]
  }

  result <- purrr::pmap(questions, function(question_id, variable, description, ...) {
    overall_dt <- NULL
    if (isTRUE(overall)) {
      raw_overall <- psrc.travelsurvey::psrc_sss_stat(sss_data, group_vars = variable)
      overall_dt <- summarize_share(raw_overall, character(0), variable)
      overall_dt[, (group_col) := "Overall"]
    }

    if (!is.null(group_var)) {
      raw_grp <- psrc.travelsurvey::psrc_sss_stat(sss_data, group_vars = c(group_var, variable), incl_na = FALSE)
      grp_dt <- summarize_share(raw_grp, group_var, variable)
      combined <- if (isTRUE(overall)) {
        data.table::rbindlist(list(overall_dt, grp_dt), use.names = TRUE)
      } else {
        grp_dt
      }
    } else {
      combined <- overall_dt
    }

    combined[, `:=`(question_id = question_id, description = description)]
    data.table::setcolorder(combined, c(group_col, "share", "share_moe", "count", "question_id", "description"))
    combined[]
  })

  names(result) <- questions$question_id
  result
}
