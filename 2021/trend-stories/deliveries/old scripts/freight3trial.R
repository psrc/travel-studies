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

install_psrc_fonts()

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
str(all_trip_income_17_19_21)
hhts_varsearch("dest_purpose_cat")
hhts_varsearch("dest_purpose_other")#none for 2021, also no dest_purpose_simple
hhts_varsearch("d_purp_cat") #none for 2021

vars_trips <- c("dest_purpose", "dest_purpose_cat", "dest_purpose_simple")
trips_by_income <- c("dest_purpose", "dest_purpose_cat", "dest_purpose_simple","hhincome_broad")

# "employment" is also a variable, but not to be considered currently

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

# 1. merge dfs for 2017/2019 and 2021 (MARY CODE)
all_trip_17_21 <- bind_rows(rs_trips_1719, rs_trips_21) %>%
  mutate(period = as.factor(survey))

table(all_trip_17_21$dest_purpose, all_trip_17_21$period)

# 2. MARYS code for plotting share and count

count_and_share_plot <- function(dt, grp_var, num_var, legend_name, tbl_name){
 
   fill_group <- dt[[grp_var]]
   x_axis_grp <- dt[[num_var]]
  
  count_plot <- ggplot(dt,
                       aes(x=x_axis_grp,
                           y=count,
                           fill = survey)) +
    geom_bar(stat="identity",
             position="dodge2") +
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Number") +
    scale_y_continuous(labels = scales::comma) +
    geom_errorbar(aes(ymin=count-count_moe, ymax=count+count_moe),
                  position = position_dodge2(width = 0.9, preserve = "single", padding = .5))
         
  share_plot <- ggplot(dt,
                       aes(x=x_axis_grp,
                           y=share,
                           fill = survey)) +
    geom_bar(stat="identity",
             position="dodge2") +
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Share") +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                  position = position_dodge2(width = 0.9, preserve = "single", padding = .5))
  
  trips <- ggarrange(count_plot, share_plot, 
                     # ncol = 2, nrow = 1,
                     common.legend = TRUE,
                     legend = "right")
  
  annotate_figure(trips, top = text_grob(tbl_name, 
                                         color = "blue", face = "bold", size = 14))
}

count_and_share_plot(all_trip_17_21,
                     "survey",
                     "dest_purpose",
                     "Destination",
                     "Number vs Share of Trips by Destination")

#just count plot

## END CODE FOR THIS SECTION
## NEW SECTION BASED ON INCOME AND TRIP TYPE

# getting variables from tables/datasets for 2017/2019 with destination purpose (by column name, not sorting by variable yet)
# -- How frequently is someone taking a grocery trip, by income bracket??
trip_income_1719_table <- get_hhts(survey = survey_a$survey, level = "t", vars = trips_by_income)%>% 
  drop_na(dest_purpose)%>%
  mutate(dest_purpose = factor(case_when(dest_purpose == "Went to work-related place (e.g., meeting, second job, delivery)"|
                                           dest_purpose == "Went to primary workplace" |
                                           dest_purpose == "Went to other work-related activity" |
                                           dest_purpose == "Went to school/daycare (e.g., daycare, K-12, college)" ~
                                           "Work or School",
                                         dest_purpose == 'Went grocery shopping' ~ "Grocery",
                                         dest_purpose == 'Went to restaurant to eat/get take-out' ~ 'Restaurant/Takeout',
                                         TRUE ~ 'Other'))) %>%
  mutate(hhincome_broad = factor(case_when(as.character(hhincome_broad) %in% c("$100,000-$199,000","$200,000 or more") ~ 
                                             "$100,000 or more", !is.na(hhincome_broad) ~ as.character(hhincome_broad)),
                                 levels=c("Under $25,000", 
                                          "$25,000-$49,999", 
                                          "$50,000-$74,999", 
                                          "$75,000-$99,999", 
                                          "$100,000 or more", 
                                          "Prefer not to answer")))

# hhts grouping and count for 2017/2019
count_trips_income_1719 <- hhts_count(trip_income_1719_table, group_vars = c("hhincome_broad", "dest_purpose"),
                            spec_wgt='trip_weight_2017_2019_v2021')%>% 
  filter(dest_purpose!='Total') %>%
  filter(hhincome_broad != 'Total') 

# getting variables from tables/datasets for 2021
# -- How frequently is someone taking a grocery trip??
trip_income_21_table <- get_hhts(survey = survey_b$survey, level = "t", vars = trips_by_income)%>% 
  drop_na(dest_purpose)%>%
  mutate(dest_purpose = factor(case_when(dest_purpose == "Went to work-related place (e.g., meeting, second job, delivery)"|
                                           dest_purpose == "Went to primary workplace" |
                                           dest_purpose == "Went to other work-related activity" |
                                           dest_purpose == "Went to school/daycare (e.g., daycare, K-12, college)" ~
                                           "Work or School",
                                         dest_purpose == 'Went grocery shopping' ~ "Grocery",
                                         dest_purpose == 'Went to restaurant to eat/get take-out' ~ 'Restaurant/Takeout',
                                         TRUE ~ 'Other')))%>% 
  mutate(hhincome_broad = factor(case_when(as.character(hhincome_broad) %in% c("$100,000-$199,000","$200,000 or more") ~ 
                                             "$100,000 or more", !is.na(hhincome_broad) ~ as.character(hhincome_broad)),
                                 levels=c("Under $25,000", 
                                          "$25,000-$49,999", 
                                          "$50,000-$74,999", 
                                          "$75,000-$99,999", 
                                          "$100,000 or more", 
                                          "Prefer not to answer")))

# hhts grouping and count for 2021
count_trips_income_21 <- hhts_count(trip_income_21_table, group_vars = c("hhincome_broad", "dest_purpose"),
                          spec_wgt='trip_weight_2021_ABS_Panel_adult')%>% 
  filter(dest_purpose!='Total')%>%
  filter(hhincome_broad != 'Total')

# merge dfs for 2017/2019 and 2021 - pulled from mary's transit_auto code
all_trip_income_17_19_21 <- bind_rows(count_trips_income_1719, count_trips_income_21) %>%
  mutate(period = as.factor(survey)) %>%
  mutate(hhincome_broad = factor(
    case_when(
      as.character(hhincome_broad) %in% c("$100,000-$199,000","$200,000 or more") ~ "$100,000 or more",
      !is.na(hhincome_broad) ~ as.character(hhincome_broad)),
    levels=c("Under $25,000",
             "$25,000-$49,999",
             "$50,000-$74,999",
             "$75,000-$99,999",
             "$100,000 or more",
             "Prefer not to answer")))

table(all_trip_income_17_19_21$dest_purpose, all_trip_income_17_19_21$period)

# plot by year and by category - pulled from mary's transit_auto code

share_plot_by_year <- function(dt1, dt2, grp_var, grp_var2, legend_name){
  
  fill_group <- all_trip_income_17_19_21[[grp_var]]
  x_axis_grp <- all_trip_income_17_19_21[[grp_var2]]
  
  ggplot(all_trip_income_17_19_21, aes(x=x_axis_grp,
                                y=share,
                                fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~period)+
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Share",
         fill = legend_name) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                  size=.5, width=.2,
                  position=position_dodge(0.9))
  
}

share_plot_by_year2 <- function(dt1, dt2, grp_var, grp_var2, legend_name){
  
  fill_group <- all_trip_income_17_19_21[[grp_var]]
  x_axis_grp <- all_trip_income_17_19_21[[grp_var2]]
  
  ggplot(all_trip_income_17_19_21, aes(x=x_axis_grp,
                                       y=share,
                                       fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~dest_purpose)+
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Share",
         fill = legend_name) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                  size=.5, width=.2,
                  position=position_dodge(0.9))
  
}

share_plot_by_cat <- function(dt1, dt2, grp_var, grp_var2, legend_name){
  
  fill_group <- all_trip_income_17_19_21[[grp_var]]
  # facet_group <- all_commute_17_21[[grp_var2]]
  
  ggplot(all_trip_income_17_19_21, aes(x=period,
                                y=share,
                                fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~all_trip_income_17_19_21[[grp_var2]])+
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Share",
         fill = legend_name) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                  size=.5, width=.2,
                  position=position_dodge(0.9))
}

# comparative charts/plots
# (to compare from above) 
# count_and_share_plot <- function(dt, grp_var, num_var, legend_name, tbl_name)
#count_and_share_plot(all_trip_17_21,
#                     "survey",
#                     "dest_purpose",
#                     "Destination",
#                     "Number of Trips by Type")

#share_plot_by_year <- function(dt1, dt2, grp_var, grp_var2, legend_name)
share_plot_by_year(trip_income_1719_table, trip_income_21_table, 
                   'dest_purpose', 'hhincome_broad',
                   'Trip Categories')

share_plot_by_year2(trip_income_1719_table, trip_income_21_table, 
                   'survey', 'hhincome_broad',
                   'Survey Year')

share_plot_by_cat(trip_income_1719_table, trip_income_21_table, 
                  'hhincome_broad', 'dest_purpose',
                  'Income Categories')+
  psrc_style()+
  scale_fill_discrete_psrc("psrc_light")

# z score and statistical significance
t_2017_19c  <- get_hhts("2017_2019", "t", c("mode_simple","trip_path_distance","travel_time"))
rs          <- hhts_median(t_2017_19c, "travel_time", "mode_simple")
z_score(rs[1], rs[3])   # Compares the first-line and third-line estimates for significant difference; 
                        # -- true difference indicated by score > 1

xy17 <- hhts_count(commute_1719, group_vars=c('final_home_is_rgc', 'numwork_veh_grp'))
xy21 <- hhts_count(commute_21, group_vars=c('final_home_is_rgc', 'numwork_veh_grp'))
z_0veh <- z_score(xy17[6], xy21[6]) 

xy1719 <- hhts_count(trip_income_1719_table, group_vars = c('hhincome_broad', 'dest_purpose'))
xy21 <- hhts_count(trip_income_21_table, group_vars = c('hhincome_broad', 'dest_purpose'))
z_1721 <- z_score(xy1719[1], xy21[1]) 

disconnect