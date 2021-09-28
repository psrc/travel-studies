source('travel_survey_analysis_functions.R')
library(tidyverse)
library(openxlsx)
library(odbc)
library(DBI)
library(data.table)
library(dplyr)
library(ggplot2)

#### Read in Data ####
#where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel_studies/2019/analysis"

#where you want to output tables
file_loc <- 'C:/Users/SChildress/Documents/HHSurvey/commuting'

sql.trip.query <- paste("SELECT hhincome_detailed, race_category, person_dim_id, mode_simple, 
                        survey_year, o_purpose, d_purpose, trip_wt_combined FROM HHSurvey.v_trips_2017_2019")
trips <- read.dt(sql.trip.query, 'sqlquery')



sql.person.query<-paste("SELECT employment,hhincome_broad, hhincome_detailed,race_category,person_dim_id, vehicle_count,commute_auto_time,
commute_auto_Distance, commute_mode, work_county, age, telecommute_freq, survey_year,
benefits_1, benefits_2, benefits_3, benefits_4, mode_freq_1,  mode_freq_2,  mode_freq_3, mode_freq_4, mode_freq_5, workplace, sample_county,
hh_wt_2019, hh_wt_revised, hh_wt_combined, workpass FROM HHSurvey.v_persons_2017_2019")

persons<-read.dt(sql.person.query, 'sqlquery')



# Who get transit pass subsidies from work?

person_wt_field<- 'hh_wt_combined'
person_count_field<-'person_dim_id'

persons_no_na<-persons %>% drop_na(all_of(person_wt_field))
persons_no_na_benefits<-persons_no_na %>% filter(benefits_3!='Missing: Non-response' & benefits_3!='Missing: Skip logic' )%>% 
  filter(benefits_3!='Missing: Non-response' & benefits_3!='Missing: Skip logic' )

var_to_summarize<- 'benefits_3'
group_cats <- c('hhincome_broad', 'work_county', 'telecommute_freq', 
'race_category','vehicle_count', 'mode_freq_1','commute_mode','age')

benefit3<-create_table_one_var(var_to_summarize,persons_no_na_benefits, 'person')




for(cat in group_cats){
  print(cat)
  cross_table<-cross_tab_categorical(persons_no_na,cat, var_to_summarize, person_wt_field)
  
  sample_size_group<- persons_no_na %>%
  group_by(.data[[cat]]) %>%
  summarize(sample_size = n_distinct((person_dim_id)))
  
  sample_size_MOE<- categorical_moe(sample_size_group)
  
  
  cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=cat)
  
  cross_table_w_MOE_long<-cross_table_w_MOE %>%
  pivot_longer(
    cols = starts_with("Percent"),
    names_to = "Transit_Subsidy",
    names_prefix = "Percentage_",
    values_to = "Percent",
    values_drop_na = TRUE
  )


  
  plt <- ggplot(data=cross_table_w_MOE_long, aes(x=Transit_Subsidy, y=Percent, fill=.data[[cat]])) +
    geom_bar(stat="identity", position="dodge") 
  file_name <- paste(cat,'_', var_to_summarize,'.pdf')
  file_ext<-file.path(file_loc, file_name)
  ggsave(file_ext)
  print(plt)
  write_cross_tab(cross_table_w_MOE,cat,var_to_summarize,file_loc)
}

## Who pays for parking at work?

person_wt_field<- 'hh_wt_2019'
person_count_field<-'person_dim_id'

persons_no_na<-persons %>% drop_na(all_of(person_wt_field))
persons_no_na<-persons_no_na %>% filter(benefits_3!='Missing: Non-response' & benefits_3!='Missing: Skip logic' )

var_to_summarize<- 'workpass'
group_cats <- c('hhincome_broad', 'work_county', 'telecommute_freq', 
                'race_category','vehicle_count', 'mode_freq_1','commute_mode','age')

workpass<-create_table_one_var(var_to_summarize,persons_no_na, 'person')




for(cat in group_cats){
  print(cat)
  cross_table<-cross_tab_categorical(persons_no_na,cat, var_to_summarize, person_wt_field)
  
  sample_size_group<- persons_no_na %>%
    group_by(.data[[cat]]) %>%
    summarize(sample_size = n_distinct((person_dim_id)))
  
  sample_size_MOE<- categorical_moe(sample_size_group)
  
  
  cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=cat)
  
  cross_table_w_MOE_long<-cross_table_w_MOE %>%
    pivot_longer(
      cols = starts_with("Percent"),
      names_to = "Transit_Subsidy",
      names_prefix = "Percentage_",
      values_to = "Percent",
      values_drop_na = TRUE
    )
  
  
  
  plt <- ggplot(data=cross_table_w_MOE_long, aes(x=Transit_Subsidy, y=Percent, fill=.data[[cat]])) +
    geom_bar(stat="identity", position="dodge") 
  file_name <- paste(cat,'_', var_to_summarize,'.pdf')
  file_ext<-file.path(file_loc, file_name)
  ggsave(file_ext)
  print(plt)
  write_cross_tab(cross_table_w_MOE,cat,var_to_summarize,file_loc)
}

