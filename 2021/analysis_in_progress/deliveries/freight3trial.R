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
library(summarytools)
library(sp)
library(gridExtra)
library(ggpubr)

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
names(trip_errands)
freq(trip_errands$dest_purpose)
hhts_varsearch("dest_purpose_cat")
hhts_varsearch("dest_purpose_other")#none for 2021, also no dest_purpose_simple
hhts_varsearch("d_purp_cat") #none for 2021

vars_trips <- c("dest_purpose", "dest_purpose_cat", "dest_purpose_simple")
income <- c("hhincome_broad", "employment")

# getting variables from tables/datasets for 2017/2019 with destination purpose (by column name, not sorting by variable yet)
# -- How frequently is someone taking a grocery trip??
trip_1719_new <- get_hhts(survey = survey_a$survey, level = "t", vars = vars_trips)%>% 
  drop_na(dest_purpose)%>%
  mutate(dest_purpose = factor(case_when(dest_purpose == "Went to work-related place (e.g., meeting, second job, delivery)"|
                                           dest_purpose == "Went to primary workplace" |
                                           dest_purpose == "Went to other work-related activity" |
                                           dest_purpose == "Went to school/daycare (e.g., daycare, K-12, college)" ~
                                           "Work or School",
                                         dest_purpose == 'Went grocery shopping' ~ "Grocery",
                                         dest_purpose == 'Went to restaurant to eat/get take-out' ~ 'Restaurant/Takeout',
                                         TRUE ~ 'Other')))

# hhts grouping and count for 2017/2019
rs_trips_1719 <- hhts_count(trip_1719_new, group_vars = "dest_purpose",
                                  spec_wgt='trip_weight_2017_2019_v2021')%>% filter(dest_purpose!='Total')

# getting variables from tables/datasets for 2021
# -- How frequently is someone taking a grocery trip??
trip_21_new <- get_hhts(survey = survey_b$survey, level = "t", vars = vars_trips)%>% 
  drop_na(dest_purpose)%>%
  mutate(dest_purpose = factor(case_when(dest_purpose == "Went to work-related place (e.g., meeting, second job, delivery)"|
                                           dest_purpose == "Went to primary workplace" |
                                           dest_purpose == "Went to other work-related activity" |
                                           dest_purpose == "Went to school/daycare (e.g., daycare, K-12, college)" ~
                                           "Work or School",
                                         dest_purpose == 'Went grocery shopping' ~ "Grocery",
                                         dest_purpose == 'Went to restaurant to eat/get take-out' ~ 'Restaurant/Takeout',
                                         TRUE ~ 'Other')))

# hhts grouping and count for 2021
rs_trips_21 <- hhts_count(trip_21_new, group_vars = "dest_purpose",
                            spec_wgt='trip_weight_2021_ABS_Panel_adult')%>% filter(dest_purpose!='Total')

# 1. merge data frames for combined 2017/2019 and 2021
trip_freq <- merge(rs_trips_1719, rs_trips_21, by = 'dest_purpose', suffixes =c('17/19. 21'))
trip_freq_17_19_21 <- rbind(rs_trips_1719, rs_trips_21)
rename(trip_freq_17_19_21, year = survey)
rename(trip_freq_17_19_21, "trip purpose" = dest_purpose)

# 1a. merge dfs for 2017/2019 and 2021 (MARY CODE)
all_trip_17_21 <- bind_rows(rs_trips_1719, rs_trips_21) %>%
  mutate(period = as.factor(survey))

table(all_trip_17_21$dest_purpose, all_trip_17_21$period)

# 2. write csv and plot - suzanne code
write.csv(trip_freq_17_19_21, 'trips_by_freq_food.csv')

food<-create_column_chart(t=trip_freq_17_19_21, w.x='dest_purpose', w.y='share', f='survey', 
                       w.moe='share_moe', 
                       est.type='percent', w.color = 'psrc_pairs')+
  xlab(as.character('Type of Trip')) + ylab('Share of Trips')+
  theme(axis.text.x = element_text(size=10,color="#4C4C4C"))+ 
  theme(axis.title.x = element_text(size=20,color="#4C4C4C"))+
  theme(axis.title.y = element_text(size=20,color="#4C4C4C"))

print(food)

food_count<-create_column_chart(t=trip_freq_17_19_21, w.x='dest_purpose', w.y='count', f='survey', 
                          w.moe='count_moe', 
                          est.type='number', w.color = 'psrc_pairs')+
  xlab(as.character('Type of Trip')) + ylab('Count of Trips')+
  theme(axis.text.x = element_text(size=10,color="#4C4C4C"))+ 
  theme(axis.title.x = element_text(size=20,color="#4C4C4C"))+
  theme(axis.title.y = element_text(size=20,color="#4C4C4C"))

print(food_count)

# 2a. MARYS code for plotting share and count

count_prep_fx <- function(data, grp1) {
  
  hhts_count(data,
             group_vars = c(grp1)) %>%
    mutate(period = data$label) 
}

count_and_share_plot <- function(dt, num_var, legend_name, tbl_name){
  
  x_axis_grp <- dt[[num_var]]
  
  count_plot <- ggplot(dt,
                       aes(x=x_axis_grp,
                           y=count,
                           fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Number",
         fill = "count") +
    scale_y_continuous(labels = scales::comma) +
    geom_errorbar(aes(ymin=count-count_moe, ymax=count+count_moe),
                  size=.5,width=.2,
                  position=position_dodge(.9))
  
  
  share_plot <- ggplot(dt,
                       aes(x=x_,
                           y=share,
                           fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Share",
         fill = "share") +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                  size=.5, width=.2,
                  position=position_dodge(0.9))
  
  trips <- ggarrange(count_plot, share_plot, 
                     # ncol = 2, nrow = 1,
                     common.legend = TRUE,
                     legend = "right")
  annotate_figure(autos, top = text_grob(tbl_name, 
                                         color = "blue", face = "bold", size = 14))
}

count_and_share_plot(all_trip_17_21,
                     "dest_purpose",
                     "Destination",
                     "Number of Trips by Type")
