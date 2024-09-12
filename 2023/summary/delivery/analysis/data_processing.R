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

# get earlier delivery data
delivery_1719 <- get_query(sql= "select household_id as hh_id,person_id,daynum,survey_year,deliver_food, deliver_grocery, deliver_work, deliver_package,delivery_pkgs_freq,delivery_grocery_freq,delivery_food_freq,delivery_work_freq from HHSurvey.days_2017_2019" )%>%
  mutate(survey_year=survey_year,
         hh_id = as.character(hh_id),
         person_id = as.character(person_id)) %>%
  mutate(deliver_food = case_when(( is.na(delivery_food_freq) & is.na(deliver_food))  ~NA,
                                  ((delivery_food_freq) %in% c("Missing: Skip Logic",'Missing: Non-response') &
                                     (deliver_food %in% c("Missing: Skip Logic",'Missing: Non-response') )) ~ NA,
                                  delivery_food_freq == "0 (none)"~ "No",
                                  deliver_food=='No' ~ "No",
                                  TRUE~"Yes"),
         deliver_grocery= case_when(( is.na(delivery_grocery_freq) & is.na(deliver_grocery))  ~NA,
                                    ((delivery_grocery_freq) %in% c("Missing: Skip Logic",'Missing: Non-response') &
                                       (deliver_grocery %in% c("Missing: Skip Logic",'Missing: Non-response') )) ~ NA,
                                    delivery_grocery_freq == "0 (none)"~ "No",
                                    deliver_grocery=='No' ~ "No",
                                    TRUE~"Yes"),
         deliver_package= case_when(( is.na(delivery_pkgs_freq) & is.na(deliver_package))  ~NA,
                                    ((delivery_pkgs_freq) %in% c("Missing: Skip Logic",'Missing: Non-response') &
                                       (deliver_package %in% c("Missing: Skip Logic",'Missing: Non-response') )) ~ NA,
                                    delivery_pkgs_freq == "0 (none)"~ "No",
                                    deliver_package=='No' ~ "No",
                                    TRUE~"Yes"),
         deliver_work= case_when(( is.na(delivery_work_freq) & is.na(deliver_work))  ~NA,
                                 ((delivery_work_freq) %in% c("Missing: Skip Logic",'Missing: Non-response') &
                                    (deliver_work %in% c("Missing: Skip Logic",'Missing: Non-response') )) ~ NA,
                                 delivery_work_freq == "0 (none)"~ "No",
                                 deliver_work=='No' ~ "No",
                                 TRUE~"Yes"))%>%
  select(c("hh_id","person_id","daynum","survey_year","deliver_food","deliver_grocery","deliver_package","deliver_work"))
day_2017_2019 <- hts_data$day %>%
  filter(survey_year %in% c(2017, 2019)) %>%
  select(-c("deliver_food","deliver_grocery","deliver_package","deliver_work")) %>%
  left_join(delivery_1719, by = c("hh_id","person_id","daynum","survey_year")) %>%
  select(names(hts_data$day))


delivery_2021 <- get_query(sql= "select household_id as hh_id,person_id,daynum,delivery_pkgs_freq,delivery_grocery_freq,delivery_food_freq,delivery_work_freq from HHSurvey.days_2021" ) %>%
  mutate(survey_year=2021,
         hh_id = as.character(hh_id),
         person_id = as.character(person_id)) %>%
  mutate(deliver_food = case_when(delivery_food_freq == "0 (none)"~ "No",
                                  delivery_food_freq == "Missing: Skip Logic"~ NA,
                                  delivery_food_freq == "Missing: Non-response"~ NA,
                                  TRUE~"Yes"),
         deliver_grocery= case_when(delivery_grocery_freq == "0 (none)"~ "No",
                                    delivery_grocery_freq == "Missing: Skip Logic"~ NA,
                                    delivery_food_freq == "Missing: Non-response"~ NA,
                                    TRUE~"Yes"),
         deliver_package= case_when(delivery_pkgs_freq == "0 (none)"~ "No",
                                    delivery_pkgs_freq == "Missing: Skip Logic"~ NA,
                                    TRUE~"Yes"),
         deliver_work= case_when(delivery_work_freq == "0 (none)"~ "No",
                                 delivery_work_freq == "Missing: Skip Logic"~ NA,
                                 TRUE~"Yes")) %>%
  select(c("hh_id","person_id","daynum","survey_year","deliver_food","deliver_grocery","deliver_package","deliver_work"))
day_2021 <- hts_data$day %>%
  filter(survey_year==2021) %>%
  select(-c("deliver_food","deliver_grocery","deliver_package","deliver_work")) %>%
  left_join(delivery_2021, by = c("hh_id","person_id","daynum","survey_year")) %>%
  select(names(hts_data$day))


day <-  hts_data$day %>%
  # add 2021 delivery data to day data
  filter(!(survey_year %in% c(2017, 2019,2021))) %>%
  add_row(day_2021) %>%
  add_row(day_2017_2019)%>%
  rowwise() %>%
  mutate(deliver_home_any = case_when(
    deliver_food=="Yes" | deliver_grocery=="Yes" | deliver_package=="Yes" | deliver_work=="Yes" | deliver_other=="Yes"~ "Yes",
    is.na(deliver_food)+is.na(deliver_grocery)+ is.na(deliver_package)+is.na(deliver_work)+ is.na(deliver_other)==5~ NA,
    TRUE~ "No"),
    .after="deliver_work") %>%
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
             by=c("hh_id")) %>%
   mutate(hh_day_weight = hh_weight/n_days) %>%
   select(hh_id,n_days,hh_day_weight)

# have one record for each household at this point; the weights will sum to less than households in the region
 # needs to be joined to the day table to represent days


hh_day_delivery <- day %>%
  group_by(survey_year, hh_id, daynum) %>%
  # any 18+ person in household has delivery -> yes
  summarise_at(vars(deliver_food, deliver_grocery, deliver_package, deliver_work, deliver_other,
                    deliver_none, deliver_elsewhere, deliver_office, deliver_home_any),
               ~case_when(sum(.=="Yes", na.rm=TRUE)>0~"Yes",
                          sum(.=="No", na.rm=TRUE)>0~"No",
                          TRUE~NA)) %>%
  ungroup() %>%
  left_join(hh_day_weight, by=c("hh_id"))
# 
saveRDS(hh_day_delivery, "hh_day_delivery.rds")


