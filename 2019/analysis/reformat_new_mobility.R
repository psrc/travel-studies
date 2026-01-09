library(dplyr)
library(tidyr)
library(openxlsx)
folder<- 'J:/Projects/Surveys/HHTravel/Survey2019/Analysis/new_mobility/upd_tables'



file_names <- c('age_summary_tnc.csv',
                'age_summary_carshare.csv',
                 'income_summary_tnc.csv', 
                 'income_summary_carshare.csv',
                 'education_summary_tnc.csv',
                 'education_summary_carshare.csv',
                 'veh_count_summary_carshare.csv',
                  'veh_ownership_summary_tnc.csv'
                )

#file_names<-c('veh_ownership_summary_tnc.csv')
 
for (name in file_names){
    file_ext<-file.path(folder, name)
    
    tbl<-read.csv(file_ext)
    # summarize shares, category1, categor'y 2, perc_comb, pivot the table
    tbl$Share2017<-tbl$perc_2017/100
    tbl$Share2019<-tbl$perc_2019/100
    tbl$ChangeinPercent2017to2019<-tbl$delta/100
    
    share_positions <- c(2:3,14)
    shares <- tbl %>% select(all_of(share_positions))
    
    var2<-names(shares[2])
    pivot_shares<- shares%>%
                   pivot_wider(names_from=var2, values_from=c(Share2019))
    
    file_name_share <- paste(names(shares[1]),'_', names(shares[2]),'_share1.xlsx')
    file_ext_share<-file.path(folder, file_name_share)
    write.xlsx(pivot_shares, file_ext_share, sheetName ="data", 
               col.names = TRUE, row.names = FALSE, append = FALSE)
    
    # summarize change in category 1, category 2, percents delta, pivot the table
    

    delta_positions <- c(2:3,12:15)
    deltas <- tbl %>% select(all_of(delta_positions))
    
    var2<-names(deltas[2])
     pivot_delta<- deltas%>%
       pivot_wider(names_from=c(Share2017, Share2019,ChangeinPercent2017to2019), values_from=var2)
    
    
    
    # this isn't working and I'm not sure why
    #var1<-names(pivot_delta[1])
    #pivot_delta <- pivot_delta %>% filter(!!sym(var1) =='I never do this')
     # 
    file_name_delta <- paste(names(shares[1]),'_', names(shares[2]),'_delta1.xlsx')
    file_ext_delta<-file.path(folder, file_name_delta)
    write.xlsx(deltas, file_ext_delta, sheetName ="data", 
               col.names = TRUE, row.names = FALSE, append = FALSE)
    
}



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



# Code Examples -----------------------------------------------------------
#Read the data from Elmer

#You can do this by using read.dt function. The function has two arguments: 
# first argument passes a sql query or a table name (as shown in Elmer)
# in the second argument user should specify if the first argument is 'table_name' or 'sqlquery'

#Here is an example using sql query - first, you need to create a variable with the sql query
# and then pass this variable to the read.dt function
sql.query = paste("SELECT * FROM HHSurvey.v_persons_2017_2019_in_house")
person = read.dt(sql.query, 'sqlquery')

#If you would like to use the table name, instead of query, you can use the following code
#that will produce the same results
person = read.dt("HHSurvey.v_persons_2017_2019", 'table_name')


#Check the data
# this step will allow you to understand the variable and the table that you are analyzing
#you can use the following functions to check for missing values, categories, etc.

#this function will allow you to see all of the variables in the table, check the data type,
#and see the first couple of values for each of the variables
glimpse(person)

# to check the distribution of a specific variable, you can use the following code
#here, for example, we are looking at mode_freq_5 category 
person %>% group_by() %>% summarise(n=n())

#if you analyze a numerical variable, you can use the following code to see the variable range
describe()


#to delete NA you can use the following code
#the best practices suggest to create a new variable with the updated table

person_no_na = person %>% filter(!is.na(mode_freq_5))

#when we re-run the distribution code, we see that we've eliminated NAs
person_no_na %>% group_by(mode_freq_5) %>% summarise(n=n())

# to exclude missing codes, you can use the following code
#note, that we've assigned missing_codes at the beginning of the script(lines 20-21)
person_no_na = person_no_na %>% filter(!mode_freq_5 %in% missing_codes)



tnc<-create_table_one_var("mode_freq_5", person_no_na,"person" )

seattle_person <-person_no_na %>% filter(seattle_home=='Home in Seattle')

tnc_seattle<-create_table_one_var("mode_freq_5", seattle_person,"person" )

person_no_na = person_no_na %>% filter(!mode_freq_4 %in% missing_codes)



carshare<-create_table_one_var("mode_freq_4", person_no_na,"person" )

seattle_person <-person_no_na %>% filter(seattle_home=='Home in Seattle')

carshare_seattle<-create_table_one_var("mode_freq_4", seattle_person,"person" )

