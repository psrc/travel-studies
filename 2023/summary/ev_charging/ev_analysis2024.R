# Loading in packages and libraries

library(devtools)
devtools::install_github('rsgInc/travelSurveyTools')
devtools::install_github('psrc/psrcelmer')
devtools::install_github('psrc/psrcplot')

# libraries
library(data.table)
library(stringr)
library(travelSurveyTools)
library(psrcelmer)
library(dplyr)
library(psrcplot)
library(tidyverse)
library(kableExtra)


source("C:/Users/BWong/OneDrive - Puget Sound Regional Council/Documents/GitHub/travel-studies/2023/summary/survey-23-preprocess_JLin.R")

# reading in the codebook path
cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx")

variable_list = readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels = readxl::read_xlsx(cb_path, sheet = 'value_labels')

setDT(variable_list)
setDT(value_labels)

# Creating a new variable
# Created the ev_typical_charge_melted and home_comp variable, and veh_count

variable_list = rbind(
  variable_list,
  data.table(
    variable = "ev_typical_charge_melted",
    is_checkbox = 0,
    hh = 0,
    person = 1,
    day = 0,
    trip = 0,
    vehicle = 0,
    location = 0,
    data_type = "integer/categorical",
    description = "ev typical charging location",
    logic = "ev typical charging location",
    shared_name = "ev_typical_charge_melted"
  )
)

# adding to the value labels
value_labels = rbind(
  value_labels,
  data.table(
    variable = rep("ev_typical_charge_melted", 7),
    value = c(1, 2, 3, 4, 5, 6, 997),
    label = c("At home",
              "At work",
              "At a commute location (e.g., Park and Ride lot, parking garage)", 
              "At a shopping location (e.g., grocery store, shopping mall)", 
              "At a public location (e.g., hospital, library, government building)",
              "At a hotel/inn",
              "Other"),
    val_order = c(6062:6068),
    group_1_title = rep(NA, 7),
    group_1_value = rep(NA, 7),
    group_2_title = rep(NA, 7),
    group_2_value = rep(NA, 7),
    group_3_title = rep(NA, 7),
    group_3_value = rep(NA, 7))
)


variable_list = rbind(
  variable_list,
  data.table(
    variable = "home_comp",
    is_checkbox = 0,
    hh = 1,
    person = 0,
    day = 0,
    trip = 0,
    vehicle = 0,
    location = 0,
    data_type = "integer/categorical",
    description = "ev charging location home vs. not home",
    logic = "ev charging location home vs. not home",
    shared_name = "home_comp"
  )
)

# adding to the value labels
value_labels = rbind(
  value_labels,
  data.table(
    variable = rep("home_comp", 3),
    value = c(1, 2, 3),
    label = c("At home",
              "Not home",
              "Missing"),
    val_order = c(6069:6071),
    group_1_title = rep(NA, 3),
    group_1_value = rep(NA, 3),
    group_2_title = rep(NA, 3),
    group_2_value = rep(NA, 3),
    group_3_title = rep(NA, 3),
    group_3_value = rep(NA, 3))
)

variable_list = rbind(
  variable_list,
  data.table(
    variable = "veh_count",
    is_checkbox = 0,
    hh = 1,
    person = 0,
    day = 0,
    trip = 0,
    vehicle = 0,
    location = 0,
    data_type = "integer/categorical",
    description = "Number of vehicles simplified",
    logic = "Number of vehicles simplified",
    shared_name = "veh_count"
  )
)

# adding to the value labels
value_labels = rbind(
  value_labels,
  data.table(
    variable = rep("veh_count", 5),
    value = c(0, 1, 2, 3, 4),
    label = c("0 (no vehicles)",
              "1 vehicle",
              "2 vehicles",
              "2 vehicles",
              "4 or more vehicles"),
    val_order = c(6072:6076),
    group_1_title = rep(NA, 5),
    group_1_value = rep(NA, 5),
    group_2_title = rep(NA, 5),
    group_2_value = rep(NA, 5),
    group_3_title = rep(NA, 5),
    group_3_value = rep(NA, 5))
)

# This code accesses the data from Elmer via a SQL query.
# reading in HTS from Elmer

person<- get_query(sql= "select household_id as hh_id, person_id, survey_year, ev_typical_charge_1, ev_typical_charge_2,
                         ev_typical_charge_3, ev_typical_charge_4, ev_typical_charge_5, ev_typical_charge_6,
                         ev_typical_charge_997, person_weight
                         from HHSurvey.v_persons_labels where survey_year = 2023")

vehicle<- get_query(sql= "select v.household_id as hh_id, v.vehicle_id, v.survey_year, v.fuel, h.hh_weight
                         from HHSurvey.v_vehicles_labels v
                         join HHSurvey.v_households_labels h on v.household_id = h.household_id
                         where v.survey_year = 2023")

hh<- get_query(sql= "select household_id as hh_id, survey_year, vehicle_count, hh_weight
                     from HHSurvey.v_households_labels
                     where survey_year = 2023")

# converting the df to data.tables
setDT(hh)
setDT(vehicle)
setDT(person)

# characters as id's
person[, hh_id:=as.character(hh_id)]
person[, person_id := as.character(person_id)]
person <- person%>%mutate(survey_year=as.character(survey_year))

vehicle[, hh_id:=as.character(hh_id)]
vehicle[, vehicle_id := as.character(vehicle_id)]
vehicle <- vehicle%>%mutate(survey_year=as.character(survey_year))

hh[, hh_id:=as.character(hh_id)]
hh <- hh%>%mutate(survey_year=as.character(survey_year))


# Created a new person table with a ev_typical_charge_melted column
# Aggregated commute and shopping to public location and hotel/Inn to Other
person_charge <- hts_melt_vars(shared_name = "ev_typical_charge",
                                shared_name_vars = c("ev_typical_charge_1", "ev_typical_charge_2", "ev_typical_charge_3",
                                                     "ev_typical_charge_4", "ev_typical_charge_5", "ev_typical_charge_6",
                                                     "ev_typical_charge_997"),
                                wide_dt = person,
                                ids =  c("person_id", "hh_id"),
                                data = person) %>% 
                  filter(value == "Selected") %>% 
                  mutate(ev_typical_charge_melted = gsub('Typical charge location for EV -- ','',ev_typical_charge),
                         ev_typical_charge_melted = gsub("\\(.*", "",ev_typical_charge_melted),
                         ev_typical_charge_melted = case_when(ev_typical_charge_melted %in% c("At a commute location ", "At a shopping location ",
                                                                                              "At a hotel/inn") ~ "At a public location", 
                                                                                              TRUE~ ev_typical_charge_melted))

# Summarized all ev charging locations for each hh and whether they charged at home
hh_charge <- person_charge %>%
  group_by(hh_id) %>%
  summarise(all_ev_charge = paste(sort(unique(ev_typical_charge_melted)), collapse = "; ")) %>%
  ungroup() %>%
  mutate(home_comp = case_when(grepl("At home",all_ev_charge)~"At home",
                               TRUE~"Not home"),
         top_ev_loc = case_when(grepl("work", all_ev_charge)~"At work",
                                grepl("public", all_ev_charge)~"At public/other",
                                grepl("Other", all_ev_charge)~"At public/other",
                                TRUE~"At home"),
         work_comp = case_when(grepl("At work",all_ev_charge)~"At work",
                               TRUE~"Not work"),
         public_other_comp = case_when(grepl("public", all_ev_charge)~"At public/other",
                                       grepl("Other", all_ev_charge)~"At public/other",
                                       TRUE~"Not public/other"))  

  
# get fuel type from vehicle data
# recoded hybrid HEV and PHEV to be the same variable
vehicle_fuel <- vehicle %>%
  mutate(fuel_type = case_when(fuel %in% c("Hybrid (HEV)", "Plug-in hybrid (PHEV)")~ "Hybrid (HEV and PHEV)",
                               TRUE~ fuel))
# Summarized all vehicle fuel types a hh owns and whether they own an EV
hh_fuel <- vehicle_fuel %>%
  group_by(hh_id) %>%
  summarise(fuel_cat = paste(sort(unique(fuel_type)), collapse = "; ")) %>%
  ungroup() %>%
  mutate(fuel_ev = case_when(grepl("Electric",fuel_cat)~"Own EV",
                             TRUE~"No EV"),
        fuel_gas = case_when(grepl("Gas",fuel_cat)~"Own Gas",
                             TRUE~"No Gas"),
     fuel_diesel = case_when(grepl("Diesel",fuel_cat)~"Own Diesel",
                             TRUE~"No Diesel"),
     fuel_hybrid = case_when(grepl("Hybrid",fuel_cat)~"Own Hybrid",
                                TRUE~"No Hybrid"),
      fuel_other = case_when(grepl("Other",fuel_cat)~"Own Other",
                             TRUE~"No Other"))
  
# new household dataframe veh_count, fuel_cat, fuel_ev, all_ev_charge, and home_comp variables
# recoded any hh with 4-8 vehicles as 4 or more vehicles
hh_new <- hh %>% 
  mutate(veh_count = case_when(vehicle_count %in% c("4 vehicles","5 vehicles","6 vehicles","7 vehicles","8 or more vehicles") ~ "4 or more vehicles",
                               TRUE~ vehicle_count)) %>%
  # merge household level typical charging and fuel type
  left_join(hh_fuel, by = "hh_id") %>%
  left_join(hh_charge, by = "hh_id") %>%
  # fill in households that own EV but with no charging info
  mutate(all_ev_charge = case_when(!is.na(all_ev_charge)~all_ev_charge,
                                   fuel_ev=="Own EV"~"Missing"),
         home_comp = case_when(!is.na(home_comp)~home_comp,
                               fuel_ev=="Own EV"~"Missing"))

hh_home_only <- hh_new %>% filter(all_ev_charge == "At home")

# full hh data
# storing hh and ev data into lists
hh_data <- list("hh" = hh_new %>% filter(vehicle_count != "0 (no vehicles)"))
# hh data including only households with EVs
EV_data <- list("hh" = hh_new %>% filter(fuel_ev=="Own EV" & home_comp != "Missing")) # this filters out people who did not answer the ev question


# home vs.not home summary
prep_data <- hts_prep_variable(
    summarize_var =  "home_comp",
    id_cols = "hh_id",
    variables_dt = variable_list,
    wt_cols="hh_weight",
    data = EV_data,
    missing_values=NA,
    weighted = TRUE)

at_home_summary <- hts_summary_cat(prep_data$cat, 
                                  summarize_var = "home_comp",
                                  wtname = "hh_weight",
                                  id_cols =  "hh_id",
                                  se = TRUE)

home_comparison <- at_home_summary$wtd %>% mutate(moe = prop_se * 1.645)

at_home <- home_comparison %>% filter(home_comp == "At home")

# vehicle count summary
veh_count_prep <- hts_prep_variable(
  summarize_var =  "veh_count",
  id_cols = "hh_id",
  variables_dt = variable_list,
  wt_cols="hh_weight",
  data = hh_data,
  missing_values=NA,
  weighted = TRUE)

veh_count_summary <- hts_summary_cat(veh_count_prep$cat, 
                               summarize_var = "veh_count",
                               wtname = "hh_weight",
                               id_cols =  "hh_id",
                               se = TRUE)




# fuel type summary

# --- old code to delete 
fuel_type_variable_list <- new_add_variable(variables_dt = variable_list, 
                                     variable_names = c("fuel_cat"), 
                                     table_name = "hh")


fuel_type_summary <- get_hts_summary(hh_data, 
                        summary_var = c("survey_year","fuel_cat"), 
                        variables_dt = fuel_type_variable_list, 
                        id_var="hh_id",
                        wt_var="hh_weight",
                        wt_name="hh_weight")


# ----

fuel_vrble_list <- new_add_variable(variables_dt = variable_list, 
                                     variable_names = c("fuel_cat", "fuel_ev", "fuel_gas", "fuel_diesel", "fuel_hybrid", "fuel_other"), 
                                     table_name = "hh")


own_ev <- get_hts_summary(hh_data, 
                        summary_var = c("survey_year", "fuel_ev"), 
                        variables_dt = fuel_vrble_list, 
                        id_var="hh_id",
                        wt_var="hh_weight",
                        wt_name="hh_weight")

own_gas <- get_hts_summary(hh_data, 
                           summary_var = c("survey_year", "fuel_gas"), 
                           variables_dt = fuel_vrble_list, 
                           id_var="hh_id",
                           wt_var="hh_weight",
                           wt_name="hh_weight")

own_diesel <- get_hts_summary(hh_data, 
                           summary_var = c("survey_year", "fuel_diesel"), 
                           variables_dt = fuel_vrble_list, 
                           id_var="hh_id",
                           wt_var="hh_weight",
                           wt_name="hh_weight")
own_hybrid <- get_hts_summary(hh_data, 
                           summary_var = c("survey_year", "fuel_hybrid"), 
                           variables_dt = fuel_vrble_list, 
                           id_var="hh_id",
                           wt_var="hh_weight",
                           wt_name="hh_weight")
own_other <- get_hts_summary(hh_data, 
                           summary_var = c("survey_year", "fuel_other"), 
                           variables_dt = fuel_vrble_list, 
                           id_var="hh_id",
                           wt_var="hh_weight",
                           wt_name="hh_weight")


fuel_summary_df <- bind_rows(own_ev, own_diesel, own_gas, own_hybrid, own_other)

# concatenate the columns 

fuel_summary_df1 <- fuel_summary_df %>% mutate(fuel_type = NA) %>% 
unite(., fuel_type, c(fuel_ev, fuel_diesel, fuel_gas, fuel_hybrid, fuel_other)) %>%
  mutate(fuel_type = gsub('NA_','',fuel_type),
         fuel_type = gsub('_NA', '',fuel_type)) %>% 
  .[!grepl('No', .$fuel_type),]



fuel_no_gas <- fuel_summary_df1 %>% 
               filter(fuel_type != "Own Gas")

fuel_gas <- fuel_summary_df1 %>% 
  filter(fuel_type == "Own Gas")

# ev charging location summary

ev_loc_variable_list <- new_add_variable(variables_dt = variable_list, 
                                     variable_names = c("fuel_ev","all_ev_charge", "top_ev_loc", "work_comp", "public_other_comp"), 
                                     table_name = "hh")

work_summary <- get_hts_summary(EV_data, 
                                     summary_var = c("survey_year","work_comp"), 
                                     variables_dt = ev_loc_variable_list, 
                                     id_var="hh_id",
                                     wt_var="hh_weight",
                                     wt_name="hh_weight")

public_other_summary <- get_hts_summary(EV_data, 
                                summary_var = c("survey_year","public_other_comp"), 
                                variables_dt = ev_loc_variable_list, 
                                id_var="hh_id",
                                wt_var="hh_weight",
                                wt_name="hh_weight")

home_summary <- get_hts_summary(EV_data, 
                                        summary_var = c("survey_year","home_comp"), 
                                        variables_dt = ev_loc_variable_list, 
                                        id_var="hh_id",
                                        wt_var="hh_weight",
                                        wt_name="hh_weight")


ev_summary_df <- bind_rows(home_summary, work_summary, public_other_summary)


ev_summary_df1 <- ev_summary_df %>% mutate(ev_loc = NA) %>% 
  unite(., ev_loc, c(home_comp, work_comp, public_other_comp)) %>%
  mutate(ev_loc = gsub('NA_','',ev_loc),
         ev_loc = gsub('_NA', '',ev_loc)) %>% 
  .[!grepl('Not', .$ev_loc),]


ev_charge1 <- ev_summary_df1

ev_charge1$prop <- round(ev_charge1$prop, 4)
ev_charge1$est <- round(ev_charge1$est, 2)

ev_sum <- get_hts_summary(EV_data, 
                                summary_var = c("survey_year","top_ev_loc"), 
                                variables_dt = ev_loc_variable_list, 
                                id_var="hh_id",
                                wt_var="hh_weight",
                                wt_name="hh_weight")

ev_charge <- ev_sum

ev_charge$prop <- round(ev_charge$prop, 4)
ev_charge$est <- round(ev_charge$est, 2)
