# This code analyses delivery variables from the day table

library(data.table)
library(tidyverse)
library(DT)

setwd("//aws-prod-file01/datateam/Projects/Surveys/HHTravel/Survey2019/Data/PSRC_2019_HTS_RSG_Final_Deliverable")

hh      = read.csv(file = '1_Household.csv')
person  = read.csv(file = '2_Person.csv')
vehicle = read.csv(file = '3_Vehicle.csv')
day     = read.csv(file = '4_Day.csv')
trip    = read.csv(file = '5_Trip.csv')



#find a non-respond rate (household level) in 2019
non_responce_2019 = function(variable,variable_freq) {
  temp = day %>% mutate(delivery_pkgs_freq_upd = case_when(variable_freq > 0 & variable_freq < 10  ~ 1,
                                                           variable_freq == 0 ~ 0,
                                                           variable_freq == -9999 ~ -9999,
                                                           variable_freq == -9998 ~ -9998,
                                                           variable_freq == 995 ~ 995)) %>% 
  mutate(delivery_all = case_when(delivery_pkgs_freq_upd == 1 ~ 1,
                                  delivery_pkgs_freq_upd == 0 ~ 0,
                                  variable == 1 ~ 1,
                                  variable == 0 ~ 0,
                                  variable == -9999 ~ -9999,
                                  variable == -9998 ~ -9998,
                                  variable == 995 ~ 995,
                                  delivery_pkgs_freq_upd == -9999 ~ -9999,
                                  delivery_pkgs_freq_upd == -9998 ~ -9998,
                                  delivery_pkgs_freq_upd == 995 ~ 995)) %>%
  filter(survey_year == 2019) %>% 
  mutate(skipped = case_when(delivery_all == -9998 ~ 1,
                             delivery_all == 995 ~ 1,
                             TRUE ~ 0 )) %>%
  #finding the households where all people in the household skipped delivery question
  group_by(hhid) %>% summarize(min_skipped = min(skipped)) %>% group_by(min_skipped) %>% tally
  return (temp)
}

#checking a non-responce rate for package deliveries
non_responce_2019("deliver_package", "delivery_pkgs_freq")

#checking a non-responce rate for grocery deliveries
non_responce_2019("deliver_grocery", "delivery_grocery_freq")

#checking a non-responce rate for food deliveries
non_responce_2019("deliver_food", "delivery_food_freq")

#checking a non-responce rate for services deliveries
non_responce_2019("deliver_work", "delivery_work_freq")
