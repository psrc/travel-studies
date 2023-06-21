library(psrc.travelsurvey)
library(dplyr)
library(stringr)
library(ggplot2)
library(forcats)
library(odbc)
library(DBI)
library(tidyr)


output_path='C:/GitHub/travel-studies/2021/trend-stories/bike-ped/'

db.connect <- function(adatabase) {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\SOCKEYE",
                                database = adatabase,
                                trusted_connection = "yes"
  )
}

# read table
read.dt <- function(adatabase, atable) {
  elmer_connection <- db.connect(adatabase)
  dtelm <- dbReadTable(elmer_connection, SQL(atable))
  dbDisconnect(elmer_connection)
  return(dtelm)
}

# read-in variable metadata table for levels
vars_meta <- read.dt('Elmer', 'HHSurvey.variable_metadata')


mode_vars<-c('mode_1', 'mode_simple')
other_vars<-c('final_home_rgcnum', 'hhsize', 'vehicle_count',  "hhincome_broad", 'rent_own', 'res_dur', 'student', 'education',  'hhincome_detailed', "age", "age_category", 'race_category', 'race_eth_broad', 'gender', 'employment',  'lifecycle', 'mode_acc', 'dest_purpose_cat', 'origin_purpose_cat', 'final_home_is_rgc')
trip_path_dist<-'trip_path_distance'
all_vars<-c(mode_vars, other_vars, trip_path_dist)

Walk_bike_data_17_19<- get_hhts("2017_2019", "t", vars=all_vars)%>% mutate(year=ifelse(survey=='2017_2019', '2017/2019', '2021'))

Walk_bike_data_21<- get_hhts("2021", "t", vars=all_vars)%>% mutate(year=ifelse(survey=='2017_2019', '2017/2019', '2021'))

Walk_bike_data_17_19<-Walk_bike_data_17_19%>%mutate(NoVehicles=ifelse(vehicle_count=='0 (no vehicles)', 'No Vehicles', "Has Vehicles"))%>%
  mutate(hhsize_simple=case_when(hhsize== '4 people' ~'4 or more people',                                                                     hhsize== '5 people' ~'4 or more people',
                                 hhsize== '6 people' ~'4 or more people',
                                 hhsize== '7 people' ~'4 or more people',
                                 hhsize== '8 people' ~'4 or more people',
                                 hhsize== '12 people' ~'4 or more people',
                                 TRUE ~ hhsize))%>%
  mutate(hhincome_100= case_when(hhincome_broad=='$100,000-$199,000' ~ '$100,000 or more',
                                 hhincome_broad=='$200,000 or more' ~ '$100,000 or more',
                                 TRUE~hhincome_broad))%>%
  mutate(edu_simple= case_when(education=='Bachelor degree' ~ 'Bachelors or higher', 
                               education=='Graduate/Post-graduate degree' ~ 'Bachelors or higher',
                               TRUE ~ 'Less than Bachelors degree'))%>%
  mutate(age_grp= case_when(age=='75-84 years' ~ '75 years or older', 
                            age == '85 or years older' ~ '75 years or older',
                            TRUE ~ age))%>%
  mutate(gender_grp= case_when(gender == 'Prefer not to answer' ~ 'Non-binary, another, prefer not to answer',
                               gender=='Not listed here / prefer not to answer' ~ 'Non-binary, another, prefer not to answer',
                               gender=='Non-Binary'~ 'Non-binary, another, prefer not to answer',
                               gender=='Another'~ 'Non-binary, another, prefer not to answer',
                               TRUE ~ gender))%>%mutate(work_purpose=ifelse(dest_purpose_cat=='Work', 'Work', 'Not Work'))%>%
  
  mutate(race_short= str_extract(race_eth_broad,  "^[^ ]+"))%>%
  mutate(simple_purpose=ifelse(dest_purpose_cat=='Home', origin_purpose_cat, dest_purpose_cat))%>%
  mutate(simple_purpose=case_when(simple_purpose=='Work'~ 'Work/School',
                                  simple_purpose=='School'~ 'Work/School',
                                  simple_purpose=='Work-related'~ 'Work/School',
                                  simple_purpose=='Shop'~ 'Shop and Errands',
                                  simple_purpose=='Escort'~ 'Shop and Errands',
                                  simple_purpose=='Errand/Other'~ 'Shop and Errands',
                                  simple_purpose=='Change mode'~ 'Shop and Errands',
                                  simple_purpose=='Social/Recreation' ~ 'Social/Recreation/Meal',
                                  simple_purpose=='Meal' ~ 'Social/Recreation/Meal',
                                  simple_purpose=='Home' ~'Shop and Errands',
                                  is.na(simple_purpose) ~ 'Shop and Errands',
                                  TRUE ~ simple_purpose))%>%mutate(rgc=as.factor(final_home_is_rgc))%>%
  mutate(non_motorized_mode=ifelse((mode_simple=='Walk'|mode_simple=='Bike'),'Walk/Bike', 'Not Walk/Bike'))%>%
  mutate(mode_acc_walk=ifelse(mode_acc=='Walked or jogged', 'Walked or jogged', 'Other Access Mode'))


Walk_bike_data_21<-Walk_bike_data_21%>%mutate(NoVehicles=ifelse(vehicle_count=='0 (no vehicles)', 'No Vehicles', "Has Vehicles"))%>%
  mutate(hhsize_simple=case_when(hhsize== '4 people' ~'4 or more people',                                                                    hhsize== '5 people' ~'4 or more people',
                                 hhsize== '6 people' ~'4 or more people',
                                 hhsize== '7 people' ~'4 or more people',
                                 hhsize== '8 people' ~'4 or more people',
                                 hhsize== '12 people' ~'4 or more people',
                                 TRUE ~ hhsize)) %>%
  mutate(hhincome_100= case_when(hhincome_broad=='$100,000-$199,000' ~ '$100,000 or more',
                                 hhincome_broad=='$200,000 or more' ~ '$100,000 or more',
                                 TRUE~hhincome_broad))%>%
  mutate(edu_simple= case_when(education=='Bachelor degree' ~ 'Bachelors or higher', 
                               education=='Graduate/Post-graduate degree' ~ 'Bachelors or higher',
                               TRUE ~ 'Less than Bachelors degree'))%>%
  mutate(age_grp= case_when(age=='75-84 years' ~ '75 years or older', 
                            age == '85 or years older' ~ '75 years or older',
                            TRUE ~ age))%>%
  mutate(gender_grp= case_when(gender == 'Prefer not to answer' ~ 'Non-binary, another, prefer not to answer',
                               gender=='Not listed here / prefer not to answer' ~ 'Non-binary, another, prefer not to answer',
                               gender=='Non-Binary'~ 'Non-binary, another, prefer not to answer', 
                               gender=='Another'~ 'Non-binary, another, prefer not to answer',
                               TRUE ~ gender))%>%
  mutate(work_purpose=ifelse(dest_purpose_cat=='Work', 'Work', 'Not Work'))%>%
  mutate(simple_purpose=ifelse(dest_purpose_cat=='Home', origin_purpose_cat, dest_purpose_cat))%>%
  mutate(simple_purpose=case_when(simple_purpose=='Work'~ 'Work/School',
                                  simple_purpose=='School'~ 'Work/School',
                                  simple_purpose=='Work-related'~ 'Work/School',
                                  simple_purpose=='Shop'~ 'Shop and Errands',
                                  simple_purpose=='Escort'~ 'Shop and Errands',
                                  simple_purpose=='Errand/Other'~ 'Shop and Errands',
                                  simple_purpose=='Change mode'~ 'Shop and Errands',
                                  simple_purpose=='Social/Recreation' ~ 'Social/Recreation/Meal',
                                  simple_purpose=='Meal' ~ 'Social/Recreation/Meal',
                                  simple_purpose=='Meal' ~ 'Social/Recreation/Meal',
                                  simple_purpose=='Home' ~'Shop and Errands',
                                  is.na(simple_purpose) ~ 'Shop and Errands',
                                  TRUE ~ simple_purpose))%>%mutate(rgc=as.factor(final_home_is_rgc))%>%
  mutate(non_motorized_mode=ifelse((mode_simple=='Walk'|mode_simple=='Bike'),'Walk/Bike', 'Not Walk/Bike'))%>%
  mutate(mode_acc_walk=ifelse(mode_acc=='Walked or jogged', 'Walked or jogged', 'Other Access Mode'))

Walk_bike_data_17_19$hhincome_100_f=factor(Walk_bike_data_17_19$hhincome_100, levels=c("Prefer not to answer",  "$100,000 or more","$75,000-$99,999", "$50,000-$74,999" ,"$25,000-$49,999" , "Under $25,000"  ))

Walk_bike_data_21$hhincome_100_f=factor(Walk_bike_data_21$hhincome_100, levels=c("Prefer not to answer",  "$100,000 or more","$75,000-$99,999", "$50,000-$74,999" ,"$25,000-$49,999" , "Under $25,000"  ))




trips_by_mode_17_19<-hhts_count(Walk_bike_data_17_19, group_vars='mode_simple')%>%
  filter(mode_simple!='Total')
trips_by_mode_21<-hhts_count(Walk_bike_data_21, group_vars='mode_simple')%>%filter(mode_simple!='Total')

trips_by_mode_17_19_21<-merge(trips_by_mode_17_19, trips_by_mode_21, by='mode_simple', suffixes=c('17_19', '21'))
trips_by_mode<-rbind(trips_by_mode_17_19, trips_by_mode_21)%>% mutate(year=ifelse(survey=='2017_2019', '2017/2019', '2021'))
trips_by_mode_no_drive<-trips_by_mode%>%filter(!mode_simple %in% c('Drive', 'Other'))

write.csv(trips_by_mode_no_drive, paste0(output_path, 'trips_by_mode.csv'))


all_trips_summs_2017_2019 <- hhts_count(Walk_bike_data_17_19,
                                        group_vars=c('simple_purpose'),
                                        spec_wgt='trip_adult_weight_2017_2019')%>%
  filter(simple_purpose!='Total')




all_trips_summs_2021 <- hhts_count(Walk_bike_data_21,
                                   group_vars=c('simple_purpose'),
                                   spec_wgt='trip_adult_weight_2021')%>%
  filter(simple_purpose!='Total')




all_trips_summs_long<- rbind(all_trips_summs_2017_2019, all_trips_summs_2021) %>%
  mutate(survey = str_replace_all(survey, "_", "/"))

write.csv(all_trips_summs_long,  paste0(output_path,'trips_by_purpose.csv'))


all_trips_summs_2021_mode <- hhts_count(Walk_bike_data_21,
                                        group_vars=c('simple_purpose','mode_simple'),
                                        spec_wgt='trip_adult_weight_2021')%>%
  filter(simple_purpose!='Total')%>%drop_na(mode_simple)%>%filter(mode_simple=='Walk' | mode_simple=='Bike')


all_trips_summs_2017_19_mode <- hhts_count(Walk_bike_data_17_19,
                                           group_vars=c('simple_purpose','mode_simple'),
                                           spec_wgt='trip_adult_weight_2017_2019')%>%
  filter(simple_purpose!='Total')%>%drop_na(mode_simple)%>%filter(mode_simple=='Walk' | mode_simple=='Bike')


mode_purp_long<-rbind(all_trips_summs_2017_19_mode,  all_trips_summs_2021_mode) %>%
  mutate(survey = str_replace_all(survey, "_", "/"))


mode_purp_long_walk<- mode_purp_long%>%filter(mode_simple=='Walk')
write.csv(mode_purp_long_walk,  paste0(output_path,'trips_by_purpose_walk.csv'))





transit_trips_by_mode_17_19<-Walk_bike_data_17_19%>%drop_na('mode_acc')
trips_by_mode_17_19<-hhts_count(transit_trips_by_mode_17_19, group_vars='mode_acc_walk',
                                spec_wgt='trip_adult_weight_2017_2019')%>%
  filter(mode_acc_walk!='Total')

transit_trips_by_mode_21<-Walk_bike_data_21%>%drop_na('mode_acc')
Walk_bike_data_21_no_miss_acc<-transit_trips_by_mode_21%>% filter(mode_acc!='Missing: Technical Error')
trips_by_mode_21<-hhts_count(Walk_bike_data_21_no_miss_acc, group_vars='mode_acc_walk', spec_wgt='trip_adult_weight_2021')%>%filter(mode_acc_walk!='Total')

trips_by_mode_access17_19_21<-merge(trips_by_mode_17_19, trips_by_mode_21, by='mode_acc_walk', suffixes=c('17_19', '21'))
trips_by_mode_access<-rbind(trips_by_mode_17_19, trips_by_mode_21)%>% mutate(year=ifelse(survey=='2017_2019', '2017/2019', '2021'))

write.csv(trips_by_mode_access,  paste0(output_path,'transit_access.csv'))


# Walk Trip distance
all_trips_summs_2017_2019 <- hhts_median(Walk_bike_data_17_19,
                                         stat_var = 'trip_path_distance',
                                         group_vars=c('mode_simple'),
                                         spec_wgt='trip_adult_weight_2017_2019')%>%
  filter(mode_simple=='Walk' )%>%drop_na(mode_simple)

all_trips_summs_2021 <- hhts_median(Walk_bike_data_21,
                                    stat_var = 'trip_path_distance',
                                    group_vars=c('mode_simple'),
                                    spec_wgt='trip_adult_weight_2021')%>%
  filter(mode_simple=='Walk')%>%drop_na(mode_simple)

all_trips_summs_long<- rbind(all_trips_summs_2017_2019, all_trips_summs_2021) %>%
  mutate(survey = str_replace_all(survey, "_", "/"))
write.csv(all_trips_summs_long,  paste0(output_path,'walk_distance.csv'))

#Walk Frequency
mode_vars<-c('mode_freq_2', 'mode_freq_3')
other_vars<-c('final_home_rgcnum', 'hhsize', 'vehicle_count',  "hhincome_broad", 'rent_own', 'res_dur',
              'student', 'education',  'hhincome_detailed', "age", "age_category", 'race_category', 'race_eth_broad', 
              'gender', 'employment',  'lifecycle', 'final_home_is_rgc')
all_vars<-c(mode_vars, other_vars)

Walk_Walk_freq_data_17_19<- get_hhts("2017_2019", "p", vars=all_vars)%>% mutate(year=ifelse(survey=='2017_2019', '2017/2019', '2021'))%>%mutate(Walks_sometimes=ifelse(mode_freq_3=='I never do this', 'Never Walks', 'Walks Sometimes' ))

Walk_Walk_freq_data_21<- get_hhts("2021", "p", vars=all_vars)%>% mutate(year=ifelse(survey=='2017_2019', '2017/2019', '2021'))%>%mutate(Walks_sometimes=ifelse(mode_freq_3=='I never do this', 'NeverWalks', 'Walks Sometimes' ))

wbfreq_summs_2017_2019 <- hhts_count(Walk_Walk_freq_data_17_19,
                                     group_vars=c('mode_freq_3'),
                                     spec_wgt='hh_weight_2017_2019')%>%
  filter(mode_freq_3!='Total')

wbfreq_summs_2021 <- hhts_count(Walk_Walk_freq_data_21,
                                group_vars=c('mode_freq_3'),
                                spec_wgt='person_adult_weight_2021')%>%
  filter(mode_freq_3!='Total')

wbfreq_summs_long<- rbind(wbfreq_summs_2017_2019, wbfreq_summs_2021) %>%
  mutate(survey = str_replace_all(survey, "_", "/"))

write.csv(wbfreq_summs_long, paste0(output_path,'walk_frequency.csv'))

# Walk frequency by demographics
#Group variables into meaningful categories and redo analysis

Walk_Walk_freq_data_17_19<-Walk_Walk_freq_data_17_19%>%mutate(NoVehicles=ifelse(vehicle_count=='0 (no vehicles)', 'No Vehicles', "Has Vehicles"))%>%
  mutate(hhsize_simple=case_when(hhsize== '4 people' ~'4 or more people',                                                                     hhsize== '5 people' ~'4 or more people',
                                 hhsize== '6 people' ~'4 or more people',
                                 hhsize== '7 people' ~'4 or more people',
                                 hhsize== '8 people' ~'4 or more people',
                                 hhsize== '12 people' ~'4 or more people',
                                 TRUE ~ hhsize))%>%
  mutate(hhincome_100= case_when(hhincome_broad=='$100,000-$199,000' ~ '$100,000 or more',
                                 hhincome_broad=='$200,000 or more' ~ '$100,000 or more',
                                 TRUE~hhincome_broad))%>%
  mutate(edu_simple= case_when(education=='Bachelor degree' ~ 'Bachelors or higher', 
                               education=='Graduate/Post-graduate degree' ~ 'Bachelors or higher',
                               TRUE ~ 'Less than Bachelors degree'))%>%
  mutate(age_grp= case_when(age=='75-84 years' ~ '75 years or older', 
                            age == '85 or years older' ~ '75 years or older',
                            TRUE ~ age))%>%
  mutate(gender_grp= case_when(gender == 'Prefer not to answer' ~ 'Non-binary, another, prefer not to answer',
                               gender=='Not listed here / prefer not to answer' ~ 'Non-binary, another, prefer not to answer',
                               gender=='Non-Binary'~ 'Non-binary, another, prefer not to answer',
                               gender=='Another'~ 'Non-binary, another, prefer not to answer',
                               TRUE ~ gender))%>%
  
  mutate(race_short= str_extract(race_eth_broad,  "^[^ ]+"))%>%filter(age !='5-11 years' & age != '16-17 years' & age != '12-15 years')



Walk_Walk_freq_data_21<-Walk_Walk_freq_data_21%>%mutate(NoVehicles=ifelse(vehicle_count=='0 (no vehicles)', 'No Vehicles', "Has Vehicles"))%>%
  mutate(hhsize_simple=case_when(hhsize== '4 people' ~'4 or more people',                                                                    hhsize== '5 people' ~'4 or more people',
                                 hhsize== '6 people' ~'4 or more people',
                                 hhsize== '7 people' ~'4 or more people',
                                 hhsize== '8 people' ~'4 or more people',
                                 hhsize== '12 people' ~'4 or more people',
                                 TRUE ~ hhsize)) %>%
  mutate(hhincome_100= case_when(hhincome_broad=='$100,000-$199,000' ~ '$100,000 or more',
                                 hhincome_broad=='$200,000 or more' ~ '$100,000 or more',
                                 TRUE~hhincome_broad))%>%
  mutate(edu_simple= case_when(education=='Bachelor degree' ~ 'Bachelors or higher', 
                               education=='Graduate/Post-graduate degree' ~ 'Bachelors or higher',
                               TRUE ~ 'Less than Bachelors degree'))%>%
  mutate(age_grp= case_when(age=='75-84 years' ~ '75 years or older', 
                            age == '85 or years older' ~ '75 years or older',
                            TRUE ~ age))%>%
  mutate(gender_grp= case_when(gender == 'Prefer not to answer' ~ 'Non-binary, another, prefer not to answer',
                               gender=='Not listed here / prefer not to answer' ~ 'Non-binary, another, prefer not to answer',
                               gender=='Non-Binary'~ 'Non-binary, another, prefer not to answer', 
                               gender=='Another'~ 'Non-binary, another, prefer not to answer',
                               TRUE ~ gender))

Walk_Walk_freq_data_17_19$hhincome_100_f=factor(Walk_Walk_freq_data_17_19$hhincome_100, levels=c("Prefer not to answer",  "$100,000 or more","$75,000-$99,999", "$50,000-$74,999" ,"$25,000-$49,999" , "Under $25,000"  ))

Walk_Walk_freq_data_21$hhincome_100_f=factor(Walk_Walk_freq_data_21$hhincome_100, levels=c("Prefer not to answer",  "$100,000 or more","$75,000-$99,999", "$50,000-$74,999" ,"$25,000-$49,999" , "Under $25,000"  ))

simple_groupings<-c('race_eth_broad'='Race/Ethnicity','hhincome_100_f'='Household Income','edu_simple'= 'Education Level', 'hhsize_simple'= 'Household Size','NoVehicles'= 'Household Vehicles', 'final_home_is_rgc'='Home in Regional Growth Center', 'gender_grp'='Gender', 'final_cnty'='Home County', 'lifecycle' ='Household Lifecycle', 'seattle_home'='Home in Seattle', 'employment'='Employment', 'age'= 'Age' )

#Bike frequency
Walk_bike_freq_data_17_19<- get_hhts("2017_2019", "p", vars=all_vars)%>% mutate(year=ifelse(survey=='2017_2019', '2017/2019', '2021'))%>%mutate(bikes_sometimes=ifelse(mode_freq_2=='I never do this', 'Never Bikes', 'Bikes Sometimes' ))
Walk_bike_freq_data_21<- get_hhts("2021", "p", vars=all_vars)%>% mutate(year=ifelse(survey=='2017_2019', '2017/2019', '2021'))%>%mutate(bikes_sometimes=ifelse(mode_freq_2=='I never do this', 'Never Bikes', 'Bikes Sometimes' ))

wbfreq_summs_2017_2019 <- hhts_count(Walk_bike_freq_data_17_19,
                                     group_vars=c('mode_freq_2'),
                                     spec_wgt='hh_weight_2017_2019')%>%
  filter(mode_freq_2!='Total')


wbfreq_summs_2021 <- hhts_count(Walk_bike_freq_data_21,
                                group_vars=c('mode_freq_2'),
                                spec_wgt='person_adult_weight_2021')%>%
  filter(mode_freq_2!='Total')

wbfreq_summs_long<- rbind(wbfreq_summs_2017_2019, wbfreq_summs_2021) %>%
  mutate(survey = str_replace_all(survey, "_", "/"))

write.csv(wbfreq_summs_long,  paste0(output_path,'bike_frequency.csv'))

# Walking by demographics
mode_vars<-c('mode_1', 'mode_simple', 'mode_acc_walk')
other_vars<-c('final_home_rgcnum', 'hhsize', 'vehicle_count',  "hhincome_broad", 'rent_own', 'res_dur', 'student', 'education',  'hhincome_detailed', "age", "age_category", 'race_category', 'race_eth_broad', 'gender', 'employment',  'lifecycle', 'mode_acc', 'dest_purpose_cat', 'origin_purpose_cat', 'final_home_is_rgc')
trip_path_dist<-'trip_path_distance'
all_vars<-c(mode_vars, other_vars, trip_path_dist)


simple_groupings<-c('race_eth_broad'='Race/Ethnicity','hhincome_100_f'='Household Income',
                    'NoVehicles'= 'Household Vehicles', 'final_home_is_rgc'='Home in Regional Growth Center')

for(i in seq(1, length(simple_groupings))){
  g <- simple_groupings[i]
  # cat_name <- eval(names(g))
  cat_name <- names(g)
  print(cat_name)
  Walk_bike_summs_2017_2019 <- hhts_count(Walk_bike_data_17_19,
                                          group_vars=c(names(g),'mode_simple'),
                                          spec_wgt='trip_adult_weight_2017_2019')%>%
    filter(cat_name!='Total') %>%
    filter(mode_simple=='Walk')
  
  
  
  Walk_bike_summs_2021 <- hhts_count(Walk_bike_data_21,
                                     group_vars=c(names(g),'mode_simple'),
                                     spec_wgt='trip_adult_weight_2021')%>%
    filter(cat_name!='Total') %>%
    filter(mode_simple=='Walk')
  
  if(cat_name=='race_eth_broad'){
    
    Walk_bike_summs_2017_2019 <- Walk_bike_summs_2017_2019 %>%
      mutate(race_eth_broad= str_extract(race_eth_broad,  "^[^ ]+"))%>%
      filter(race_eth_broad!='No')
    
    Walk_bike_summs_2021 <- Walk_bike_summs_2021 %>%
      mutate(race_eth_broad= str_extract(race_eth_broad,  "^[^ ]+"))%>%
      filter(race_eth_broad!='No')
    Walk_bike_summs_2017_2019$race_eth_broad<-factor(Walk_bike_summs_2017_2019$race_eth_broad, levels=
                                                       c('White', 'Other', 'Hispanic', 'Black', 'Asian'))
    
    Walk_bike_summs_2021$race_eth_broad<-factor(Walk_bike_summs_2021$race_eth_broad, levels=
                                                  c('White', 'Other', 'Hispanic', 'Black', 'Asian'))
    
    
    
  }
  
  if(cat_name=='hhincome_100_f'){
    
    Walk_bike_summs_2017_2019$hhincome_100_f=factor( Walk_bike_summs_2017_2019$hhincome_100_f, levels=c("Prefer not to answer",  "$100,000 or more","$75,000-$99,999", "$50,000-$74,999" ,"$25,000-$49,999" , "Under $25,000"  ))
    
    Walk_bike_summs_2021$hhincome_100_f=factor(Walk_bike_summs_2021$hhincome_100_f, levels=c("Prefer not to answer",  "$100,000 or more","$75,000-$99,999", "$50,000-$74,999" ,"$25,000-$49,999" , "Under $25,000"  ))
    
    
  }
  
  walk_bike_summs_long<- rbind(Walk_bike_summs_2017_2019, Walk_bike_summs_2021) %>%
    mutate(survey = str_replace_all(survey, "_", "/"))
  
  write.csv(walk_bike_summs_long,paste0(output_path,names(g),'walk_mode_share.csv' ))
  
 
  
}



