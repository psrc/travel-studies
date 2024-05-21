library(data.table)
library(travelSurveyTools)
library(psrcelmer)
library(psrcplot)
library(tidyverse)
library(openxlsx)

source(here::here('2023/summary/survey-23-preprocess.R'))

current_year <- 2023

# ## Read in Codebook
# cb_path <- here::here("2023/summary/shiny/PSRC_Codebook_2023_for_shiny.xlsx")
# 
# codebook <- map(list('variable_list', 'value_labels'), ~setDT(readxl::read_xlsx(cb_path, sheet = .x)))
# 
# variable_list <- as.data.table(codebook[[1]])
# value_labels <- as.data.table(codebook[[2]])

# ## Read hhts tables
# dataset_types <- c("household", "person", "day", "trip") # 
# 
# hh_sql <- "select * from HHSurvey.v_households_labels"
# person_sql <- "select * from HHSurvey.v_persons_labels"
# day_sql <- "select * from HHSurvey.v_days_labels"
# trip_sql <- "select * from HHSurvey.v_trips_labels"
# 
# dfs <- map(c(hh_sql, person_sql, day_sql, trip_sql), ~setDT(get_query(sql = .x))) #,


#load the rda file
load(file = here::here("2023/summary/shiny/start_data.rda"))

names(dfs) <- dataset_types

## Set IDs as characters
change_cols <- c(paste(dataset_types, 'id', sep = "_"), 'survey_year')

for(i in 1:length(dfs)) {
  
  if(names(dfs[i]) == 'household') {
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

names(dfs)[[1]] <- "hh"
ids <- c('household_id', 'person_id', 'day_id', 'trip_id')
wts <- c('hh_weight', 'person_weight', 'day_weight', 'trip_weight')

# tab 1 ----
# source(here::here('2023/summary/shiny/create-trends-table.R'))

# tab 2 ----
source(here::here('2023/summary/shiny/create-crosstab-table.R'))
write.csv(crosstab_df, "T:\\2024May\\christy\\crosstab_df.csv", row.names = FALSE)
write.csv(crosstab_df, "C:\\Users\\CLam\\github\\household-travel-survey-trends\\data\\crosstab_df.csv", row.names = FALSE)