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
displ_index_data<- 'C:/Users/SChildress/Documents/GitHub/data-science/HHSurvey/displacement_risk_estimation.csv'
displ_risk_df <- read.csv(displ_index_data)


#merge the households to info about the tracts they live in
hh_df$final_home_tract<- as.character(hh_df$final_home_tract)
displ_risk_df$GEOID<-as.character(displ_risk_df$GEOID)
hh_df_tract<- merge(hh_df,displ_risk_df, by.x='final_home_tract', by.y='GEOID', all.x=TRUE)


# get transit score data from Stefan; by block group ???

unique(hh_df_tract$vehicle_count)
hh_df_veh <- hh_df_tract %>% mutate(vehicle_group = case_when(vehicle_count== "0 (no vehicles)" ~ '0',
                                                              vehicle_count == "1" ~ '1',
                                                              vehicle_count == "2" ~ '2',
                                                              TRUE ~ "2+"))



vehicle_est= multinom(vehicle_group ~ numworkers + hhincome_detailed + hh_race_category+
                        ln_jobs_transit_45, data=hh_df_veh)

summary(vehicle_est)
