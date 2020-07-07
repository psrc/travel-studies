library(tidyverse)
library(odbc)
library(DBI)

# Read in data from Elmer
elmer_conn <- dbConnect(odbc::odbc(),
                        driver = "SQL Server",
                        server = "AWS-PROD-SQL\\Coho",
                        database = "Elmer",
                        trusted_connection = "yes"
                        )

hh_2019 <- dbGetQuery(elmer_conn,
                      "SELECT * FROM HHSurvey.v_households_2017_2019_in_house WHERE survey_year = 2019")

person_2019 <- dbGetQuery(elmer_conn,
                          "SELECT * FROM HHSurvey.v_persons_2017_2019_in_house WHERE survey_year = 2019")

dbDisconnect(elmer_conn)

hh_2019$household_id <- as.integer(hh_2019$household_id)
person_2019$household_id <- as.integer(person_2019$household_id)

# Create a table with only households that moved recently in WA
hh_recent_move <- hh_2019 %>% 
  filter(res_dur %in% c("Less than a year",
                        "Between 1 and 2 years",
                        "Between 2 and 3 years",
                        "Between 3 and 5 years")
         & prev_home_wa == "Yes, previous home was in Washington")

# Binary variable to indicate if a household was displaced or not
hh_recent_move$displaced <- case_when(
  hh_recent_move$prev_res_factors_housing_cost == "Selected" ~ 1,
  hh_recent_move$prev_res_factors_income_change == "Selected" ~ 1,
  hh_recent_move$prev_res_factors_community_change == "Selected" ~ 1,
  hh_recent_move$prev_res_factors_forced == "Selected" ~ 1,
  TRUE ~ 0
)

# Create a person table narrowed to age and race fields
person_lt <- person_2019 %>% 
  select(household_id,
         person_id,
         age,
         age_category,
         starts_with("race_")
  ) %>% 
  mutate(age_cat_narrow = case_when(
    age %in% c("Under 5 years old", "5-11 years", "12-15 years", "16-17 years")
    ~ "Persons under 18",
    age %in% c("18-24 years", "25-34 years")
    ~ "Persons 18-34 years",
    age %in% c("35-44 years", "45-54 years", "55-64 years")
    ~ "Persons 35-64 years",
    age %in% c("65-74 years", "75-84 years", "85 or years older")
    ~ "Persons 65+"
  ),
  race_cat_broad = case_when(
    race_category == "White Only"
    ~ "White",
    race_category == "African-American, Hispanic, Multiracial, and Other"
    ~ "POC",
    race_category == "Asian Only" ~ "Asian",
    race_category == "Children or missing" & age_cat_narrow == "Persons under 18"
    ~ "Children",
    race_category == "Children or missing" & age_cat_narrow != "Persons under 18"
    ~ "Missing"
  )) %>% 
  group_by(household_id) %>% 
  mutate(hh_age = case_when(
    any(age_cat_narrow == "Persons under 18")
    ~ "Household with children",
    any(age_cat_narrow == "Persons 65+")
    ~ "Household age 65+",
    any(age_cat_narrow == "Persons 35-64 years")
    ~ "Household age 35-64",
    TRUE ~ "Household excl. age 18-34"
  ),
  hh_race_sep = case_when(
    all(race_cat_broad == "POC") | all(race_cat_broad %in% c("POC", "Children"))
    ~ "POC Only",
    all(race_cat_broad == "Asian") | all(race_cat_broad %in% c("Asian", "Children"))
    ~ "Asian Only",
    any(race_cat_broad == "White") & any(race_cat_broad == "Asian")
    ~ "Asian & White",
    any(race_cat_broad == "White") & any(race_cat_broad == "POC")
    ~ "POC & White",
    any(race_cat_broad == "Asian") & any(race_cat_broad == "POC")
    ~ "Asian & POC",
    all(race_cat_broad == "White") | all(race_cat_broad %in% c("White", "Children"))
    ~ "White Only",
    any(race_cat_broad == "Missing")
    ~ "Missing" 
  ),
  hh_race = case_when(
    all(race_cat_broad == "POC") | all(race_cat_broad %in% c("POC", "Children"))
    ~ "Non-Asian POC",
    all(race_cat_broad == "Asian") | all(race_cat_broad %in% c("Asian", "Children"))
    ~ "Asian",
    any(race_cat_broad == "White") & any(race_cat_broad == "Asian")
    ~ "Asian",
    any(race_cat_broad == "White") & any(race_cat_broad == "POC")
    ~ "Non-Asian POC",
    any(race_cat_broad == "Asian") & any(race_cat_broad == "POC")
    ~ "Other",
    all(race_cat_broad == "White") | all(race_cat_broad %in% c("White", "Children"))
    ~ "White",
    any(race_cat_broad == "Missing")
    ~ "Other"
  )) %>% 
  ungroup()

# Create a table with the new household age and race categories
# and join to the table of recently moved households
hh_race_cat <- person_lt %>% 
  group_by(household_id) %>% 
  summarize(hh_age = first(hh_age_18),
            hh_race_sep = first(hh_race_sep),
            hh_race = first(hh_race))

hh_movers_race <- left_join(hh_recent_move, hh_race_cat,
                            by = c("household_id" = "household_id"))

# Analysis of data (examples of summaries using the new household variables)

# Region
hh_recent_move %>% 
  group_by(displaced) %>% 
  summarize(n = n(),
            households = sum(hh_wt_2019)) %>% 
  mutate(hh_pct = households / sum(households),
         moe = 1.645 * sqrt(0.25 / sum(n))) %>% 
  ungroup()

# County
hh_recent_move %>% 
  group_by(sample_county, displaced) %>% 
  summarize(n = n(),
            households = sum(hh_wt_2019)) %>% 
  mutate(hh_pct = households / sum(households),
         moe = 1.645 * sqrt(0.25 / sum(n))) %>% 
  ungroup()

# Household age
hh_movers_race %>% 
  group_by(hh_age, displaced) %>% 
  summarize(n = n(),
            households = sum(hh_wt_2019)) %>% 
  mutate(hh_pct = households / sum(households), 
         moe = 1.645 * sqrt(0.25 / sum(n))) %>% 
  ungroup()

# Household race (separated)
hh_movers_race %>% 
  group_by(hh_race_sep, displaced) %>% 
  summarize(n = n(),
            households = sum(hh_wt_2019)) %>% 
  mutate(hh_pct = households / sum(households), 
         moe = 1.645 * sqrt(0.25 / sum(n))) %>% 
  ungroup()

# Household race (combined)
hh_movers_race %>% 
  group_by(hh_race, displaced) %>% 
  summarize(n = n(),
            households = sum(hh_wt_2019)) %>% 
  mutate(hh_pct = households / sum(households), 
         moe = 1.645 * sqrt(0.25 / sum(n))) %>% 
  ungroup()

# Households by household age, race
hh_age_race <- hh_movers_race %>% 
  group_by(hh_age, hh_race, displaced) %>% 
  summarize(n = n(),
            households = sum(hh_wt_2019)) %>% 
  mutate(hh_pct = households / sum(households), 
         moe = 1.645 * sqrt(0.25 / sum(n))) %>% 
  ungroup()
