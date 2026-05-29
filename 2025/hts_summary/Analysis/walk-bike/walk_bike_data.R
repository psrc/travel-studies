library(tidyverse)
library(psrc.travelsurvey)
library(psrcplot)


# Pull survey data ----------------------------------------------------------------------------
vars <- c("hhincome_detailed", "home_rgcname", "home_jurisdiction", "home_county",  # household
          "age", "gender", "race_category", "disability_person", "share_2",         # person
          "origin_purpose_cat", "dest_purpose_cat", "dest_purpose_cat_5", "mode_class", "mode_class_5"    # trip
)

hts_data <- get_psrc_hts(survey_vars = vars,
                         survey_years = c(2017, 2019, 2021, 2023, 2025))

hts_data$hh$survey_year <- as.character(hts_data$hh$survey_year)
hts_data$person$survey_year <- as.character(hts_data$person$survey_year)
hts_data$day$survey_year <- as.character(hts_data$day$survey_year)
hts_data$trip$survey_year <- as.character(hts_data$trip$survey_year)
hts_data$vehicle$survey_year <- as.character(hts_data$vehicle$survey_year)


# Create aggregated variables -----------------------------------------------------------------
# condense hhincome
hts_data$hh <- hts_data$hh %>% 
  mutate(hhincome_detailed_combined = case_when(hhincome_detailed %in% c("Under $10,000", "$10,000-$24,999", "$25,000-$34,999", "$35,000-$49,999") ~ "Under $50,000",
                                                hhincome_detailed %in% c("$50,000-$74,999", "$75,000-$99,999") ~ "$50,000-$99,999",
                                                hhincome_detailed %in% c("$150,000-$199,999", "$200,000-$249,999", "$250,000 or more") ~ "$150,000 or more",
                                                TRUE ~ hhincome_detailed)) %>% 
  mutate(hhincome_detailed_combined = factor(hhincome_detailed_combined,
                                             levels = c("Under $50,000", "$50,000-$99,999", "$100,000-$149,999",
                                                        "$150,000 or more", "Prefer not to answer")))

hts_data$hh <- hts_data$hh %>% 
  mutate(hhincome_bike = case_when(hhincome_detailed %in% c("Under $10,000", "$10,000-$24,999", "$25,000-$34,999", "$35,000-$49,999", "$50,000-$74,999", "$75,000-$99,999") ~ "Under $100,000",
                                   hhincome_detailed %in% c("$100,000-$149,999", "$150,000-$199,999", "$200,000-$249,999", "$250,000 or more") ~ "$100,000 or more",
                                   TRUE ~ hhincome_detailed)) %>% 
  mutate(hhincome_bike = factor(hhincome_bike,
                                levels = c("Under $100,000", "$100,000 or more", "Prefer not to answer")))

# condense age
hts_data$person <- hts_data$person %>% 
  mutate(age_condensed = case_when(age %in% c("Under 5 years old", "5-11 years", "12-15 years", "16-17 years") ~ "Under 18 years old",
                                   age %in% c("18-24 years", "25-34 years") ~ "18-34 years",
                                   age %in% c("35-44 years", "45-54 years", "55-64 years") ~ "35-64 years",
                                   age %in% c("65-74 years", "75-84 years", "85 years or older") ~ "65 years or older")) %>% 
  mutate(age_condensed = factor(age_condensed, levels = c("Under 18 years old", "18-34 years", "35-64 years", "65 years or older")))

# condense gender
hts_data$person <- hts_data$person %>% 
  mutate(gender_group = case_when(gender %in% c("Female", "Girl/Woman (cisgender or transgender)") ~ "Women",
                                  gender %in% c("Male", "Boy/Man (cisgender or transgender)") ~ "Men",
                                  gender %in% c("Non-Binary", "Non-binary/Something else fits better", "Another") ~ "Non-Binary/Other",
                                  gender == "Not listed here / prefer not to answer" ~ "Prefer not to answer",
                                  TRUE ~ gender)) %>% 
  mutate(gender_group = factor(gender_group, levels = c("Women", "Men", "Non-Binary/Other", "Prefer not to answer")))

# simplify race values
hts_data$person <- hts_data$person %>% 
  mutate(race_simple = case_when(race_category == "White non-Hispanic" ~ "White",
                                 race_category == "AANHPI non-Hispanic" ~ "Asian American, Native Hawaiian, or Pacific Islander",
                                 race_category == "Black or African American non-Hispanic" ~ "Black or African American",
                                 race_category %in% c("Some Other Race non-Hispanic", "Two or More Races non-Hispanic") ~ "Some Other Race",
                                 TRUE ~ race_category))

hts_data$person <- hts_data$person %>% 
  mutate(race_binary = case_when(race_category == "White non-Hispanic" ~ "White",
                                 race_category %in% c("AANHPI non-Hispanic", "Black or African American non-Hispanic", "Hispanic", "Some Other Race non-Hispanic", "Two or More Races non-Hispanic") ~ "People of Color",
                                 TRUE ~ race_category))

# create geographic variables
hts_data$hh <- hts_data$hh %>% 
  mutate(in_rgc = ifelse(home_rgcname == "Not RGC", "Home Not in RGC", "Home in RGC"))

hts_data$hh <- hts_data$hh %>% 
  mutate(home_geography = factor(case_when(home_jurisdiction == "Seattle" ~ home_jurisdiction,
                                           home_county == "King County" & home_jurisdiction != "Seattle" ~ "Rest of King",
                                           home_county %in% c("Kitsap County", "Pierce County", "Snohomish County") ~ home_county),
                                 levels = c("Seattle", "Rest of King", "Kitsap County", "Pierce County", "Snohomish County")))


# Create analysis tables ----------------------------------------------------------------------
mode_summary <- psrc_hts_stat(hts_data,
                              analysis_unit = "trip",
                              group_vars = "mode_class_5")

trip_summary <- mode_summary %>%
  group_by(survey_year) %>%
  summarize(est = sum(est)) %>%
  mutate(est_rounded = est/1000000)

walk_bike_by_income <- psrc_hts_stat(hts_data,
                                     analysis_unit = "trip",
                                     group_vars = c("hhincome_detailed", "mode_class_5")) %>% 
  filter(mode_class_5 %in% c("Walk", "Bike/Micromobility"))

walk_bike_by_income_combined <- psrc_hts_stat(hts_data,
                                              analysis_unit = "trip",
                                              group_vars = c("hhincome_detailed_combined", "mode_class_5")) %>% 
  filter(mode_class_5 %in% c("Walk", "Bike/Micromobility"))

bike_by_income_binary <- psrc_hts_stat(hts_data,
                                       analysis_unit = "trip",
                                       group_vars = c("hhincome_bike", "mode_class_5")) %>% 
  filter(mode_class_5 == "Bike/Micromobility")

walk_bike_by_race <- psrc_hts_stat(hts_data,
                                   analysis_unit = "trip",
                                   group_vars = c("race_simple", "mode_class_5")) %>% 
  filter(mode_class_5 %in% c("Walk", "Bike/Micromobility"))

walk_bike_by_race_binary <- psrc_hts_stat(hts_data,
                                          analysis_unit = "trip",
                                          group_vars = c("race_binary", "mode_class_5")) %>% 
  filter(mode_class_5 %in% c("Walk", "Bike/Micromobility"))

walk_bike_by_gender <- psrc_hts_stat(hts_data,
                                     analysis_unit = "trip",
                                     group_vars = c("gender_group", "mode_class_5")) %>% 
  filter(mode_class_5 %in% c("Walk", "Bike/Micromobility"))

walk_bike_by_age <- psrc_hts_stat(hts_data,
                                  analysis_unit = "trip",
                                  group_vars = c("age_condensed", "mode_class_5")) %>% 
  filter(mode_class_5 %in% c("Walk", "Bike/Micromobility"))
