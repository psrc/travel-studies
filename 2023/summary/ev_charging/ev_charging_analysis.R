
# Loading in Packages
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


# reading in codebook
cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx")

variable_list = readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels = readxl::read_xlsx(cb_path, sheet = 'value_labels')

setDT(variable_list)
setDT(value_labels)


# reading in data from Elmer
person<- get_query(sql= "select household_id as hh_id,
person_id, survey_year, ev_typical_charge_1, ev_typical_charge_2, ev_typical_charge_3, ev_typical_charge_4, ev_typical_charge_5,
ev_typical_charge_6, num_trips, vehicleused, race_category, age, commute_freq
                from HHSurvey.v_persons_labels")
setDT(person)


# setting id's as characters
person[, hh_id:=as.character(hh_id)]
person[, person_id := as.character(person_id)]
person <- person%>%mutate(survey_year=as.character(survey_year))

# converting persons variable into a list
hts_data = list(hh=hh,
                person=person,
                day=day,
                trip = trip)


hts_melt_vars(
  shared_name = "ev_typical_charge",
  wide_dt = person,
  shared_name_vars = NULL,
  variables_dt = variable_list,
  data = hts_data,
  ids = c("hh_id", "person_id", "survey_year"),
  remove_missing = TRUE,
  missing_values = c("Missing Response", "995"),
  checkbox_label_sep = ":",
  to_single_row = FALSE
)


# summary
ev_list = hts_prep_variable(
  summarize_var = "ev_typical_charge_1",
  variables_dt = variable_list,
  data = person
)

ev_charging_cat_summary = hts_summary(
  prepped_dt = ev_list$cat,
  summarize_var = "ev_typical_charge_1",
  summarize_by = NULL,
  summarize_vartype = "categorical",
  weighted = FALSE
)

ev_charging_cat_summary$summary