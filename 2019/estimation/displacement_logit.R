#The codebook is checked in with these code files, named Combined_Codebook_022020.xlsx
library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)
library(fastDummies)
library(aod)

missing_codes <- c('Missing: Technical Error', 'Missing: Non-response', 'Missing: Skip logic', 'Children or missing')

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


missing_codes <- c('Missing: Technical Error', 'Missing: Non-response', 'Missing: Skip logic', 'Children or missing')
dbtable.person.query<- paste("SELECT *  FROM HHSurvey.v_persons_2017_2019")
hh_weight_name <- 'hh_wt_combined'


person_dt<-read.dt(dbtable.person.query, 'tablename')

res_factors<-c("prev_res_factors_forced", "prev_res_factors_housing_cost","prev_res_factors_income_change",
               "prev_res_factors_community_change")

person_dt<-drop_na(person_dt, res_factors)
# remove missing data
for(factor in res_factors){
  for(missing in missing_codes){
    person_dt<- subset(person_dt, get(res_factors) != missing)
  }
}

person_df <- setDF(person_dt)
person_df$displaced = 0
for (factor in res_factors){
  dummy_name<- paste(factor, ' dummy')
  print(dummy_name)
  person_df[person_df[factor]=='Selected', 'displaced']<-1
  
}


# dfs better for making dummy variables


person_df_dum <- dummy_cols(person_df)

vars_to_consider <- c('displaced', "hhincome_broad_Under $25,000", "hhincome_broad_$25,000-$49,999","res_type_Single-family house (detached house)","race_category_African-American, Hispanic, Multiracial, and Other",
                      "seattle_home_Home in Seattle",)
person_df_dum_short<-person_df_dum[vars_to_consider]
summary(person_df_dum_short)

#writeClipboard(names(person_df_dum))
writeClipboard(summary(person_df_dum))
displ_logit<- glm(displaced ~ `hhincome_broad_Under $25,000`+`hhincome_broad_$25,000-$49,999`+`res_type_Single-family house (detached house)`
                  +`vehicle_count_0 (no vehicles)`
                  +`hhincome_broad_$50,000-$74,999`
                  +`rent_own_Rent`
                  +`lifecycle_Household includes children under 5`
                  +`lifecycle_Household size = 1, Householder age 65+`
                  +`gender_Female`
                  +`employment_Not currently employed`
                  +`commute_mode_Bus (public transit)`
                  +`race_category_African-American, Hispanic, Multiracial, and Other`
                  +`race_category_Asian Only`
                  +`sample_county_King`
              ,data = person_df_dum, family = "binomial")
summary(displ_logit)