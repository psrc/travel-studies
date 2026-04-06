#  Displacement - reclassifying'prev_res_factors_other' responses  
#  This script is meant to pull the HTS data for the most recent survey year in order to reclassify the open-ended responses. It generates an excel workbook that can be used by 2 or more reviewers to separately and collaboratively. The resulting excel file will need some manual formatting - easier to format the original tab and then copy for reviewer and difference tabs. For the reviewer tabs, a Comment column will be added and for the difference tab there is a formula, which is available in the previous survey year network project folder.  

# Libraries
library(travelSurveyTools)
library(psrcelmer)
library(tidyverse)
library(psrc.travelsurvey)
library(openxlsx)

# for output workbook
loc <- "J:/Projects/Surveys/HHTravel/Survey2025/Data/prev_res_factors"
workbook_name <- "prev_res_factors_other_2025.xlsx"

## Read in Data from Elmer

# Specify which variables to retrieve
# View(psrc.travelsurvey:::init_variable_list)

vars <- c(
  #household-level variables
  'household_id', 'res_dur', 'prev_home_wa',
  'prev_res_factors_amenities', 'prev_res_factors_community_change',
  'prev_res_factors_crime', 'prev_res_factors_employment', 
  'prev_res_factors_forced', 'prev_res_factors_hh_size', 
  'prev_res_factors_housing_cost', 'prev_res_factors_income_change', 
  'prev_res_factors_less_space', 'prev_res_factors_more_space', 
  'prev_res_factors_no_answer',  
  'prev_res_factors_quality', 'prev_res_factors_school', 
  'prev_res_factors_telework',
  'prev_res_factors_other','prev_res_factors_specify')

# Depending on the timing of this exercise, the psrc.travelsurvey package may or may not yet be updated with the most recent data - there are two workflows to retrieve data for this exercise:

# 1. Before psrc.travelsurvey package is updated with 2025 data, as long as the data is in Elmer -----

# list of table names and view names for each data table
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households','v_persons','v_days','v_trips','v_vehicles')
names(view_names) <- table_names

# Focus on the household view
hh_data_full <- get_query(sql= paste0("select * from HHSurvey.", view_names['hh']))

# Select the relevant variables
hh_data <- hh_data_full %>% 
  select(all_of(vars), survey_year)


# 2. After psrc.travelsurvey package is updated with 2025 data -----
# Retrieve the data
hts_data <- get_psrc_hts(survey_vars = vars)  # default includes all survey_years

# Focus on the household view 
hh_data <- hts_data$hh


# Once the data has been downloaded, it needs to be filtered: 
# Refine data set to households that moved within the past 5 years and moved within the state - only those who moved within the last 5 years should have been asked whether their previous home was in WA, but in 2023, there were some who had moved more than 5 years prior and they were still asked about previous home state - and those who selected that they moved for 'other' reasons, not provided
wa_movers_other <- hh_data %>% 
  filter(grepl("Yes", prev_home_wa),
         grepl("Less than|1 and 2 years|2 and 3 years|3 and 5 years", res_dur),
         prev_res_factors_other=="Selected")

table(wa_movers_other$survey_year)

# Further refine to movers from most recent survey year 
wa_movers_other_2025 <- wa_movers_other %>% 
  filter(survey_year==2025) %>% 
  select(-survey_year) # not needed in output file


# Save the data to the network project folder (J:\Projects\Surveys\HHTravel\Survey2025\Data)
# create list of tabs in workbook
list_of_datasets <- list("original" = wa_movers_other_2025
                         # "reviewer_1" = wa_movers_other_2025,
                         # "reviewer_2" = wa_movers_other_2025,
                         # "differences" = wa_movers_other_2025
                         )

# write excel workbook file
write.xlsx(list_of_datasets, file = file.path(loc, workbook_name),
           colNames = TRUE,
           overwrite = TRUE)
