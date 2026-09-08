# Standalone smoke test / demo for bundle_sss_stat() and plot_facet_sss_bundle().
#
# The real SSS data-prep pipeline (querying Elmer via get_psrc_sss() and recoding raw
# numeric responses to factors) has moved to another repo. To exercise these two
# functions here without that dependency, this script builds a small synthetic
# person-level SSS dataset using the local value_labels.csv/variable_descriptions.csv
# as the source of truth for realistic column names and response levels.

library(data.table)

source("bundle_sss_stat.R")
source("plot_facet_sss_bundle.R")

set.seed(42)

value_labels <- fread("data/value_labels.csv", colClasses = "character")

# Build a factor-sampling helper for one Likert/frequency-style question variable,
# with `bias` shifting the sampling toward higher (more concerned) response levels.
sample_question <- function(n, variable, bias = 0) {
  levels_dt <- value_labels[value_labels$variable == variable & value_labels$label != ""]
  levels_dt <- levels_dt[order(as.integer(value))]
  levs <- levels_dt$label
  weights <- (seq_along(levs) + bias)
  weights[weights < 0.1] <- 0.1
  sample(levs, size = n, replace = TRUE, prob = weights / sum(weights))
}

n <- 1200
sss_data <- data.table(
  person_id = seq_len(n),
  person_weight = runif(n, 0.4, 2.5),
  sample_segment = sample(paste0("segment_", 1:6), n, replace = TRUE)
)

# Roughly 30% of respondents report having experienced a personal security concern.
sss_data[, security_concern := sample(c("Selected", "Not Selected"), n, replace = TRUE, prob = c(0.3, 0.7))]
sss_data[, security_concern_group := fifelse(
  security_concern == "Selected",
  "Experienced a security concern",
  "Never experienced a security concern"
)]

# The seven "worry about safety/security while traveling" questions shown in the
# reference chart, in display order, biased so the "experienced" group answers
# higher (more worried) on average.
question_vars <- c(
  "worry_destination", "travel_anxiety", "alert_traveler",
  "urgent_worry", "traffic_worry", "travel_worry", "drive_worry"
)
for (v in question_vars) {
  bias_experienced <- sample_question(sum(sss_data$security_concern == "Selected"), v, bias = 1)
  bias_never <- sample_question(sum(sss_data$security_concern == "Not Selected"), v, bias = -1)
  sss_data[security_concern == "Selected", (v) := bias_experienced]
  sss_data[security_concern == "Not Selected", (v) := bias_never]
}

question_ids <- c("5.13", "5.05", "5.10", "5.03", "5.01", "5.07", "5.11")

bundle <- bundle_sss_stat(
  sss_data,
  question_ids = question_ids,
  group_var = "security_concern_group",
  endorse_values = c("Agree", "Strongly agree")
)

print(bundle)

p <- plot_facet_sss_bundle(bundle, group_var = "security_concern_group")
print(p)
