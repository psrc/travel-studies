install.packages("stargazer")
library(nnet)
library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)
library(dplyr)
library(stargazer)

# Estimating a multinomial logit model for household vehicles
# https://www.princeton.edu/~otorres/LogitR101.pdf


#functions for reading in data
db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\SOCKEYE",
                                database = "Elmer",
                                trusted_connection = "yes"
  )
}

read.dt <- function(astring, type =c('table_name', 'sqlquery')) {
  elmer_connection <- db.connect()
  if (type == 'table_name') {
    dtelm <- dbReadTable(elmer_connection, SQL(astring))
  } else {
    dtelm <- dbGetQuery(elmer_connection, SQL(astring))
  }
  dbDisconnect(elmer_connection)
  setDT(dtelm)
}



#read in the household table
dbtable.household.query<- paste("SELECT *  FROM HHSurvey.v_households_2017_2019_in_house")
hh_df<-read.dt(dbtable.household.query, 'tablename')


# this has some information on the Census Tract level that could be useful
displ_index_data<- 'C:/Users/mrichards/Documents/GitHub/travel-studies/2019/analysis/zero_veh_hh/displacement_risk_estimation.csv'
displ_risk_df <- read.csv(displ_index_data)
transit_score_data <- 'T:/2020October/Mary/HHTS/reference_materials/bg_transit_score2018_2_sf_10302020.csv'
transit_sc_df <- read.csv(transit_score_data)

#merge the households to info about the tracts/blocks they live in - displacement risk/transit score
hh_df$final_home_tract<- as.character(hh_df$final_home_tract)
hh_df$final_home_bg<- as.character(hh_df$final_home_bg)
# displacement risk - by tract
displ_risk_df$GEOID<-as.character(displ_risk_df$GEOID)
hh_df_tract<- merge(hh_df,displ_risk_df, by.x='final_home_tract', by.y='GEOID', all.x=TRUE)
glimpse(hh_df_tract)
# transit score - by block
transit_sc_df$geoid10<-as.character(transit_sc_df$geoid10)
glimpse(transit_sc_df$geoid10)
glimpse(hh_df_tract$final_home_bg)
hh_df_tract <- merge(hh_df_tract, transit_sc_df, by.x='final_home_bg', by.y='geoid10', all.x=TRUE )
glimpse(hh_df_tract)

# probably want to predict the vehicle categorization Mary had been using
# lucky there are no NAs
unique(hh_df_tract$vehicle_count)
hh_df_veh <- hh_df_tract %>% mutate(vehicle_group = case_when(vehicle_count== "0 (no vehicles)" ~ 0,
                                                              vehicle_count == "1" ~  1,
                                                              vehicle_count == "2" ~ 2,
                                                              vehicle_count == "3" ~ 3,
                                                              TRUE ~ 4))
hh_df_veh %>% group_by(vehicle_group, vehicle_count) %>% tally()

# look at vehicle access by number of workers in a household
unique(hh_df_veh$numworkers)

hh_df_veh <- hh_df_veh %>%
  mutate(numworkers_simp = case_when(numworkers >= 3 ~ 3,
                                     TRUE~as.numeric(numworkers)))
unique(hh_df_veh$numworkers_simp)

# compare veh count and numworkers
class(hh_df_veh$vehicle_group)
class(hh_df_veh$numworkers_simp)


hh_df_veh <- hh_df_veh %>%
  mutate(hh_veh_access = case_when(vehicle_group < numworkers_simp ~ 'Reduced Access',
                                       vehicle_group == numworkers_simp ~ 'Equal access',
                                       vehicle_group > numworkers_simp ~ 'Good access'))
unique(hh_df_veh$hh_veh_access)
xtabs(~hh_veh_access, data=hh_df_veh)



# try different race groupings
unique(hh_df_veh$hh_race_category)

# further simplify race category 
hh_df_veh <- hh_df_veh %>% 
  mutate(hh_race_2 = case_when(hh_race_category == "White Only" ~ 'White Only',
                               hh_race_category == "Missing" | hh_race_category == "Other" ~ "Missing/Other",
                                                    TRUE ~ 'People of Color'))
freq(hh_df_veh$hh_race_2)

# get transit score by block group from Stefan
# try other variables on the household table and the tract table
hh_df_veh <- hh_df_veh %>%
  mutate(RGC_binary = case_when(final_home_rgcnum == "Not RCG" ~ "Not RGC",
                                TRUE ~ "RGC"))


# model
vehicle_est = multinom(vehicle_group ~ 
                         numworkers + hhincome_broad + hh_race_2 +
                         rent +
                         ln_jobs_transit_45 + ln_jobs_auto_30 + dist_super +
                         seattle_home + RGC_binary, 
                       data=hh_df_veh)

vehicle_est

stargazer(vehicle_est, type= 'text', out='C:/Users/mrichards/Documents/GitHub/travel-studies/2019/analysis/zero_veh_hh/veh_est_results_mr.txt')
