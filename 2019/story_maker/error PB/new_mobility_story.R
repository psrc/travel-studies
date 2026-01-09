# This is a code that covers New Mobility Story which includes:

#Rideshare:
#mode_freq_5 (person) - Times used rideshare in past 30 days
#mode_1 (trip) - Primary mode
#mode_2 (trip) - Second mode chosen
#mode_3 (trip) - Third mode chosen
#mode_4 (trip) - Fourth mode chosen
#mode_acc (trip) - Travel mode to transit
#mode_egr (trip) - Travel mode from transit
#mode_type (trip) - Synthesized mode (derived)

#Carshare services:
#car_share (hh) - HH belongs to carshare program
#mode_freq_4 (person) - Times used carshare in past 30 days
#mode_1 (trip) - Primary mode
#mode_2 (trip) - Second mode chosen
#mode_3 (trip) - Third mode chosen
#mode_4 (trip) - Fourth mode chosen
#mode_acc (trip) - Travel mode to transit
#mode_egr (trip) - Travel mode from transit
#mode_type (trip) - Synthesized mode (derived)
#vehicleused (person) - Vehicle uses most often


#delivery:
#deliver_package (day) - Packages delivered on travel day
#deliver_grocery (day) - Groceries delivered on travel day
#deliver_food (day) - Food/meal prep delivered on travel day
#deliver_work (day) - Services delivered on travel day
#delivery_food_freq (day) - Number of food/meal prep deliveries on travel day
#delivery_grocery_freq (day) - Number of grocery deliveries on travel day
#delivery_pkgs_freq (day) - Number of package deliveries on travel day
#delivery_work_freq (day) - Number of service deliveries on travel day

setwd("C:/Users/pbutrina/Documents/GitHub/travel-studies/2019/story_maker")

source('global.R')
source('travel_crosstab.R')

# where you are running your R code
wrkdir <- "C:/Users/pbutrina/Documents/GitHub/travel-studies/2019/story_maker"

#where you want to output tables
file_loc <- 'C:/Users/pbutrina/Documents/HHSurvey/mobility_story'


table_map_freq = data.table(variable = c("6-7 days/week", "5 days/week", "2-4 days/week", "1 day/week",
                                    "1-3 times in the past 30 days", "I do this, but not in the past 30 days", "I never do this" ),
                       changed_var = c("5 or more days/week", "5 or more days/week", "1-4 days/week", "1-4 days/week",
                                       "1-3 times in the past 30 days", "I do this, but not in the past 30 days", "I never do this" ))

simpl_fun = function(new_mobility_data,table_map_freq ){
  temp = table[table_map, mode_freq_4 := changed_var, on = c(mode_freq_4 = "variable")]
  
  
}

tmp = "mode_freq_4"
temp = table[table_map_freq, on = c(table[[tmp]] = "variable")]

table[[var]] <- table_map_freq$changed_var[match(table[[var]],table_map_freq$variable)]

# what is the frequency of people using carshare
new_mobility_data <-c('mode_freq_4')
summarize_simple_tables(new_mobility_data, table_map_freq) 

# what is the frequency of people using TNC
new_mobility_data_carshare <-c('mode_freq_5')
summarize_simple_tables(new_mobility_data_carshare) 


#ridehailing frequency by gender, income, education, age, vehicle ownership, number of children

prev_res_vars <-
  c('gender',
    'hhincome_broad',
    'education',
    'age',
    'vehicle_count',
    'numchildren')

for (res_factor in prev_res_vars){
  summarize_cross_tables(new_mobility_data, res_factor)
}

#carsharing frequency by gender, income, education, age, vehicle ownership, number of children

for (res_factor in prev_res_vars){
  summarize_cross_tables(new_mobility_data_carshare, res_factor)
}
  
#Q1. How does vehicle ownership vary by race?
summarize_cross_tables(race_data, c('vehicle_count'))

#Q2. How do mode shares differ by race?
summarize_cross_tables(race_data,c('mode_simple'))

# Person Race by Trip Mode by Trip Purpose, 3 dimension data summary example
d_purp_cat<-c('d_purp_cat')
purposes<-values.lu[variable=='d_purp_cat'][['value_text']]
for(this_purpose in purposes){
  summarize_cross_tables(race_data,mode,d_purp_cat, this_purpose)
  }

mode<-c('mode_simple')
#Person Race by Trip Mode by Household Income, 
inc<-c('hhincome_broad')
incomes<-values.lu[variable=='hhincome_broad'][['value_text']]
for(this_income in incomes){
  summarize_cross_tables(race_data,mode,inc, this_income)
}
#- by gender 
gender<-c('gender')
incomes<-values.lu[variable=='gender'][['value_text']]
for(this_gender in gender){
  summarize_cross_tables(race_data,mode,gender, gender)
}

#Q3. Do people of color have longer or shorter commutes than others? Are people of color being forced to have longer commutes?
#Commute Travel Time by Race
summarize_cross_tables(race_data, c('commute_auto_time'))
summarize_cross_tables(race_data, c('commute_auto_distance'))


#Q4. Are people of color using non-SOV modes at the same rate as other groups? 
#Are people of color using active transportation as much as other groups? 
#Do people of color have to drive more than others to conduct daily business (person miles or vehicle miles of travel)? This may indicate if the non-motorized network and new services are meeting people’s needs.
# Times ridden transit/walk/biked/ridehailing in past 30 days 
# -	By race
# mode_freq_1..mode_freq_5
summarize_cross_tables(race_data, c('mode_freq_1'))
summarize_cross_tables(race_data,c('mode_freq_2'))
summarize_cross_tables(race_data, c('mode_freq_3'))
summarize_cross_tables(race_data,c('mode_freq_4'))
summarize_cross_tables(race_data, c('mode_freq_5'))


#Q5. Who is benefiting from TDM strategies?
#Usual way of paying for parking at work by race
#Work parking costs per month by race
#Employer commuter benefits by race (flextime, compressed workweek, transit pass ownership)
#AV interest and concern by race

summarize_cross_tables(race_data, c('workpass'))
summarize_cross_tables(race_data, c('benefits_1'))
summarize_cross_tables(race_data, c('benefits_2'))
summarize_cross_tables(race_data, c('benefits_3'))
summarize_cross_tables(race_data,c('benefits_4'))

#Q6. What impact could non-motorized improvements have on usage by people of color?
summarize_cross_tables(race_data, c('wbt_transitmore_1'))
summarize_cross_tables(race_data,c('wbt_transitmore_2'))
summarize_cross_tables(race_data,c('wbt_transitmore_3'))
summarize_cross_tables(race_data,c('wbt_bikemore_1'))
summarize_cross_tables(race_data,c('wbt_bikemore_2'))
summarize_cross_tables(race_data,c('wbt_bikemore_3'))



#delivery question exploration
#load tables
day %>%
  mutate(delivery_pkgs_freq_upd = case_when(delivery_pkgs_freq > 0 & delivery_pkgs_freq < 10  ~ 1,
                                            delivery_pkgs_freq == 0 ~ 0)) %>% 
  #checking the categories and the sum of the categories
  group_by(delivery_pkgs_freq_upd) %>% summarize(n=n(), weigth_combined = sum(hh_day_wt_combined),weight_2017 = sum(hh_day_wt_revised),
                                                 weight_2019 = sum(hh_day_wt_2019))


#summing the delivery_all and creating a variable taht identifies the hh with more than 1 delivery
delivery_gen = day %>% mutate(delivery_pkgs_freq_upd = case_when(delivery_pkgs_freq > 0 & delivery_pkgs_freq < 10  ~ 1,
                                                            delivery_pkgs_freq == 0 ~ 0)) %>% 
  mutate(delivery_all = case_when(delivery_pkgs_freq_upd == 1 ~ 1,
                                  delivery_pkgs_freq_upd == 0 ~ 0,
                                  deliver_package == 1 ~ 1,
                                  deliver_package == 0 ~ 0)) %>% 
  select(hhid, delivery_all) %>% 
  group_by(hhid) %>% 
  summarize(delivery_sum = sum(delivery_all, na.rm = TRUE)) %>% 
  mutate(delivery_true = case_when(delivery_sum > 0 ~ 1,
                                   delivery_sum == 0 ~ 0))  

#adding a variable that indicated if there were any deliveries or not (delivery freq and deliver_packages variables)
day_upd = day %>% mutate(delivery_pkgs_freq_upd = case_when(delivery_pkgs_freq > 0 & delivery_pkgs_freq < 10  ~ 1,
                                                            delivery_pkgs_freq == 0 ~ 0,
                                                            delivery_pkgs_freq == -9999 ~ -9999,
                                                            delivery_pkgs_freq == -9998 ~ -9998,
                                                            delivery_pkgs_freq == 995 ~ 995)) %>% 
  mutate(delivery_all = case_when(delivery_pkgs_freq_upd == 1 ~ 1,
                                  delivery_pkgs_freq_upd == 0 ~ 0,
                                  deliver_package == 1 ~ 1,
                                  deliver_package == 0 ~ 0,
                                  deliver_package == -9999 ~ -9999,
                                  deliver_package == -9998 ~ -9998,
                                  deliver_package == 995 ~ 995,
                                  delivery_pkgs_freq == 995 ~ 995)) %>% group_by(delivery_all) %>% tally 

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

delivery_result = hh_deliv_join %>% 
  mutate(ave_deliv_weekdays_region_comb = ave_deliveries*hh_wt_combined,ave_deliv_weekdays_region_2017 = ave_deliveries*hh_wt_revised,
         ave_deliv_weekdays_region_2019 = ave_deliveries*hh_wt_2019) %>% 
  summarize(ave_delivery_wk_reg_comb = sum(ave_deliv_weekdays_region_comb,na.rm = TRUE), 
            ave_delivery_wk_reg_2017 = sum(ave_deliv_weekdays_region_2017,na.rm = TRUE),
            ave_delivery_wk_reg_2019 = sum(ave_deliv_weekdays_region_2019,na.rm = TRUE))
  

#find a non-respond rate (household level) in 2019
day_upd_deliv_2019 = day %>%filter(survey_year == 2019) %>% 
  mutate(delivery_pkgs_freq_upd = case_when(delivery_pkgs_freq > 0 & delivery_pkgs_freq < 10  ~ 1,
                                                            delivery_pkgs_freq == 0 ~ 0,
                                                            delivery_pkgs_freq == -9999 ~ -9999,
                                                            delivery_pkgs_freq == -9998 ~ -9998,
                                                            delivery_pkgs_freq == 995 ~ 995)) %>%  
  mutate(delivery_all = case_when(delivery_pkgs_freq_upd == 1 ~ 1,
                                  delivery_pkgs_freq_upd == 0 ~ 0,
                                  deliver_package == 1 ~ 1,
                                  deliver_package == 0 ~ 0,
                                  deliver_package == -9999 ~ -9999,
                                  deliver_package == -9998 ~ -9998,
                                  deliver_package == 995 ~ 995,
                                  delivery_pkgs_freq_upd == 995 ~ 995)) %>% 
  #filter(survey_year == 2019) %>% 
  mutate(skipped = case_when(delivery_all == -9998 ~ 1,
                             delivery_all == 995 ~ 1,
                             TRUE ~ 0 )) %>%
  #finding the households where all people in the household skipped delivery question
  group_by(hhid) %>% summarize(min_skipped = min(skipped)) %>% group_by(min_skipped) %>% tally



#function
delivery_result_generator = function (delivery_variable,delivery_freq_variable) { 
  day_upd = day %>% mutate(delivery_pkgs_freq_upd = case_when(delivery_freq_variable > 0 & delivery_freq_variable < 10  ~ 1,
                                                              delivery_freq_variable == 0 ~ 0)) %>% 
    mutate(delivery_all = case_when(delivery_pkgs_freq_upd == 1 ~ 1,
                                    delivery_pkgs_freq_upd == 0 ~ 0,
                                    delivery_variable == 1 ~ 1,
                                    delivery_variable == 0 ~ 0)) 
  
  print(day_upd %>% group_by(delivery_all) %>% tally)
  
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
 
  hh_deliv_join = left_join(ave_deliver_weekdays_hh,hh_selected)
  
  temp_result = hh_deliv_join %>% 
    mutate(ave_deliv_weekdays_region_comb = ave_deliveries*hh_wt_combined,ave_deliv_weekdays_region_2017 = ave_deliveries*hh_wt_revised,
           ave_deliv_weekdays_region_2019 = ave_deliveries*hh_wt_2019) %>% 
    summarize(ave_delivery_wk_reg_comb = sum(ave_deliv_weekdays_region_comb,na.rm = TRUE), 
              ave_delivery_wk_reg_2017 = sum(ave_deliv_weekdays_region_2017,na.rm = TRUE),
              ave_delivery_wk_reg_2019 = sum(ave_deliv_weekdays_region_2019,na.rm = TRUE))
    
  return(temp_result)
}

delivery_result_generator("deliver_package", "delivery_pkgs_freq")



day_upd = day %>% mutate(delivery_grocery_freq_upd = case_when(delivery_grocery_freq > 0 & delivery_grocery_freq < 10  ~ 1,
                                                               delivery_grocery_freq == 0 ~ 0)) %>% 
  mutate(delivery_all_grocery = case_when(delivery_grocery_freq_upd == 1 ~ 1,
                                  delivery_grocery_freq_upd == 0 ~ 0,
                                  deliver_grocery == 1 ~ 1,
                                  deliver_grocery == 0 ~ 0)) 

#calculate average number of packages per weekday
ave_deliver_weekdays_hh = day_upd %>% 
  group_by(hhid,daynum,hh_day_wt_combined) %>% 
  summarise(days_delivery = sum(delivery_all_grocery,na.rm = TRUE)) %>% 
  #filter(days_delivery > 1) %>% 
  mutate(days_delivery_hh = case_when(days_delivery > 0 && hh_day_wt_combined > 0 ~ 1,
                                      days_delivery == 0 ~0),weekdays_num = case_when(hh_day_wt_combined > 0 ~1 )) %>% 
  group_by(hhid) %>% 
  summarize(days_delivery_sum = sum(days_delivery_hh,na.rm = TRUE),weekdays_num_sum = sum(weekdays_num,na.rm = TRUE) ) %>% 
  #filter(days_delivery_sum > 1)
  mutate(ave_deliveries = days_delivery_sum/weekdays_num_sum )

hh_deliv_join = left_join(ave_deliver_weekdays_hh,hh_selected)

grocery_result = hh_deliv_join %>% 
  mutate(ave_deliv_weekdays_region_comb = ave_deliveries*hh_wt_combined,ave_deliv_weekdays_region_2017 = ave_deliveries*hh_wt_revised,
         ave_deliv_weekdays_region_2019 = ave_deliveries*hh_wt_2019) %>% 
  summarize(ave_delivery_wk_reg_comb = sum(ave_deliv_weekdays_region_comb,na.rm = TRUE), 
            ave_delivery_wk_reg_2017 = sum(ave_deliv_weekdays_region_2017,na.rm = TRUE),
            ave_delivery_wk_reg_2019 = sum(ave_deliv_weekdays_region_2019,na.rm = TRUE))










day_upd_deliv=hh %>% 
  select(hhid,hh_day_wt_combined,hh_day_wt_revised,hh_day_wt_2019) %>% 
  left_join(delivery_gen)


day_upd_ids = day_upd %>% 
  filter(delivery_all %in% c(0,1)) %>%
  group_by(hhid) %>% 
  summarize(n = n()) %>% 
  filter (n>1)

list_ids = c(day_upd_ids$hhid) 

inner_join(day_upd_ids,day_upd,by = c("hhid" = "hhid")) %>%  
  select(hhid, personid, daynum, survey_year, delivery_pkgs_freq, deliver_package, hh_day_wt_revised,hh_wt_2019,hh_day_wt_combined,delivery_all) %>% 
  filter(is.na(delivery_all))
  
  group_by(delivery_all) %>% tally
  
  
  
  select(hhid, personid, daynum, survey_year, delivery_pkgs_freq, deliver_package, hh_day_wt_revised,hh_wt_2019,hh_day_wt_combined)

  
  
  group_by(delivery_pkgs_freq) %>% tally
  
  
day_upd %>% 
  filter(hhid == "17100060") %>% 
  select(hhid, personid, daynum, delivery_pkgs_freq, deliver_package, hh_day_wt_revised,hh_day_wt_2019,hh_day_wt_combined, hh_wt_revised,hh_wt_2019,hh_wt_combined)

day_upd %>% 
  filter(hhid %in% list_ids) %>% 
  group_by(hhgroup) %>% 
  summarize(n=n())

hh %>% 
  group_by() %>% 
  summarize(hh_wt_revised_sum = sum(hh_wt_revised, na.rm = TRUE), hh_wt_2019_sum=sum(hh_wt_2019, na.rm = TRUE), 
            hh_wt_combined_sum =sum(hh_wt_combined, na.rm = TRUE), hh_day_wt_revised_sum = sum(hh_day_wt_revised, na.rm = TRUE),
            hh_day_wt_2019_sum=sum(hh_day_wt_2019, na.rm = TRUE), hh_day_wt_combined_sum = sum(hh_day_wt_combined, na.rm = TRUE))
 
  

