# Add grouping variables to codebook

# Variables that need grouping:
# telework_time: use group_2, group_2_value: telework_time_broad
# gender: gender_grp group_1
# telecommute_freq: telecommute_freq_simple: group_1-- this variable is confusing right now, need some digging
# dest_purpose: dest_purpose_simple, group_1
# mode: mode_simple, group_1

library(data.table)
library(travelSurveyTools)
library(psrcelmer)
library(psrcplot)
library(tidyverse)
library(openxlsx)
source('survey-23-preprocess.R')
source('preprocess-codebook-metadata.R')

## Read in Codebook
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/codebook/PSRC_Combined_Codebook_2023_packagable.xlsx"

codebook <- map(list('variable_list', 'value_labels'), ~setDT(readxl::read_xlsx(cb_path, sheet = .x)))
names(codebook) <- c('vars_list', 'val_labels')

## Read hhts tables
dataset_types <- c("hh", "person", "day", "trip")

hh_sql <- "select household_id as hh_id, hhincome_broad, survey_year, hh_weight from HHSurvey.v_households_labels"
person_sql <- "select household_id as hh_id,race_category, person_id, workplace, telecommute_freq, survey_year, person_weight, gender, age, industry 
                from HHSurvey.v_persons_labels"
day_sql <- "select person_id, day_id, household_id as hh_id, telework_time, day_weight , survey_year from HHSurvey.v_days_labels"
trip_sql <- "select trip_id, household_id as hh_id, day_id, person_id, mode_1, dest_purpose, survey_year, trip_weight from HHSurvey.v_trips_labels"

dfs <- map(c(hh_sql, person_sql, day_sql, trip_sql), ~setDT(get_query(sql = .x)))
names(dfs) <- dataset_types

## Set IDs as characters
change_cols <- c(paste(dataset_types, 'id', sep = "_"), 'survey_year')

for(i in 1:length(dfs)) {
  
  if(names(dfs[i]) == 'hh') {
    cols <- change_cols[c(1, 5)]
  } else if(names(dfs[i]) == 'person') {
    cols <- change_cols[c(1, 2, 5)]
  } else if(names(dfs[i]) == 'day') {
    cols <- change_cols[c(-4)]
  } else if(names(dfs[i]) == 'trip') {
    cols <- change_cols
  }
  
  dfs[[i]][, (cols) := lapply(.SD, as.character), .SDcols = cols]
}


# append to codebook ----

## append to variables list
codebook$vars_list <- rbind(codebook$vars_list, new_groups)

## join new grouping variables to datasets 
my_list <- list(value_labels = codebook$val_labels, 
                group_id = 'group_1', 
                group_name = 'gender_grp', 
                tbl = 'person', 
                ungrouped_name = 'gender')

my_list2 <- list(value_labels = codebook$val_labels, 
                 group_id = 'group_2', 
                 group_name = 'telework_time_broad', 
                 tbl = 'day', 
                 ungrouped_name = 'telework_time')

my_list3 <- list(value_labels = codebook$val_labels, 
                 group_id = 'group_1', 
                 group_name = 'mode_simple', 
                 tbl = 'trip', 
                 ungrouped_name = 'mode_1')

my_list4 <- list(value_labels = codebook$val_labels, 
                 group_id = 'group_1', 
                 group_name = 'telecommute_freq_simple', 
                 tbl = 'person', 
                 ungrouped_name = 'telecommute_freq')

lists <- str_subset(ls(all.names = TRUE), "my_list.*")
my_lists <- map(lists, ~get(.x))

rm(list = lists)

for(i in 1:length(my_lists)) {
  group_labels <- get_grouped_labels(.value_labels = codebook$val_labels, 
                                     group_id = my_lists[[i]][['group_id']],
                                     group_name = my_lists[[i]][['group_name']])
  
  # update values list in codebook
  codebook$val_labels <- add_values_code(.value_labels = codebook$val_labels, 
                                         .group_labels = group_labels,
                                         group_name = my_lists[[i]][['group_name']])
  
  dfs[[my_lists[[i]][['tbl']]]] <- grp_to_tbl(.group_labels = group_labels,
                                              tbl = dfs[[my_lists[[i]][['tbl']]]],
                                              ungrouped_name = my_lists[[i]][['ungrouped_name']],
                                              grouped_name = my_lists[[i]][['group_name']])
}

# export codebook or dfs
# names(codebook) <- c('variable_list', 'value_labels')
# write.xlsx(codebook, paste0("codebook_", Sys.Date(), ".xlsx"))







