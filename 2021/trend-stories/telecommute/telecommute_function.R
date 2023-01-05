# Function to get travel survey telecommute data for travel story
library(tidyverse)
library(psrc.travelsurvey)

get_telecommute_data <- function(survey, stat_var, group_vars, weight, incl_na = TRUE) {
  
  if(survey == "2021") {
    sdf <- get_hhts(survey = survey,
                    level = "p",
                    vars = c("age_category",
                             "worker",
                             "workplace",
                             "gender",
                             "race_category",
                             "race_eth_poc",
                             "telecommute_freq",
                             "benefits_1",
                             "benefits_2",
                             "benefits_3",
                             "industry")) %>% 
      filter(age_category != "Under 18 years"
             & worker != "No jobs") %>% 
      mutate(telecommute_freq_cond = case_when(telecommute_freq %in% c("1-2 days", "3-4 days", "5+ days")
                                                 ~ "1+ days per week",
                                               !is.na(telecommute_freq) ~ telecommute_freq),
             workplace_travel = case_when(workplace %in% c("Usually the same location (outside home)",
                                                           "Workplace regularly varies (different offices or jobsites)",
                                                           "Drives for a living (e.g., bus driver, salesperson)")
                                            ~ "Works outside the home",
                                          workplace %in% c("Telework some days and travel to a work location some days",
                                                           "At home (telecommute or self-employed with home office)")
                                            ~ "Works at home",
                                          !is.na(workplace) ~ workplace),
             gender_group = case_when(gender %in% c("Not listed here / prefer not to answer", "Non-Binary")
                                        ~ "Prefer not to answer / Another",
                                      !is.na(gender) ~ gender),
             industry = str_trim(industry)) %>% 
      mutate(industry_cond = case_when(
        industry %in% c("Construction", "Natural resources (e.g., forestry, fishery, energy)")
          ~ "Construction & Resources",
        industry == "Personal services (e.g., hair styling, personal assistance, pet sitting)"
          ~ "Personal Services",
        industry == "Manufacturing (e.g., aerospace & defense, electrical, machinery)"
          ~ "Manufacturing",
        industry %in% c("Financial services", "Real estate")
          ~ "Finance & Real Estate",
        industry %in% c("Public education", "Private education")
          ~ "Education (all)",
        industry %in% c("Health care", "Social assistance", "Childcare (e.g., nanny, babysitter)")
          ~ "Health Care, Social Services, & Childcare",
        industry %in% c("Arts and entertainment", "Media")
          ~ "Media & Entertainment",
        industry %in% c("Hospitality (e.g., restaurant, accommodation)", "Retail")
          ~ "Hospitality & Retail",
        industry %in% c("Landscaping", "Sports and fitness", "Other")
          ~ "Other",
        industry == "Government"
          ~ "Government",
        industry == "Military"
          ~ "Military",
        industry == "Missing: Skip Logic"
          ~ "Missing",
        industry == "Professional and business services (e.g., consulting, legal, marketing)"
          ~ "Professional & Business Services",
        industry == "Technology and telecommunications"
          ~ "Technology & Telecommunications",
        industry == "Transportation and utilities"
          ~ "Transportation & Utilities"))
  } else {
    sdf <- get_hhts(survey = survey,
                    level = "p",
                    vars = c("age_category",
                             "worker",
                             "employment",
                             "workplace",
                             "gender",
                             "race_category",
                             "race_eth_poc",
                             "telecommute_freq",
                             "benefits_1",
                             "benefits_2",
                             "benefits_3")) %>% 
      filter(age_category != "Under 18 years"
             & worker != "No jobs") %>% 
      mutate(telecommute_freq = case_when(telecommute_freq %in% c("1 day a week", "2 days a week") ~ "1-2 days", 
                                          telecommute_freq %in% c("3 days a week", "4 days a week") ~ "3-4 days", 
                                          telecommute_freq %in% c("5 days a week", "6-7 days a week") ~ "5+ days",
                                          telecommute_freq %in% c("Never", "Not applicable") ~ "Never / None",
                                          !is.na(telecommute_freq) ~ telecommute_freq)) %>% 
      mutate(telecommute_freq_cond = case_when(telecommute_freq %in% c("1-2 days", "3-4 days", "5+ days")
                                                 ~ "1+ days per week",
                                               !is.na(telecommute_freq) ~ telecommute_freq),
             workplace_travel = case_when(workplace %in% c("Usually the same location (outside home)",
                                                           "Workplace regularly varies (different offices or jobsites)",
                                                           "Drives for a living (e.g., bus driver, salesperson)")
                                            ~ "Works outside the home",
                                          workplace == "At home (telecommute or self-employed with home office)"
                                            ~ "Works at home",
                                          !is.na(workplace) ~ "Missing"),
             gender_group = case_when(gender %in% c("Prefer not to answer", "Another")
                                        ~ "Prefer not to answer / Another",
                                      !is.na(gender) ~ gender))
  }
  
  sdf$race_category <- recode(sdf$race_category, `White Only` = "White")
  sdf$race_eth_poc <- recode(sdf$race_eth_poc, `Non-POC` = "White")
  
  stats <- hhts_count(df = sdf,
                      stat_var = stat_var,
                      group_vars = group_vars,
                      spec_wgt = weight,
                      incl_na = incl_na)
  
  return(stats)
  
}
