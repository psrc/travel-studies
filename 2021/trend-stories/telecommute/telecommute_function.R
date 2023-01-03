# Function to get travel survey telecommute data for travel story
library(dplyr)
library(magrittr)
library(psrc.travelsurvey)

get_telecommute_data <- function(survey, stat_var, group_vars, weight, incl_na = TRUE) {
  
  if(survey == "2021") {
    sdf <- get_hhts(survey = survey,
                    level = "p",
                    vars = c("age_category",
                             "worker",
                             "workplace",
                             "gender",
                             "race_eth_poc",
                             "telecommute_freq",
                             "benefits_1",
                             "benefits_2",
                             "benefits_3",
                             "industry")) %>% 
      filter(age_category != "Under 18 years"
             & worker != "No jobs")
  } else {
    sdf <- get_hhts(survey = survey,
                    level = "p",
                    vars = c("age_category",
                             "worker",
                             "employment",
                             "workplace",
                             "gender",
                             "race_eth_poc",
                             "telecommute_freq",
                             "benefits_1",
                             "benefits_2",
                             "benefits_3")) %>% 
      filter(age_category != "Under 18 years"
             & worker != "No jobs")
  }
  
  stats <- hhts_count(df = sdf,
                      stat_var = stat_var,
                      group_vars = group_vars,
                      spec_wgt = weight,
                      incl_na = incl_na)
  
  return(stats)
  
}
