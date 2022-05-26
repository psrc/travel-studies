library(psrc.travelsurvey)
library(dplyr)
library(stringr)
library(data.table)
library(tidyr)


library(psrc.travelsurvey)


hhts_stat <- function(df, stat_type, target_var, group_vars, geographic_unit=NULL, spec_wgt=NULL){
  vars <- c(geographic_unit, target_var, unlist(group_vars)) %>% unique()
  dyear <- df %>% setDT() %>% .[, .(survey_year)] %>% unique() %>% .[[1]]
  so <- hhts2srvyr(df, vars, spec_wgt) %>% dplyr::ungroup()
  prefix <- if(stat_type %in% c("count","share")){""}else{paste0(target_var,"_")}
  if(!is.null(group_vars)){
    so %<>% srvyr::group_by(dplyr::across(tidyselect::all_of(group_vars)))                         # Apply grouping
  }
  if(!is.null(geographic_unit)){so %<>% srvyr::group_by(!!as.name(geographic_unit), .add=TRUE)}
  if(stat_type=="count"){
    rs <- suppressMessages(
      cascade(so,
              count:=survey_total(na.rm=TRUE),
              share:=survey_prop()))
  }else if(stat_type=="summary"){
    rs <- suppressMessages(
      cascade(so, count:=survey_total(na.rm=TRUE),
              !!paste0(prefix,"total"):=survey_total(!!as.name(target_var), na.rm=TRUE),
              !!paste0(prefix,"median"):=survey_median(!!as.name(target_var), na.rm=TRUE),
              !!paste0(prefix,"mean"):=survey_mean(!!as.name(target_var), na.rm=TRUE)))
  }else{
    srvyrf_name <- as.name(paste0("survey_",stat_type))                                            # Specific srvyr function name
    rs <- suppressMessages(
      cascade(so,
              !!paste0(prefix, stat_type):=(as.function(!!srvyrf_name)(!!as.name(target_var), na.rm=TRUE))))
  }
  rs %<>% purrr::modify_if(is.factor, as.character) %>% setDT() %>%
    .[, grep("_se", colnames(.)):=lapply(.SD, function(x) x * 1.645), .SDcols=grep("_se", colnames(.))] %>%
    setnames(grep("_se", colnames(.)), stringr::str_replace(grep("_se", colnames(.), value=TRUE), "_se", "_moe"))
  if(!is.null(geographic_unit)){
    setcolorder(rs, c(geographic_unit))
    setorder(rs, geographic_unit, na.last=TRUE)
    rs[is.na(geographic_unit), (geographic_unit):="Region"]
  }
  if(!is.null(group_vars)){
    rs[, (group_vars):=lapply(.SD, function(x) {x[is.na(x)] <- "Total" ; x}), .SDcols=group_vars]
  }
  so %<>% dplyr::ungroup()
  return(rs)
}


hhts_count <- function(df, target_var=NULL, group_vars=NULL, geographic_unit=NULL, spec_wgt=NULL){
  rs <- hhts_stat(df=df, stat_type="count", target_var=NULL, group_vars=group_vars, geographic_unit=geographic_unit, spec_wgt=spec_wgt)
  return(rs)
}



w_cur <- get_hhts(dyear = 2021, level = 'p', vars = 'workplace')%>%drop_na('workplace')
w_cur_cnt <- hhts_count(w_cur, group_vars = 'workplace')