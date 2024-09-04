library(tidyverse)
library(psrc.travelsurvey)
library(psrcelmer)
library(travelSurveyTools)
library(data.table)
library(psrcplot)
install_psrc_fonts()

# source("analysis/analysis_funcs.R")
source("../survey-23-preprocess_JLin.R")

# reading in codebook
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx"
variable_list <- readxl::read_xlsx(cb_path, sheet = 'variable_list')
setDT(variable_list)


delivery_vars <- c("deliver_elsewhere", "deliver_food", "deliver_grocery",
                   "deliver_none", "deliver_office", "deliver_package")
vars <- c(delivery_vars, "daynum","travel_dow","travel_date",
          "hhincome_broad", "home_county", "vehicle_count",
          "age","transit_freq","race_category")
all_ids <- c("hh_id","person_id","day_id","trip_id","vehicle_id")
all_weights <- c("hh_weight","person_weight","day_weight","trip_weight")

# Retrieve the data
hts_data <- get_psrc_hts(survey_vars = vars) 

day <-  hts_data$day %>%
  rowwise() %>%
  mutate(deliver_home_any = case_when(
    deliver_food=="Yes" | deliver_grocery=="Yes" | deliver_package=="Yes"~ "Yes",
    is.na(deliver_food)+is.na(deliver_grocery)+ is.na(deliver_package)==3~ NA,
    TRUE~ "No"),
    .after="deliver_package") %>%
  ungroup() %>%
  mutate_at(vars(deliver_elsewhere,deliver_office,deliver_none),
            ~case_when(.=="Selected"~"Yes",
                       .=="Not selected"~"No"))


hh_day_weight <- hts_data$hh %>%
  select(hh_id,hh_weight) %>%
  full_join(day %>%
              group_by(hh_id) %>%
              summarise(n_days = length(unique(daynum))) %>%
              ungroup(),
            by="hh_id") %>%
  mutate(hh_day_weight = hh_weight/n_days) %>%
  select(hh_id,hh_day_weight)

hh_day_delivery <- day %>%
  group_by(survey_year,hh_id, daynum) %>%
  summarise_at(vars(deliver_elsewhere:deliver_home_any),
               ~case_when(sum(.=="Yes")>0~"Yes",
                          sum(.=="No")>0~"No",
                          TRUE~NA)) %>%
  ungroup() %>%
  left_join(hh_day_weight, by="hh_id")
# 
# saveRDS(hh_day_delivery, "analysis/hh_day_delivery.rds")
