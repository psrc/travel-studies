# This file has functions to help organize and summarize
# one-way and two-way tables from a household travel survey.

# One-Way tables####
#Functions to summarize and compile simple one-way tables

# This function identifies two things about a selected variable: the table it is on, and the type of data it is,
# either a category (dimension) or numeric value(fact). It returns a list of the table and the data type.
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

#This function takes in the raw unweighted data for the summary and returns the final table with
# weighted data, margins of error and the sample counts.  
# This is the function that is doing all the heavy lifting for this code.
simple_table <- function(table, var, wt_field, type) {
  
  # removing all NAs, and data with a missing code.
  # We may want to make this be an optional argument of whether to remove NAs
  # First take care of making tables for dimensional/categorical data.
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
    # Getting weighted totals
    expanded <- table[, lapply(.SD, sum), .SDcols = wt_field, by = var]
    expanded_tot <- expanded[, lapply(.SD, sum), .SDcols = wt_field][[eval(wt_field)]]
    print(expanded_tot)
    setnames(expanded, wt_field, "estimate")
    #Calculating weighted shares
    expanded[, share := estimate/eval(expanded_tot)]
    expanded <- merge(expanded, N_hh, by = var)
    # Initial calculation for margin of error, z* in=MOE
    expanded[, ("in") := (share*(1-share))/hhid][, MOE := z*sqrt(get("in"))][, N_HH := hhid]
    expanded$total <- sum(expanded$estimate)
    expanded$estMOE = expanded$MOE * expanded$total
    s_table <- merge(raw, expanded, by = var)
    return(s_table)
    
  }
  # Numeric data has different calculations somewhat
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
    
    # This code is basically the same as the dimensional code
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


# This function queries out the necessary data from the database to do the summary, including
# the correct weight, which subset of households (either Seattle or regional), and returns the data records
# needed to summarize the weighted and unweighted data.

get_sTable <- function(var1, sea_reg, wt_field, table_type){
  sql.query <- paste("SELECT seattle_home, hhid,", var1,",", wt_field, "FROM" , table_names[[table_type]]$table_name)
  survey <- read.dt(sql.query, 'sqlquery')
  
  if (sea_reg== 'Seattle'){
    survey <- survey[seattle_home == 'Home in Seattle',]}
  survey<- survey[ , !'seattle_home']
  return(survey)
}

#

# This function reads a list of variables to summarize and returns the completed summarized tables.
# It calls the functions to munge and filter the data. 
summarize_simple_tables <-function(var_list){
  first = 1
  
  for(var in var_list){
    # find the table the variable is on
    table_type <- stabTableType(var)$Res
    data_type <- stabTableType(var)$Type
    # find which weight to use
    wt_field<- table_names[[table_type]]$weight_name
    
    if(var=='weighted_trip_count' ){
      # use a special weight here because trip counts are a weird case
      wt_field <-hh_day_weight_name
    }
    
    # get all the variable data weights, for the region
    region_recs<-get_sTable(var, 'Region', wt_field, table_type)
    seattle_recs<-get_sTable(var, 'Seattle', wt_field, table_type)

    #do the number crunching to get the weighted data, counts, and MOEs
    region_tab<- simple_table(region_recs, var, wt_field, data_type)
    seattle_tab<- simple_table(seattle_recs, var, wt_field, data_type)
    
    #merge the seattle data and regional data to get a single table
    tbl_output <-merge(region_tab, seattle_tab, by=var, suffixes =c(' Region', ' Seattle'))  
    vars <-variables.lu[variable==var]
    var_name <-unique(vars[,variable_name])
    # Clean up variable names
    setnames(tbl_output, var, var_name)
    #share_fields <-c(var_name, paste('share', 'Region'), paste('share', 'Seattle'))
    #tbl_output <- tbl_output[, ..share_fields]
    #setnames(tbl_output,'share Region', paste(var_name,'share Region') )
    #setnames(tbl_output,'share Seattle', paste(var_name,'share Seattle'))
    #cols <- grep("^share\|^sample\|^MOE", names(tbl_output), value=T)
    #tbl_output <-tbl_output[, .SD, .SDcols = cols]
    file_name <- paste(var_name,'.xlsx', sep='')
    file_ext<-file.path(file_loc, file_name)
    write.xlsx(tbl_output, file_ext, sheetName ="data", 
               col.names = TRUE, row.names = FALSE, append = FALSE)
    print(tbl_output)
  }
}


# Two-way Tables #####


# This function identifies two things about two selected variables: 
# the tables they are on, and which one takes precedence in determining weights.
# Then it determines whether the data
# is either a category (dimension) or numeric value(fact). It returns a list of the table which will be
# used and the data type.
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
#
# return list of tables subsetted by value types

# This function queries out the necessary data from the database to do the summary, including
# the correct weight, which subset of households (either Seattle or regional), and returns the data records
# needed to summarize the weighted and unweighted data.

get_xtabTable <- function(var1, var2, sea_reg, wt_field, table_type, var3 = FALSE, value3=FALSE){
    if(var1=='weighted_trip_count' || var2=='weighted_trip_count'){
    # use a special weight here because trip counts are a weird case
    wt_field <-hh_day_weight_name
    }
  # when you are only summarizing two variables
  if(var3==FALSE){
    sql.query <- paste("SELECT seattle_home, hhid,", var1,",",var2, ",", wt_field, "FROM", table_names[[table_type]]$table_name)
    survey <- read.dt(sql.query, 'sqlquery')
  }
  # to summarize three dimensions
  else{
  sql.query <- paste("SELECT seattle_home, hhid,", var1,",",var2, ",", wt_field, "FROM", table_names[[table_type]]$table_name,
                     "WHERE ", var3, "=")
  sql.query<-paste(sql.query,'\'', value3,'\'', sep='')
  }
  
  survey <- read.dt(sql.query, 'sqlquery')

  
  if (sea_reg== 'Seattle'){
    survey <- survey[seattle_home == 'Home in Seattle',]
  }
  return(survey)
}


#This function takes in the raw unweighted data for the summary and returns the final table with
# weighted data, margins of error and the sample counts.  
# This is the function that is doing all the heavy lifting for this code.
cross_tab <- function(table, var1, var2, wt_field, type) {
  # z <- 1.96 # 95% CI

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
    #setnames(expanded, var1, 'var1')
    setnames(expanded, 'hhid', 'N_HH')
    crosstab <- expanded
    

  }
  
  setnames(crosstab, 'var1', var1)
  return(crosstab)
}


# This function reads a list of variables to summarize and returns the completed summarized tables.
# It calls the functions to munge and filter the data. 

summarize_cross_tables <-function(var_list1, var_list2, var3=FALSE, val3=FALSE){
  first = 1
  
  for(var1 in var_list1){
    for(var2 in var_list2){
      
      # find the table the variables are on
      table_type <- xtabTableType(var1, var2)$Res
      data_type <- xtabTableType(var1,var2)$Type
      # find which weight to use
      wt_field<- table_names[[table_type]]$weight_name
      
      
      region_recs<-get_xtabTable(var1, var2, 'Region', wt_field, table_type, var3, val3)
      seattle_recs<-get_xtabTable(var1, var2, 'Seattle', wt_field, table_type, var3, val3)
      
      region_tab<-cross_tab(region_recs, var1, var2, wt_field, data_type)
      seattle_tab<-cross_tab(seattle_recs, var1, var2, wt_field, data_type)
      

      tbl_output <-merge(region_tab, seattle_tab, var1, suffixes =c(' Region', ' Seattle'))  
      vars1 <-variables.lu[variable==var1]
      var1_name <-unique(vars1[,variable_name])
      setnames(tbl_output, var1, var1_name)
      vars2 <-variables.lu[variable==var2]
      var2_name <-unique(vars2[,variable_name])
      if(val3==FALSE){
      file_name <- paste(var1_name,'_', var2_name,'.xlsx')
      }
      else{
      val3<-gsub('/', '_',val3)
      file_name <- paste(var1_name,'_', var2_name,'_', var3,'_', val3,'.xlsx')
      }
      #cols <- grep("^share\|^sample\|MOE", names(tbl_output), value=T)
      #tbl_output <-tbl_output[, .SD, .SDcols = cols]
      file_ext<-file.path(file_loc, file_name)
      write.xlsx(tbl_output, file_ext, sheetName ="data", 
                 col.names = TRUE, row.names = FALSE, append = FALSE)
      print(tbl_output)
    }
  }
}
