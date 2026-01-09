## Updated Transit code to new weights/method - 12/17/2024

library(data.table)
library(stringr)
library(travelSurveyTools)
library(psrc.travelsurvey)
library(psrcelmer)
library(dplyr)
library(psrcplot)
library(tidyverse)
source("C:/temp/2023/summary/transit/survey-23-preprocess.R")

## Read in codebook

cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx")

variable_list = readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels = readxl::read_xlsx(cb_path, sheet = 'value_labels')

setDT(variable_list)
setDT(value_labels)

## Read in data from Elmer
hh<- get_query(sql= "select  household_id as hh_id, hhincome_broad,home_jurisdiction, 
home_county, hh_weight,vehicle_count, home_rgcname, home_lat, home_lng, survey_year, 
numworkers, hh_race_category
                from HHSurvey.v_households_labels")


person<- get_query(sql= "select household_id as hh_id,race_category,
person_id, workplace, telecommute_freq, survey_year, person_weight, gender, age, sexuality, 
industry,office_available, commute_freq, education, adult_student, employment, disability_person,
commute_subsidy_transit, commute_subsidy_use_1,  work_lat, work_lng , work_rgcname, 
work_jurisdiction, work_county
                from HHSurvey.v_persons_labels")

day<- get_query(sql= "select person_id, day_id, household_id as hh_id, telework_time, 
                day_weight , survey_year from HHSurvey.v_days_labels")

trip<- get_query(sql= "select trip_id, household_id as hh_id, day_id,
person_id, mode_1, dest_purpose, survey_year, trip_weight, distance_miles, mode_class, 
mode_class_5, mode_acc, dest_purpose_cat, dest_purpose_cat_5, dest_rgcname,
travelers_total 
                from HHSurvey.v_trips_labels")
setDT(hh)
setDT(person)
setDT(day)
setDT(trip)

#add access_cond - Drove/Dropped Off, Bike/Micromobility/Other, Walk
variable_list <- add_variable(variable_list,
                              variable_name = "access_cond",
                              table_name = "trip",
                              data_type = "character")

trip <- trip %>%
  mutate(access_cond = case_when(mode_acc %in% c("Bicycle or e-bicycle", "Rode a bike", "Scooter, moped, skateboard", 
                                                       "Transferred from other rail", "Transferred from another bus, shuttle, or vanpool",
                                                      "Transferred from other transit (e.g., ferry, air)",
                                                        "Other") ~ "Bike/Micromobility/Other", 
                                       mode_acc %in% c("Drove and parked a car (e.g., a vehicle in my household)",
                                                       "Drove and parked a carshare vehicle (e.g., ZipCar, Car2Go)", "Got dropped off", 
                                                       "Took a taxi (e.g., Yellow Cab)", "Took ride-share/other hired car service (e.g., Lyft, Uber)",
                                                       "Uber/Lyft, taxi, or car service", 
                                                       "Drove and parked my own household's vehicle (or motorcycle)",
                                                       "Drove and parked another vehicle (or motorcycle)", "Got dropped off in my own household's vehicle (or motorcycle)",
                                                       "Got dropped off in another vehicle (or motorcycle)") ~ "Drove/Dropped Off", 
                                      mode_acc %in% c("Walked or jogged") ~ "Walk")) %>% 
  mutate(access_cond = factor(access_cond, levels = c("Bike/Micromobility/Other", "Drove/Dropped Off", "Walk")))

#add access_cond2 - Drove/Bike/Other, Walk
variable_list <- add_variable(variable_list,
                              variable_name = "access_cond2",
                              table_name = "trip",
                              data_type = "character")

trip <- trip %>%
  mutate(access_cond2 = case_when(mode_acc %in% c("Bicycle or e-bicycle", "Rode a bike", "Drove and parked a car (e.g., a vehicle in my household)",
                                                       "Drove and parked a carshare vehicle (e.g., ZipCar, Car2Go)", "Got dropped off", 
                                                       "Took a taxi (e.g., Yellow Cab)", "Took ride-share/other hired car service (e.g., Lyft, Uber)",
                                                       "Transferred from another bus, shuttle, or vanpool", "Scooter, moped, skateboard", 
                                                       "Transferred from other rail", "Transferred from other transit (e.g., ferry, air)",
                                                       "Uber/Lyft, taxi, or car service", "Drove and parked my own household's vehicle (or motorcycle)",
                                                       "Drove and parked another vehicle (or motorcycle)", "Got dropped off in my own household's vehicle (or motorcycle)",
                                                       "Got dropped off in another vehicle (or motorcycle)", "Other") ~ "Drove/Bike/Other", 
                                       mode_acc %in% c("Walked or jogged") ~ "Walk")) %>% 
  mutate(access_cond2 = factor(access_cond2, levels = c("Drove/Bike/Other", "Walk")))

#add access bike/micro specific
variable_list <- add_variable(variable_list,
                              variable_name = "access_bike_micro",
                              table_name = "trip",
                              data_type = "character")

trip <- trip %>%
  mutate(access_bike_micro = case_when(mode_acc %in% c("Bicycle or e-bicycle", "Rode a bike", "Scooter, moped, skateboard" 
                                                       ) ~ "Bike/Micromobility", 
                                       mode_acc %in% c("Drove and parked a car (e.g., a vehicle in my household)",
                                                       "Drove and parked a carshare vehicle (e.g., ZipCar, Car2Go)", "Got dropped off", 
                                                       "Took a taxi (e.g., Yellow Cab)", "Took ride-share/other hired car service (e.g., Lyft, Uber)",
                                                       "Transferred from another bus, shuttle, or vanpool", "Transferred from other rail", 
                                                       "Transferred from other transit (e.g., ferry, air)", "Uber/Lyft, taxi, or car service", 
                                                       "Drove and parked my own household's vehicle (or motorcycle)",
                                                       "Drove and parked another vehicle (or motorcycle)", "Got dropped off in my own household's vehicle (or motorcycle)",
                                                       "Got dropped off in another vehicle (or motorcycle)", "Other", "Walked or jogged") ~ "Other")) %>% 
  mutate(access_bike_micro = factor(access_bike_micro, levels = c("Bike/Micromobility", "Other")))

#add mode bike/micro specific
variable_list <- add_variable(variable_list,
                              variable_name = "mode_bike_micro",
                              table_name = "trip",
                              data_type = "character")

trip <- trip %>%
  mutate(mode_bike_micro = case_when(mode_class %in% c("Bike", "Micromobility") ~ "Bike/Micromobility", 
  mode_class %in% c("Drive SOV", "Drive HOV2", "Drive HOV3+", "Transit", "Walk",
                    "Ride Hail", "School Bus", "Other") ~ "Other")) %>% 
  mutate(mode_bike_micro = factor(mode_bike_micro, levels = c("Bike/Micromobility", "Other")))

#add destination purpose for chart
variable_list <- add_variable(variable_list,
                              variable_name = "dest_custom",
                              table_name = "trip",
                              data_type = "character")

trip <- trip %>%
  mutate(dest_custom = case_when(dest_purpose_cat %in% c("Home") ~ "Go Home", 
                                 dest_purpose_cat %in% c("Work", "Work-related") ~ "Work", 
                                 dest_purpose_cat %in% c("School", "School-related") ~ "School",
                                 dest_purpose_cat %in% c("Shopping", "Escort",
                                                         "Personal Business/Errand/Appointment") ~ "Errands/Shopping",
                                 dest_purpose_cat %in% c("Social/Recreation", "Meal") ~ "Social/Recreation",
                                 dest_purpose_cat %in% c("Other", "Overnight", "Change mode") ~ "Other")) %>% 
  mutate(dest_custom = factor(dest_custom, levels = c("Social/Recreation", "School", "Go Home", "Work", "Errands/Shopping", "Other")))


hts_data = list(hh=hh,
                person=person,
                day=day,
                trip = trip)
ids = c('hh_id', 'person_id','day_id', 'trip_id')
wts = c('hh_weight', 'person_weight', 'day_weight', 'trip_weight')

#some how a duplicate snuck into the variable list not sure how
variable_list<-variable_list%>%distinct(variable, .keep_all=TRUE)

## trips
trip_totals <- summarize_weighted(hts_data = hts_data,
                                  summarize_var = "survey_year",
                                  summarize_by = NULL,
                                  id_cols = ids,
                                  wt_cols = wts,
                                  wtname = "trip_weight"
)

trip_summary <- trip_totals$summary$wtd %>% 
  mutate(moe = est_se * 1.645,
         est_rounded = est/1000000)

trip_summary$survey_year<-as.character(trip_summary$survey_year)

static_column_chart(trip_summary,
                    x = "survey_year", y = "est_rounded", fill = "survey_year",
                    ylabel = "# of Trips", xlabel = "Survey Year", title = "Total Trips in Region (in millions)",
                    dec = 1) + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 16),
                      axis.title.x = element_text(size = 16),
                      plot.title = element_text(size = 24)
                    )

## mode
mode = summarize_weighted(hts_data= hts_data,
                              summarize_var = 'mode_class_5',
                              summarize_by = c('survey_year'),
                              id_cols= ids,
                              wt_cols=wts,
                              wtname='trip_weight'
)

mode_5<-mode$summary$wtd%>%mutate(moe=prop_se*1.645)

mode_5$survey_year<-as.character(mode_5$survey_year)

chart_mode <- static_column_chart(mode_5, x='mode_class_5', y='prop', fill='survey_year', 
                                      xlabel='Mode Share'
                                  , moe='moe'
                                  )+ 
                              theme(axis.text.x=element_text(size=14), axis.text.y=element_text(size=14),
                                    legend.text = element_text(size=14), axis.title.y=element_text(size=20), 
                                    axis.title.x=element_text(size=20))

chart_mode

## mode for 2023
mode_5_2023 <- mode_5 %>% filter(survey_year == '2023')

chart_mode_2023 <- static_column_chart(mode_5_2023, x='mode_class_5', y='prop', fill='survey_year', 
                                  xlabel='Mode Share'
                                  , moe='moe'
)+ 
  theme(axis.text.x=element_text(size=14), axis.text.y=element_text(size=14),
        legend.text = element_text(size=14), axis.title.y=element_text(size=20), 
        axis.title.x=element_text(size=20))


chart_mode_2023

## transit trips both count and share
mode_transit_prop<-mode$summary$wtd%>%mutate(moe=prop_se*1.645)%>%filter(mode_class_5=='Transit')

mode_transit_est<-mode$summary$wtd%>%mutate(moe=est_se*1.645)%>%filter(mode_class_5=='Transit')

mode_transit_prop$survey_year<-as.character(mode_transit_prop$survey_year)
mode_transit_est$survey_year<-as.character(mode_transit_est$survey_year)

### swap out est or prop to create each chart
chart_transit <- static_column_chart(mode_transit_prop, x='survey_year', y='prop', fill='survey_year',  
                                    , moe='moe'
)+ 
  theme(axis.text.x=element_text(size=14), axis.text.y=element_text(size=14),
        legend.text = element_text(size=14), axis.title.y=element_text(size=20), 
        axis.title.x=element_text(size=20))

chart_transit

## walk both count and share
mode_walk_prop<-mode$summary$wtd%>%mutate(moe=prop_se*1.645)%>%filter(mode_class_5=='Walk')

mode_walk_est<-mode$summary$wtd%>%mutate(moe=est_se*1.645)%>%filter(mode_class_5=='Walk')

mode_walk_prop$survey_year<-as.character(mode_walk_prop$survey_year)
mode_walk_est$survey_year<-as.character(mode_walk_est$survey_year)

### swap out est or prop to create each chart
chart_walk <- static_column_chart(mode_walk_prop, x='survey_year', y='prop', fill='survey_year', 
                                  , moe='moe'
)+ 
  theme(axis.text.x=element_text(size=14), axis.text.y=element_text(size=14),
        legend.text = element_text(size=14), axis.title.y=element_text(size=20), 
        axis.title.x=element_text(size=20))


chart_walk

## mode bike/micro
hts_data2 <- hts_data

hts_data2$trip <- hts_data2$trip %>%
  drop_na(mode_bike_micro)

mode_bike <- summarize_weighted(hts_data = hts_data2,                                       
                                summarize_var = "mode_bike_micro",
                                summarize_by = c("survey_year"),
                                id_cols = ids,                                       
                                wt_cols = wts,                                      
                                wtname = "trip_weight"                                       )  

## bike/micro trips both count and share
mode_bike_prop<-mode_bike$summary$wtd%>%mutate(moe=prop_se*1.645)

mode_bike_est<-mode_bike$summary$wtd%>%mutate(moe=est_se*1.645)

mode_bike_prop$survey_year<-as.character(mode_bike_prop$survey_year)
mode_bike_est$survey_year<-as.character(mode_bike_est$survey_year)


### filter for prop and micro/bike
mode_bike_prop<-mode_bike_prop%>%
  filter(mode_bike_micro != "Other")

### filter for est and micro/bike
mode_bike_est<-mode_bike_est%>% 
  filter(mode_bike_micro != "Other")

### swap out est or prop to create each chart
mode_bike_chart <- static_column_chart(mode_bike_est,
                                       x = "survey_year", y = "est", fill = "survey_year", 
                                       color = "gnbopgy_10",
                                       ylabel = "# of Trips", xlabel = "Survey Year", 
                                       moe = "moe"
) + 
  theme(
    axis.text.x = element_text(size = 14),
    axis.text.y = element_text(size = 14),
    axis.title.y = element_text(size = 20),
    axis.title.x = element_text(size = 20),
    plot.title = element_text(size = 24)
  )

mode_bike_chart

## transit by race
race_transit = summarize_weighted(hts_data= hts_data,
                          summarize_var = 'mode_class_5',
                          summarize_by = c('survey_year', 'race_category'),
                          id_cols= ids,
                          wt_cols=wts,
                          wtname='trip_weight'
)

race_tran<-race_transit$summary$wtd%>%mutate(moe=prop_se*1.645)%>%filter(mode_class_5=='Transit')%>%
  filter(race_category!='Child')%>%filter(race_category!='Missing/No response')

race_tran$survey_year<-as.character(race_tran$survey_year)

#clean up
race_tran_2023 <- race_tran%>%filter(survey_year=='2023')%>%
  filter(race_category!='Two or More Races non-Hispanic')%>%
  filter(race_category!='Some Other Race non-Hispanic') %>%
  mutate(race_category = recode(race_category, 'White non-Hispanic' = 'White')) %>%
  mutate(race_category = recode(race_category, 'Hispanic' = 'Hispanic or Latinx')) %>%
  mutate(race_category = recode(race_category, 'Black or African American non-Hispanic' = 'Black or African American')) %>%
  mutate(race_category = recode(race_category, 'AANHPI non-Hispanic' = 'Asian/Native Hawaiian/Pacific Islander')) 

chart_race_tran <- static_bar_chart(race_tran_2023, x='prop', y='race_category', fill='race_category', 
                                    ylabel= 'Race/Ethnicity', 
                                     xlabel='Share of Trips by Transit'
                                     , moe='moe'
                                    )+ theme(axis.text.x=element_text(size=14), 
                                             axis.text.y=element_text(size=14),
        legend.text = element_text(size=14), axis.title.y=element_text(size=20), 
        axis.title.x=element_text(size=20))


chart_race_tran

## transit and disability
disability = summarize_weighted(hts_data= hts_data,
                                summarize_var = 'mode_class_5',
                                summarize_by = c('survey_year', 'disability_person'),
                                id_cols= ids,
                                wt_cols=wts,
                                wtname='trip_weight'
)

dis<-disability$summary$wtd%>%mutate(moe=prop_se*1.645)%>%drop_na(disability_person)

dis$survey_year<-as.character(dis$survey_year)

dis_transit <- dis%>%filter(mode_class_5=="Transit")

chart_dis <- static_column_chart(dis_transit, x='disability_person', y='prop', fill='disability_person', 
                                 ylabel= 'Share of Trips by Transit', 
                                 xlabel='Identify as Having a Disability'
                                 , moe='moe'
)+ 
  theme(axis.text.x=element_text(size=14), axis.text.y=element_text(size=14),
        legend.text = element_text(size=14), axis.title.y=element_text(size=20), 
        axis.title.x=element_text(size=20))

chart_dis

## mode by income
mode_inc = summarize_weighted(hts_data= hts_data,
                              summarize_var = 'mode_class_5',
                              summarize_by = c('survey_year', 'hhincome_broad'),
                              id_cols= ids,
                              wt_cols=wts,
                              wtname='trip_weight'
)

mode_income<-mode_inc$summary$wtd%>%
  mutate(moe=prop_se*1.645)%>%filter(survey_year=='2023')%>%
  filter(hhincome_broad!='Prefer not to answer')%>%
  filter(mode_class_5=="Transit")%>%
  mutate(hhincome_broad=factor(hhincome_broad, 
                              levels=c('Under $25,000', '$25,000-$49,999','$50,000-$74,999', 
                              '$75,000-$99,999', '$100,000-$199,999','$200,000 or more')))%>%
  filter(hhincome_broad!='NA')

chart_mode_income <- static_bar_chart(mode_income, x='prop', y='hhincome_broad', 
                                      fill='mode_class_5', ylabel= 'Household Income', 
                                      xlabel='Transit Mode Share', moe='moe')+ 
  theme(axis.text.x=element_text(size=14), axis.text.y=element_text(size=14),
        legend.text = element_text(size=14), axis.title.y=element_text(size=20), 
        axis.title.x=element_text(size=20))

#write.csv(mode_income, 'mode_income.csv')

chart_mode_income

## commute pass by income
pass_inc = summarize_weighted(hts_data= hts_data,
                              summarize_var = 'commute_subsidy_transit',
                              summarize_by = c('survey_year', 'hhincome_broad'),
                              id_cols= ids,
                              wt_cols=wts,
                              wtname='person_weight'
)

pass_income<-pass_inc$summary$wtd%>%
  drop_na(commute_subsidy_transit)%>%mutate(moe=prop_se*1.645)%>%filter(survey_year=='2023')%>%
  filter(commute_subsidy_transit=='Offered')%>%filter(hhincome_broad!='Prefer not to answer')%>%
  mutate(hhincome_broad=factor(hhincome_broad, levels=c('Under $25,000', '$25,000-$49,999','$50,000-$74,999', 
                                                        '$75,000-$99,999', '$100,000-$199,999','$200,000 or more')))

chart_pass_income <- static_bar_chart(pass_income, x='prop', y='hhincome_broad', fill='hhincome_broad', 
                                      xlabel='Transit Pass Offered'
                                      #, moe='moe'
)+ theme(axis.text.x=element_text(size=14), 
         axis.text.y=element_text(size=14),
         legend.text = element_text(size=14), 
         axis.title.y=element_text(size=20), 
         axis.title.x=element_text(size=20))

#write.csv(pass_income, 'pass_income.csv')

chart_pass_income

## mode to access transit for walk or drove/bike/other
hts_data3 <- hts_data

hts_data3$trip <- hts_data3$trip %>%
  drop_na(access_cond2) %>% 
  filter(mode_class_5 == "Transit")

access <- summarize_weighted(hts_data = hts_data3, 
                             summarize_var = "access_cond2",
                             summarize_by = c("survey_year", "mode_class_5"),
                             id_cols = ids,                                       
                             wt_cols = wts,                                      
                             wtname = "trip_weight" ) 

access_summary <- access$summary$wtd %>%
  mutate(moe=prop_se*1.645)

access_summary$survey_year<-as.character(access_summary$survey_year)

accesstransit_chart <- static_column_chart(access_summary,
                                           x = "survey_year", y = "prop", fill = "access_cond2", 
                                           color = "gnbopgy_10",
                                           ylabel = "Share of Trips", xlabel = "Survey Year", 
                                           title = "Access to Transit Trips - Share",
                                           moe = "moe"
) + 
  theme(
    axis.text.x = element_text(size = 14),
    axis.text.y = element_text(size = 14),
    axis.title.y = element_text(size = 20),
    axis.title.x = element_text(size = 20),
    plot.title = element_text(size = 24)
  )

accesstransit_chart

## mode to access transit for drove and bike/other
hts_data4 <- hts_data

hts_data4$trip <- hts_data4$trip %>%
  drop_na(access_cond) %>% 
  filter(mode_class_5 == "Transit")

access_nowalk <- summarize_weighted(hts_data = hts_data4,                                       
                             summarize_var = "access_cond",
                             summarize_by = c("survey_year", "mode_class_5"),
                             id_cols = ids,                                       
                             wt_cols = wts,                                      
                             wtname = "trip_weight"                                       )  

access_summary_nowalk <- access_nowalk$summary$wtd %>%
  mutate(moe = prop_se * 1.645) 

access_summary_nowalk$survey_year<-as.character(access_summary_nowalk$survey_year)

access_summary_nowalk<-access_summary_nowalk%>%
  filter(access_cond != "Walk")

accesstransit_nowalk_chart <- static_column_chart(access_summary_nowalk,
                                           x = "survey_year", y = "prop", fill = "access_cond", 
                                           color = "gnbopgy_10",
                                           ylabel = "Share of Trips", xlabel = "Survey Year", 
                                           title = "Access to Transit Trips - Share",
                                           moe = "moe"
) + 
  theme(
    axis.text.x = element_text(size = 14),
    axis.text.y = element_text(size = 14),
    axis.title.y = element_text(size = 20),
    axis.title.x = element_text(size = 20),
    plot.title = element_text(size = 24)
  )

accesstransit_nowalk_chart

## walk mode to transit based on destination 2023
hts_data5 <- hts_data

hts_data5$trip <- hts_data5$trip %>%
  drop_na(dest_custom) %>% 
  filter(mode_acc!="Missing: Skip Logic")

destination = summarize_weighted(hts_data= hts_data5,
                                summarize_var = 'mode_acc',
                                summarize_by = c('survey_year', 'mode_class_5', 'dest_custom'),
                                id_cols= ids,
                                wt_cols=wts,
                                wtname='trip_weight'
)

dest<-destination$summary$wtd%>%
  mutate(moe=prop_se*1.645) 

dest$survey_year<-as.character(dest$survey_year)

dest_2023 <- dest%>%filter(survey_year=="2023")%>%
  filter(mode_class_5=="Transit")%>%
  filter(mode_acc=="Walked or jogged")

chart_dest <- static_column_chart(dest_2023, x='dest_custom', y='prop', fill='mode_acc', 
                                  color='pognbgy_10',
                                  , moe='moe'
)+ 
  theme(axis.text.x=element_text(size=14), axis.text.y=element_text(size=14),
        legend.text = element_text(size=14), axis.title.y=element_text(size=20), 
        axis.title.x=element_text(size=20))

chart_dest
