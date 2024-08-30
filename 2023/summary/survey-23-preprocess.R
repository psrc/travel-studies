
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

summarize_weighted <- function(hts_data, summarize_var, summarize_by = NULL, id_cols, wt_cols,wtname,summarize_vartype='categorical'){
  
  
  prepped_dt <- hts_prep_variable(summarize_var = summarize_var,
                                  summarize_by = summarize_by,
                                  data = hts_data,
                                  id_cols=id_cols,
                                  wt_cols=wt_cols,
                                  weighted=TRUE,
                                  remove_missing=TRUE)

  
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
  print(new_var_tbl)
  variable_list<-rbind(variable_list, new_var_tbl)
  
  
}


# Add associated values to value table
new_value_tbl <- function(variable_name_list, variable_value_list,order_start = 0){
  
  len <- length(variable_name_list)-1
  
  add_value_tbl <- data.frame(variable = variable_name_list,
                              value = c(0:len),
                              label = variable_value_list,
                              val_order = c(order_start:(order_start+len)),
                              group_1_title = NA,
                              group_1_value = NA,
                              group_2_title = NA,
                              group_2_value = NA,
                              group_3_title = NA,
                              group_3_value = NA)
}

# Add variables from existing grouping
get_var_grouping <- function(value_tbl, group_number, grouping_name){
  
  group_title <- paste0("group_",group_number,"_title")
  group_value <- paste0("group_",group_number,"_value")
  #TODO: fix value order
  value_order_start <- max(value_tbl[,c("val_order")]) +1
  
  grouping_tbl <- value_tbl %>% 
    filter(!!sym(group_title) == grouping_name)
  
  variable_name <- unname(unlist(grouping_tbl[1,c("variable")]))
  group_name <- unname(unlist(grouping_tbl[1,c(group_title)]))
  
  grouping_value <- grouping_tbl %>%
    select(all_of(c("label", group_value))) %>%
    rename(!!variable_name := label,
           !!grouping_name  := !!sym(group_value))
  distinct_value <- grouping_tbl %>%
    select(all_of(c(group_title, group_value))) %>% 
    distinct()
  
  add_value_tbl <- new_value_tbl(distinct_value[[group_title]],distinct_value[[group_value]], value_order_start)
  
  final <- list(add_value_tbl,grouping_value)
  
  return(final)
}

# Add custom variable 
create_custom_variable <- function(value_tbl, variable_name,label_vector){
  
  value_order_start <- max(value_tbl[,c("val_order")]) +1
  add_value_tbl <- new_value_tbl(rep(variable_name, times=length(label_vector)),label_vector, value_order_start)
  
  return(add_value_tbl)
}

add_variable_to_data <- function(hts_data, value_map) {
  
  ungroup_name <- names(value_map)[1]
  group_name <- names(value_map)[2]
  
  tbl <- hts_data %>% left_join(value_map, by = ungroup_name)
  
  return(tbl)
}



