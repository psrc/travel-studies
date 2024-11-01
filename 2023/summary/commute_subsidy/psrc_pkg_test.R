
psrc_hts_stat <- function(hts_data, analysis_unit, group_vars=NULL, stat_var=NULL, incl_na=TRUE){
  options(survey.adjust.domain.lonely=TRUE)
  options(survey.lonely.psu="adjust")
  statvar <- grpvars <- found_idx <- found_tbl <- found_classes <- NULL
  found_dtype <- codebook_vars <- var_row <- newvars <- newrows <- NULL
  statvartype <- prepped_dt <- summary_dt <- NULL # For CMD check
  pk_id <- paste0(analysis_unit,"_id")
  if(is.null(stat_var)){                                                       # Separate last grouping var for counts   
    statvar <- group_vars[length(group_vars)]
    grpvars <- if(rlang::is_empty(group_vars[-length(group_vars)])){NULL}else{group_vars[-length(group_vars)]}
  }else{
    statvar <- stat_var
    grpvars <- group_vars 
  }
  if("survey_year" %not_in% grpvars){grpvars <- c("survey_year", grpvars)}
  # Helper function to add variable row to codebook         
  add_var <- function(var){
    found_idx <- lapply(hts_data, function(x) any(var %in% colnames(x))==TRUE) %>% unlist()
    if(is.null(found_idx)){
      NULL
    }else if(!is.null(found_idx)){
      found_tbl <- names(hts_data[found_idx])
      found_classes <- class(hts_data[[found_tbl]][[var]])
      found_dtype <- if("numeric" %in% found_classes){"numeric"
      }else if("Date" %in% found_classes){"date"    
      }else if(any(c("POSIXct","POSIXt") %in% found_classes)){"date-time" 
      }else if(any(c("character","factor") %in% found_classes)){"integer/categorical"
      }
      var_row <- data.frame(variable=var, 
                            is_checkbox=0, 
                            hh=     if('hh'      %in% found_tbl){1}else{0},
                            person= if('person'  %in% found_tbl){1}else{0},
                            day=    if('day'     %in% found_tbl){1}else{0},
                            trip=   if('trip'    %in% found_tbl){1}else{0},
                            vehicle=if('vehicle' %in% found_tbl){1}else{0},
                            location=0,
                            data_type=found_dtype,
                            description="Added",
                            shared_name=var)
      return(var_row)
    }
  }
  codebook_vars <- copy(init_variable_list) %>% setDT()                        # mutable copy
  newvars <- NULL                                                              # find any new variables
  newvars <- if(rlang::is_empty(setdiff(c(grpvars, statvar), codebook_vars$variable))){
    NULL
  }else{
    setdiff(c(grpvars, statvar), codebook_vars$variable) 
  }
  if(!is.null(newvars)){                                                       # add new variables to codebook
    newrows <- lapply(newvars, add_var) %>% rbindlist()
    codebook_vars %<>% rbind(newrows)
  }
  if(analysis_unit=="vehicle"){                                                # keep only tables relevant to analysis unit
    hts_data_relevant <- copy(hts_data)[c("hh","vehicle")]                     # for vehicle, hh is only other table
    codebook_vars %<>% .[(hh==1|vehicle==1)]
  }else{
    keep_range <- 1:(which(names(hts_data)==analysis_unit))                    # otherwise, keep hierarchically higher tables
    hts_data_relevant <- copy(hts_data)[{{ keep_range }}]                      # e.g. day keeps day, person, hh, but not trip
    filter_cols <- names(hts_data_relevant)
    codebook_vars %<>% .[.[, Reduce(`|`, lapply(.SD, `==`, 1)), .SDcols = filter_cols]] # filter variable list so prep doesn't complain
  }
  prepped_dt <- suppressMessages(
    travelSurveyTools::hts_prep_variable(
      summarize_var = statvar,
      summarize_by = grpvars,
      variables_dt = codebook_vars,
      data = hts_data_relevant,
      id_cols = paste0(names(hts_data_relevant),"_id"),
      wt_cols = paste0(names(hts_data_relevant),"_weight"),
      weighted = TRUE,
      remove_outliers = FALSE,
      remove_missing = !incl_na,
      strataname = "sample_segment")) %>% lapply(setDT) %>%
    lapply(unique, by=pk_id, na.rm=!incl_na)
  if(is.null(stat_var)){
    statvartype <- codebook_vars[variable==(statvar), data_type] %>% unique()
    if(incl_na==FALSE){prepped_dt$cat %<>% tidyr::drop_na()}
    pkgcond::suppress_warnings(
      summary_dt <- travelSurveyTools::hts_summary_cat(                          # count
        prepped_dt = prepped_dt$cat,                 
        summarize_var = statvar,
        summarize_by = grpvars,
        summarize_vartype = statvartype,
        weighted = TRUE,
        wtname = hts_wgt_var(analysis_unit),
        strataname = "sample_segment",
        se = TRUE,
        id_cols = pk_id),
      pattern="NAs introduced by coercion"
    )
  }else{
    if(incl_na==FALSE){prepped_dt$num %<>% tidyr::drop_na()}
    pkgcond::suppress_warnings(    
      summary_dt <- travelSurveyTools::hts_summary_num(                          # min/max/median/mean
        prepped_dt = prepped_dt$num,                 
        summarize_var = statvar,
        summarize_by = grpvars,
        weighted = TRUE,
        wtname = hts_wgt_var(analysis_unit),
        strataname = "sample_segment",
        se = TRUE),
      pattern="NAs introduced by coercion"
    )
  }
  summary_dt$wtd %<>%                                                          # convert se to moe
    .[, grep("_se$", colnames(.)):=lapply(.SD, function(x) x * 1.645), .SDcols=grep("_se$", colnames(.))] %>%
    setnames(grep("_se$", colnames(.)), stringr::str_replace(grep("_se$", colnames(.), value=TRUE), "_se$", "_moe"))
  return(summary_dt$wtd)
}
