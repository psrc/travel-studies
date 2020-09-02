## Read from Elmer
#assuming a conservative estimate for p for MOE
p_MOE <- 0.5
z<-1.645


db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\Sockeye",
                                database = "Elmer",
                                trusted_connection = "yes"
  )
}

read.dt <- function(astring, type =c('table_name', 'sqlquery')) {
  elmer_connection <- db.connect()
  if (type == 'table_name') {
    dtelm <- dbReadTable(elmer_connection, SQL(astring))
  } else {
    dtelm <- dbGetQuery(elmer_connection, SQL(astring))
  }
  dbDisconnect(elmer_connection)
  setDT(dtelm)
}

# Make a crosstab
#This function takes in the raw unweighted data for the summary and returns the final table with
# weighted data, margins of error and the sample counts.  
# This is the function that is doing all the heavy lifting for this code.
cross_tab <- function(table, var1, var2, wt_field, type, n_type_name) {
  # z <- 1.96 # 95% CI
  
  cols <- c(var1, var2)
 
  
  if (type == "dimension") {
    setkeyv(table, cols)
    table[table==""]<- NA

    cols <- c(var1, var2)
    table<-table[!is.na(get(wt_field))]
    raw <- table[, .(sample_count = .N), by = cols] 
    n_size_table <- table[, .(n_size = uniqueN(n_type_name)), by= c(var1, n_type_name)]
    n_size_ct<-n_size_table[,lapply(.SD, sum), .SDcols = 'n_size', by=var1]
    expanded <- table[, lapply(.SD, sum), .SDcols = wt_field, by = cols]
    expanded_tot <- expanded[, lapply(.SD, sum), .SDcols = wt_field, by = var1]
    setnames(expanded, wt_field, "Total")
    expanded <- merge(expanded, expanded_tot, by = var1)
    expanded[, Share := Total/get(eval(wt_field))]
    expanded <- merge(expanded, n_size_ct, by = var1)
    expanded[,p_col :=p_MOE] 
    expanded[, ("in") := (p_col*(1-p_col))/n_size][, MOE := z*sqrt(get("in"))]
    #expanded[, ("in") := (Share*(1-Share))/hhid][, MOE := z*sqrt(get("in"))][, N_HH := hhid]
    expanded$estMOE= expanded$MOE*expanded[[wt_field]]
    crosstab <- merge(raw, expanded, by = cols)
    crosstab <- dcast.data.table(crosstab, 
                                 get(eval(var1)) ~ get(eval(var2)), 
                                 value.var = c('sample_count', 'Total', 'estMOE','Share', 'MOE', 'n_size'))
    
  } else if (type == "fact") {
    cols = c(var1, var2, n_type_name, wt_field)
    var_weights <- table[, cols, with = FALSE]
    var_weights <- na.omit(var_weights)
    raw <- var_weights[, .(sample_count = .N), by = var1] 
    n_size<- var_weights[, .(n_size = uniqueN(n_type_name)), by = var1]
    var_weights<-var_weights[eval(parse(text=var2))>min_float]
    var_weights<-var_weights[eval(parse(text=var2))<max_float]
    var_weights[, weighted_Total := get(eval((wt_field)))*get(eval((var2)))]
    expanded <- var_weights[, lapply(.SD, sum), .SDcols = "weighted_Total", by = var1][order(get(eval(var1)))]
    expanded_tot <- var_weights[, lapply(.SD, sum), .SDcols = wt_field, by = var1]
    expanded_moe <- var_weights[, lapply(.SD, function(x) z*sd(x)/sqrt(length(x))), .SDcols = var2, by = var1][order(get(eval(var1)))]
    setnames(expanded_moe, var2, 'MOE')
    expanded <- merge(expanded, expanded_tot, by = var1)
    expanded <- merge(expanded, expanded_moe, by = var1)
    expanded[, mean := weighted_Total/get(eval(wt_field))]
    n_size<- merge(raw, n_size, by = var1)
    expanded <- merge(expanded, n_size, by = var1)
    #setnames(expanded, var1, 'var1')
    setnames(expanded, 'n_size', 'n')
    crosstab <- expanded
    
    
  }
  
  #setnames(crosstab, 'var1', var1)
  return(crosstab)
}


colClean <- function(x){ colnames(x) <- gsub("_", " ", colnames(x)); x } 
# This function reads a list of variables to summarize and returns the completed summarized tables.
# It calls the functions to munge and filter the data. 

summarize_cross_tables <-function(var_list1, var_list2, var3=FALSE, val3=FALSE, group1=FALSE, group2=FALSE){
  first = 1
  
  
  for(var1 in var_list1){
    for(var2 in var_list2){
      
      # find the table the variables are on
      table_type <- xtabTableType(var1, var2)$Res
      data_type <- xtabTableType(var1,var2)$Type
      # find which weight to use
      wt_field<- table_names[[table_type]]$weight_name
      
      
      region_recs<-get_xtabTable(var1, var2, 'Region', wt_field, table_type, var3, val3, group1)
      seattle_recs<-get_xtabTable(var1, var2, 'Seattle', wt_field, table_type, var3, val3, group1)
      
      region_tab<-cross_tab(region_recs, var1, var2, wt_field, data_type, group1, group2)
      seattle_tab<-cross_tab(seattle_recs, var1, var2, wt_field, data_type, group1, group2)
      
      tbl_output <-merge(region_tab, seattle_tab, 'var1', suffixes =c(' Region', ' Seattle'))  
      
      if(group1 == FALSE){
        vars1 <-variables.lu[variable==var1]
        var1_name <-unique(vars1[,variable_name])
      }
      else{
        vars1 <-variables.lu[variable==var1]
        var1_name <-paste(unique(vars1[,variable_name]), ' Group')
        setnames(tbl_output, 'var1', var1_name)
      }
      if(group2== FALSE){
        vars2 <-variables.lu[variable==var2]
        var2_name <-unique(vars2[,variable_name])
      }
      else{
        vars1 <-variables.lu[variable==var1]
        var1_name <-paste(unique(vars1[,variable_name]), ' Group')
        setnames(tbl_output, 'var2', var1_name)
      }
      
      if(val3==FALSE){
        file_name <- paste(var1_name,'_', var2_name,'.xlsx')
      }
      else{
        val3<-gsub('/', '_',val3)
        file_name <- paste(var1_name,'_', var2_name,'_', var3,'_', val3,'.xlsx')
      }
      
      
      
      Share_cols <- grep("^Share", names(tbl_output), value=T)
      est_cols <- grep("^Total", names(tbl_output), value=T)
      sample_cols <- grep("^sample_count", names(tbl_output), value=T)
      tbl_output[,(est_cols) := round(.SD,0), .SDcols=est_cols]
      
      
      s_cols <-c(Share_cols, est_cols, sample_cols)
      
      Share_tbl <- tbl_output[ , ..s_cols]
      Share_tbl <- colClean(Share_tbl) 
      #cols <- grep("^Share\|^sample\|MOE", names(tbl_output), value=T)
      #tbl_output <-tbl_output[, .SD, .SDcols = cols]
      file_ext<-file.path(file_loc, file_name)
      write.xlsx(tbl_output, file_ext, sheetName ="data", 
                 col.names = TRUE, row.names = FALSE, append = FALSE)
      
      file_name_Share<- paste('Share ', file_name, sep='')
      file_ext_Share<-file.path(file_loc, file_name_Share)
      
      write.xlsx(tbl_output, file_ext, sheetName ="data", 
                 col.names = TRUE, row.names = FALSE, append = FALSE)
      
      write.xlsx(Share_tbl, file_ext_Share, sheetName ="data", 
                 col.names = TRUE, row.names = FALSE, append = FALSE)
      
      
    }
  }
}