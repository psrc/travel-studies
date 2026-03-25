library(psrc.travelsurvey)
library(tidyverse)

vars <- c("hhincome_broad", "workplace", "employment", "industry", "office_available", "commute_subsidy_3",
          "telecommute_freq", "commute_freq", 
          "work_rgcname", "work_jurisdiction", "work_county", 
          "home_rgcname", "home_jurisdiction", "home_county",
          "dest_purpose_cat", "dest_purpose_cat_5", "mode_class_5", "mode_class", "distance_miles", "travelers_total")

hts_data <- get_psrc_hts(survey_vars = vars)

my_hts_data <- hts_data %>%
  hts_bin_industry_sector() %>%
  hts_bin_worker() %>%
  hts_bin_income()

# person ----
telework_days <- c("1 day a week", "2 days a week", "3 days a week", "4 days a week", "5 days a week", "1-2 days", "3-4 days", "5+ days", "6-7 days a week")

df_person <- my_hts_data$person %>%
  mutate(
    # missing assignment for government and military
      industry_sector = case_when(
        industry %in% c("Government", "Military") ~ "Government & Military",
        TRUE ~ industry_sector
      ),
    # telecommute frequency
    telecommute_freq_org = case_when(
      # remove any non-workers
      worker != "Worker" | is.na(worker) ~ NA,
      # only workers: workers teleworking more than one day per week or work fully at home
      telecommute_freq %in% telework_days | 
        workplace=="At home (telecommute or self-employed with home office)" ~ '1+ days per week',
      TRUE~ "Don't telework"),
    # telecommute status version 1
    telecommute_status3 = case_when(
      # remove any non-workers
      worker != "Worker" | is.na(worker) ~ NA,
      workplace == 'At home (telecommute or self-employed with home office)' ~ "Fully at home",
      telecommute_freq_org == "Don't telework" ~ "Fully in person",
      telecommute_freq_org == '1+ days per week' ~ "Hybrid",
      TRUE ~ "Other"
    ),
    telecommute_status3 = factor(telecommute_status3, levels = c("Fully in person", "Hybrid", "Fully at home")),
    # telecommute status version 2
    telecommute_status2 = case_when(
      # remove any non-workers
      worker != "Worker" | is.na(worker) ~ NA,
      telecommute_status3 == "Fully at home" ~ NA,
      TRUE ~ telecommute_status3
    ),
    # work location
    work_geog = case_when(
      work_rgcname == 'Seattle Downtown' ~ "Seattle Downtown",
      work_jurisdiction=="Seattle" ~ "Seattle Outside Downtown",
      work_jurisdiction=="Bellevue" ~ "Bellevue",
      work_county=="King County" ~ "King Suburban",
      work_county %in% c("Kitsap County","Snohomish County","Pierce County") ~ work_county,
      # work at home workers don't have work locations
      is.na(work_county) ~ NA,
      TRUE ~ "Outside Region"),
    parking_subsidy = commute_subsidy_3)

# household ----
df_hh <- my_hts_data$hh %>%
  mutate(
    hhincome3 = case_when(hhincome_broad %in% c("Under $25,000", "$25,000-$49,999", "$50,000-$74,999")~ "Under $75,000",
                          hhincome_broad %in% c("$75,000-$99,999", "$100,000-$199,999")~ "$75,000-$199,999",
                          TRUE~hhincome_broad),
    home_geog = case_when(
      home_rgcname == 'Seattle Downtown' ~ "Seattle Downtown",
      home_jurisdiction=="Seattle" ~ "Seattle Outside Downtown",
      home_jurisdiction=="Bellevue" ~ "Bellevue",
      home_county=="King County" ~ "King Suburban",
      home_county %in% c("Kitsap County","Snohomish County","Pierce County") ~ home_county,
      TRUE ~ "Outside Region"))

# trip ----
df_trip <- my_hts_data$trip %>%
  mutate(
    dest_purpose_S = case_when(
      dest_purpose_cat %in% c("Personal Business/Errand/Appointment", "Shopping", "School", "School-related", "Escort")~ "Errands, Shopping, School",
      dest_purpose_cat %in% c("Social/Recreation", "Meal")~ "Social, Recreation, Eat Meal",
      dest_purpose_cat %in% c("Work", "Work-related")~ "Work and Work-related",
      TRUE~ NA
    )
  ) %>% 
  # filter to the trips that should be included in the vmt calculation
  mutate(if_drive = ifelse(grepl("^Ride|Drive",mode_class) & distance_miles<200,1,0)) %>%
  mutate(travelers_total_num = replace_na(as.numeric(substring(travelers_total,1,1)),1),
         travelers_total_num_7 = ifelse(travelers_total_num>=5, 7, travelers_total_num)) %>% # have to make some assumption for 5+
  mutate(weighted_vmt = replace_na(if_drive*distance_miles*trip_weight/travelers_total_num,0),
         weighted_vmt_7 = replace_na(if_drive*distance_miles*trip_weight/travelers_total_num_7,0))


my_hts_data$hh <- df_hh %>% filter(survey_year=="2023")
my_hts_data$person <- df_person %>% filter(survey_year=="2023")
my_hts_data$day <- my_hts_data$day %>% filter(survey_year=="2023")
my_hts_data$trip <- df_trip %>% filter(survey_year=="2023")
my_hts_data$vehicle <- my_hts_data$vehicle %>% filter(survey_year=="2023")

