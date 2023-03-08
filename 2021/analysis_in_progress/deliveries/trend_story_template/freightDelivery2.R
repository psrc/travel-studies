# This analysis is looking at food, grocery, package, and work/service deliveries from 2017, 2019, 2017/2019, and 2021 by hh.
# Did the share of deliveries change by year? by hhsize? by income? by lifecycle?

library(data.table)
library(leaflet)
library(shiny)
library(tidytext)
library(dplyr)
library(readr)
library(ggplot2)
library(ggiraph)
library(magrittr)
library(usethis)
library(installr)
library(sf)
library(forcats)
library(tidyr)
library(summarytools)
library(sp)
library(gridExtra)
library(ggpubr)

# packages that are from github that host functions for pulling data (do the install in R Gui, not RStudio)

#devtools::install_github("psrc/psrc.travelsurvey", force = TRUE)
#devtools::install_github("psrc/psrccensus", force = TRUE)
#devtools::install_github("psrc/psrcplot", force = TRUE)
#devtools::install_github("psrc/psrctrends", force = TRUE)

# run these after installing github changes through R Gui

library(psrc.travelsurvey)
library(psrccensus)
library(psrcplot)
library(psrctrends)

install_psrc_fonts()
setwd("C:/Coding/CURRENT_REPOS_GITHUB/travel-studies/2021/analysis_in_progress/deliveries/trend_story_template")
#output_path <- "C:/Coding/CURRENT_REPOS_GITHUB/travel-studies/2021/analysis_in_progress/deliveries/trend_visuals"

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

# functions
source("delivery_fxns.R")

# views and global variables for days and households (** the days table has been updated to include hh variables)
# surveys a,b,c, and d will be used in functions later in code

deliveries <- dbReadTable(elmer_connection, SQL("HHSurvey.v_days"))
household_info <- dbReadTable(elmer_connection, SQL("HHSurvey.v_households"))

survey_a <- list(survey = '2017_2019', label = '2017/2019')
survey_b <- list(survey = '2021', label = '2021')
survey_c <- list(survey = '2017', label = '2017')
survey_d <- list(survey = '2019', label = '2019')

# create variables that would like to group by for analysis of deliveries by household

delivery_type <- c("household_id", "delivery_food_freq", "delivery_grocery_freq", "delivery_pkgs_freq","delivery_work_freq", 
                   "deliver_package", 'deliver_work', 'deliver_grocery', 'deliver_food')
days <- c("dayofweek", "typical_day")
hh_data <- c('lifecycle', 'hhincome_broad', 'hhincome_detailed', 'hhincome_dichot', 'race_category_alone_multi', 
             'race_eth_broad', 'race_eth_poc', 'race_eth_apoc', 'hh_race_category', 'seattle_home', 'final_home_rgcnum', 
             'final_home_uvnum', 'final_home_is_rgc','pernum', 'hhsize')

# -- How frequently is someone having a delivery made?? 
# -- 2017, 2019, 2017/2019, 2021

dsurvey_17 <- get_hhts(survey = survey_c$survey, 
                        level = "d", 
                        vars = c(delivery_type, days, hh_data)) 


dsurvey_19 <- get_hhts(survey = survey_d$survey, 
                       level = "d", 
                       vars = c(delivery_type, days, hh_data)) 


dsurvey_1719 <- get_hhts(survey = survey_a$survey, 
                       level = "d", 
                       vars = c(delivery_type, days, hh_data)) 


dsurvey_21 <- get_hhts(survey = survey_b$survey, 
                       level = "d", 
                       vars = c(delivery_type, days, hh_data)) 

# generate datasets

delivery_17 <- smp_delivery_combo(dsurvey_17, '2017')
delivery_19 <- smp_delivery_combo(dsurvey_19, '2019')
delivery_1719 <- smp_delivery_combo(dsurvey_1719, '2017/2019')
delivery_21 <- smp_delivery_combo(dsurvey_21, '2021')

# renamed datasets

joined_df_deliveries_17 <-delivery_17
joined_df_deliveries_19 <- delivery_19
joined_df_deliveries_1719 <- delivery_1719
joined_df_deliveries_21 <- delivery_21

# apply weights 

joined_df_deliveries_1719$day_weight_2017_2019<-joined_df_deliveries_1719$day_weight_2017_2019/2
sum(joined_df_deliveries_1719$day_weight_2017_2019)
dsurvey_17%>%filter(pernum==1)%>%summarize(hh_day=sum(day_weight_2017))
joined_df_deliveries_17%>%filter(pernum==1)%>%summarize(hh_day=sum(day_weight_2017))

# removing duplicate household member responses
joined_df_deliveries_17<<-joined_df_deliveries_17%>%filter(pernum==1)
joined_df_deliveries_19<-joined_df_deliveries_19%>%filter(pernum==1)
joined_df_deliveries_21<-joined_df_deliveries_21%>%filter(pernum==1)

# removing true non-responses
joined_df_deliveries_17<-joined_df_deliveries_17%>%filter(delivery_food_all!='No HH Response')
joined_df_deliveries_19<-joined_df_deliveries_19%>%filter(delivery_food_all!='No HH Response')
joined_df_deliveries_21<-joined_df_deliveries_21%>%filter(delivery_food_all!='No HH Response')

# descriptive stats for hhsize
# ggplot(data = deliveries) + 
  # geom_bar(mapping = aes(x =hhsize))

# food deliveries by year alone

count_food_17 <- hhts_count(joined_df_deliveries_17, group_vars = "delivery_food_all",
                                     spec_wgt = "day_weight_2017")%>%
  filter(delivery_food_all== "Delivery Received")


count_food_19 <- hhts_count(joined_df_deliveries_19, group_vars = "delivery_food_all",
                               spec_wgt = "day_weight_2019")%>%
  filter(delivery_food_all == "Delivery Received")


count_food_21 <- hhts_count(joined_df_deliveries_21, group_vars = "delivery_food_all",
                               spec_wgt = "hh_weight_2021") %>%
  filter(delivery_food_all == "Delivery Received")

# merge food data frames for combined 2017/2019 and 2021 and write csv

food_freq_separate <- rbind(count_food_17, count_food_19, count_food_21)
write.csv(food_freq_separate, 'delivery_by_freq_food2.csv')

# create food by year plot

food_column<- static_column_chart(t= food_freq_separate,
                                     x="delivery_food_all", y="share",
                                     f="survey",
                                     moe = "share_moe",
                                     color="psrc_pairs",
                                     est ="percent",
                                     dec=1)
                                    # title="Food/Meal Deliveries",
                                     #subtitle="(e.g., pizza/sushi, Grubhub)")
                                    # source = "regional household travel survey")

food_column

# package deliveries by year alone

count_pkgs_17 <- hhts_count(joined_df_deliveries_17, group_vars = "delivery_pkgs_all",
                                     spec_wgt = "day_weight_2017")%>%
  filter(delivery_pkgs_all== "Delivery Received")


count_pkgs_19 <- hhts_count(joined_df_deliveries_19, group_vars = "delivery_pkgs_all",
                               spec_wgt = "day_weight_2019")%>%
  filter(delivery_pkgs_all == "Delivery Received")


count_pkgs_21 <- hhts_count(joined_df_deliveries_21, group_vars = "delivery_pkgs_all",
                               spec_wgt = "hh_weight_2021") %>%
  filter(delivery_pkgs_all == "Delivery Received")


# merge package data frames for combined 2017/2019 and 2021 and write csv

pkgs_freq_separate <- rbind(count_pkgs_17, count_pkgs_19, count_pkgs_21)
write.csv(pkgs_freq_separate, 'delivery_by_freq_pkgs2.csv')

# create plot

package_column<- static_column_chart(t= pkgs_freq_separate,
                                     x="delivery_pkgs_all", y="share",
                                     f="survey",
                                     moe = "share_moe",
                                     color="psrc_pairs",
                                     est ="percent",
                                     dec=1)
                                   #  title="Package Deliveries",
                                    # subtitle="(e.g., FedEx, UPS, USPS)")
                                    # source = "regional household travel survey")

package_column

# grocery deliveries by year alone

count_grocery_17 <- hhts_count(joined_df_deliveries_17, group_vars = "delivery_grocery_all",
                                     spec_wgt = "day_weight_2017")%>%
  filter(delivery_grocery_all== "Delivery Received")


count_grocery_19 <- hhts_count(joined_df_deliveries_19, group_vars = "delivery_grocery_all",
                               spec_wgt = "day_weight_2019")%>%
  filter(delivery_grocery_all == "Delivery Received")


count_grocery_21 <- hhts_count(joined_df_deliveries_21, group_vars = "delivery_grocery_all",
                               spec_wgt = "hh_weight_2021") %>%
  filter(delivery_grocery_all == "Delivery Received")


# merge grocery data frames for combined 2017/2019 and 2021 and write csv

grocery_freq_separate <- rbind(count_grocery_17, count_grocery_19, count_grocery_21)
write.csv(grocery_freq_separate, 'delivery_by_freq_grocery2.csv')

# create plot

grocery_column<- static_column_chart(t= grocery_freq_separate,
                                                  x="delivery_grocery_all", y="share",
                                                  f="survey",
                                                  moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1)
                                                 # title="Grocery Deliveries",
                                                  #subtitle="(e.g., Amazon Fresh, Instacart, Safeway Online)")
                                                 # source = "regional household travel survey")

grocery_column

# work/service deliveries by year alone
count_work_17 <- hhts_count(joined_df_deliveries_17, group_vars = "delivery_work_all",
                                     spec_wgt = "day_weight_2017")%>%
  filter(delivery_work_all== "Delivery Received")


count_work_19 <- hhts_count(joined_df_deliveries_19, group_vars = "delivery_work_all",
                               spec_wgt = "day_weight_2019")%>%
  filter(delivery_work_all == "Delivery Received")


count_work_21 <- hhts_count(joined_df_deliveries_21, group_vars = "delivery_work_all",
                               spec_wgt = "hh_weight_2021") %>%
  filter(delivery_work_all == "Delivery Received")

# merge data frames for combined 2017/2019 and 2021
# write csv

work_freq_separate <- rbind(count_work_17, count_work_19, count_work_21)
write.csv(work_freq_separate, 'delivery_by_freq_work2.csv')

# create plot

work_column<- static_column_chart(t= work_freq_separate,
                                                  x="delivery_work_all", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1)
                                                 # title="Work/Service Deliveries",
                                                  #subtitle="(e.g., landscaping, cable, house-cleaning)")
                                        # source = "regional household travel survey")

work_column

# facet wrap charts for all deliveries
# pull from Mary's T:\2022September\Mary\EquityTracker\Transportation\HCTaccess_2020_5y_Elmer_CSV.Rmd code

# rename column names so that can bind dfs
# change response type from Delivery Received to delivery_type (i.e., food, grocery, pkgs, work)

food_freq_separate$delivery_type = c("food/meal", "food/meal", "food/meal")
grocery_freq_separate$delivery_type = c("grocery", "grocery", "grocery")
pkgs_freq_separate$delivery_type = c("packages", "packages", "packages")
work_freq_separate$delivery_type = c("work/service", "work/service", "work/service")

# bind all dataframes together 

all_deliveries_freq_17_21 <- rbind(food_freq_separate, grocery_freq_separate, pkgs_freq_separate, work_freq_separate, fill = TRUE)
                                   
# remove unnecessary columns

all_deliveries_freq_17_21_new <- all_deliveries_freq_17_21[, -c(2, 9, 10, 11)]

# create facet bar chart

#deliveries_facet1<- static_facet_column_chart(t= all_deliveries_freq_17_21_new,
 #                                                 x="survey", y="share",
  #                                                fill="delivery_type", #g="delivery_type",
   #                                               facet = 2,
    #                                              est ="percent",
     #                                             scales = "fixed",
      #                                            dec = 2,
       #                                           color="blues_inc",
        #                                          title="Home Deliveries or Services",
         #                                         subtitle="Share of Households on Average Weekday")+
  #ggplot2::theme(axis.title = ggplot2::element_blank()) 

#?static_facet_column_chart()

#deliveries_facet1

deliveries_all_column<- static_column_chart(t= all_deliveries_freq_17_21_new,
                                                  x="delivery_type", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1)
                                                  #title="Home Deliveries or Services",
                                                  #subtitle="Share of Households on Average Weekday")
                                        # source = "regional household travel survey")

deliveries_all_column

# create data frames to run crosstabs for broad income and food deliveries
# crosstabs for BROAD income and food delivery by share and count (across years)

#food_income_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
 #                   group_vars = c('hhincome_broad', 'delivery_food_all')) %>% 
  #filter(hhincome_broad != 'Total')%>%
  #filter(delivery_food_all != 'Total')%>%
  #filter(delivery_food_all != 'No Delivery')

#food_income_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
 #                   group_vars = c('hhincome_broad', 'delivery_food_all')) %>% 
  #filter(hhincome_broad != 'Total')%>%
  #filter(delivery_food_all != 'Total')%>%
  #filter(delivery_food_all != 'No Delivery')

#food_income_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
 #                   group_vars = c('hhincome_broad', 'delivery_food_all')) %>% 
  #filter(hhincome_broad != 'Total')%>%
  #filter(delivery_food_all != 'Total')%>%
  #filter(delivery_food_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs

#all_food_freq_17_21 <- bind_rows(food_income_17, food_income_19, food_income_21) %>%
 # mutate(period = as.factor(survey))

#table(all_food_freq_17_21$delivery_food_all, all_food_freq_17_21$period)

# crosstabs for DICHOTOMOUS income and food delivery by share (across years)

food_income_17_dichot <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                                    group_vars = c('hhincome_dichot', 'delivery_food_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')%>%
  mutate(hhincome_dichot = fct_relevel(hhincome_dichot,
                                       "Under $75,000", "$75,000+", "Prefer not to answer"))

food_income_19_dichot <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                                    group_vars = c('hhincome_dichot', 'delivery_food_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')

food_income_21_dichot <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                                    group_vars = c('hhincome_dichot', 'delivery_food_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs

all_food_dichot_17_21 <- bind_rows(food_income_17_dichot, food_income_19_dichot, food_income_21_dichot) %>%
  mutate(period = as.factor(survey))

# crosstab for income and food delivery 

food_income_column<- static_column_chart(t= all_food_dichot_17_21,
                                         x="hhincome_dichot", y="share",
                                         f="survey",
                                         moe = "share_moe",
                                         color="psrc_pairs",
                                         est ="percent",
                                         dec=1,
                                         title="Food/Meal Deliveries by Income",
                                         subtitle="(e.g.., pizza/sushi, Grubhub)")
                                        # source = "PSRC Regional Household Travel Survey")

food_income_column

# crosstabs for income and grocery delivery by share and count (across years)

grocery_income_17_dichot <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('hhincome_dichot', 'delivery_grocery_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')%>%
  mutate(hhincome_dichot = fct_relevel(hhincome_dichot,
            "Under $75,000", "$75,000+", "Prefer not to answer"))

grocery_income_19_dichot <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('hhincome_dichot', 'delivery_grocery_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')

grocery_income_1719_dichot <- hhts_count(joined_df_deliveries_1719, spec_wgt = 'day_weight_2017_2019', 
                    group_vars = c('hhincome_dichot', 'delivery_grocery_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')%>%
  mutate(hhincome_dichot = fct_relevel(hhincome_dichot,
            "Under $75,000", "$75,000+", "Prefer not to answer"))%>%
  mutate(survey = case_when(survey == "2017_2019" ~ "2019/2019"))

grocery_income_21_dichot <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('hhincome_dichot', 'delivery_grocery_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs

all_grocery_income_dichot_17_21 <- bind_rows(grocery_income_17_dichot, grocery_income_19_dichot, grocery_income_21_dichot) %>%
  mutate(period = as.factor(survey))

# plot by year and by category

groceries_income_column<- static_column_chart(t= all_grocery_income_dichot_17_21,
                                                  x="hhincome_dichot", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Grocery Deliveries",
                                                  subtitle="(i.e., Amazon Fresh, Safeway Online, Instacart)",
                                         source = "PSRC Regional Household Travel Survey")

groceries_income_column

# crosstabs for package deliveries and income dichotomies, share_plot_by_year2 is favored plot

pkg_income_17_dichot <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('hhincome_dichot', 'delivery_pkgs_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')%>%
  mutate(hhincome_dichot = fct_relevel(hhincome_dichot,
            "Under $75,000", "$75,000+", "Prefer not to answer"))

pkg_income_19_dichot <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('hhincome_dichot', 'delivery_pkgs_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')

pkg_income_1719_dichot <- hhts_count(joined_df_deliveries_1719, spec_wgt = 'day_weight_2017_2019', 
                    group_vars = c('hhincome_dichot', 'delivery_pkgs_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')%>%
  mutate(hhincome_dichot = fct_relevel(hhincome_dichot,
            "Under $75,000", "$75,000+", "Prefer not to answer"))%>%
  mutate(survey = case_when(survey == "2017_2019" ~ "2019/2019"))

pkg_income_21_dichot <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('hhincome_dichot', 'delivery_pkgs_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs

all_pkgs_income_dichot_17_21 <- bind_rows(pkg_income_17_dichot, pkg_income_19_dichot, pkg_income_21_dichot) %>%
  mutate(period = as.factor(survey))

# plot by year and by category

pkgs_income_column<- static_column_chart(t= all_pkgs_income_dichot_17_21,
                                                  x="hhincome_dichot", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Package Deliveries by Income",
                                                  subtitle="(i.e., FedEx, UPS, USPS)")
                                        # source = "PSRC Regional Household Travel Survey")

pkgs_income_column

# crosstabs for income and package delivery by share and count (across years)

work_income_17_dichot <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('hhincome_dichot', 'delivery_work_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')%>%
  mutate(hhincome_dichot = fct_relevel(hhincome_dichot,
            "Under $75,000", "$75,000+", "Prefer not to answer"))

work_income_19_dichot <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('hhincome_dichot', 'delivery_work_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')

work_income_1719_dichot <- hhts_count(joined_df_deliveries_1719, spec_wgt = 'day_weight_2017_2019', 
                    group_vars = c('hhincome_dichot', 'delivery_work_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')%>%
  mutate(hhincome_dichot = fct_relevel(hhincome_dichot,
            "Under $75,000", "$75,000+", "Prefer not to answer"))%>%
  mutate(survey = case_when(survey == "2017_2019" ~ "2019/2019"))

work_income_21_dichot <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('hhincome_dichot', 'delivery_work_all')) %>% 
  filter(hhincome_dichot != 'Total')%>%
  filter(hhincome_dichot != 'Prefer not to answer') %>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs

all_work_income_dichot_17_21 <- bind_rows(work_income_17_dichot, work_income_19_dichot, work_income_21_dichot) %>%
  mutate(period = as.factor(survey))

# plot by year and by category

work_income_column<- static_column_chart(t= all_work_income_dichot_17_21,
                                                  x="hhincome_dichot", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec= 1,
                                                  title="Work Deliveries by Income",
                                                  subtitle="(e.g., landscaping, cable service, house-cleaningcable)",
                                         source = "PSRC Regional Household Travel Survey")

work_income_column

# crosstabs for lifecycle and food delivery by share and count (across years)

food_lifecycle_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('lifecycle', 'delivery_food_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

food_lifecycle_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('lifecycle', 'delivery_food_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

food_lifecycle_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = "hh_weight_2021", 
                    group_vars = c('lifecycle', 'delivery_food_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))


# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_food_lifecycle_17_21 <- bind_rows(food_lifecycle_17, food_lifecycle_19, food_lifecycle_21) %>%
  mutate(period = as.factor(survey))

# plot

food_lifecycles<- static_column_chart(t= all_food_lifecycle_17_21,
                                                  x="survey", y="share",
                                                  f="lifecycle",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=0,
                                                  title="Food Deliveries",
                                                  subtitle="(e.g., pizza/sushi, GrubHub)",
                                         source = "PSRC Regional Household Travel Survey")

food_lifecycles

# crosstabs for grocery deliveries and lifecycle stages

grocery_lifecycle_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('lifecycle', 'delivery_grocery_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

grocery_lifecycle_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('lifecycle', 'delivery_grocery_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

grocery_lifecycle_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('lifecycle', 'delivery_grocery_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_grocery_lifecycle_17_21 <- bind_rows(grocery_lifecycle_17, grocery_lifecycle_19, grocery_lifecycle_21) %>%
  mutate(period = as.factor(survey))

# column chart

grocery_lifecycles<- static_column_chart(t= all_grocery_lifecycle_17_21,
                                                  x="lifecycle", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Grocery Deliveries by Household",
                                                  subtitle="(e.g., Amazon Fresh, Safeway Online, Instacart)",
                                         source = "PSRC Regional Household Travel Survey")

grocery_lifecycles

# crosstabs for lifecycle and food delivery by share and count (across years)

pkgs_lifecycle_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('lifecycle', 'delivery_pkgs_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

pkgs_lifecycle_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('lifecycle', 'delivery_pkgs_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

pkgs_lifecycle_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('lifecycle', 'delivery_pkgs_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))


# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_pkgs_lifecycle_17_21 <- bind_rows(pkgs_lifecycle_17, pkgs_lifecycle_19, pkgs_lifecycle_21) %>%
  mutate(period = as.factor(survey))

# column chart

pkgs_lifecycles<- static_column_chart(t= all_pkgs_lifecycle_17_21,
                                                  x="lifecycle", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Packages Deliveries by Household",
                                                  subtitle="(e.g., FedEx, UPS, USPS)",
                                         source = "PSRC Regional Household Travel Survey")

pkgs_lifecycles

# crosstabs for work/service deliveries and lifecycle stages

work_lifecycle_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('lifecycle', 'delivery_work_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

work_lifecycle_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('lifecycle', 'delivery_work_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))

work_lifecycle_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('lifecycle', 'delivery_work_all')) %>% 
  filter(lifecycle != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')%>%
  mutate(lifecycle = fct_relevel(lifecycle,
            "Household has kids", "Under 35 years, no kids", "35-64", "65 years or older"))


# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_work_lifecycle_17_21 <- bind_rows(work_lifecycle_17, work_lifecycle_19, work_lifecycle_21) %>%
  mutate(period = as.factor(survey))

# column chart

work_lifecycles<- static_column_chart(t= all_work_lifecycle_17_21,
                                                  x="lifecycle", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Work/Service Deliveries by Household",
                                                  subtitle="(e.g., landscaping, cable service, house-cleaning)",
                                         source = "PSRC Regional Household Travel Survey")

work_lifecycles

# lifecycle facet wrap with fixed scale

food_lifecycle_21$delivery_type = c("food/meal", "food/meal", "food/meal", "food/meal")
grocery_lifecycle_21$delivery_type = c("grocery", "grocery", "grocery", "grocery")
pkgs_lifecycle_21$delivery_type = c("packages", "packages", "packages", "packages")
work_lifecycle_21$delivery_type = c("work/service", "work/service", "work/service", "work/service")

# bind all dataframes together 

all_deliveries_lifecycle <- rbind(food_lifecycle_21, grocery_lifecycle_21, pkgs_lifecycle_21, work_lifecycle_21, fill = TRUE)
                                   
# remove unnecessary columns

all_deliveries_lifecycle_new <- all_deliveries_lifecycle[, -c(3, 10, 11, 12)]

# create facet bar chart

deliveries_lifecycle_facet<- static_facet_column_chart(t= all_deliveries_lifecycle_new,
                                                  x="delivery_type", y="share",
                                                  fill="lifecycle", facet="survey",
                                                  moe = "share_moe",
                                                  color="greens_inc",
                                                  est ="percent",
                                                  dec=2,
                                                  scales="fixed",
                                                  ncol = 4,
                                                  title="Home Deliveries or Services by Age Group",
                                                  subtitle="Share of Households on Average Weekday")

deliveries_lifecycle_facet

# facet for suzanne - request on teams
# 2017
food_lifecycle_17$delivery_type = c("food/meal", "food/meal", "food/meal", "food/meal")
grocery_lifecycle_17$delivery_type = c("grocery", "grocery", "grocery", "grocery")
pkgs_lifecycle_17$delivery_type = c("packages", "packages", "packages", "packages")
work_lifecycle_17$delivery_type = c("work/service", "work/service", "work/service", "work/service")

#2019
food_lifecycle_19$delivery_type = c("food/meal", "food/meal", "food/meal", "food/meal")
grocery_lifecycle_19$delivery_type = c("grocery", "grocery", "grocery", "grocery")
pkgs_lifecycle_19$delivery_type = c("packages", "packages", "packages", "packages")
work_lifecycle_19$delivery_type = c("work/service", "work/service", "work/service", "work/service")

#2021
food_lifecycle_21$delivery_type = c("food/meal", "food/meal", "food/meal", "food/meal")
grocery_lifecycle_21$delivery_type = c("grocery", "grocery", "grocery", "grocery")
pkgs_lifecycle_21$delivery_type = c("packages", "packages", "packages", "packages")
work_lifecycle_21$delivery_type = c("work/service", "work/service", "work/service", "work/service")

# bind all dataframes together 

all_deliveries_lifecycle2 <- rbind(food_lifecycle_17, grocery_lifecycle_17, pkgs_lifecycle_17, work_lifecycle_17, food_lifecycle_19, grocery_lifecycle_19, pkgs_lifecycle_19, work_lifecycle_19,food_lifecycle_21, grocery_lifecycle_21, pkgs_lifecycle_21, work_lifecycle_21, fill = TRUE)
                                   
# remove unnecessary columns

all_deliveries_lifecycle_new2 <- all_deliveries_lifecycle2[, -c(3, 10, 11, 12)]

deliveries_lifecycle_facet2<- static_facet_column_chart(t= all_deliveries_lifecycle_new2,
                                                  x="survey", 
                                                  y="share",
                                                  fill="lifecycle", 
                                                  facet="delivery_type",
                                                  color="greens_inc",
                                                  est ="percent",
                                                  dec=2,
                                                  scales="fixed",
                                                  ncol=2,
                                                  title="Home Deliveries or Services by Year and by Type",
                                                  subtitle="Share of Households on Average Weekday")+ 
  ggplot2::theme(axis.title = ggplot2::element_blank())

deliveries_lifecycle_facet2

# favored - with free scale instead of fixed
deliveries_lifecycle_facet3<- static_facet_column_chart(t= all_deliveries_lifecycle_new2,
                                                  x="lifecycle", 
                                                  y="share",
                                                  fill="survey", 
                                                  facet="delivery_type",
                                                  moe = "share_moe",
                                                  color="purples_inc",
                                                  est ="percent",
                                                  dec=2,
                                                  scales="free",
                                                  ncol=2)
                                                  #title="Home Deliveries or Services by Year and by Type",
                                                  #subtitle="Share of Households on Average Weekday")+ 
  ggplot2::theme(axis.title = ggplot2::element_blank()) +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10))

deliveries_lifecycle_facet3

# food deliveries and rgc location/destination, location variables : 'seattle_home', 'final_home_rgcnum', 'final_home_uvnum', 'final_home_is_rgc'

food_rgc_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('final_home_is_rgc', 'delivery_food_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')

food_rgc_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('final_home_is_rgc', 'delivery_food_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')

food_rgc_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('final_home_is_rgc', 'delivery_food_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_food_rgc_17_21 <- bind_rows(food_rgc_17, food_rgc_19, food_rgc_21) %>%
  mutate(period = as.factor(survey))

# plot by year and by category

food_rgc_plot<- static_column_chart(t= all_food_rgc_17_21,
                                                  x="final_home_is_rgc", y="share",
                                                  f="survey",
                                                  moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1)
                                                  #title="Food/Meal Deliveries by Household Location",
                                                  #subtitle="Share of Households on Average Weekday")
                                                  #source = "PSRC Regional Household Travel Survey")

food_rgc_plot

# grocery deliveries and rgc location/destination

grocery_rgc_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('final_home_is_rgc', 'delivery_grocery_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')

grocery_rgc_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('final_home_is_rgc', 'delivery_grocery_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')

grocery_rgc_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('final_home_is_rgc', 'delivery_grocery_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_grocery_rgc_17_21 <- bind_rows(grocery_rgc_17, grocery_rgc_19, grocery_rgc_21) %>%
  mutate(period = as.factor(survey))

# plot by year and by category

grocery_rgc_plot<- static_column_chart(t= all_grocery_rgc_17_21,
                                                  x="final_home_is_rgc", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1)
                                                #  title="Grocery Deliveries by Household Location",
                                                 # subtitle="Share of Households on Average Weekday")
                                        # source = "PSRC Regional Household Travel Survey")

grocery_rgc_plot

# package deliveries and rgc location/destination

pkg_rgc_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('final_home_is_rgc', 'delivery_pkgs_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')

pkg_rgc_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('final_home_is_rgc', 'delivery_pkgs_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')

pkg_rgc_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('final_home_is_rgc', 'delivery_pkgs_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_pkg_rgc_17_21 <- bind_rows(pkg_rgc_17, pkg_rgc_19, pkg_rgc_21) %>%
  mutate(period = as.factor(survey))

# plot by year and by category

pkg_rgc_plot<- static_column_chart(t= all_pkg_rgc_17_21,
                                                  x="final_home_is_rgc", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1)
                                                  #title="Package Deliveries by Household Location",
                                          #subtitle="Share of Households on Average Weekday",
                                         #source = "PSRC Regional Household Travel Survey")

pkg_rgc_plot

# work deliveries and rgc location/destination

work_rgc_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('final_home_is_rgc', 'delivery_work_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')

work_rgc_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('final_home_is_rgc', 'delivery_work_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')

work_rgc_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('final_home_is_rgc', 'delivery_work_all')) %>% 
  filter(final_home_is_rgc != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_work_rgc_17_21 <- bind_rows(work_rgc_17, work_rgc_19, work_rgc_21) %>%
  mutate(period = as.factor(survey))

# plot by year and by category

work_rgc_plot<- static_column_chart(t= all_work_rgc_17_21,
                                                  x="final_home_is_rgc", y="share",
                                                  f="survey",
                                            moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Work Deliveries by Household Location",
                                                  subtitle="Share of Households on Average Weekday",
                                         source = "PSRC Regional Household Travel Survey")

work_rgc_plot

# rgc facet wrap with fixed scale

all_food_rgc_17_21$delivery_type = c("food/meal", "food/meal", "food/meal", "food/meal", "food/meal", "food/meal")
all_grocery_rgc_17_21$delivery_type = c("grocery", "grocery", "grocery", "grocery", "grocery", "grocery")
all_pkg_rgc_17_21$delivery_type = c("packages", "packages", "packages", "packages", "packages", "packages")
all_work_rgc_17_21$delivery_type = c("work/service", "work/service", "work/service", "work/service", "work/service", "work/service")

# bind all dataframes together 

all_deliveries_rgc <- rbind(all_food_rgc_17_21, all_grocery_rgc_17_21, all_pkg_rgc_17_21, all_work_rgc_17_21, fill = TRUE)
                                   
# remove unnecessary columns

all_deliveries_rgc_new <- all_deliveries_rgc[, -c(3, 11, 12, 13)]

# create facet bar chart

deliveries_rgc<- static_facet_column_chart(t= all_deliveries_rgc_new,
                                                  x="final_home_is_rgc",
                                                  y="share",
                                                  fill = "delivery_type",
                                                  facet = "survey",
                                                  moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=2,
                                                  scales="fixed",
                                                  ncol = 4,
                                                  title="Home Deliveries or Services by RGC",
                                                  subtitle="Share of Households on Average Weekday")+ 
  ggplot2::theme(axis.title = ggplot2::element_blank())

deliveries_rgc

# hhsize and food deliveries: hhsize'

food_hh_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('hhsize', 'delivery_food_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')

food_hh_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('hhsize', 'delivery_food_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')

food_hh_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('hhsize', 'delivery_food_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_food_all != 'Total')%>%
  filter(delivery_food_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_food_hh_17_21 <- bind_rows(food_hh_17, food_hh_19, food_hh_21) %>%
  mutate(period = as.factor(survey))

# psrc plot style

food_hhsize_plot<- static_column_chart(t= all_food_hh_17_21,
                                                  x="hhsize", y="share",
                                                  f="survey",
                                                  moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Food/Meal Deliveries by Household Size",
                                                  subtitle="Share of Households on Average Weekday")
                                                #  source = "PSRC Regional Household Travel Survey")

food_hhsize_plot

#hhsize and grocery deliveries

# hh variables: hhsize'

grocery_hh_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('hhsize', 'delivery_grocery_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')

grocery_hh_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('hhsize', 'delivery_grocery_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')

grocery_hh_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('hhsize', 'delivery_grocery_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_grocery_all != 'Total')%>%
  filter(delivery_grocery_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_grocery_hh_17_21 <- bind_rows(grocery_hh_17, grocery_hh_19, grocery_hh_21) %>%
  mutate(period = as.factor(survey))

#ppsrc plot style

grocery_hhsize_plot<- static_column_chart(t= all_grocery_hh_17_21,
                                                  x="hhsize", y="share",
                                                  f="survey",
                                                  moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Grocery Deliveries by Household Size",
                                                  subtitle="Share of Households on Average Weekday")
                                             #     source = "PSRC Regional Household Travel Survey")

grocery_hhsize_plot

# hhsize and package deliveries

pkgs_hh_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('hhsize', 'delivery_pkgs_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')

pkgs_hh_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('hhsize', 'delivery_pkgs_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')

pkgs_hh_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('hhsize', 'delivery_pkgs_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_pkgs_all != 'Total')%>%
  filter(delivery_pkgs_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_pkgs_hh_17_21 <- bind_rows(pkgs_hh_17, pkgs_hh_19, pkgs_hh_21) %>%
  mutate(period = as.factor(survey))

#ppsrc plot style

pkgs_hhsize_plot<- static_column_chart(t= all_pkgs_hh_17_21,
                                                  x="hhsize", y="share",
                                                  f="survey",
                                                  moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=1,
                                                  title="Package Deliveries by Household Size",
                                                  subtitle="Share of Households on Average Weekday")
                                                #  source = "PSRC Regional Household Travel Survey")

pkgs_hhsize_plot

# hhsize and work deliveries

work_hh_17 <- hhts_count(joined_df_deliveries_17, spec_wgt = 'day_weight_2017', 
                    group_vars = c('hhsize', 'delivery_work_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')

work_hh_19 <- hhts_count(joined_df_deliveries_19, spec_wgt = 'day_weight_2019', 
                    group_vars = c('hhsize', 'delivery_work_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')

work_hh_21 <- hhts_count(joined_df_deliveries_21, spec_wgt = 'hh_weight_2021', 
                    group_vars = c('hhsize', 'delivery_work_all')) %>% 
  filter(hhsize != 'Total')%>%
  filter(delivery_work_all != 'Total')%>%
  filter(delivery_work_all != 'No Delivery')

# merge dfs for 2017, 2017/2019, and 2021 - alternate approach for crosstabs
all_work_hh_17_21 <- bind_rows(work_hh_17, work_hh_19, work_hh_21) %>%
  mutate(period = as.factor(survey))

#ppsrc plot style

work_hhsize_plot<- static_column_chart(t= all_work_hh_17_21,
                                                  x="hhsize", y="share",
                                                  f="survey",
                                                  moe = "share_moe",
                                                  color="psrc_pairs",
                                                  est ="percent",
                                                  dec=0,
                                                  title="Work/Service Deliveries by Household Size",
                                                  subtitle="Share of Households on Average Weekday")
                                               #   source = "PSRC Regional Household Travel Survey")

work_hhsize_plot