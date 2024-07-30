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

# reading in the codebook path
cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx")

variable_list = readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels = readxl::read_xlsx(cb_path, sheet = 'value_labels')

setDT(variable_list)
setDT(value_labels)

# Creating a new variable
# ev_typical_charge is a checkbox variable so I am creating a new variable called 
# 'ev_typical_charge_melted' to the variable list and value labels so that it can 
# be later referenced when creating a summary.

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



# This code accesses the data from Elmer via a SQL query. Here I am accessing the person table from the Household Travel Survey.
# reading in data from Elmer

person<- get_query(sql= "select household_id as hh_id,
person_id, survey_year, ev_typical_charge_1, ev_typical_charge_2, ev_typical_charge_3, ev_typical_charge_4, ev_typical_charge_5,
ev_typical_charge_6, ev_typical_charge_997, person_weight
                from HHSurvey.v_persons_labels where survey_year = 2023")

vehicle<- get_query(sql= "select v.household_id as hh_id, v.vehicle_id, v.survey_year, v.fuel, h.hh_weight
                         from HHSurvey.v_vehicles_labels v
                              join HHSurvey.v_households_labels h on v.household_id = h.household_id
                         where v.survey_year = 2023")

hh<- get_query(sql= "select household_id as hh_id, survey_year, vehicle_count, hh_weight
                         from HHSurvey.v_households_labels
                         where survey_year = 2023")

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

# This code stores the person, hh, and vehicale data tables as lists so they can be used in the hts_summary function.
hts_data1 = list("person" = person)
hts_data2 = list("hh" = hh)
hts_data3 = list("vehicle" = vehicle)

# Melting

# I used the hts_melt_vars variable to create a new person table that stores the ev_typical_charge variables in a long format.
# Then I joined the new table back to the person table.

new_person_tbl <- hts_melt_vars(
  shared_name = "ev_typical_charge",
  shared_name_vars = c("ev_typical_charge_1", "ev_typical_charge_2", "ev_typical_charge_3", "ev_typical_charge_4", "ev_typical_charge_5",
                       "ev_typical_charge_6", "ev_typical_charge_997"),
  wide_dt = person,
  ids = "person_id", 
  data = hts_data1
) %>% filter(value == "Selected")

person_new <- person%>%left_join(new_person_tbl, by=c("person_id")) %>% 
  rename(ev_typical_charge_melted=ev_typical_charge) %>%
  mutate(ev_typical_charge_melted = gsub('Typical charge location for EV -- ','',ev_typical_charge_melted )) %>%
  filter(!is.na(ev_typical_charge_melted))
hts_data1 <- list(person = person_new)
head(person_new[,c("hh_id", "person_id", "person_weight", "variable", "ev_typical_charge_melted")])
