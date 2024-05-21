# matrix of every single variable combo...
n <- 2
vars <- c("age", "broadband", "transit_pass", "mode_1", "rent_own")
pairings <- lapply(numeric(n), function(x) vars)
combos <- as.data.table(expand.grid(pairings))
combos <- combos[Var1 != Var2, ]
geogs <- c('Region', 'Seattle', "Bellevue")

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
      if(!("hh" %in% weight_names)) {
        tables <- setdiff(weight_names, "hh")
      } else {
        tables <- "hh"
      }
      
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
    
    # add labels
    v1_label <- variable_list[variable == v1, ][['description']]
    v2_label <- variable_list[variable == v2, ][['description']]
    
    df <- summarize_df$summary$wtd[, `:=` (var1 = v1, var2 = v2, geography = geogs[x])
    ][, `:=` (label1 = v1_label, label2 = v2_label)]
    
    setnames(df, c(v1, v2), c('val1', 'val2'))
    ifelse(is.null(crosstab_df), crosstab_df <- df, crosstab_df <- rbindlist(list(crosstab_df, df), fill=TRUE))
    
  }
}

# Add categories and calculate MOE
crosstab_df[, `:=` (category_1 = "Test1", category_2 = "Test2", survey_year = current_year)]

z_score <- 1.645 
crosstab_df[, `:=` (est_moe = z_score * est_se, prop_moe = z_score * prop_se)]


