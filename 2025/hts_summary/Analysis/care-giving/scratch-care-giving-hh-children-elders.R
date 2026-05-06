library(tidyverse)
library(psrc.travelsurvey)
library(psrcplot)
install_psrc_fonts()

# Data collection ----

## vars and categories ----

survey_year <- c(2023, 2025)

vars <- c("dest_county","dest_purpose","dest_purpose_cat","dest_purpose_cat_5","mode_class","mode_class_5",
          "age","can_drive","gender",
          "hhincome_broad","home_county",
          "numchildren")

care_purpose_cat <- c("Escort", "Shopping", "Meal", "Personal Business/Errand/Appointment")
work_cat <- c("Work","Work-related")
other_cat <- c("Other","Change mode","Overnight")
school_cat <- c("School","School-related")

## read hts data ----

hts_data <- get_psrc_hts(survey_vars = vars,
                         survey_years = survey_year)

## trip ----

trip_mutate <- hts_data[["trip"]] |> 
  mutate(dest_purpose_cat_no_home = case_when(dest_purpose_cat == "Home" ~ NA,
                                              TRUE ~ dest_purpose_cat),
         care_purpose_cat = factor(case_when(dest_purpose_cat %in% care_purpose_cat ~ "Care",
                                             dest_purpose_cat %in% work_cat ~ "Work",
                                             dest_purpose_cat %in% other_cat ~ "Other",
                                             dest_purpose_cat %in% school_cat ~ "School",
                                             dest_purpose_cat == "Home" ~ NA,
                                             TRUE ~ dest_purpose_cat_5),
                                   levels = c("Care","Work","School","Social/Recreation","Other"))) |> 
  mutate(dest_region = case_when(dest_county %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "Region",
                                 !is.na(dest_county) ~ NA_character_)) 



## households ----

hh_mutate <- hts_data[["hh"]] |> 
  mutate(home_children = case_when(numchildren != "0 children" ~ "Yes",
                                   .default = "No"))

## person ----

person_mutate <- hts_data[["person"]] |> 
  mutate(home_elder = case_when(age %in% c("65-74 years", "75-84 years", "85 years or older") ~ "Yes",
                                .default = "No"))

# final HTS data ----

df_hts <- hts_data
df_hts[["trip"]] <- trip_mutate
df_hts[["hh"]] <- hh_mutate
df_hts[["person"]] <- person_mutate

rs <- psrc_hts_stat(df_hts,
                    analysis_unit = "trip",
                    group_vars = c("dest_region", "care_purpose_cat", "home_children", "home_elder"),
                    incl_na = FALSE) |>
  rename(dest_loc = dest_region) |>
  filter(dest_loc == "Region",
         care_purpose_cat == "Care") 