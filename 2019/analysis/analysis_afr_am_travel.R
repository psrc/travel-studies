source('analysis_functions.R')
library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)
library(dplyr)



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


# In this analysis, I would like to redo everything that I had done for the
# travel-studies\2019\analysis\outputs\race_summaries_no_afr_am.xlsx, but
# with details for African American People especially

# I would like to recategorize the race groups into these buckets:
# African-American, Non-African-American Person of Color, Non-Hispanic White
# The variables I'm interested in are:
# 'vehicle_count'
#'mode_simple'
#'('commute_auto_time'), c('commute_auto_distance'))
#'mode_freq_1', 'mode_freq_'..'mode_freq_5'
#''wbt_transitmore_1'..3, 'wbt_bikemore_1'


# where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel_studies/2019/analysis"

#where you want to output tables
file_loc <- 'C:/Users/SChildress/Documents/HHSurvey/race_story/afr_am'

sql.trip.query <- paste("SELECT race_category, person_dim_id, mode_simple, trip_wt_combined FROM HHSurvey.v_trips_2017_2019")
trips <- read.dt(sql.trip.query, 'sqlquery')

sql.person.query<-paste("SELECT race_category,person_dim_id, vehicle_count,commute_auto_time,
commute_auto_Distance, mode_freq_1,  mode_freq_2,  mode_freq_3, mode_freq_4, mode_freq_5,
wbt_transitmore_1, wbt_transitmore_2, wbt_transitmore_3, wbt_bikemore_1, wbt_bikemore_2, wbt_bikemore_3,
hh_wt_combined FROM HHSurvey.v_persons_2017_2019")



persons<-read.dt(sql.person.query, 'sqlquery')

# First explore a new category for race.

persons %>% group_by(race_category) %>% count()
persons$afr_am_race_category<-persons$race_category

persons<-persons %>%
  mutate(afr_am_race_category=ifelse(afr_am_race_category %in% c('Asian', 'Hispanic'), 
                                     'Asian or Hispanic', afr_am_race_category))

persons<-persons %>%
  mutate(afr_am_race_category=ifelse(afr_am_race_category %in% c('Child','Missing', 'Other', 'Child, Missing, Other'), 
                                     'Child, Missing, Other', afr_am_race_category))


persons %>% group_by(afr_am_race_category) %>% count()

# Auto Ownership
#cross_tab <- function(table, var1, var2, wt_field, type, n_type_name)
persons<-as.data.table(persons)

auto_own<-cross_tab(persons, 'afr_am_race_category', 'vehicle_count','hh_wt_combined','dimension', 'person_dim_id')
