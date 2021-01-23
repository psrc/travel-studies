source('travel_survey_analysis_functions.R')
library(tidyverse)
library(openxlsx)
library(odbc)
library(DBI)
library(dplyr)
library(ggplot2)

#### Read in Data ####
#where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel_studies/2019/analysis"

#where you want to output tables
file_loc <- 'C:/Users/SChildress/Documents/HHSurvey/commuting'

sql.trip.query <- paste("SELECT hhincome_detailed, race_category, person_dim_id, mode_simple, 
                        survey_year, o_purpose, d_purpose, trip_wt_2019 FROM HHSurvey.v_trips_2017_2019")
trips <- read.dt(sql.trip.query, 'sqlquery')

trips_2019 <- trips %>% filter(survey_year==2019)

sql.person.query<-paste("SELECT employment, hhincome_detailed,race_category,person_dim_id, vehicle_count,commute_auto_time,
commute_auto_Distance, mode_freq_1,  mode_freq_2,  mode_freq_3, mode_freq_4, mode_freq_5, workplace, survey_year, sample_county,
work_county,telecommute_freq, hh_wt_2019 FROM HHSurvey.v_persons_2017_2019")

persons<-read.dt(sql.person.query, 'sqlquery')
persons_2019 <- persons  %>% filter(survey_year==2019)



### # filter to commute trips made by people who work outside the home usually ####
# What is the share of trips made for "commuting"? 
# I define commuting as the trips where one or other trip end is to
# the regular workplace


trips_total <- sum(trips_2019$trip_wt_2019)
#17,813,956
trips_commute <- trips_2019 %>% filter(o_purpose=='Went to primary workplace' | d_purpose=='Went to primary workplace') %>% 
                           summarize(commute_trips=sum(trip_wt_2019))
trips_commute/trips_total
#24%

workers <- persons_2019 %>% filter(employment=='Employed full time (35+ hours/week, paid)'|
                                     employment=='Employed part time (fewer than 35 hours/week, paid)'|
                                     employment=='Self-employed')

work_loc_type <- workers %>% group_by(workplace)%>%summarize(tot_workers=sum(hh_wt_2019))%>%
  mutate(share_workers=tot_workers/sum(workers$hh_wt_2019))
# get workers who don't work at home all the time with commute distances less than 200 miles
# remove outliers
not_home_workers <- workers %>% filter(workplace!='At home (telecommute or self-employed with home office)') %>%
  filter(commute_auto_Distance<200)
not_home_workers


# how does the distance or time from home to your primary workplace vary by income and race
# using the field commute_auto_distance, commute_auto_time from the survey
# filter to workers

#### Distance to Work ####

mean_dist<-weighted.mean(not_home_workers$commute_auto_Distance, w=not_home_workers$hh_wt_2019,na.rm=TRUE)


# summarize the distribuion of distances to work
# note: only 2019 data has the distances on there
hist(not_home_workers$commute_auto_Distance)
ggplot(not_home_workers, aes(x=commute_auto_Distance, weight=hh_wt_2019)) + geom_histogram(fill='darkblue', binwidth=2)+xlim(c(0, 50))+
  geom_vline(xintercept=mean_dist)+
  labs(title="Distribution of 2019 Commute Distances (from the HTS))",
      x ="Commute Distance (miles)", y = "Number of Workers (Weighted)")

avg_dist_by_inc<-not_home_workers %>% group_by(hhincome_detailed)%>% 
  summarize(avg_dist=weighted.mean(commute_auto_Distance,hh_wt_2019))

avg_dist_by_race<-not_home_workers %>% group_by(race_category)%>% 
  summarize(avg_time=weighted.mean(commute_auto_Distance,hh_wt_2019))


#### Travel Time to Work ####
mean_time<-weighted.mean(not_home_workers$commute_auto_time, w=not_home_workers$hh_wt_2019,na.rm=TRUE)

ggplot(not_home_workers, aes(x=commute_auto_time, weight=hh_wt_2019)) + geom_histogram(fill='darkblue', binwidth=5)+xlim(c(0, 200))+
  scale_x_continuous(breaks=seq(0,200,5))+
  geom_vline(xintercept=mean_time)+
  labs(title="Distribution of 2019 Commute Times (from the HTS))",
       x ="Commute Times(minutes))", y = "Number of Workers (Weighted)")

avg_time_by_inc<-not_home_workers %>% group_by(hhincome_detailed)%>% 
  summarize(avg_dist=weighted.mean(commute_auto_time,hh_wt_2019))

avg_time_by_race<-not_home_workers %>% group_by(race_category)%>% 
  summarize(avg_time=weighted.mean(commute_auto_time,hh_wt_2019))
  




