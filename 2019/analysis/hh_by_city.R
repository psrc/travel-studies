
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
  
  sample_w_MOE<- select(sample_w_MOE, -c(p_col, MOE_calc1))

  return(sample_w_MOE)
  }   
 

#write out crosstabs
write_cross_tab<-function(out_table, var1, var2, file_loc){
 
  file_name <- paste(var1,'_', var2,'.xlsx')
  file_ext<-file.path(file_loc, file_name)
  write.xlsx(out_table, file_ext, sheetName ="data", 
             col.names = TRUE, row.names = FALSE, append = FALSE)
  
}


# Two-way table -----------------------------------------------------------

sql.query = paste("SELECT * FROM HHSurvey.v_households_2019_current_city")
hh = read.dt(sql.query, 'sqlquery')
# This is an example of how to create a two-way table, including counts, weighted totals, shares, and margins of error.
# The analysis is for race of a person by whether they have a driver's license or permit.

# First before you start calcuating
# you will need to determine the names of the data fields you are using, 
# the weight to use, and an id for counting.

# User defined variables on each analysis:

# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# this is a field to count the number of records
hh_count_field<-'hh_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hhincome_broad'
# this is the second thing you want to summarize by
var <- 'city_name'

# filter data missing weights
hh_no_na<-hh %>% drop_na(all_of(hh_wt_field))

# now find the sample size of your subgroup
sample_size_group<- hh_no_na %>%
  group_by(hhincome_broad) %>%
  summarize(sample_size = n())

# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)

# calculate totals and shares
cross_table<-cross_tab_categorical(hh_no_na,group_cat,var,hh_wt_field)

# merge the cross tab with the margin of error
cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=group_cat)

cross_table_w_MOE
# optional step:  write it out to a file
file_loc <- 'C:/Users/SChildress/Documents/GitHub/travel-studies/2019/analysis'

write_cross_tab(cross_table_w_MOE,group_cat,var,file_loc)
