library(tidyverse)
library(psrcelmer)

# read data
day_data <- get_query(sql= "select * from HHSurvey.v_days_labels")
trip_data <- get_query(sql= "select * from HHSurvey.v_trips_labels")

# person-days with 0 day weight
test_day <- day_data %>% filter(day_weight==0 | is.na(day_weight))

vars_list <- c("trip_id","household_id","person_id","day_id","day_iscomplete","svy_complete",
               "speed_mph","speed_flag","dest_purpose_cat",
               "survey_year","hh_day_iscomplete","trip_weight","trip_weight_2017_2019_combined")
# all trips made in test_day with valid trip weights
test_trip <- trip_data %>% 
  filter(day_id %in% test_day$day_id & trip_weight!=0) %>%
  select(all_of(vars_list)) %>%
  # add day weights
  left_join(day_data %>% select(day_id,day_weight), by="day_id")