# set IDs to characters
set_id_as_character <- function(tbl, id_cols=c("survey_year", "hh_id", "person_id", "day_id", "trip_id")){
  cols <- intersect(colnames(tbl) ,id_cols )
  return(
    tbl[, (cols) := lapply(.SD, function(x) as.character(x)), .SDcols = cols]
    )
}


new_add_variable <- function(variables_dt = variable_list, variable_name, table_name, data_type='integer/categorical'){
  
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
           !!grouping_name  := !!sym(group_value)) %>% 
    distinct()
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

get_hts_summary <- function(dt_list, summary_var, variables_dt = variable_list, id_var, wt_var){
  
  prepped_dt <- hts_prep_variable(summarize_var = summary_var[length(summary_var)],
                                  summarize_by = summary_var[-length(summary_var)],
                                  variables_dt = variables_dt,
                                  data = dt_list,
                                  id_cols=id_var,
                                  wt_cols=wt_var,
                                  weighted=TRUE)
  summary_dt <- hts_summary(prepped_dt = prepped_dt$cat,
                            summarize_var = summary_var[length(summary_var)],
                            summarize_by = summary_var[-length(summary_var)],
                            summarize_vartype = 'categorical',
                            id_cols = id_var,
                            wtname = wt_var,
                            weighted= TRUE,
                            se= TRUE)
  
  return(summary_dt$summary$wtd)
  
}
