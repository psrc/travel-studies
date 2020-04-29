#The codebook is checked in with these code files, named Combined_Codebook_022020.xlsx
library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)

dbtable.household <- "HHSurvey.v_households_2017_2019"
dbtable.day <- "HHSurvey.v_day_2017_2019"
dbtable.vehicle <- "HHSurvey.v_vehicle_2017_2019"
dbtable.person <- "HHSurvey.v_persons_2017_2019"
dbtable.trip <- "HHSurvey.v_trips_2017_2019"
dbtable.variables <- "HHSurvey.data_explorer_variables"
dbtable.values <- "HHSurvey.v_data_explorer_values_2019" #"HHSurvey.data_explorer_values"

db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\COHO",
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

household<-read.dt(dbtable.household, 'table_name')

sum(household$hh_wt_combined)
