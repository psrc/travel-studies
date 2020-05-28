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
library(MASS)

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
                      'displaced', "hhincome_broad", 'race_category', 'education', 'age',
                      'age_category', 'numchildren', 'numadults', 'numworkers','lifecycle','prev_rent_own',
                      'prev_res_type','hhincome_detailed','res_dur', 'hhsize',
                      'vehicle_count', 'student', 'license','age_category', 'city_name', 'growth_center_name')


person_df_dis_sm <-person_df_dis[vars_to_consider]
person_df_dis_sm$college<- with(person_df_dis_sm,ifelse(education %in% c('Bachelor degree',
                                                                         'Graduate/post-graduate degree'), 'college', 'no_college'))

person_df_dis_sm$vehicle_group= 
with(person_df_dis_sm,ifelse(vehicle_count > numadults, 'careq_gr_adults', 'cars_less_adults'))
person_df_dis_sm$rent_or_not= 
  with(person_df_dis_sm,ifelse(prev_rent_own == 'Rent', 'Rent', 'Not Rent'))

person_df_dis_sm$seattle= 
  with(person_df_dis_sm,ifelse(city_name=='Seattle', 'Seattle', 'Not Seattle'))

person_df_dis_sm$rgc= 
  with(person_df_dis_sm,ifelse(growth_center_name!='', 'rgc', 'not_rgc'))



person_df_dis_sm$sf_house<-with(person_df_dis_sm,ifelse(prev_res_type == 'Single-family house (detached house)', 'Single Family House', 'Not Single Family House'))

person_df_dis_sm$has_children= 
  with(person_df_dis_sm,ifelse(numchildren>1, 'children', 'no children'))

person_df_dis_sm$wrker_group= 
         with(person_df_dis_sm,ifelse(numworkers==0, 'no workers', 'are workers'))

person_df_dis_sm$size_group= 
  with(person_df_dis_sm,ifelse(hhsize>=3, 'hhsize_3ormore', 'hhsize_2orless'))

person_df_dis_sm$age_group= 
  with(person_df_dis_sm,ifelse(age_category=='65 years+', '65+ years', 'less than 65'))

person_df_dis_sm$moved_lst_yr= 
  with(person_df_dis_sm,ifelse(res_dur=='Less than a year', 'Moved Last Year', 'Moved 1-5 years ago'))

person_df_dis_sm$hhincome_mrbroad <- person_df_dis_sm$hhincome_broad
person_df_dis_sm$hhincome_mrbroad[person_df_dis_sm$hhincome_broad== '$50,000-$74,999']<-'50,000-$99,999'
person_df_dis_sm$hhincome_mrbroad[person_df_dis_sm$hhincome_broad== '$75,000-$99,999']<-'50,000-$99,999'

person_df_dis_sm[sapply(person_df_dis_sm, is.character)] <- lapply(person_df_dis_sm[sapply(person_df_dis_sm, is.character)], 
                                       as.factor)
y_big<-vars_to_consider[!vars_to_consider %in% "displaced"]

less_vars<-c('displaced', "hhincome_mrbroad", 
            'rent_or_not',
             'vehicle_group', 'sf_house', 'age_group','moved_lst_yr', 'size_group',
            "white","poor_english","dist_super",
            'seattle')
            # "rent","cost_burdened")
            # , 
            # "severe_cost_burdened","poverty_200"	,
            # "ln_jobs_auto_30", "ln_jobs_transit_45", "transit_qt_mile","transit_2025_half",
            # "dist_super", "dist_pharm", "dist_rest","dist_park",	"dist_school",
            # "prox_high_inc",	"at_risk_du","voting")  
x_sm<-less_vars[!less_vars %in% "displaced"]
person_df_ls<-person_df_dis_sm[less_vars]




                                                  
            # "dist_pharm",                                                     
            # "dist_rest",                                                       
            # "dist_park",                                                      
            #  "dist_school"
            #"transit_2025_half")

    
displ_logit<-glm(reformulate(x_sm,'displaced'), data=person_df_ls,
                 family = 'binomial')
summary(displ_logit, correlation= TRUE)
# less_vars<-c('displaced',
#              "hhincome_detailed",          
#              "dist_super")
# person_df_ls<-person_df_dis_sm[less_vars]
#                               
#  # using the bma library to select variables
x<-person_df_ls[, !names(person_df_ls) %in% c('displaced')]
y<-person_df_ls$displaced

glm.out <- bic.glm(x, y, strict = FALSE, OR = 20,
                        glm.family="binomial", factor.type=TRUE)
summary(glm.out)
imageplot.bma(glm.out)
