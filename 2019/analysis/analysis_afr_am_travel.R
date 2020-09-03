source('travel_survey_analysis_functions.R')
library(tidyverse)
library(openxlsx)
library(odbc)
library(DBI)
library(dplyr)



#where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel_studies/2019/analysis"

#where you want to output tables
file_loc <- 'C:/Users/SChildress/Documents/HHSurvey/race_story/afr_am'

sql.trip.query <- paste("SELECT race_category, person_dim_id, mode_simple, trip_wt_combined FROM HHSurvey.v_trips_2017_2019")
trips <- read.dt(sql.trip.query, 'sqlquery')

sql.person.query<-paste("SELECT race_category,person_dim_id, vehicle_count,commute_auto_time,
commute_auto_Distance, mode_freq_1,  mode_freq_2,  mode_freq_3, mode_freq_4, mode_freq_5,
wbt_transitmore_1, wbt_transitmore_2, wbt_transitmore_3, wbt_bikemore_1, wbt_bikemore_2, wbt_bikemore_3,
hh_wt_combined FROM HHSurvey.v_persons_2017_2019")


persons<-read.dt(sql.person.query, 'sqlquery')

# First explore a new category for race.

persons %>% group_by(race_category) %>% count()
persons$afr_am_race_category<-persons$race_category

# Defining an African-American group

persons<-persons %>%
  mutate(afr_am_race_category=ifelse(afr_am_race_category %in% c('Asian', 'Hispanic'), 
                                     'Asian or Hispanic', afr_am_race_category))

persons<-persons %>%
  mutate(afr_am_race_category=ifelse(afr_am_race_category %in% c('Child','Missing', 'Other', 'Child, Missing, Other'), 
                                     'Child, Missing, Other', afr_am_race_category))


persons %>% group_by(afr_am_race_category) %>% count()

# Find the count of people in each category
person_wt_field<- 'hh_wt_combined'
person_count_field<-'person_dim_id'
group_cat <- 'afr_am_race_category'

persons_no_na<-persons %>% drop_na(all_of(person_wt_field))


sample_size_group<- persons_no_na %>%
                    group_by(afr_am_race_category) %>%
                    summarize(sample_size = n_distinct((person_dim_id)))
  


# Auto Ownership ####################################################

var2<-'vehicle_count'
auto_own_cross <- cross_tab_categorical(persons_no_na,group_cat, var2, person_wt_field)
auto_own_MOE <- categorical_moe(sample_size_group)
auto_own<-merge(auto_own_cross, auto_own_MOE, by=group_cat)
write_cross_tab(auto_own, group_cat, var2, file_loc)

