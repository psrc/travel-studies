
# get new labels associated with a group  
get_grouped_labels<-function(.value_labels=value_labels,group_id, group_name){
  
  group_title<-paste0(group_id, '_title')
  group_value<-paste0(group_id, '_value')
  
  group_labels   <- .value_labels%>%
  filter(!!sym(group_title) == group_name)%>%
  select('label', !!sym(group_value))

 
return(group_labels)
}


# function for grouping variable and adding it to the values list
add_values_code<- function(.group_labels=group_labels, .value_labels=value_labels, group_name){
  names_labels<-names(.group_labels)
  group_id_value<-names_labels[grepl('group', names_labels)]

  var_val_labels<- .group_labels%>%
    mutate(variable=group_name) %>%
    distinct(!!as.name(group_id_value), .keep_all=TRUE)%>%
    rowid_to_column(var='value')%>%
    select(variable, value, !!as.name(group_id_value))%>%
    rename(label=!!as.name(group_id_value))%>%
    mutate(group_1_title = NA, group_1_value = NA,
           group_2_title = NA, group_2_value= NA,
           group_3_title = NA, group_3_value = NA)
  
  all_value_labels<-.value_labels%>%select(variable, value, label, group_1_title, group_1_value,
                                      group_2_title, group_2_value, group_3_title, group_3_value)
  new_value_labels<-rbind(all_value_labels, var_val_labels)
  new_value_labels[, val_order := seq_len(nrow(new_value_labels))]
  new_value_labels<-setDT(new_value_labels)
  
  return(new_value_labels) 
}

grp_to_tbl<-function(.group_labels=group_labels, tbl, ungrouped_name, grouped_name){

  tbl <-left_join(tbl, .group_labels, by=setNames('label', ungrouped_name))
  #find what the group id is based on the group_labels
  # find the group text based on the group_labels
  names_labels<-names(.group_labels)
  group_id_value<-names_labels[grepl('group', names_labels)]
  
  setnames(tbl, group_id_value, grouped_name)
  return(tbl)
}





summarize_weighted<-function(hts_data, summarize_var, summarize_by, id_cols, wt_cols,wtname){
  
  
  prepped_dt <- hts_prep_variable(summarize_var = summarize_var,
                                  summarize_by = summarize_by,
                                  data = hts_data,
                                  id_cols=id_cols,
                                  wt_cols=wt_cols,
                                  weighted=TRUE)
  
  summary<-hts_summary(prepped_dt = prepped_dt$cat,
                       summarize_var = summarize_var,
                       summarize_by = summarize_by,
                       id_cols= id_cols,
                       wtname=wtname,
                       weighted=TRUE,
                       se=TRUE)
  
  return(summary)
}



  

