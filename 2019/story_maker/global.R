library(shiny)
library(shinythemes)
library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(plotly)
library(shinyjs)
library(data.table)
library(odbc)
library(DBI)




missing_codes <- c('Missing: Technical Error', 'Missing: Non-response', 'Missing: Skip logic', 'Children or missing')

dbtable.household <- "HHSurvey.v_households_2017_2019"
dbtable.day <- "HHSurvey.v_day_2017_2019"
dbtable.vehicle <- "HHSurvey.v_vehicle_2017_2019"
dbtable.person <- "HHSurvey.v_persons_2017_2019"
dbtable.trip <- "HHSurvey.v_trips_2017_2019"
dbtable.variables <- "HHSurvey.data_explorer_variables"
dbtable.values <- "HHSurvey.v_data_explorer_values_2019" #"HHSurvey.data_explorer_values"

hh_weight_name <- 'hh_wt_combined'
hh_day_weight_name <-'hh_day_wt_combined'
trip_weight_name <- 'trip_wt_combined'

table_names <- list("Household" = list("weight_name" = hh_weight_name, "table_name" = dbtable.household),
                    "Day" = list("weight_name" = hh_day_weight_name , "table_name" = dbtable.day),
                    "Vehicle" = list("weight_name" = hh_weight_name, "table_name" =dbtable.vehicle),
                    "Person" = list("weight_name" = hh_weight_name , "table_name" = dbtable.person), 
                    "Trip" = list("weight_name" = trip_weight_name, "table_name" = dbtable.trip))

z <- 1.645 # 90% CI


## Read from Elmer

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



readme.dt <- read.xlsx(file.path(wrkdir, 'readme.xlsx'), colNames = T, skipEmptyRows = F)


# master list
dtype.choice <- c("Share" ="share",
                  "Total" = "estimate",
                  "Margin of Error (Total)" = "estMOE",
                  "Total with Margin of Error" = "estimate_with_MOE",
                  "Number of Households" = "N_HH",
                  "Share with Margin of Error" = "share_with_MOE",
                  "Margin of Error (Share)" = "MOE",
                  "Sample Count" = "sample_count",
                  "Mean" = "mean",
                  "Mean with Margin of Error" = "mean_with_MOE")

# xtab sublist: dimensions
dtype.choice.xtab <- dtype.choice[c(1:2, 6, 4, 8)]
col.headers <- c("sample_count", "estimate", "estMOE", "share", "MOE", "N_HH")

# xtab sublist: facts
dtype.choice.xtab.facts <- dtype.choice[c(9, 10, 8)]
col.headers.facts <-  c("mean", "MOE", "sample_count", "N_HH")

# stab sublist
dtype.choice.stab <- dtype.choice[c(1:2, 7, 3, 8)]
dtype.choice.stab.vis <- dtype.choice[c(1:2, 6, 4, 8)]

min_float <- 0
max_float <- 200
hist_breaks<- c(0,1,3,5,10,20,30,45,60,180)
hist_breaks_labels<-c('0 to 1', '1 to 3', '3 to 5', '5 to 10', '10 to 20', '20 to 30', '30 to 45', '45 to 60', '60 to 180')
hist_breaks_num_trips<-c(-.01,0,2,4,6,8,10,12,14,16,18,20,100)
hist_breaks_num_trips_labels<-c('0', '1-2', '3-4', '5-6', '7-8', '9-10', '11-12', '13-14', '14-16', '17-18', '19-20', '20-100')