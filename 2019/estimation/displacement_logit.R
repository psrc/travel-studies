#The codebook is checked in with these code files, named Combined_Codebook_022020.xlsx
library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)
library(fastDummies)
library(aod)
library(BMA)

displ_index_data<- 'C:/Users/SChildress/Documents/HHSurvey/displace_estimate/displacement_risk_estimation.csv'

missing_codes <- c('Missing: Technical Error', 'Missing: Non-response', 
                   'Missing: Skip logic', 'Children or missing')

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


dbtable.person.query<- paste("SELECT *  FROM HHSurvey.v_persons_2017_2019_displace_estimation")
hh_weight_name <- 'hh_wt_combined'

displ_risk_df <- read.csv(displ_index_data)

person_dt<-read.dt(dbtable.person.query, 'tablename')

res_factors<-c("prev_res_factors_forced", "prev_res_factors_housing_cost","prev_res_factors_income_change",
               "prev_res_factors_community_change", "prev_home_wa")



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


#prev_home_taz_2010
person_df$census_2010_tract <- as.character(person_df$census_2010_tract)
person_df$displa <- as.character(person_df$census_2010_tract)

person_df_dis <- merge(person_df,displ_risk_df, by.x='census_2010_tract', by.y='GEOID', all.x=TRUE)


vars_to_consider <- c('displaced', "white","poor_english","no_bachelors","rent","cost_burdened", 
                      "severe_cost_burdened","poverty_200"	,
                      "ln_jobs_auto_30", "ln_jobs_transit_45", "transit_qt_mile","transit_2025_half",
                       "dist_super", "dist_pharm", "dist_rest","dist_park",	"dist_school",
                      "prox_high_inc",	"at_risk_du","voting",
                      'displaced', "hhincome_broad", 'race_category', 'education', 
                      'age_category', 'numchildren', 'numadults', 'numworkers','lifecycle','prev_rent_own',
                      'prev_res_type','hhincome_detailed','res_dur', 'hhsize',
                      'vehicle_count', 'student', 'license')

person_df_dis_sm <-person_df_dis[vars_to_consider]
dummy_col_names<-c("hhincome_broad", 'race_category', 'education', 
                   'age_category', 'numchildren', 'numadults', 'numworkers','lifecycle','prev_rent_own',
                   'prev_res_type','hhincome_detailed','res_dur', 'hhsize',
                   'vehicle_count', 'student', 'license')
person_df_dum <- dummy_cols(person_df_dis_sm, select_columns=dummy_col_names)



less_vars<-c("`hhincome_detailed_Under $10,000`",
             "`hhincome_detailed_$10,000-$24,999`",
             "`hhincome_detailed_$25,000-$34,999`",                              
            "`hhincome_detailed_$35,000-$49,999`",                              
             "`hhincome_detailed_$50,000-$74,999`",                               
            "`hhincome_detailed_$75,000-$99,999`" ,                              
            "`hhincome_detailed_Prefer not to answer`",
             "transit_qt_mile" ,                                                
             "transit_2025_half",                                             
             "dist_super",                                                     
            "dist_pharm",                                                     
            "dist_rest",                                                       
            "dist_park",                                                      
             "dist_school")
            
            
            
#             "`race_category_African-American, Hispanic, Multiracial, and Other`",
#             "`race_category_Asian Only`" ,
#             "`ln_jobs_auto_30`",
#             "`ln_jobs_transit_45`"           
# )
 
 person_df_dum_ls<-person_df_dum[less_vars]
 
 displ_logit<-glm(reformulate(less_vars,'displaced'), data=person_df_dum,
                           family = 'binomial')
 summary(displ_logit)

 
 
 # playing with the estimation manually
 # displ_logit<- glm(displaced ~ `hhincome_detailed_Under $10,000` +`hhincome_detailed_$10,000-$24,999`     
 #                   + `hhincome_detailed_$25,000-$34,999`+`hhincome_detailed_$50,000-$74,999`+
 #                     `hhincome_detailed_$75,000-$99,999`
 #                   +`race_category_African-American, Hispanic, Multiracial, and Other`
 #                   +`race_category_Asian Only`
 #                   ,data = person_df_dum, family = "binomial")
 # summary(displ_logit)
                              
 # using the bma library to select variables
 x<-person_df_dum[, !names(person_df_dum) %in% c('displaced')]
 y<-person_df_dum$displaced

 glm.out <- bic.glm(x, y, strict = FALSE, OR = 20,
                       glm.family="binomial", factor.type=TRUE)
 summary(glm.out)
 imageplot.bma(glm.out)
