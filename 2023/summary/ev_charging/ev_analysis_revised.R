# libraries
library(tidyverse)
library(data.table)
library(kableExtra)

library(travelSurveyTools)
library(psrcelmer)
library(psrcplot)
library(psrc.travelsurvey)

source("../survey-23-preprocess_JLin.R")

# reading in codebook
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx"
variable_list <- readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels <- readxl::read_xlsx(cb_path, sheet = 'value_labels')

setDT(variable_list)
setDT(value_labels)

# read in HTS data from Elmer
person <- get_query(sql= "select household_id as hh_id, person_id, survey_year, 
                      ev_typical_charge_1, ev_typical_charge_2, ev_typical_charge_3, ev_typical_charge_4, ev_typical_charge_5,
                      ev_typical_charge_6, ev_typical_charge_997, person_weight
                    from HHSurvey.v_persons_labels where survey_year = 2023")

vehicle <- get_query(sql= "select household_id as hh_id, vehicle_id, survey_year, fuel
                     from HHSurvey.v_vehicles_labels where survey_year = 2023")

hh <- get_query(sql= "select household_id as hh_id, survey_year, vehicle_count, hh_weight
                         from HHSurvey.v_households_labels
                         where survey_year = 2023")

setDT(hh)
setDT(vehicle)
setDT(person)

# characters as id's
person[, hh_id := as.character(hh_id)]
person[, person_id := as.character(person_id)]
person <- person %>% mutate(survey_year = as.character(survey_year))

vehicle[, hh_id := as.character(hh_id)]
vehicle[, vehicle_id := as.character(vehicle_id)]
vehicle <- vehicle %>% mutate(survey_year = as.character(survey_year))

hh[, hh_id := as.character(hh_id)]
hh <- hh %>% mutate(survey_year = as.character(survey_year))

# get typical charging from person data
person_charge <- hts_melt_vars(shared_name = "ev_typical_charge",
                           shared_name_vars = c("ev_typical_charge_1", "ev_typical_charge_2", "ev_typical_charge_3", "ev_typical_charge_4", 
                                                "ev_typical_charge_5", "ev_typical_charge_6", "ev_typical_charge_997"),
                           wide_dt = person,
                           ids = c("hh_id","person_id"), 
                           data = person) %>% 
  filter(value == "Selected") %>% 
  mutate(ev_typical_charge_melted = gsub('Typical charge location for EV -- ','',ev_typical_charge))

hh_charge <- person_charge %>%
  group_by(hh_id) %>%
  summarise(all_ev_charge = paste(sort(unique(ev_typical_charge_melted)), collapse = "; ")) %>%
  ungroup() %>%
  mutate(home_comp = case_when(grepl("At home",all_ev_charge)~"At home",
                               TRUE~"Not home"))


# get fuel type from vehicle data
vehicle_fuel <- vehicle %>%
  mutate(fuel_type = case_when(fuel %in% c("Hybrid (HEV)", "Plug-in hybrid (PHEV)")~ "Hybrid (HEV and PHEV)",
                              TRUE~ fuel))

hh_fuel <- vehicle_fuel %>%
  group_by(hh_id) %>%
  summarise(fuel_cat = paste(sort(unique(fuel_type)), collapse = "; ")) %>%
  ungroup() %>%
  mutate(fuel_ev = case_when(grepl("Electric",fuel_cat)~"Own EV",
                               TRUE~"No EV"))

# household data
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

# full hh data
hh_data <- list("hh" = hh_new)
# hh data including only households with EVs
EV_data <- list("hh" = hh_new %>% filter(fuel_ev=="Own EV"))


# create new variable list with added custom variables
my_variable_list <- new_add_variable(variables_dt = variable_list, 
                                     variable_names = c("veh_count","fuel_cat","fuel_ev","all_ev_charge","home_comp"), 
                                     table_name = "hh")


test <- get_hts_summary(EV_data, 
                        summary_var = c("survey_year","home_comp"), 
                        variables_dt = my_variable_list, 
                        id_var="hh_id",
                        wt_var="hh_weight",
                        wt_name="hh_weight")


