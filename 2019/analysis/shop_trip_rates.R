
# Load Libraries ----------------------------------------------------------

library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)
library(psych)


# Functions ----------------------------------------------------------------


## Read from Elmer

# Statistical assumptions for margins of error
p_MOE <- 0.5
z<-1.645
missing_codes <- c('Missing: Technical Error', 'Missing: Non-response', 
                   'Missing: Skip logic', 'Children or missing', ' Prefer not to answer')

# connecting to Elmer
db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\Sockeye",
                                database = "Elmer",
                                trusted_connection = "yes"
  )
}

# a function to read tables and queries from Elmer
read.dt <- function(astring, type =c('table_name', 'sqlquery')) {
  elmer_connection <- db.connect()
  if (type == 'table_name') {
    dtelm <- dbReadTable(elmer_connection, SQL(astring))
  } else {
    dtelm <- dbGetQuery(elmer_connection, SQL(astring))
  }
  dbDisconnect(elmer_connection)
  dtelm
}


#Create a crosstab from one variable, calculate counts, totals, and shares,
# for categorical data
create_table_one_var = function(var1, table_temp,table_type ) {
  #table_temp = recategorize_var_upd(var2,table_temp)
  #print(table_temp)
  if (table_type == "household" | table_type == "person" ) {
    weight_2017 = "hh_wt_revised"
    weight_2019 = "hh_wt_2019"
    weight_comb = "hh_wt_combined"
  } else if (table_type == "trip") {
    weight_2017 = "trip_weight_revised"
    weight_2019 = "trip_wt_2019"
    weight_comb = "trip_wt_combined"  
  } 
  
  temp = table_temp %>% select(!!sym(var1), all_of(weight_2017), all_of(weight_2019), all_of(weight_comb)) %>% 
    filter(!.[[1]] %in% missing_codes, !is.na(.[[1]])) %>% 
    group_by(!!sym(var1)) %>% 
    summarise(n=n(),sum_wt_comb = sum(.data[[weight_comb]],na.rm = TRUE),sum_wt_2017 = sum(.data[[weight_2017]],na.rm = TRUE),sum_wt_2019 = sum(.data[[weight_2019]],na.rm = TRUE)) %>% 
    mutate(perc_comb = sum_wt_comb/sum(sum_wt_comb)*100, perc_2017 = sum_wt_2017/sum(sum_wt_2017)*100, perc_2019 = sum_wt_2019/sum(sum_wt_2019)*100,delta = perc_2019-perc_2017) %>% 
    ungroup() %>%  mutate(MOE=1.65*(0.25/sum(n))^(1/2)*100) %>% arrange(desc(perc_comb))
  return(temp)
}

#Create a crosstab from two variables, calculate counts, totals, and shares,
# for categorical data
cross_tab_categorical <- function(table, var1, var2, wt_field) {
  expanded <- table %>% 
    group_by(.data[[var1]],.data[[var2]]) %>%
    summarize(Count= n(),Total=sum(.data[[wt_field]])) %>%
    group_by(.data[[var1]])%>%
    mutate(Percentage=Total/sum(Total)*100)
  
  expanded_pivot <-expanded%>%
    pivot_wider(names_from=.data[[var2]], values_from=c(Percentage,Total, Count))
  
  return (expanded_pivot)
  
} 

# Create margins of error for dataset
categorical_moe <- function(sample_size_group){
  sample_w_MOE<-sample_size_group %>%
    mutate(p_col=p_MOE) %>%
    mutate(MOE_calc1= (p_col*(1-p_col))/sample_size) %>%
    mutate(MOE_Percent=z*sqrt(MOE_calc1))
  
  return(sample_w_MOE)
}   


#write out crosstabs
write_cross_tab<-function(out_table, var1, var2, file_loc){
  
  file_name <- paste(var1,'_', var2,'.xlsx')
  file_ext<-file.path(file_loc, file_name)
  write.xlsx(out_table, file_ext, sheetName ="data", 
             col.names = TRUE, row.names = FALSE, append = FALSE)
  
}

# first calculate total trips
#d_purp_cat
# by gender , as an example
# gender

#where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel_studies/2019/analysis"

#where you want to output tables
file_loc <-  "C:/Users/SChildress/Documents/GitHub/travel_studies/2019/analysis/shop_trips.csv"

trip.query = paste("SELECT * FROM HHSurvey.v_trips_2017_2019")
trips = read.dt(trip.query, 'sqlquery')

#  total shopping trips by gender
shop_trips <- trips %>% filter(d_purp_cat=='Shop')

# total estimated average weekday shopping trips
sum(shop_trips$trip_wt_combined)

shop_trips_gender<-create_table_one_var('gender', shop_trips, 'trip') 

#
person.query = paste("SELECT * FROM HHSurvey.v_persons_2017_2019")
person = read.dt(person.query, 'sqlquery')

people_gender<-create_table_one_var('gender', person, 'person') 

shop_trips_2<-merge(shop_trips_gender, people_gender, by='gender')

days<-paste("SELECT * FROM HHSurvey.v_days_2017_2019_in_house")
person_days=read.dt(days, 'sqlquery')

#hh_day_wt_combined
person_days_2<-merge(person_days, person, by.x='personid', by.y='person_dim_id')

person_day_gender <- person_days_2 %>% group_by(gender) %>%
                      summarize(n=n(), day_combined = sum(hh_day_wt_combined.x))

shop_trips_3 <- merge(shop_trips_2, person_day_gender, by = 'gender')
write.csv(shop_trips_3, 'shop_trips_w_diff_wts.csv')