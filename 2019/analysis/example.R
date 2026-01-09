library(tidyverse)
library(openxlsx)
library(odbc)
library(DBI)
library(dplyr)


# Statistical assumptions for margins of error
p_MOE <- 0.5
z<-1.645

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



sql.household.query <- paste("SELECT hhid, vehicle_count, numworkers,hh_wt_combined FROM HHSurvey.v_households_2017_2019")
households <- read.dt(sql.household.query, 'sqlquery')

unique(households$vehicle_count)
households$vehicle_count_int<-recode(households$vehicle_count,  "0 (no vehicles)" = "0", "10 or more vehicles" = "10")
unique(households$vehicle_count_int)

households$vehicle_count_int<-as.numeric(households$vehicle_count_int)
unique(households$vehicle_count_int)
unique(households$numworkers)


hh<-households %>%  mutate(hh_veh_access = case_when(vehicle_count_int < numworkers ~ "Limited Access",
                                                  vehicle_count_int == numworkers ~ "Equal",
                                                  vehicle_count_int > numworkers ~ "Good Access",
                                                  TRUE ~ "No Category"))

hh_veh_acc_wrkrs <- cross_tab_categorical(hh, 'hh_veh_access', 'numworkers', 'hh_wt_combined')