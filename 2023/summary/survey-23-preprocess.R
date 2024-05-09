
# get new labels associated with a group  
get_grouped_labels <- function(.value_labels = value_labels, group_id, group_name) {
  group_title <- paste0(group_id, '_title')
  group_value <- paste0(group_id, '_value')
  
  cols <- c('label', group_value)
  group_labels <- .value_labels[get(eval(group_title)) == group_name, ..cols]
  group_labels<-group_labels%>%distinct(label, .keep_all=TRUE)
  return(group_labels)
}


# function for grouping variable and adding it to the values list
add_values_code <- function(.group_labels = group_labels, .value_labels = value_labels, group_name) {

  names_labels <- names(.group_labels)
  group_id_value <- names_labels[grepl('group', names_labels)]

  v <- unique(.group_labels, by = group_id_value)
  v <- v[, value := .I][, .(variable = group_name, value, label = get(eval(group_id_value)))]

  new_cols <- map( c('title', 'value'), ~paste('group', 1:3, .x, sep = '_')) |> unlist()
  v[, (new_cols) := NA]

  new_val_labels <- rbindlist(list(.value_labels, v), fill=TRUE)
  new_val_labels[, val_order := .I]
  
  return(new_val_labels) 
}

grp_to_tbl <- function(tbl, .group_labels = group_labels, ungrouped_name, grouped_name) {
  tbl <- left_join(tbl, .group_labels, by = setNames('label', ungrouped_name))
  #find what the group id is based on the group_labels
  # find the group text based on the group_labels
  names_labels <- names(.group_labels)
  group_id_value <- names_labels[grepl('group', names_labels)]
  
  setnames(tbl, group_id_value, grouped_name)
  return(tbl)
}

order_factors<-function(tbl, variable_name, value_labels){
  var_val_labels<-value_labels%>%filter(variable==variable_name)
  tbl<-tbl%>%left_join(var_val_labels, by=join_by(!!sym(variable_name)==label))%>%
    arrange(val_order)%>%
    mutate({{variable_name}}:=factor(!!sym(variable_name), levels=unique(!!sym(variable_name))))
  return(tbl)
}

summarize_weighted <- function(hts_data, summarize_var, summarize_by, id_cols, wt_cols,wtname,summarize_vartype='categorical'){
  
  
  prepped_dt <- hts_prep_variable(summarize_var = summarize_var,
                                  summarize_by = summarize_by,
                                  data = hts_data,
                                  id_cols=id_cols,
                                  wt_cols=wt_cols,
                                  weighted=TRUE)
  
  if(summarize_vartype=='categorical'){
      summary<-hts_summary(prepped_dt = prepped_dt$cat,
                       summarize_var = summarize_var,
                       summarize_by = summarize_by,
                       summarize_vartype = summarize_vartype,
                       id_cols= id_cols,
                       wtname=wtname,
                       weighted=TRUE,
                       se=TRUE)
  }else{
    summary<-hts_summary(prepped_dt = prepped_dt$num,
                         summarize_var = summarize_var,
                         summarize_by = summarize_by,
                         summarize_vartype = summarize_vartype,
                         id_cols= id_cols,
                         wtname=wtname,
                         weighted=TRUE,
                         se=TRUE)
    
  }
  
  
  return(summary)
}

add_variable<-function(variable_list,variable_name, table_name, data_type='integer/categorical'){

  new_var_tbl<-
  data.table(
    variable = variable_name,
    is_checkbox = 0,
    hh = 0,
    person = 0,
    day = 0,
    trip = 0,
    vehicle = 0,
    location = 0,
    description = variable_name,
    logic = variable_name,
    data_type =data_type,
    shared_name = variable_name
  )
  
  new_var_tbl<-new_var_tbl%>%mutate({{table_name}}:=1)
  variable_list<-rbind(variable_list, new_var_tbl)
  
  
}
