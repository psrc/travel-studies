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

#Find number of households that received different types of deliveries

delivery_result_generator_upd = function (delivery_variable,delivery_freq_variable) { 

  day_upd = day %>% mutate(delivery_pkgs_freq_upd = case_when(!!sym(delivery_freq_variable) > 0 & !!sym(delivery_freq_variable) < 10  ~ 1,
                                                              !!sym(delivery_freq_variable) == 0 ~ 0)) %>% 
    mutate(delivery_all = case_when(delivery_pkgs_freq_upd == 1 ~ 1,
                                    delivery_pkgs_freq_upd == 0 ~ 0,
                                    !!sym(delivery_variable) == 1 ~ 1,
                                    !!sym(delivery_variable) == 0 ~ 0)) 
  
  #print(day_upd %>% group_by(delivery_all) %>% tally)
  #calculate average number of packages per weekday
  ave_deliver_weekdays_hh = day_upd %>% 
    group_by(hhid,daynum,hh_day_wt_combined) %>% 
    summarise(days_delivery = sum(delivery_all,na.rm = TRUE)) %>% 
    #filter(days_delivery > 1) %>% 
    mutate(days_delivery_hh = case_when(days_delivery > 0 && hh_day_wt_combined > 0 ~ 1,
                                        days_delivery == 0 ~0),weekdays_num = case_when(hh_day_wt_combined > 0 ~1 )) %>% 
    group_by(hhid) %>% 
    summarize(days_delivery_sum = sum(days_delivery_hh,na.rm = TRUE),weekdays_num_sum = sum(weekdays_num,na.rm = TRUE) ) %>% 
    #filter(days_delivery_sum > 1)
    mutate(ave_deliveries = days_delivery_sum/weekdays_num_sum )
  
  hh_selected = hh %>% 
    #select(hhid, hh_day_wt_revised,hh_day_wt_2019,hh_day_wt_combined,hh_wt_revised, hh_wt_2019, hh_wt_combined)
    select(hhid, hh_day_wt_combined,hh_wt_revised, hh_wt_2019, hh_wt_combined )
  
  hh_deliv_join = left_join(ave_deliver_weekdays_hh,hh_selected)
  
  temp_result = hh_deliv_join %>% 
    mutate(ave_deliv_weekdays_region_comb = ave_deliveries*hh_wt_combined,ave_deliv_weekdays_region_2017 = ave_deliveries*hh_wt_revised,
           ave_deliv_weekdays_region_2019 = ave_deliveries*hh_wt_2019) %>% 
    summarize(ave_delivery_wk_reg_comb = sum(ave_deliv_weekdays_region_comb,na.rm = TRUE), 
              ave_delivery_wk_reg_2017 = sum(ave_deliv_weekdays_region_2017,na.rm = TRUE),
              ave_delivery_wk_reg_2019 = sum(ave_deliv_weekdays_region_2019,na.rm = TRUE))
  
  return(temp_result)
}

#checking a number of households that received package deliveries
delivery_result_generator_upd("deliver_package", "delivery_pkgs_freq")

#checking a number of households that received grocery deliveries
delivery_result_generator_upd("deliver_grocery", "delivery_grocery_freq")

#checking a number of households that received food deliveries
delivery_result_generator_upd("deliver_food", "delivery_food_freq")

#checking a number of households that received services deliveries
delivery_result_generator_upd("deliver_work", "delivery_work_freq")



#find a non-respond number of hh (household level) in 2019
non_responce_2019 = function(variable,variable_freq) {
  temp = day %>% mutate(delivery_pkgs_freq_upd = case_when(!!sym(variable_freq) > 0 & !!sym(variable_freq) < 10  ~ 1,
                                                           !!sym(variable_freq) == 0 ~ 0,
                                                           !!sym(variable_freq) == -9999 ~ -9999,
                                                           !!sym(variable_freq) == -9998 ~ -9998,
                                                           !!sym(variable_freq) == 995 ~ 995)) %>%  
  #print(temp %>% group_by(delivery_pkgs_freq_upd) %>% tally)  
  mutate(delivery_all = case_when(delivery_pkgs_freq_upd == 1 ~ 1,
                                  delivery_pkgs_freq_upd == 0 ~ 0,
                                  !!sym(variable) == 1 ~ 1,
                                  !!sym(variable) == 0 ~ 0,
                                  !!sym(variable) == -9999 ~ -9999,
                                  !!sym(variable) == -9998 ~ -9998,
                                  !!sym(variable) == 995 ~ 995,
                                  delivery_pkgs_freq_upd == -9999 ~ -9999,
                                  delivery_pkgs_freq_upd == -9998 ~ -9998,
                                  delivery_pkgs_freq_upd == 995 ~ 995)) 
  
  #print(temp %>% group_by(delivery_pkgs_freq_upd) %>% tally) 
  temp = temp %>% filter(survey_year == 2019) %>% 
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

#online shopping time distribution
shopping_distr = day %>% 
  mutate(online_shop_time_upd = case_when( online_shop_time == 0 ~ "Din't shop online",
                                           online_shop_time > 0 & online_shop_time <= 30 ~ "0 to 30 minutes",
                                           online_shop_time > 30 & online_shop_time <= 60 ~"30 to 60 minutes",
                                           online_shop_time > 60 ~ "more than 60 minutes")) %>% 
  group_by(online_shop_time_upd) %>% 
  filter(!is.na(online_shop_time_upd)) %>% 
  summarize(hh_day_wt_combined = sum(hh_day_wt_combined), hh_day_wt_revised = sum(hh_day_wt_revised,na.rm = TRUE),hh_day_wt_2019 = sum(hh_day_wt_2019)) %>% 
  mutate(share_comb = round(hh_day_wt_combined/sum(hh_day_wt_combined)*100,2),
         share_2017 = round(hh_day_wt_revised/sum(hh_day_wt_revised)*100,2),
         share_2019 = round(hh_day_wt_2019/sum(hh_day_wt_2019)*100,2)) 
  
  
#share of people who shopped online
yes_onlins_shop_2019 = day %>% mutate(online_shopping_yn = case_when(online_shop_time == 0 ~ 0,
                                              online_shop_time > 0 ~ 1)) %>% 
  filter(survey_year == 2019) %>% 
  mutate(shopping_region_comb = online_shopping_yn*hh_day_wt_2019) %>% 
  summarize(yes_sum = sum(shopping_region_comb, na.rm = TRUE))

no_online_shop_2019 = day %>% mutate(online_shopping_yn = case_when(online_shop_time == 0 ~ 1,
                                              online_shop_time > 0 ~ 0)) %>% 
  filter(survey_year == 2019) %>% 
  mutate(shopping_region_comb = online_shopping_yn*hh_day_wt_2019) %>% 
  summarize(no_sum = sum(shopping_region_comb, na.rm = TRUE))
  

yes_onlins_shop_2019/(yes_onlins_shop_2019+no_online_shop_2019)*100

yes_onlins_shop_2017 = day %>% mutate(online_shopping_yn = case_when(online_shop_time == 0 ~ 0,
                                                                     online_shop_time > 0 ~ 1)) %>% 
  filter(survey_year == 2017) %>% 
  mutate(shopping_region_comb = online_shopping_yn*hh_day_wt_revised) %>% 
  summarize(yes_sum = sum(shopping_region_comb, na.rm = TRUE))

no_online_shop_2017 = day %>% mutate(online_shopping_yn = case_when(online_shop_time == 0 ~ 1,
                                                                    online_shop_time > 0 ~ 0)) %>% 
  filter(survey_year == 2017) %>% 
  mutate(shopping_region_comb = online_shopping_yn*hh_day_wt_revised) %>% 
  summarize(no_sum = sum(shopping_region_comb, na.rm = TRUE))


yes_onlins_shop_2017/(yes_onlins_shop_2017+no_online_shop_2017)*100


