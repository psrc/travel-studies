

hhts_connect <- function(connection=NULL){
    if(!is.null(connection)) return(connection)
    con <- DBI::dbConnect(odbc::odbc(),
                          driver = "ODBC Driver 17 for SQL Server",
                          server = "AWS-PROD-SQL\\Sockeye",
                          database = "Elmer",
                          trusted_connection = "yes",
                          port = 1433)
  }




get_hhts_no_weights <- function(survey, level, vars, ...){
  db_connection <- hhts_connect()
  abbr <- tbl_ref <- NULL
  dyears<-survey%>% as.list() %>% lapply(as.integer) %>% unlist()

  
  sql_hhts_lookup <- data.frame(
    abbr    =c("h","p","t","d","v","households","persons","trips","days","vehicles"),
    tbl_ref =rep(c("HHSurvey.v_households",
                   "HHSurvey.v_persons",
                   "HHSurvey.v_trips",
                   "HHSurvey.v_days",
                   "HHSurvey.v_vehicles"),2)) %>% setDT()
    sql_tbl_ref <- sql_hhts_lookup[abbr==level, .(tbl_ref)][[1]]
    want_vars <- c(unlist(vars)) 
    sql_code <- paste0("SELECT survey_year, ",
                       paste(want_vars, collapse=", "), " FROM ",sql_tbl_ref,                      # Build query for only relevant variables
                       " WHERE survey_year IN(", paste(unique(dyears), collapse=", "),");")
                                                                    # Recode NULL
    df <- DBI::dbGetQuery(db_connection, DBI::SQL(sql_code))  
    print(sql_code)
    DBI::dbDisconnect(db_connection)
    return(df) 
}

category_shares<- function(tbl, var_name){

  tbl_counts<-tbl%>%
    group_by(survey_year, !!!syms(var_name))%>%
    summarise(n=n())%>%
    mutate(share= n/sum(n))
  
  tbl_wide<- tbl_counts%>%select(survey_year, share, !!!syms(var_name))%>%
    mutate(share=percent(share))%>%
    pivot_wider(names_from= survey_year, values_from=share)
  print(tbl_wide)
  
  return(tbl_counts)

}

category_shares_wide<- function(tbl, var_name){
  
  tbl_counts<-tbl%>%
    group_by(survey_year, !!!syms(var_name))%>%
    summarise(n=n())%>%
    mutate(share= n/sum(n))
  
  tbl_wide<- tbl_counts%>%select(survey_year, share, !!!syms(var_name))%>%
    mutate(share=percent(share))%>%
    pivot_wider(names_from= survey_year, values_from=share)
  print(tbl_wide)
  
  return(tbl_wide)
  
}


category_totals_wide<- function(tbl, var_name){
  
  tbl_counts<-tbl%>%
    group_by(survey_year, !!!syms(var_name))%>%
    summarise(n=n())%>%
    mutate(share= n/sum(n))
  
  tbl_wide<- tbl_counts%>%select(survey_year, n, !!!syms(var_name))%>%
    pivot_wider(names_from= survey_year, values_from=n)
  print(tbl_wide)
  
  return(tbl_wide)
  
}


one_var_compare<-function(df, dfname, id, var_name){
  #id=!!ensym(id)
  #var_name=!!ensym(var_name)
  
  df_cols<-df%>%select(!!ensym(id), !!ensym(var_name))
  vals<- values%>%filter(variable==sym(var_name))
  df_cols<-df_cols%>%
    left_join(vals, by=join_by(!!ensym(var_name)==value))
  df_summary<-df_cols%>%
    group_by(final_label)%>%
    count()
  df_summary<-df_summary%>%
    rename(!!quo_name(dfname):=n)
}


lookup_names<-function(df, dfname, id,var_name){

  
  df_cols<-df%>%select(!!ensym(var_name))
  vals<- values%>%filter(variable==sym(var_name))%>%mutate(char_value=as.character(value))
  df_cols<-df_cols%>%
    left_join(vals, by=join_by(!!ensym(var_name)==value))

  df_summary<-df_cols%>%
    select(final_label)%>%rename(!!ensym(var_name):=final_label)
  
  df_summary
}

  
