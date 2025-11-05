source("functions.R")

# Check if the file exists
if (file.exists("safety_responses.RDS")) {
  safety_responses <- readRDS("safety_responses.RDS")
} else {
  # read data
  safety_responses <- get_query("SELECT * FROM safety_20251029.safety_responses", db_name = config$db_raw) %>%
    # only include completed responses
    filter(complete == 2) %>%
    # remove sensitive data
    select(-any_of(c("ip_lon", "ip_lat", "work_loc_1", "work_loc_2", "work_loc_3", "work_loc_4", "work_loc_5", 
                     "home_lon", "home_lat", "work_lat", "work_lon", "work_loc_flag", 
                     "home_loc_1", "home_loc_2", "home_loc_3", "home_loc_4", "home_loc_5", "home_loc_flag", 
                     "invite_lat", "invite_lon")))
  saveRDS(safety_responses, "safety_responses.RDS")
}

