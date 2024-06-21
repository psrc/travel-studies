# Vehicle Table  ----
# Access the data via a SQL query
# do some data manipulation to get specific columns that show the gas only, does not have car, has ev only, and has ev and gas
# and also check to see if this adds up to the region
# Access the household table to get the hh_weights
# purpose of this is to also confirm the count for the ev_typical_charge location

# Loading in Packages ----
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

# reading in codebook ----
cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx")

variable_list = readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels = readxl::read_xlsx(cb_path, sheet = 'value_labels')

setDT(variable_list)
setDT(value_labels)

# reading in data from Elmer -----
vehicle<- get_query(sql= 
                        "select v.household_id as hh_id, v.vehicle_id, v.survey_year, v.fuel, h.hh_weight
                         from HHSurvey.v_vehicles_labels v
                              join HHSurvey.v_households_labels h on v.household_id = h.household_id
                         where v.survey_year = 2023")
setDT(vehicle)

hh<- get_query(sql= 
                      "select household_id as hh_id, survey_year, vehicle_count, hh_weight
                         from HHSurvey.v_households_labels
                         where survey_year = 2023")
setDT(hh)

# setting id's as characters -----
vehicle[, hh_id:=as.character(hh_id)]
vehicle[, vehicle_id := as.character(vehicle_id)]
vehicle <- vehicle%>%mutate(survey_year=as.character(survey_year))

hh[, hh_id:=as.character(hh_id)]
hh <- hh%>%mutate(survey_year=as.character(survey_year))

# converting persons variable into a list ----
hts_data = list("vehicle" = vehicle)
hts_data2 = list( "hh" = hh)
# summaries ----

# This summary displays the proportion and counts for each fuel type
prep_data <- hts_prep_variable(
    summarize_var = "fuel",
    id_cols = "hh_id",
    variables_dt = variable_list,
    wt_cols="hh_weight",
    data = hts_data
  )

fuel_cat_summary = hts_summary(
  prepped_dt = prep_data$cat,
  summarize_var = "fuel",
  summarize_by = NULL,
  summarize_vartype = "categorical",
  weighted = TRUE,
  wtname = "hh_weight",
  id_cols =  "hh_id"
)

fuel_cat_summary$summary

# This summary shows the counts for the number of people who have a car and those that do not have a car

prep_data2 <- hts_prep_variable(
    summarize_var = "vehicle_count",
    id_cols = "hh_id",
    variables_dt = variable_list,
    wt_cols="hh_weight",
    data = hts_data2
  )

veh_count_summary = hts_summary(
  prepped_dt = prep_data2$cat,
  summarize_var = "vehicle_count",
  summarize_by = NULL,
  summarize_vartype = "categorical",
  weighted = TRUE,
  wtname = "hh_weight",
  id_cols =  "hh_id"
)
veh_count_summary$summary

# This summary table displays for each household, the number of vehicles it has for each fuel type and the household's total vehicles
# step 1: creates a new column and adds a '1' if it satisfies this condition
# step 2: groups by household
# step 3: for each group of hh rows, it sums the column values for each vehicle type
veh_type_count <- vehicle %>% 
  mutate(
  total_ev = case_when(fuel == 'Electric (EV)' ~ 1, TRUE ~ 0),
  total_gas = case_when(fuel == 'Gas' ~ 1, TRUE ~ 0),
  total_diesel = case_when(fuel == 'Diesel' ~ 1, TRUE ~ 0),
  total_hybrid = case_when(fuel == 'Hybrid' ~ 1, TRUE ~ 0),
  total_flex_fuel = case_when(fuel == 'Flex Fuel' ~ 1, TRUE ~ 0),
  total_biofuel = case_when(fuel == 'Biofuel' ~ 1, TRUE ~ 0),
  total_natural_gas = case_when(fuel == 'Natural gas' ~ 1, TRUE ~ 0),
  total_other = case_when(fuel == 'Other (e.g., natural gas, bio-diesel, Flex fuel (FFV))' ~ 1, TRUE ~ 0),
  total_hev = case_when(fuel == 'Hybrid (HEV)' ~ 1, TRUE ~ 0),
  total_phev = case_when(fuel == 'Plug-in hybrid (PHEV)' ~ 1, TRUE ~ 0)) %>% 
  group_by(hh_id) %>%
  summarise(across(c(total_ev, total_gas, total_diesel, total_hybrid, total_flex_fuel, total_biofuel, total_natural_gas,
                     total_other, total_hev, total_phev), sum)) %>% 
  mutate(total_vehicles = rowSums(.[2:11]))
  
  
# used to verify the total number of vehicles for each hh is the same as in the vehicles table  
test <- vehicle %>% group_by(hh_id) %>% summarise(count = n())

