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


