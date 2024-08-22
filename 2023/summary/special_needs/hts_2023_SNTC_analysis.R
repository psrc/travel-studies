library(magrittr)
library(dplyr)
library(psrc.travelsurvey)
library(travelSurveyTools)
library(data.table)
library(psrcplot)

sn_vars <- c("age", "race_category_2023_b", "vehicle_count",                                       # Special needs dimensions
             "hhincome_broad", "disability_person")
travel_dims <- c("dest_purpose_cat", "telework_time", "mode_characterization",                     # Travel behavior variables
                 "num_trips", "distance_miles", "duration_minutes", "travelers_total")

battery <- function(sn_var){                                                                       # Statistical summaries for each SN dimension
  hts_data2 <- copy(hts_data)
  if(sn_var=="disability_person"){
    hts_data2 %<>% lapply(FUN=function(x) dplyr::filter(x, survey_year==2023))                     # -- disability is new to the survey
  }
  sn_stat <- purrr::partial(psrc_hts_stat, hts_data2, ... = , incl_na=FALSE)                       # excluding NA from share denominator
  rs <- list()
  rs$tripcount     <- sn_stat("person", c("adult", sn_var), "num_trips")
  rs$purpose_share <- sn_stat("trip",   c("adult", sn_var, "dest_purpose_cat"))
  rs$mode_share    <- sn_stat("trip",   c("adult", sn_var, "mode_characterization"))
  rs$distance      <- sn_stat("trip",   c("adult", sn_var), "distance_miles")
  rs$minutes       <- sn_stat("trip",   c("adult", sn_var), "duration_minutes")
  rs %<>% lapply(FUN=function(x) dplyr::select(x, -adult))                                         # Drop filter column
  return(rs)
}

hts_data <- get_psrc_hts(survey_vars=c(sn_vars, travel_dims))                                      # Retrieve the data
hts_data %<>% hts_bin_age(3) %>% hts_bin_income()                                                  # Add standard group variables
hts_data$person %<>% mutate(
  adult=case_when(substr(age_bin3, 1L, 2L) %in% c("18","65") ~"Adult", TRUE ~ NA))                 # Restricting stats to adult trips
sn_vars %<>% case_match("age" ~ "age_bin3", "hhincome_broad" ~ "hhincome_bin5", .default=sn_vars)  # Swap in standard groups
rs_master <- sapply(sn_vars, battery, simplify=FALSE, USE.NAMES=TRUE)                              # Run the analysis batches






