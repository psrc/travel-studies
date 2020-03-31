# The R version of travel_crosstab.py

library(data.table)
library(tidyverse)

xtabTableType <- function(var1, var2){
  select.vars <- variables.lu[variable %in% c(var1, var2), ]
  tables <- as.vector(unique(select.vars$table_name))
  dtypes <- as.vector(unique(select.vars$dtype))
  
  if('Trip' %in% tables){
    res<-'Trip'
  } else if('Person' %in% tables){
    res<-'Person'
  }else{
    res<-'Household'
  }
  
  
  if('fact' %in% dtypes){
    type<- 'fact'
  }
  else{
    type<-'dimension'
  }
  
  return(list(Res=res, Type=type))
} 

# return list of tables subsetted by value types
xtabTable <- function(var1, var2, sea_reg){
  table.type<- xtabTableType(var1, var2)$Res
  wt_field<- table_names[[table.type]]$weight_name
  
  if(var1=='weighted_trip_count' || var2=='weighted_trip_count'){
    # use a special weight here because trip counts are a weird case
    wt_field <-hh_day_weight_name
  }
  
  sql.query <- paste("SELECT seattle_home, hhid,", var1,",",var2, ",", wt_field, "FROM", table_names[[table.type]]$table_name)
  survey <- read.dt(sql.query, 'sqlquery')
  
  type <- xtabTableType(var1, var2)$Type
  
  if (sea_reg== 'Seattle') survey <- survey[seattle_home == 'Home in Seattle',]
  
  crosstab <-cross_tab(survey, var1, var2, wt_field, type)
  xvals <- xtabXValues()[, .(value_order, value_text)]
  
  crosstab <- merge(crosstab, xvals, by.x='var1', by.y='value_text')
  setorder(crosstab, value_order)
  return(crosstab)
}


stabTableType <- function(var1) {
  select.vars <- variables.lu[variable %in% c(var1), ]
  tables <- unique(select.vars$table_name) 
  dtypes <- as.vector(unique(select.vars$dtype)) 
  
  if('Trip' %in% tables){
    res<-'Trip'
  } else if('Person' %in% tables){
    res<-'Person'
  }else{
    res<-'Household'
  }
  
  if('fact' %in% dtypes){
    type<- 'fact'
  }
  else{
    type<-'dimension'
  }
  
  return(list(Res=res, Type=type))
} 

# return list of tables subsetted by value types
stabTable <- function(var1, sea_reg){
table.type <- stabTableType(var1)$Res
wt_field<- table_names[[table.type]]$weight_name

if(var1=='weighted_trip_count' ){
  # use a special weight here because trip counts are a weird case
  wt_field <-hh_day_weight_name
}

sql.query <- paste("SELECT seattle_home, hhid,", var1,",", wt_field, "FROM" , table_names[[table.type]]$table_name)
survey <- read.dt(sql.query, 'sqlquery')
type <- stabTableType(var1)$Type

if (sea_reg== 'Seattle') survey <- survey[seattle_home == 'Home in Seattle',]


simtable <- simple_table(survey, var1, wt_field, type)
return(simtable)
}



# create_cross_tab_with_weights
cross_tab <- function(table, var1, var2, wt_field, type) {
  # z <- 1.96 # 95% CI
 

  print("reading in data")

  cols <- c(var1, var2)

  if (type == "dimension") {
    setkeyv(table, cols)
    table[table==""]<- NA
    for(missing in missing_codes){
       table<- subset(table, get(var1) != missing)
       table<- subset(table, get(var2) != missing)
     }    
    table <- na.omit(table, cols = cols)
    table<-table[!is.na(get(wt_field))]
    raw <- table[, .(sample_count = .N), by = cols] 
    N_hh <- table[, .(hhid = uniqueN(hhid)), by = var1]
    expanded <- table[, lapply(.SD, sum), .SDcols = wt_field, by = cols]
    expanded_tot <- expanded[, lapply(.SD, sum), .SDcols = wt_field, by = var1]
    setnames(expanded, wt_field, "estimate")
    expanded <- merge(expanded, expanded_tot, by = var1)
    expanded[, share := estimate/get(eval(wt_field))]
    expanded <- merge(expanded, N_hh, by = var1)
    expanded[, ("in") := (share*(1-share))/hhid][, MOE := z*sqrt(get("in"))][, N_HH := hhid]
    expanded$estMOE= expanded$MOE*expanded[[wt_field]]
    crosstab <- merge(raw, expanded, by = cols)
    crosstab <- dcast.data.table(crosstab, 
                                 get(eval(var1)) ~ get(eval(var2)), 
                                 value.var = c('sample_count', 'estimate', 'estMOE','share', 'MOE', 'N_HH'))
    
  } else if (type == "fact") {
    cols = c(var1, var2, 'hhid', wt_field)
    var_weights <- table[, cols, with = FALSE]
    for(missing in missing_codes){
      var_weights<- subset(var_weights, get(var1) != missing)
      var_weights<- subset(var_weights, get(var2) != missing)
    }  
    var_weights <- na.omit(var_weights)
    raw <- var_weights[, .(sample_count = .N), by = var1] 
    N_hh <- var_weights[, .(hhid = uniqueN(hhid)), by = var1]
    var_weights<-var_weights[eval(parse(text=var2))>min_float]
    var_weights<-var_weights[eval(parse(text=var2))<max_float]
    var_weights[, weighted_total := get(eval((wt_field)))*get(eval((var2)))]
    expanded <- var_weights[, lapply(.SD, sum), .SDcols = "weighted_total", by = var1][order(get(eval(var1)))]
    expanded_tot <- var_weights[, lapply(.SD, sum), .SDcols = wt_field, by = var1]
    expanded_moe <- var_weights[, lapply(.SD, function(x) z*sd(x)/sqrt(length(x))), .SDcols = var2, by = var1][order(get(eval(var1)))]
    setnames(expanded_moe, var2, 'MOE')
    expanded <- merge(expanded, expanded_tot, by = var1)
    expanded <- merge(expanded, expanded_moe, by = var1)
    expanded[, mean := weighted_total/get(eval(wt_field))]
    N_hh <- merge(raw, N_hh, by = var1)
    expanded <- merge(expanded, N_hh, by = var1)
    setnames(expanded, var1, 'var1')
    setnames(expanded, 'hhid', 'N_HH')
    crosstab <- expanded
    print(crosstab)
  }
 
  return(crosstab)
}

simple_table <- function(table, var, wt_field, type) {
  z <- 1.645
  


  if (type == "dimension") {
    setkeyv(table, var)
    table[table==""]<- NA
    for(missing in missing_codes){
      table<- subset(table, get(var) != missing)
    }
    table <- na.omit(table, cols = var)
    raw <- table[, .(sample_count = .N), by = var]
    N_hh <- table[, .(hhid = uniqueN(hhid)), by = var]
    table<-table[!is.na(get(wt_field))]
    expanded <- table[, lapply(.SD, sum), .SDcols = wt_field, by = var]
    expanded_tot <- expanded[, lapply(.SD, sum), .SDcols = wt_field][[eval(wt_field)]]
    print(expanded_tot)
    setnames(expanded, wt_field, "estimate")
    expanded[, share := estimate/eval(expanded_tot)]
    expanded <- merge(expanded, N_hh, by = var)
    expanded[, ("in") := (share*(1-share))/hhid][, MOE := z*sqrt(get("in"))][, N_HH := hhid]
    expanded$total <- sum(expanded$estimate)
    expanded$estMOE = expanded$MOE * expanded$total
    s_table <- merge(raw, expanded, by = var)
  
  }
  else if(type == "fact") {
    # rework this because really the cuts are just acting as the variables
    # I think this can have the same logic as the code above.
    setkeyv(table, var)
    table[table==""]<- NA
    for(missing in missing_codes){
      table<- subset(table, get(var) != missing)
    }
    cols<- c(var, wt_field)
    table <- na.omit(table)
    if(var == 'weighted_trip_count'){
      breaks<- hist_breaks_num_trips
      hist_labels <- hist_breaks_num_trips_labels
    }
    else{
      table <- table[eval(parse(text=var))>min_float]
      table <- table[eval(parse(text=var))<max_float]
      breaks<- hist_breaks
      hist_labels<- hist_breaks_labels
    }
    
    var_breaks <- table[, cuts := cut(eval(parse(text=var)),breaks,labels=hist_labels, order_result=TRUE,)]
    # to do: find a way to pull out this hard code

    
    N_hh <-table[,.(hhid = uniqueN(hhid)), by = cuts]
    raw <- table[, .(sample_count = .N), by = cuts]
    var_cut <-var_breaks[, lapply(.SD, sum), .SDcols = wt_field, by = cuts]
    setnames(var_cut, wt_field, "estimate")
    var_cut$total <- sum(var_cut$estimate)
    var_cut[, share := estimate/total]
    var_cut<- merge(var_cut, N_hh, by = 'cuts')
    var_cut[, ("in") := (share*(1-share))/hhid][, MOE := z*sqrt(get("in"))][, N_HH := hhid]
    var_cut$estMOE = var_cut$MOE * var_cut$total
    var_cut<- merge(raw, var_cut, by = 'cuts')
    s_table<-setnames(var_cut, 'cuts',var)
  }
  
return(s_table)  
}



