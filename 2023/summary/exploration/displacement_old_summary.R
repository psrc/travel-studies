library(tidyverse)
library(odbc)
library(DBI)

# Read in data from Elmer
elmer_conn <- dbConnect(odbc::odbc(),
                        driver = "SQL Server",
                        server = "AWS-PROD-SQL\\Sockeye",
                        database = "Elmer",
                        trusted_connection = "yes"
)

hh_2019 <- dbGetQuery(elmer_conn,
                      "SELECT * FROM HHSurvey.v_households WHERE survey_year = 2019")

person_2019 <- dbGetQuery(elmer_conn,
                          "SELECT * FROM HHSurvey.v_persons WHERE survey_year = 2019")

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

# Tests using fields hhincome_detailed and hhincome_broad showed that neither classification
# was best suited for this analysis of displacement.
# Create a new field between detailed and broad
hh_recent_move$hhincome_intermediate <- case_when(
  hh_recent_move$hhincome_detailed %in% c("Under $10,000",
                                          "$10,000-$24,999")
  ~ "Under $25,000",
  hh_recent_move$hhincome_detailed %in% c("$25,000-$34,999",
                                          "$35,000-$49,999")
  ~ "$25,000-$49,999",
  hh_recent_move$hhincome_detailed == "$50,000-$74,999"
  ~ "$50,000-$74,999",
  hh_recent_move$hhincome_detailed == "$75,000-$99,999"
  ~ "$75,000-$99,999",
  hh_recent_move$hhincome_detailed == "$100,000-$149,999"
  ~ "$100,000-$149,999",
  hh_recent_move$hhincome_detailed %in% c("$150,000-$199,999",
                                          "$200,000-$249,999",
                                          "$250,000 or more")
  ~ "$150,000 or more",
  hh_recent_move$hhincome_detailed == "Prefer not to answer"
  ~ "Prefer not to answer"
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
    race_category %in% c("Hispanic", "Other", "African American")~ "POC",
                         race_category == "Asian" ~ "Asian",
                         race_category == "Child"
                         ~ "Children",
                         race_category == "Missing" 
                         ~ "Missing"
    ) )%>%
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
  # used to determine how to construct hh_race below; not for analysis
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
  # use for analysis
  hh_race = case_when( # use for analysis
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
  summarize(hh_age = first(hh_age),
            hh_race_sep = first(hh_race_sep),
            hh_race = first(hh_race))

hh_movers_race <- left_join(hh_recent_move, hh_race_cat,
                            by = c("household_id" = "household_id"))

# Order levels in the new fields before beginning analysis
hh_movers_race$hhincome_intermediate <- ordered(hh_movers_race$hhincome_intermediate,
                                                levels = c("Under $25,000",
                                                           "$25,000-$49,999",
                                                           "$50,000-$74,999",
                                                           "$75,000-$99,999",
                                                           "$100,000-$149,999",
                                                           "$150,000 or more",
                                                           "Prefer not to answer"))

hh_movers_race$hh_age <- ordered(hh_movers_race$hh_age,
                                 levels = c("Household with children",
                                            "Household excl. age 18-34",
                                            "Household age 35-64",
                                            "Household age 65+"))

hh_movers_race$hh_race <- ordered(hh_movers_race$hh_race,
                                  levels = c("Asian",
                                             "Non-Asian POC",
                                             "White",
                                             "Other"))

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

# Household income
hh_movers_race %>%
  group_by(hhincome_intermediate, displaced) %>%
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

hh_forced<-hh_movers_race %>%
  group_by(hh_race, prev_res_factors_forced) %>%
  summarize(n = n(),
            households = sum(hh_wt_2019)) %>%
  mutate(hh_pct = households / sum(households),
         moe = 1.645 * sqrt(0.25 / sum(n))) %>%
  ungroup()
