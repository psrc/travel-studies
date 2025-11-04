source("functions.R")

# read data
safety_responses <- get_query("SELECT * FROM safety_20251029.safety_responses", db_name = config$db_raw) %>%
  # only include completed responses
  filter(complete == 2)
