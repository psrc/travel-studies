library(tidyverse)
library(psrc.travelsurvey)
library(psrcelmer)
library(travelSurveyTools)
library(data.table)
library(psrcplot)
install_psrc_fonts()

# source("analysis/analysis_funcs.R")
source("survey-23-preprocess.R")

# reading in codebook
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx"
variable_list <- readxl::read_xlsx(cb_path, sheet = 'variable_list')
setDT(variable_list)


delivery_vars <- c("deliver_food", "deliver_grocery", "deliver_package", "deliver_work", "deliver_other",
                   "deliver_none", "deliver_elsewhere", "deliver_office")
vars <- c(delivery_vars, "daynum","travel_dow","travel_date",
          "hhincome_broad", "home_county", "vehicle_count",
          "age","transit_freq","race_category")
all_ids <- c("hh_id","person_id","day_id","trip_id","vehicle_id")
all_weights <- c("hh_weight","person_weight","day_weight","trip_weight")

# Retrieve the data
hts_data <- get_psrc_hts(survey_vars = vars) 

day<-hts_data$day

hh_day_delivery <- day %>%
  group_by(survey_year, hh_id, daynum) %>%
  # any 18+ person in household has delivery -> yes
  summarise_at(vars(deliver_food, deliver_grocery, deliver_package, deliver_work, deliver_other,
                    deliver_none, deliver_elsewhere, deliver_office),
               ~case_when(sum(.=="Yes", na.rm=TRUE)>0~"Yes",
                          sum(.=="No", na.rm=TRUE)>0~"No",
                          sum(.=="Selected", na.rm=TRUE)>0~"Yes",
                          sum(.=="Not Selected", na.rm=TRUE)>0~"No",
                          TRUE~NA))

hh_day_weight<- day%>%
  group_by(survey_year, hh_id, daynum) %>%
  summarize(hh_day_weight=first(day_weight))

home_delivery_cols<-c('deliver_food', 'deliver_grocery', 'deliver_package', 'deliver_work')
hh_day_delivery<-hh_day_delivery%>%
  mutate(deliver_home_any= if_else( deliver_food=="Yes" | deliver_grocery=="Yes" | deliver_package=="Yes" | deliver_work=="Yes" | deliver_other=="Yes", "Yes", "No"))

hh_day_delivery<-merge(hh_day_delivery, hh_day_weight, by=c('survey_year','hh_id', 'daynum'))
# 
saveRDS(hh_day_delivery, "hh_day_delivery.rds")


