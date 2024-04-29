library(data.table)
library(travelSurveyTools)
library(psrcelmer)
library(psrcplot)
library(tidyverse)
library(openxlsx)

source(here::here('2023/summary/survey-23-preprocess.R'))

## Read in Codebook
cb_path <- here::here("2023/summary/shiny/PSRC_Codebook_2023_for_shiny.xlsx")

codebook <- map(list('variable_list', 'value_labels'), ~setDT(readxl::read_xlsx(cb_path, sheet = .x)))

variable_list <- as.data.table(codebook[[1]])
value_labels <- as.data.table(codebook[[2]])


## Read hhts tables
dataset_types <- c("household", "person", "day", "trip") # 

hh_sql <- "select * from HHSurvey.v_households_labels"
person_sql <- "select * from HHSurvey.v_persons_labels"
day_sql <- "select * from HHSurvey.v_days_labels"
trip_sql <- "select * from HHSurvey.v_trips_labels"

dfs <- map(c(hh_sql, person_sql, day_sql, trip_sql), ~setDT(get_query(sql = .x))) #,
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

test_variables <- c("age", "transit_pass", "broadband")
trends_df <- NULL

for(var in test_variables) {
  source_table <- variable_list[variable == var, .(variable, hh, person, day, trip)] |>
    melt.data.table(id.vars = 'variable',
                    measure.vars = c('hh', 'person', 'day', 'trip'),
                    variable.name = 'table')
  
  weight_name <- source_table[value == 1,][['table']] |> 
    as.character() |> 
    paste0("_weight")
  
  summarize_df <- summarize_weighted(hts_data = dfs,
                                     summarize_var = var,
                                     summarize_by = 'survey_year',
                                     id_cols = ids,
                                     wt_cols = wts,
                                     wtname = weight_name) # weight name corresponds to table variable is from
  
  df <- summarize_df$summary$wtd[, variable_name := var]
  setnames(df, var, "value")
  ifelse(is.null(trends_df), trends_df <- df, trends_df <- rbindlist(list(trends_df, df), fill=TRUE))
}


