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