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

# # vars <- c("age", "transit_pass", "broadband")
# exc_vars <- c('survey_year', 'person_id', 'tripid')
# vars <- unique(variable_list$variable)[!(variable_list$variable %in% exc_vars)]
# 
# geogs <- c('Region', 'Seattle', "Bellevue")

# # tab 1 ----
# trends_df <- NULL
# 
# for(var in vars) {
#   for(geog in geogs) {
#   source_table <- variable_list[variable == var, .(variable, hh, person, day, trip)] |>
#     melt.data.table(id.vars = 'variable',
#                     measure.vars = c('hh', 'person', 'day', 'trip'),
#                     variable.name = 'table')
# 
#   weight_name <- source_table[value == 1,][['table']] |>
#     as.character() |>
#     paste0("_weight")
# 
#   if(geog != 'Region') {
#     households <- dfs$hh[home_jurisdiction == geog]
#   } else {
#     households <- dfs$hh
#   }
# 
#   summarize_df <- summarize_weighted(hts_data = list(hh = households, person = dfs$person, day = dfs$day, trip = dfs$trip),
#                                      summarize_var = var,
#                                      summarize_by = 'survey_year',
#                                      id_cols = ids,
#                                      wt_cols = wts,
#                                      wtname = weight_name) # weight name corresponds to table variable is from
# 
#   df <- summarize_df$summary$wtd[, `:=` (variable_name = var, geography = geog)]
# 
#   setnames(df, var, "value")
#   ifelse(is.null(trends_df), trends_df <- df, trends_df <- rbindlist(list(trends_df, df), fill=TRUE))
#   }
# }

# tab 2 ----
# matrix of every single variable combo...
n <- 2
vars <- c("age", "broadband", "transit_pass", "mode_1")
pairings <- lapply(numeric(n), function(x) vars)
combos <- as.data.table(expand.grid(pairings))
combos <- combos[Var1 != Var2, ]
geogs <- c('Seattle', "Bellevue", 'Region')

crosstab_df <- NULL

for(i in 1:nrow(combos)) {
  for(x in 1:length(geogs)) {
    
    v1 <- as.character(combos[i,][['Var1']])
    v2 <- as.character(combos[i,][['Var2']])
    
    source_table <- variable_list[variable %in% c(v1, v2), .(variable, hh, person, day, trip)] |>
      melt.data.table(id.vars = 'variable',
                      measure.vars = c('hh', 'person', 'day', 'trip'),
                      variable.name = 'table')
    
    weight_names <- source_table[value == 1,][['table']] |> unique() |> as.character()
    
    # evaluate weight hierarchy
    if(length(weight_names) > 1) {
      t <- 'trip' %in% weight_names
      
      if(t == TRUE) {
        weight_name <- 'trip'
      } else if(t == FALSE) {
        t <- 'person' %in% weight_names
        
        if(t == TRUE) {
          weight_name <- 'person'
        }
      }
    } else {
      weight_name <- weight_names
    }
    
    weight_name <- paste0(weight_name, "_weight")
    
    # filter dfs tables for current year (2023) & geography ----
    dfs_cyr <- copy(dfs)
    dfs_cyr <- map(dfs_cyr, ~.x[survey_year == current_year, ])
    
    ## filter relevant tables by geography ----
    if(geogs[x] != 'Region') {
      # filter hh table
      households <- dfs_cyr$hh[home_jurisdiction == geogs[x]]
      unique_hh_ids <- households[["household_id"]] |> unique()
      
      # which table(s) to filter based on weight_name; exclude hh table
      tables <- setdiff(weight_names, "hh")
      
      for(y in 1:length(tables)) {
        dfs_cyr[[tables[y]]] <- dfs_cyr[[tables[y]]][household_id %in% unique_hh_ids]
      }
      
      
    } else {
      households <- dfs_cyr$hh
    }
    
    summarize_df <- summarize_weighted(hts_data = list(hh = households, person = dfs_cyr$person, day = dfs_cyr$day, trip = dfs_cyr$trip),
                                       summarize_var = v1,
                                       summarize_by = v2,
                                       id_cols = ids,
                                       wt_cols = wts,
                                       wtname = weight_name) # weight name corresponds to table variable is from
    
    df <- summarize_df$summary$wtd[, `:=` (var1 = v1, var2 = v2, geography = geogs[x])]
    
    setnames(df, c(v1, v2), c('val1', 'val2'))
    ifelse(is.null(crosstab_df), crosstab_df <- df, crosstab_df <- rbindlist(list(crosstab_df, df), fill=TRUE))
    
  }
}

crosstab_df[, `:=` (category_1 = "Test1", category_2 = "Test2")]

# write.csv(crosstab_df, "T:\\2024May\\christy\\crosstab_df.csv", row.names = FALSE)
# write.csv(crosstab_df, "C:\\Users\\CLam\\github\\household-travel-survey-trends\\data\\crosstab_df.csv", row.names = FALSE)



