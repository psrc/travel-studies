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

}

# Make a crosstab
#This function takes in the raw unweighted data for the summary and returns the final table with
# weighted data, margins of error and the sample counts.  
# This is the function that is doing all the heavy lifting for this code.
cross_tab <- function(table, var1, var2, wt_field, type, n_type_name) {
  # z <- 1.96 # 95% CI
  
  cols <- c(var1, var2)
 
  
  if (type == "dimension") {
    #setkeyv(table, cols)
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


write_cross_tab<- function(table, var1, var2, wt_field, type, n_type_name, file_loc){
  out_cross<-cross_tab(table, var1, var2, wt_field, type, n_type_name)
  
  file_name <- paste(var1,'_', var2,'.xlsx')
  file_ext<-file.path(file_loc, file_name)
  
  write.xlsx(out_cross, file_ext, sheetName ="data", 
             col.names = TRUE, row.names = FALSE, append = FALSE)
  
}