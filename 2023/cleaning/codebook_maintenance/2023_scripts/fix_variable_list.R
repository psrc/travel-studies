# this script compares the list of HTS variables in the codebook and the elmer views
library(tidyverse)
library(psrcelmer)

# list of table names and view names for each data table
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households_labels','v_persons_labels','v_days_labels','v_trips_labels','v_vehicles_labels')
names(view_names) <- table_names


# codebook
cb2021_path <- "C:/Users/JLin/Downloads/Combined_Codebook_2021.xlsx"
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx"
cb_backup_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1 - backup.xlsx"

read_codebook <- function(table_name){
  # get variables from codebook
  var_codebook <- readxl::read_xlsx(cb_path, sheet = 'variable_list') %>% filter(.[[table_name]]==1)
  return(var_codebook)
}

hh_variables <- read_codebook('hh')
person_variables <- read_codebook('person')
day_variables <- read_codebook('day')
trip_variables <- read_codebook('trip')
vehicle_variables <- read_codebook('vehicle')



compare_variables <- function(variable_list, table_name){
  
  # get subset of table from view
  view_name <- view_names[table_name]
  var_view <- get_query(sql= paste0("select TOP (10) * from HHSurvey.", view_name)  )
  
  # compare lists of variables
  var_match <- variable_list %>% 
    full_join(data.frame(variable = colnames(var_view),
                         in_elmer_view = 1), by = "variable") %>% 
    # filter(!is.na(variable)) %>%
    mutate(in_variable_list = ifelse(!is.na(is_checkbox),1,0),
           in_elmer_view = ifelse(!is.na(in_elmer_view),in_elmer_view,0),
           information = 1-in_variable_list) %>%
    arrange(desc(in_variable_list),variable)
  
  return(var_match)
}


match_hh_names <- compare_variables(hh_variables,'hh')
match_person_names <- compare_variables(person_variables, 'person')
match_day_names <- compare_variables(day_variables, 'day')
match_trip_names <- compare_variables(trip_variables, 'trip')
match_vehicle_names <- compare_variables(vehicle_variables, 'vehicle')

match_all_names <- rbind(match_hh_names,match_person_names,match_day_names, match_trip_names, match_vehicle_names) %>%
  arrange(desc(in_variable_list),variable)

# group variables
# 1. informational variables
# fill_variables <- readxl::read_xlsx(cb_backup_path, sheet = 'variable_list') %>% 
#   filter(variable %in% match_all_names[match_all_names$in_variable_list!=1,]$variable)
# l <- list("hh" = match_hh_names, 
#           "person" = match_person_names,
#           "day" = match_day_names, 
#           "trip" = match_trip_names, 
#           "vehicle" = match_vehicle_names,
#           "fill_missing" = fill_variables)
# openxlsx::write.xlsx(l, file = "edit_variables.xlsx")
filled_all_variables <- readxl::read_xlsx("edit_variables.xlsx", sheet = 'hh') %>% 
  add_row(readxl::read_xlsx("edit_variables.xlsx", sheet = 'person')) %>% 
  add_row(readxl::read_xlsx("edit_variables.xlsx", sheet = 'day')) %>% 
  add_row(readxl::read_xlsx("edit_variables.xlsx", sheet = 'trip')) %>% 
  add_row(readxl::read_xlsx("edit_variables.xlsx", sheet = 'vehicle')) %>%
  distinct()
write_csv(filled_all_variables, "variable_lists/PSRC_HTS_variables_full_2023.csv")
test <- filled_all_variables %>%
  group_by(variable) %>%
  summarise(n())

