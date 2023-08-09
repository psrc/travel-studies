
# how many days did people receive deliveries?
# did the number of deliveries change by year? by race? by income?

# .libPaths()
# .libloc <- "C:/Users/MGrzybowski/AppData/Local/R/win-library/4.2"
# remove.packages("rlang")
# install.packages("rlang")

# r start

library(tidyverse)
library(data.table)
library(leaflet)
library(shiny)
library(tidytext)
library(dplyr)
library(readr)
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

# packages that are from github that host functions for pulling data (do the install in R, not RStudio)

devtools::install_github("psrc/psrc.travelsurvey", force = TRUE)
devtools::install_github("psrc/psrccensus", force = TRUE)
devtools::install_github("psrc/psrcplot", force = TRUE)
devtools::install_github("psrc/psrctrends", force = TRUE)

# run these in R Studio

library(psrc.travelsurvey)
library(psrccensus)
library(psrcplot)
library(psrctrends)

install_psrc_fonts()

# for Elmer connection

library(odbc)
library(DBI)

elmer_connect <- function(){
  DBI::dbConnect(odbc::odbc(),
                 driver = "ODBC Driver 17 for SQL Server",
                 server = "AWS-PROD-SQL\\Sockeye",
                 database = "Elmer",
                 trusted_connection = "yes",
                 port = 1433)
}

elmer_connection <- elmer_connect()

# views and global variables for deliveries

deliveries <- dbReadTable(elmer_connection, SQL("HHSurvey.v_days"))
household_info <- dbReadTable(elmer_connection, SQL("HHSurvey.v_households"))

survey_a <- list(survey = '2017_2019', label = '2017/2019')
survey_b <- list(survey = '2021', label = '2021')
survey_c <- list(survey = '2017', label = '2017')
survey_d <- list(survey = '2019', label = '2019')

# create variables that would like to group

hhts_varsearch("delivery")
hhts_varsearch("traveldate")
hhts_varsearch("race")
hhts_varsearch('income')
hhts_varsearch('age')
hhts_varsearch('county')
hhts_varsearch('home')
hhts_varsearch('race')

str(delivery_type)

names(deliveries)
head(household_info)

unique(household_info$lifecycle)
unique(deliveries$delivery_work_freq)

delivery_type <- c("household_id", "delivery_food_freq", "delivery_grocery_freq", "delivery_pkgs_freq","delivery_work_freq",
                   "deliver_package", 'deliver_work', 'deliver_grocery', 'deliver_food')
days <- c("dayofweek", "typical_day")
race <- c("race_eth_simple")
hh_data <- c("household_id", 'hhincome_broad', 'lifecycle', 'hh_race_apoc', 'hh_race_poc', 'final_cnty', "final_home_rgcnum")

# getting variables from tables for 2017, 2019, 2017/2019, 2021

# creating data functions 

smp_delivery_fx <- function(data, year) {
  ## rewriting labels of responses to be more concise
  temp_table <- data %>%
    mutate(delivery_food_all= case_when((is.na(delivery_food_freq) & is.na(deliver_food)) ~ 'No Response',
                                        delivery_food_freq == "0 (none)"  ~ 'No Delivery',
                                        deliver_food=='No' ~ 'No Delivery',
                                        TRUE ~ 'Delivery Received'))%>%
    mutate(delivery_pkgs_all= case_when((is.na(delivery_pkgs_freq) & is.na(deliver_package)) ~ 'No Response',
                                        delivery_pkgs_freq == "0 (none)"  ~ 'No Delivery',
                                        deliver_package=='No' ~ 'No Delivery',
                                        TRUE ~ 'Delivery Received'))%>%
    mutate(delivery_grocery_all= case_when((is.na(delivery_grocery_freq) & is.na(deliver_grocery)) ~ 'No Response',
                                           delivery_grocery_freq == "0 (none)"  ~ 'No Delivery',
                                           deliver_grocery=='No' ~ 'No Delivery',
                                           TRUE ~ 'Delivery Received'))
  
  
  
  temp_table 
}

smp_delivery_fx_hh <- function(data, year) {
  ## rewriting labels of responses to be more concise
  temp_table <- data %>%
    mutate(hhincome_broad= case_when(hhincome_broad=='$100,000-$199,000' ~ '$100,000 or more',
                                     hhincome_broad=='$200,000 or more' ~ '$100,000 or more',
                                     TRUE~hhincome_broad))%>%
    mutate(lifecycle= case_when(lifecycle == "Household size > 1, Householder age 65+" | 
                                  lifecycle == "Household size = 1, Householder age 65+"  ~ '65 years or older', 
                                lifecycle == "Household size > 1, Householder age 35 - 64" |
                                  lifecycle == "Household size = 1, Householder age 35 - 64" ~ '35-64 years',
                                lifecycle == "Household size > 1, Householder under age 35" |
                                  lifecycle == "Household size = 1, Householder under age 35" ~ 'Under 35 years, no kids',
                                lifecycle == "Household includes children age 5-17" ~ 'Household has ages 5-17',
                                lifecycle == "Household includes children under 5" ~ 'Household has ages under 5'))
  temp_table
}

# -- How frequently is someone having a delivery made?? 
# -- 2017, 2019, 2017/2019, 2021

# pull datasets from two separate dataframes per year

dsurvey_17 <- get_hhts(survey = survey_c$survey, 
                        level = "d", 
                        vars = c(delivery_type, days)) 

dsurvey_19 <- get_hhts(survey = survey_d$survey, 
                       level = "d", 
                       vars = c(delivery_type, days)) 

dsurvey_1719 <- get_hhts(survey = survey_a$survey, 
                       level = "d", 
                       vars = c(delivery_type, days)) 

dsurvey_21 <- get_hhts(survey = survey_b$survey, 
                       level = "d", 
                       vars = c(delivery_type, days)) 

# transform data

delivery_17 <- smp_delivery_fx(dsurvey_17, '2017')

delivery_19 <- smp_delivery_fx(dsurvey_19, '2019')

delivery_1719 <- smp_delivery_fx(dsurvey_1719, '2017/2019')

delivery_21 <- smp_delivery_fx(dsurvey_21, '2021')

# merge the two datasets
# using dplyr and readr to join based on common variable name

joined_df_deliveries_17 <- left_join(delivery_17, delivery_17b, by = c("household_id", "survey")) 

joined_df_deliveries_19 <- left_join(delivery_19, delivery_19b, by = c("household_id", "survey"))

joined_df_deliveries_1719 <- left_join(delivery_1719, delivery_1719b, by = c("household_id", "survey"))

joined_df_deliveries_21 <- left_join(delivery_21, delivery_21b, by = c("household_id", "survey"))

# another way to merge, but not the one I chose
# merged_df_deliveries <- merge(deliveries, household_info, by.x = "household_id", by.y = "household_id", all.x = TRUE,
#                            all.y = TRUE)

# hhts count

count_food_17 <- hhts_count(joined_df_deliveries_17, group_vars = "delivery_food_freq",
                                     spec_wgt = "day_weight_2017_v2021")%>%
  filter(delivery_food_freq != "Total")

# have tried the double variable // crosstab with day weight and not recognized, so automatically applies household weight

count_food_19 <- hhts_count(joined_df_deliveries_19, group_vars = "delivery_food_freq",
                               spec_wgt = "day_weight_2019_v2021")

count_food_1719 <- hhts_count(joined_df_deliveries_1719, group_vars = "delivery_food_freq",
                                 spec_wgt = "day_weight_2017_2019_v2021") 

count_food_21 <- hhts_count(joined_df_deliveries_21, group_vars = "delivery_food_freq",
                               spec_wgt = "person_weight_2021_ABS_panel_adult") 

# filter(delivery_food_freq != 'Total')%>%
# filter(delivery_food_freq != 'NA')

#  filter(delivery_grocery_freq != 'Total')%>%
#  filter(delivery_pkgs_freq != 'Total')%>%
#  filter(delivery_work_freq != 'Total')

# suzanne grouping for plots

# merge data frames for combined 2017/2019 and 2021
# write csv and plot
food_freq_17_19_21 <- rbind(count_food_17, count_food_19, count_food_1719, count_food_21)

food_freq_separate <- rbind(count_food_17, count_food_19, count_food_21)

write.csv(food_freq_17_19_21, 'delivery_by_freq_food.csv')

write.csv(food_freq_separate, 'delivery_by_freq_food2.csv')

food<-create_column_chart(t=food_freq_17_19_21, w.x='delivery_food_freq', w.y='share', f='survey', w.moe='share_moe', 
                          est.type='percent', w.color = 'psrc_light')+
  xlab(as.character('Number of Food Deliveries Per Day')) + ylab('Share of Households Receiving These Types of Deliveries')+
  theme(axis.text.x = element_text(size=14,color="#4C4C4C"))+ 
  theme(axis.title.x = element_text(size=20,color="#4C4C4C"))+
  theme(axis.title.y = element_text(size=8,color="#4C4C4C"))

food_b<-create_column_chart(t=food_freq_17_19_21, w.x='delivery_food_freq', w.y='count', f='survey', w.moe='count_moe', 
                          est.type='number', w.color = 'psrc_light')+
  xlab(as.character('Number of Food Deliveries Per Day')) + ylab('Count of Households')+
  theme(axis.text.x = element_text(size=14,color="#4C4C4C"))+ 
  theme(axis.title.x = element_text(size=20,color="#4C4C4C"))+
  theme(axis.title.y = element_text(size=14,color="#4C4C4C"))

food_c<-create_column_chart(t=food_freq_separate, w.x='delivery_food_freq', w.y='share', f='survey', w.moe='share_moe', 
                          est.type='percent', w.color = 'psrc_light')+
  xlab(as.character('Number of Food Deliveries Per Day')) + ylab('Share of Households Receiving These Types of Deliveries')+
  theme(axis.text.x = element_text(size=14,color="#4C4C4C"))+ 
  theme(axis.title.x = element_text(size=20,color="#4C4C4C"))+
  theme(axis.title.y = element_text(size=8,color="#4C4C4C"))

food_d<-create_column_chart(t=food_freq_separate, w.x='delivery_food_freq', w.y='count', f='survey', w.moe='count_moe', 
                            est.type='number', w.color = 'psrc_light')+
  xlab(as.character('Number of Food Deliveries Per Day')) + ylab('Count of Households')+
  theme(axis.text.x = element_text(size=14,color="#4C4C4C"))+ 
  theme(axis.title.x = element_text(size=20,color="#4C4C4C"))+
  theme(axis.title.y = element_text(size=14,color="#4C4C4C")) 

print(food)
print(food_b)
print(food_c)
print(food_d)

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_food_delivery_17_19_21 <- bind_rows(count_food_17, count_food_1719, count_food_19, count_food_21) %>%
  mutate(period = as.factor(survey))

table(all_food_delivery_17_19_21$delivery_food_freq, all_food_delivery_17_19_21$period)

# plot by year and by category

share_plot_by_year <- function(dt1, dt2, grp_var, grp_var2, legend_name){
  
  fill_group <- all_food_delivery_17_19_21[[grp_var]]
  x_axis_grp <- all_food_delivery_17_19_21[[grp_var2]]
  
  ggplot(all_food_delivery_17_19_21, aes(x=x_axis_grp,
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
  
  fill_group <- all_food_delivery_17_19_21[[grp_var]]
  x_axis_grp <- all_food_delivery_17_19_21[[grp_var2]]
  
  ggplot(all_food_delivery_17_19_21, aes(x=x_axis_grp,
                                       y=share,
                                       fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~delivery_food_freq)+
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
  
  fill_group <- all_food_delivery_17_19_21[[grp_var]]
  # facet_group <- all_commute_17_21[[grp_var2]]
  
  ggplot(all_food_delivery_17_19_21, aes(x=period,
                                       y=share,
                                       fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~all_food_delivery_17_19_21[[grp_var2]])+
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
share_plot_by_year(delivery_food_1719, delivery_food_21, 
                   'survey', 'delivery_food_freq',
                   'Food Deliveries to Households')

share_plot_by_year2(delivery_food_1719, delivery_food_21, 
                    'survey', 'delivery_food_freq', 
                    'Food Deliveries by Year')

share_plot_by_cat(delivery_food_1719, delivery_food_21, 
                  "survey", "delivery_food_freq",
                  'Delivery Categories')
 psrc_style()+
 scale_fill_discrete_psrc("psrc_light")

#### LATER cross tab help from Christy **

test2 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017_v2021', 
                    group_vars = c('delivery_food_freq', 'hhincome_broad')) %>% 
  filter(hhincome_broad != 'Total')
