# simple functions first - what do I want to see?
# how many days did people receive deliveries?
# gethhts and hhtscount functions 
# did the number of deliveries change by year? by race? by income?

# r start

library(tidyverse)
library(data.table)
library(leaflet)
library(shiny)
library(tidytext)
library(dplyr)
library(ggplot2)
library(ggiraph)
library(magrittr)

# additional packages
library(usethis)
library(devtools)
library(installr)
library(sf)
library(forcats)
library(tidyr)

# packages that are from github that host functions for pulling data
devtools::install_github("psrc/psrc.travelsurvey", force = TRUE)
devtools::install_github("psrc/psrccensus", force = TRUE)
devtools::install_github("psrc/psrcplot", force = TRUE)
devtools::install_github("psrc/psrctrends", force = TRUE)
library(psrc.travelsurvey)
library(psrccensus)
library(psrcplot)
library(psrctrends)

# for Elmer connection
library(odbc)
library(DBI)

# of this option for the new driver that makes certain *new* functions available
# however, have to still connect to R console after bringing in the connection

elmer_connect <- function(){
  DBI::dbConnect(odbc::odbc(),
                 driver = "ODBC Driver 17 for SQL Server",
                 server = "AWS-PROD-SQL\\Sockeye",
                 database = "Elmer",
                 trusted_connection = "yes",
                 port = 1433)
}

elmer_connection <- elmer_connect()

# views and global variables for errands/VMT for food trips

trip_errands <- dbReadTable(elmer_connection, SQL("HHSurvey.v_trips")) #trips includes 2017. 2019, and 2021

survey_a <- list(survey = '2017_2019', label = '2017/2019')
survey_b <- list(survey = '2021', label = '2021')
survey_c <- list(survey = '2017', label = '2017')
survey_d <- list(survey = '2019', label = '2019')

# find names of variables that are in 2017/2019 and 2021 datasets 

str(errands1719)
hhts_varsearch("origin_purpose")
hhts_varsearch("o_purp_cat") #none for 2021, but do have origin_purpose_cat
hhts_varsearch("dest_purp")
hhts_varsearch("dest_purpose_cat")
hhts_varsearch("dest_purpose_other")#none for 2021, also no dest_purpose_simple
hhts_varsearch("d_purp_cat") #none for 2021

vars_trips <- c("dest_purpose", "dest_purpose_cat", "dest_purpose_simple")

# getting variables from tables/datasets for 2017/2019 with destination purpose (by column name, not sorting by variable yet)
# -- How frequently is someone taking a grocery trip??
trip_1719 <- get_hhts(survey = survey_a$survey, level = "t", vars = vars_trips)%>% 
  mutate(grocery_trip=ifelse(dest_purpose=='Went grocery shopping', 'Grocery', 'Not Grocery'))%>%
  drop_na("grocery_trip")

# hhts grouping and count for 2017/2019
rs_errands_food1719 <- hhts_count(trip_1719, group_vars = "grocery_trip",
                              spec_wgt='trip_weight_2017_2019_v2021')%>%
  filter(grocery_trip!='Total')

# getting variables from tables/datasets for 2021
# -- How frequently is someone taking a grocery trip??
trip_21 <- get_hhts(survey = survey_b$survey, level="t", vars = vars_trips)%>% 
  mutate(grocery_trip=ifelse(dest_purpose=='Went grocery shopping', 'Grocery', 'Not Grocery'))%>%
  drop_na("grocery_trip")

# hhts grouping and count for 2021
rs_errands_food21 <- hhts_count(trip_21, group_vars = "grocery_trip",
                              spec_wgt='trip_weight_2021_ABS_Panel_adult')%>%
  filter(grocery_trip!='Total')

# merge data frames for combined 2017/2019 and 2021
trip_freq <- merge(rs_errands_food1719, rs_errands_food21, by = 'grocery_trip', suffixes =c('17_19. 21'))
trip_freq_17_19_21 <- rbind(rs_errands_food1719, rs_errands_food21)

# write csv and plot - suzanne code
write.csv(trip_freq_17_19_21, 'trips_by_freq_food.csv')

food<-create_bar_chart(t=trip_freq_17_19_21, w.x='grocery_trip', w.y='share', f='survey', 
                       w.moe='share_moe', 
                    est.type='percent', w.color = 'psrc_pairs')+
  xlab(as.character('Type of Trip')) + ylab('Share of Trips')+
  theme(axis.text.x = element_text(size=14,color="#4C4C4C"))+ 
  theme(axis.title.x = element_text(size=20,color="#4C4C4C"))+
  theme(axis.title.y = element_text(size=20,color="#4C4C4C"))

print(food)

# test dataset - mary 
ggplot(trip_freq_17_19_21, aes(x=grocery_trip,
                               y=share)) +
  geom_bar(stat="identity",
           position="dodge2") +
  theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
        axis.title.x = element_blank()) +
  labs(y = "Share",
       fill = "Survey") +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1), n.breaks = (10))+
  geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                size=.5, width=.2,
                position=position_dodge(0.9))

?geom_errorbar

# views and global variables for errands/VMT for food delivery and packages

delivery <- dbReadTable(elmer_connection, SQL("HHSurvey.v_days"))

hhts_varsearch("delivery")
hhts_varsearch("notravel_delivery")

vars_groc_delivery <- c("dayofweek", "delivery_grocery_freq")

# getting variables from tables/datasets for 2017/2019 with destination purpose (by column name, not sorting by variable yet)
# -- How frequently were grocery packages delivered?? How did that change between 2017, 2019 and 2021?

groc_delivery_1719 <- get_hhts(survey = survey_a$survey, level = "d", vars = "vars_groc_delivery")

# hhts grouping and count for 2017/2019
rs_groc_1719 <- hhts_count(groc_delivery_1719, group_vars = "delivery_grocery_freq",
                           spec_wgt='person_weight_2021_ABS_panel_respondent')








groc_delivery_17 <- get_hhts(survey = survey_c$survey, level="d", vars = "vars_groc_delivery") %>%
  spec_wgt = "day_weight_2017_v2021"

groc_delivery_19 <- get_hhts(survey = survey_d$survey, level="d", vars = "vars_groc_delivery")

deliver_survey_1719 <- get_hhts(survey = survey_a$survey,
                                level = "d",
                                vars = all_vars_food_delivery)

deliver_survey_21 <- get_hhts(survey = survey_b$survey,
                              level="d",
                              vars= all_vars_food_delivery)

deliver_survey_17 <- get_hhts(survey = survey_c$survey,
                              level="d",
                              vars= all_vars_food_delivery)

deliver_survey_19 <- get_hhts(survey = survey_d$survey,
                              level="d",
                              vars= all_vars_food_delivery)




# getting variables from tables/datasets for 2021
# -- How frequently is someone taking a grocery trip??
trip_21 <- get_hhts(survey = survey_b$survey, level="t", vars = vars_trips)%>% 
  mutate(grocery_trip=ifelse(dest_purpose=='Went grocery shopping', 'Grocery', 'Not Grocery'))%>%
  drop_na("grocery_trip")

# hhts grouping and count for 2021
rs_errands_food21 <- hhts_count(trip_21, group_vars = "grocery_trip",
                                spec_wgt='trip_weight_2021_ABS_Panel_adult')%>%
  filter(grocery_trip!='Total')

# merge data frames for combined 2017/2019 and 2021
trip_freq <- merge(rs_errands_food1719, rs_errands_food21, by = 'grocery_trip', suffixes =c('17_19. 21'))
trip_freq_17_19_21 <- rbind(rs_errands_food1719, rs_errands_food21)
rename(trip_freq_17_19_21, year = survey)
rename(trip_freq_17_19_21, "trip purpose" = dest_purpose)

# write csv and plot - suzanne code
write.csv(trip_freq_17_19_21, 'trips_by_freq_food.csv')

food<-create_bar_chart(t=trip_freq_17_19_21, w.x='grocery_trip', w.y='share', f='survey', w.moe='share_moe', 
                       est.type='percent', w.color = 'psrc_light')+
  xlab(as.character('Type of Trip')) + ylab('Share of Trips')+
  theme(axis.text.x = element_text(size=14,color="#4C4C4C"))+ 
  theme(axis.title.x = element_text(size=20,color="#4C4C4C"))+
  theme(axis.title.y = element_text(size=20,color="#4C4C4C"))

print(food)

