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

# packages that are from github that host functions for pulling data
devtools::install_github("psrc/psrc.travelsurvey", force = TRUE)
devtools::install_github("psrc/psrccensus", force = TRUE)
library(psrc.travelsurvey)
library(psrccensus)

# for Elmer connection
library(odbc)
library(DBI)

# of this option for the new driver that makes certain *new* functions available
# however, have to still connect to R console after bringing in the connection

elmer_connection <- dbConnect(odbc::odbc(),
                              driver = "SQL Server",
                              server = "AWS-PROD-SQL\\Sockeye",
                              database = "Elmer",
                              trusted_connection = "yes"
) 

elmer_connect <- function(){
  DBI::dbConnect(odbc::odbc(),
                                           driver = "ODBC Driver 17 for SQL Server",
                                           server = "AWS-PROD-SQL\\Sockeye",
                                           database = "Elmer",
                                           trusted_connection = "yes",
                                           port = 1433)
}
elmer_connection <- elmer_connect()

# to read in a whole table using schema and table name
df <- dbReadTable(elmer_connection, SQL("some_schema.some_table_name"))

### EXAMPLES to make sure functions are working properly
t_2017_19a <- get_hhts(survey="2017_2019",
                            level="t",
                            vars="trip_path_distance")

rs_median_dist  <- hhts_median(df = t_2017_19a, 
                               stat_var = "trip_path_distance")

y <- get_hhts('2021', 'p', c('gender', 'telecommute_freq'))


# for HHTS freight data tables
freight1719 <- dbReadTable(elmer_connection, SQL("HHSurvey.days_2017_2019"))
freight21 <- dbReadTable(elmer_connection, SQL("HHSurvey.days_2021"))
hhts_varsearch("dest_purp")
hhts_varsearch("dest_purpose_cat")
hhts_varsearch("dest_purpose_other")
hhts_varsearch("delivery")
hhts_varsearch("notravel_delivery")

# preliminary research for freight variables (delivery)
# from christy "gender_telecommute.R" and mary "transit_auto..."
library(psrc.travelsurvey)
library(tidyverse)
library(ggiraph)
library(psrccensus)
library(psrc.travelsurvey)
library(rlang) #required for psrccensus
library(emmeans) #required for rlang
library(magrittr)
library(knitr)
library(kableExtra)
library(ggplot2)

# library(survey)
library(summarytools) #freq
library(table1)  #nice descriptive summary table
library(scales) #number formatting
library(ggpubr) #graphing - ggarrange fx
library(forcats) #for factor releveling

# global variables
survey_a <- list(survey = '2017_2019', label = '2017/2019')
survey_b <- list(survey = '2021', label = '2021')
survey_c <- list(survey = '2017', label = '2017')
survey_d <- list(survey = '2019', label = '2019')

all_vars_deliver <- c("delivery_food_freq",
                      "delivery_grocery_freq",
                      "delivery_other_freq",
                      "delivery_pkgs_freq",
                      "delivery_work_freq",
                      "notravel_delivery") # no travel because awaiting delivery - to include or not??

all_vars_errands <- c("dest_purpose",
                      "dest_purpose_simple") #dest_purp_cat unable to be identified in the datasets, dest_purpose_other not in 2021

all_vars_food_d <- c("delivery_food_freq", "delivery_grocery_freq")
all_vars_food_err <- c('Went grocery shopping', 'Went to restaurant to eat/get take-out')

# getting variables from tables/datasets for delivery options 
deliver_survey_1719 <- get_hhts(survey = survey_a$survey,
                       level ="d",
                       vars = all_vars_deliver)

deliver_survey_21 <- get_hhts(survey = survey_b$survey,
                       level="d",
                       vars=all_vars_deliver)

deliver_survey_17 <- get_hhts(survey = survey_c$survey,
                         level="d",
                         vars=all_vars_deliver)

deliver_survey_19 <- get_hhts(survey = survey_d$survey,
                       level="d",
                       vars=all_vars_deliver)                      

# getting variables from tables/datasets for destination purpose
errands_survey_1719 <- get_hhts(survey = survey_a$survey,
                                level = "t",
                                vars = all_vars_errands)

errands_survey_21 <- get_hhts(survey = survey_b$survey,
                              level="t",
                              vars=all_vars_errands)

errands_survey_17 <- get_hhts(survey = survey_c$survey,
                              level="t",
                              vars=all_vars_errands)

errands_survey_19 <- get_hhts(survey = survey_d$survey,
                              level="t",
                              vars=all_vars_errands)    

# find the names of the variables
ES2 <- errands_survey_21 %>% arrange(dest_purpose, dest_purpose_simple)
str(ES2)
count(ES2, dest_purpose)
count(ES2, dest_purpose_simple)

ES2a <- get_hhts("2021", "t", "dest_purpose")
rs_dest_region  <- hhts_count(ES2a, group_vars="dest_purpose")

# r cleaning and establishing functions for food categories

smp_commute_fx <- function(data, year) {
  temp_table <- data %>%
    filter(race_eth_broad!="Child -- no race specified") %>%
    drop_na(commute_mode) %>%
    mutate(commute_mode = factor(case_when(commute_mode=="Bus (public transit)" |
                                             commute_mode=="Commuter rail (Sounder, Amtrak)" |
                                             commute_mode=="Ferry or water taxi" |
                                             commute_mode=="Paratransit" |
                                             commute_mode=="Streetcar" |
                                             commute_mode=="Urban rail (Link light rail, monorail)" |
                                             commute_mode=="Urban rail (Link light rail, monorail, streetcar)" ~ "2-Public Transit",
                                           commute_mode=="Bicycle or e-bike" |
                                             commute_mode=="Motorcycle/moped" |
                                             commute_mode=="Motorcycle/moped/scooter" |
                                             commute_mode=="Scooter or e-scooter (e.g., Lime, Bird, Razor)" |
                                             commute_mode=="Walk, jog, or wheelchair" ~ "1-Active transit/micro mobility",
                                           commute_mode=="Drive alone" ~ "3-Drive alone",
                                           commute_mode=="Carpool ONLY with other household members" |
                                             commute_mode=="Carpool with other people not in household (may also include household members)" |
                                             commute_mode=="Other hired service (Uber, Lyft, or other smartphone-app car service)" |
                                             commute_mode=="Taxi (e.g., Yellow Cab)" |
                                             commute_mode=="Vanpool" ~ "4-HOV modes",
                                           TRUE ~ "5-Other modes")))

smp_errand_fxn <- function(data, year) {
  temp_table <- data %>%
    filter(dest_purpose == c('Conducted personal business (e.g., bank, post office', 'Other purpose', 'Went grocery shopping',
           'Went to other shopping (e.g., mall, pet store)','Went to restaurant to eat/get take-out'))
  
  temp_table2 <- temp_table %>% # mutate categories for food and for pkgs/errands
    mutate(food_purpose = factor(case_when(dest_purpose == 'Went grocery shopping',
                                         dest_purpose == 'Went to restaurant to eat/get take-out'))) %>%
    mutate(shopping_general = factor(case_when(dest_purpose == 'Went to other shopping (e.g., mall, pet store)',
                                             dest_purpose == 'Conducted personal business (e.g., bank, post office')))
  
  assign(paste0('smp_commute_', year), temp_table2)
}

# create new datasets with food categories aggregated and removal of non-shopping-related errands

errand_17 <- smp_errand_fxn(errands_survey_17, '2017')
errand_19 <- smp_errand_fxn(errands_survey_19, '2019')
errand_1719 <- smp_errand_fxn(errands_survey_1719, '2017/2019')
errand_21 <- smp_errand_fxn(errands_survey_21, '2021')

#### rejected from freight2.R

trip_errands_17 <- get_hhts(survey = survey_c$survey,
                            level="t",
                            vars=all_vars_errands)%>% 
  mutate(grocery_trip=ifelse(dest_purpose=='Went grocery shopping', 'Grocery', 'Not Grocery'))%>%
  drop_na("grocery_trip")

trip_errands_19 <- get_hhts(survey = survey_d$survey,
                            level="t",
                            vars=all_vars_errands)%>% 
  mutate(grocery_trip=ifelse(dest_purpose=='Went grocery shopping', 'Grocery', 'Not Grocery'))%>%
  drop_na("grocery_trip")

dbDisconnect(elmer_connection)
                     