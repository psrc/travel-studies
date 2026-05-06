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

hhinc_list <- list(
  low_50 = c("Under $25,000", "$25,000-$49,999"),
  high_50 = c("$50,000-$74,999","$75,000-$99,999","$100,000-$199,999","$200,000 or more"),
  levels_50 = c("Under $50,000","$50,000 or more"),
  
  low_75 = c("Under $25,000","$25,000-$49,999","$50,000-$74,999"),
  high_75 = c("$75,000-$99,999","$100,000-$199,999","$200,000 or more"),
  levels_75 = c("Under $75,000","$75,000 or more"),
  
  low_100 = c("Under $25,000","$25,000-$49,999","$50,000-$74,999","$75,000-$99,999"),
  high_100 = c("$100,000-$199,999","$200,000 or more"),
  levels_100 = c("Under $100,000","$100,000 or more"),
  
  low_comp = c("Under $25,000", "$25,000-$49,999"),
  med_comp = c("$50,000-$74,999","$75,000-$99,999"),
  high_comp = c("$100,000-$199,999","$200,000 or more")
)

## households ----

hh_mutate <- hts_data[["hh"]] |> 
  mutate(income_50 = factor(case_when(hhincome_broad %in% hhinc_list$low_50 ~ hhinc_list$levels_50[1],
                                      hhincome_broad %in% hhinc_list$high_50 ~ hhinc_list$levels_50[2],
                                      TRUE ~ NA),
                            levels = hhinc_list$levels_50),
         income_75 = factor(case_when(hhincome_broad %in% hhinc_list$low_75 ~ hhinc_list$levels_75[1],
                                      hhincome_broad %in% hhinc_list$high_75 ~ hhinc_list$levels_75[2],
                                      TRUE ~ NA),
                            levels = hhinc_list$levels_75),
         income_100 = factor(case_when(hhincome_broad %in% hhinc_list$low_100 ~ hhinc_list$levels_100[1],
                                       hhincome_broad %in% hhinc_list$high_100 ~ hhinc_list$levels_100[2],
                                       TRUE ~ NA),
                             levels = hhinc_list$levels_100)
  ) |> 
  mutate(income_comp = factor(
    case_when(hhincome_broad %in% hhinc_list$low_comp ~ "Under $50,000",
              hhincome_broad %in% hhinc_list$med_comp ~ "$50,000-$99,999",
              hhincome_broad %in% hhinc_list$high_comp ~ "$100,000 or more"))
    )|> 
  mutate(home_region = case_when(home_county %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "Region",
                                 !is.na(home_county) ~ NA_character_)) |> 
  mutate(home_children = case_when(numchildren != "0 children" ~ "Yes",
                                   .default = "No"))

## person ----

person_mutate <- hts_data[["person"]] |> 
  mutate(
    gender2 = factor(
      case_when(gender == "Boy/Man (cisgender or transgender)" ~ "Male",
                gender == "Girl/Woman (cisgender or transgender)" ~ "Female",
                TRUE~NA),
      levels = c("Male","Female"))
  ) |> 
  mutate(home_elder = case_when(age %in% c("65-74 years", "75-84 years", "85 years or older") ~ "Yes",
                                .default = "No"))

# final HTS data ----

df_hts <- hts_data
df_hts[["trip"]] <- trip_mutate
df_hts[["hh"]] <- hh_mutate
df_hts[["person"]] <- person_mutate