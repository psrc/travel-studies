library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)

## Read from Elmer

db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\Sockeye",
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

# Check list for the HHTS analysis.
# 
# 1.	Choose the variable/variables for analysis from HHTS.
# a.	Check the questions that might be relevant to the variable (read the questionnaire from the codebook)
# b.	Formulate the questions you would like to explore
# c.	Identify the tables that you need to work with
# 2.	Exploratory data analysis
# a.	Read in your data
# i.	Choose the variables that you are interested in exploring
# ii.	Read in the table with the variables that you are interested in
# b.	Check quality of the data
# i.	Check the data type of the analysis variable (numeric, categorical, etc)
# ii.	Create summary of the variables to see n() and variable's categories (in case it is string/categorical  variable) or basic statistics line min,max, median, mean (in case it is a numerical variable)
# iii.	Are there any NAs, NaNs, "Missed question", 0, or empty values in the variable of interest? How should we handle it?
#   iv.	Cross-check if the sum of the weights matches the total population/households in the region.
# v.	Do you need to recategorize the variables?
#   c.	Create a summary
# i.	Calculate a sample size, shares, etc.
# ii.	Calculate MOE
# iii.	Create plot if needed
# d.	Check if the results make sense/if the research questions were answered. If not, adjust the categories or use different variable or set of variables.


# 1.	Choose the variable/variables for analysis from HHTS.
## I am looking for persons by vehicle by purpose, for Wintana Miller by DKS.


#We're working on updating Kirkland's transportation impact fee and our looking for
#updated information on conversion factors for vehicle to person trips. 
#We're trying to match the land use data we have so we are looking for conversion factors for residential, commercial, office, industrial and education if possible. 
#Would that be something determined through the PSRC travel survey? The factors the city is currently using (Residential - 1.45; Retail/Service - 1.22, Office - 1.18; and Industrial - 1.09) are from Redmond's household travel survey from 2010.  If we can get more recent values, that would be great.  Let me know if that's something you can help with or if you can point me in the right direction, that would be helpful!


# 2.	Exploratory data analysis
# For this I will use the trips table.
# dbtable.trip <- "HHSurvey.v_trips_2017_2019", trip_wt_combined, mode_simple, and join the trips table to the parcels table.

sql.query <- paste("SELECT mode_simple, dest_parcel_dim_id, travelers_total, trip_wt_combined FROM HHSurvey.v_trips_2017_2019")
trips <- read.dt(sql.query, 'sqlquery')


parcel_data <- 'C:/Users/SChildress/Documents/HHSurvey/displace_estimate/parcels_urbansim.txt'
parcel_df<-read.table(parcel_data, header=TRUE, sep='')

land_use_type<-'C:/Users/SChildress/Documents/data_request/trip_rate/land_use_types.xlsx'
lu_type <- read.xlsx(land_use_type)


parcel_lu<- merge(parcel_df, lu_type, by.x='LUTYPE_P', by.y= 'land_use_type_id', all.x = TRUE)


#trips$parcel_id <- as.character(trips$dest_parcel_dim_id)
#parcel_lu$PARCELID <- as.character(parcel_lu$PARCELID)
#merging by the previous residence parcel from the person table and by the parcel id in the parcel table
trips_parcel<- merge(trips, parcel_df, by.x='dest_parcel_dim_id', by.y='PARCELID', all.x = TRUE)

aggregate(trips_parcel$trip_weight_combined, by=list(trips_parcel$mode_simple, trips_parcel$travelers_total, trips_parcel$Description), FUN=sum)

