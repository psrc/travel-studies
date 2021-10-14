source('travel_survey_analysis_functions.R')
library(tidyverse)
library(openxlsx)
library(odbc)
library(DBI)
library(dplyr)



#where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel_studies/2019/analysis"

#where you want to output tables
file_loc <- 'C:/Users/SChildress/Documents/HHSurvey/travel_studies/2019/analysis'

sql.trip.query <- paste("SELECT race_category, seattle_home,person_dim_id, o_purp_cat,d_purp_cat,mode_simple, trip_path_distance, google_duration, hhincome_broad, hhincome_detailed, trip_wt_combined FROM HHSurvey.v_trips_2017_2019")
trips <- read.dt(sql.trip.query, 'sqlquery')

trips <- trips %>% mutate(person_of_color=case_when(race_category=='White Only' ~ "White Alone",
                                                    race_category=='African American' ~ "Person of Color",
                                                    race_category=='Asian' ~ "Person of Color",
                                                    race_category=='Hispanic' ~ "Person of Color",
                                                    race_category=='Missing' ~ "Child/Missing",
                                                    race_category=='Other' ~ "Person of Color",
                                                    race_category=='Child' ~ "Child/Missing"
                                                    ))


non_work_trips<- trips %>% filter(o_purp_cat != 'Work' & d_purp_cat != 'Work')%>%
  filter(trip_path_distance<200)%>%filter(google_duration<120)


avg_non_work_time_mode<-non_work_trips %>% group_by(mode_simple)%>% 
  summarise(avg_trip_length=weighted.mean(trip_path_distance, trip_wt_combined, na.rm=TRUE),
            avg_trip_time = weighted.mean(google_duration, trip_wt_combined, na.rm=TRUE))

avg_non_work_time_income<-non_work_trips %>% group_by(hhincome_broad)%>% 
  summarise(avg_trip_length=weighted.mean(trip_path_distance, trip_wt_combined, na.rm=TRUE),
            avg_trip_time = weighted.mean(google_duration, trip_wt_combined, na.rm=TRUE))

avg_non_work_time_race<-non_work_trips %>% group_by(person_of_color)%>% 
  summarise(avg_trip_length=weighted.mean(trip_path_distance, trip_wt_combined, na.rm=TRUE),
            avg_trip_time = weighted.mean(google_duration, trip_wt_combined, na.rm=TRUE))


avg_non_work_time_seattle<-non_work_trips %>% group_by(seattle_home)%>% 
  summarise(avg_trip_length=weighted.mean(trip_path_distance, trip_wt_combined, na.rm=TRUE),
            avg_trip_time = weighted.mean(google_duration, trip_wt_combined, na.rm=TRUE))

write.table(avg_non_work_time_income, "clipboard", sep="\t")
write.table(avg_non_work_time_mode, "clipboard", sep='\t')
write.table(avg_non_work_time_race, "clipboard", sep='\t')
write.table(avg_non_work_time_seattle, "clipboard", sep='\t')

avg_non_work_time_mode<-non_work_trips %>% group_by(mode_simple)%>% 
  summarise(avg_trip_length=weighted.mean(trip_path_distance, trip_wt_combined, na.rm=TRUE),
            avg_trip_time = weighted.mean(google_duration, trip_wt_combined, na.rm=TRUE))

non_work_income_mode<-cross_tab_categorical(non_work_trips, 'hhincome_broad', 'mode_simple', 'trip_wt_combined')
write.table(non_work_income_mode, "clipboard", sep="\t")


non_work_income_seattle<-cross_tab_categorical(non_work_trips, 'hhincome_broad', 'seattle_home', 'trip_wt_combined')
write.table(non_work_income_seattle, "clipboard", sep="\t")


non_work_race_mode<-cross_tab_categorical(non_work_trips, 'person_of_color', 'mode_simple', 'trip_wt_combined')
write.table(non_work_race_mode, "clipboard", sep="\t")

non_work_race_seattle<-cross_tab_categorical(non_work_trips, 'person_of_color', 'seattle_home', 'trip_wt_combined')
write.table(non_work_income_seattle, "clipboard", sep="\t")
