


# function for grouping variable and adding it to the values list
add_values_code<- function(group_labels, value_labels,var_grp_name,group_id_value){

  var_val_labels<- group_labels%>%
                   mutate(variable=var_grp_name) %>%
                   distinct(!!sym(group_id_value), .keep_all=TRUE)%>%
                   rowid_to_column(var='value')%>%
                   select(variable, value, sym(group_id_value))%>%
                   rename(label=sym(group_id_value))%>%
                   mutate(group_1_title = NA, group_1_value = NA,
                          group_2_title = NA, group_2_value= NA,
                          group_3_title = NA, group_3_value = NA)
  
  value_labels<-value_labels%>%select(variable, value, label, group_1_title, group_1_value,
                                      group_2_title, group_2_value, group_3_title, group_3_value)
  new_value_labels<-rbind(value_labels, var_val_labels)
  new_value_labels[, val_order := seq_len(nrow(new_value_labels))]
  new_value_labels<-setDT(new_value_labels)
    
 return(new_value_labels) 
}
  
    


  



summarize_weighted<-function(hts_data, summarize_var, summarize_by, id_cols, wt_cols){
  
  
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
                             wtname=wt_cols,
                             weighted=TRUE,
                             se=TRUE)
  
    return(summary)
}
