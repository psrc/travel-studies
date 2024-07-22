# this script maintains the values for variables in codebook to match the views
# must clean variable_list first with fix_variable_list.R
library(tidyverse)
library(psrcelmer)

# codebook variables
# cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_working_version_JL.xlsx")
# cb2021_path = str_glue("C:/Users/JLin/Downloads/Combined_Codebook_2021.xlsx")
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx"


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ---- step1: only keep variables in the variable_list ----
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

variable_list <- readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels <- readxl::read_xlsx(cb_path, sheet = 'value_labels')
new_value_labels <- value_labels %>% filter(variable %in% variable_list$variable)
# openxlsx::write.xlsx(new_value_labels, file = "value_labels.xlsx")

# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ---- prep step: read data ----
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# list of table names and view names for each data table
list_tables <- list(hh = c('hh','v_households_labels'),
                    person = c('person','v_persons_labels'),
                    day = c('day','v_days_labels'),
                    trip = c('trip','v_trips_labels'),
                    vehicle = c('vehicle','v_vehicles_labels')
)

# get data from codebook and views
get_data <- function(data_table){
  
  table_name <- list_tables[[data_table]][[1]]
  view_name <- list_tables[[data_table]][[2]]
  
  var_codebook <- readxl::read_xlsx(cb_path, sheet = 'variable_list') %>% 
    filter(.[[table_name]]==1 & data_type=="integer/categorical")
  values_codebook <- readxl::read_xlsx(cb_path, sheet = 'value_labels') %>% 
    filter(variable %in% var_codebook$variable)
  view_data <- get_query(sql= paste0("select * from HHSurvey.", view_name)) %>% 
    select(any_of(var_codebook$variable))
  
  return(list(var_codebook=var_codebook,
              values_codebook = values_codebook,
              view_data = view_data))
}

list_prep_data <- list(hh = get_data('hh'),
                       person = get_data('person'),
                       day = get_data('day'),
                       trip = get_data('trip'),
                       vehicle = get_data('vehicle')
                       )


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ---- step2: integer/categorical variables in variable_list that are not included in value_labels ----
## TODO: decide if values of these variables need to be added to value_labels
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++

missing_values <- function(data_table){
  
  table_name <- list_tables[[data_table]][[1]]
  view_name <- list_tables[[data_table]][[2]]
  
  var_codebook <- list_prep_data[[data_table]][['var_codebook']]
  values_codebook <-  list_prep_data[[data_table]][['values_codebook']]
  view_data <-  list_prep_data[[data_table]][['view_data']]
  
  var_value_notin_cb <- var_codebook %>% 
    filter(!variable %in% values_codebook$variable)
  # list out all values for var_value_notin_cb
  values_missing <- data.frame()
  for(var in var_value_notin_cb$variable){
    values <- unique(view_data[[var]])
    df_value <- data.frame(
      variable = rep(var,length(values)),
      label_view = values
    )
    values_missing <- rbind(values_missing,df_value)
  }
  
  return(values_missing)
  
}

values_missing_hh <- missing_values('hh')
values_missing_person <- missing_values('person')
values_missing_day <- missing_values('day')
values_missing_trip <- missing_values('trip')
values_missing_vehicle <- missing_values('vehicle')

values_missing_list_all <- variable_list %>% 
  filter(variable %in% unique(values_missing_hh$variable) |
           variable %in% unique(values_missing_person$variable) |
           variable %in% unique(values_missing_day$variable) |
           variable %in% unique(values_missing_trip$variable) |
           variable %in% unique(values_missing_vehicle$variable) )
## write a list of data.frames to individual worksheets using list names as worksheet names
l <- list("all_variables" = values_missing_list_all,
          "hh" = values_missing_hh, 
          "person" = values_missing_person,
          "day" = values_missing_day, 
          "trip" = values_missing_trip, 
          "vehicle" = values_missing_vehicle)
# openxlsx::write.xlsx(l, file = "values_missing.xlsx")


# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ---- step3: find all unique values in views for variables that exist in value_labels (only get integer/categorical variables) ----
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
compare_values <- function(data_table){
  
  table_name <- list_tables[[data_table]][[1]]
  view_name <- list_tables[[data_table]][[2]]
  
  var_codebook <- list_prep_data[[data_table]][['var_codebook']]
  values_codebook <-  list_prep_data[[data_table]][['values_codebook']]
  view_data <-  list_prep_data[[data_table]][['view_data']]
  
  values_view <- data.frame()
  for(var in unique(values_codebook$variable)){
    
    values <- unique(view_data[[var]])
    values_na_omit <- values[!is.na(values)]
    
    df_value <- data.frame(
      variable = rep(var,length(values_na_omit)),
      label_view = values_na_omit
    )
    values_view <- rbind(values_view,df_value)
  }
  
  values_match <- values_codebook %>%
    full_join(values_view, by = c("variable","label"="label_view"), keep = TRUE) %>%
    mutate(variable = ifelse(!is.na(variable.x),variable.x,variable.y)) %>%
    select(variable,value,label,label_view,group_1_title:group_3_value) %>%
    arrange(variable,value,label_view,label)
  
  return(values_match)
  
}


compare_values_hh <- compare_values('hh')
compare_values_person <- compare_values('person')
compare_values_day <- compare_values('day')
compare_values_trip <- compare_values('trip')
compare_values_vehicle <- compare_values('vehicle')

clean <- compare_values_hh %>%
  add_row(compare_values_person) %>%
  add_row(compare_values_day) %>%
  add_row(compare_values_trip) %>%
  add_row(compare_values_vehicle) %>%
  group_by(variable) %>%
  filter(sum(is.na(label))+sum(is.na(label_view))==0) %>%
  ungroup() %>%
  mutate(val_order = NA) %>%
  select(all_of(colnames(value_labels)))
get_not_clean <- function(.data){
  .data %>%
    group_by(variable) %>%
    filter(sum(is.na(label))+sum(is.na(label_view))>0) %>%
    ungroup()
}

## write a list of data.frames to individual worksheets using list names as worksheet names
l <- list("value_labels" = clean,
          "hh edit" = compare_values_hh %>% get_not_clean(), 
          "person edit" = compare_values_person %>% get_not_clean(),
          "day edit" = compare_values_day %>% get_not_clean(), 
          "trip edit" = compare_values_trip %>% get_not_clean(), 
          "vehicle edit" = compare_values_vehicle %>% get_not_clean())
# openxlsx::write.xlsx(l, file = "compare_values.xlsx")


# next step: list out variables with or without NAs
## check NAs in each survey_year
na_list_hh <- var_view_hh %>% 
  group_by(survey_year) %>%
  summarise_all(~sum(!is.na(.))) %>%
  ungroup()

na_all_valid <- na_list_hh %>% select(c("survey_year",where(~ sum(.x==0)==0)))
na_not_valid <- na_list_hh %>% select(c("survey_year",where(~ sum(.x==0)>0)))
