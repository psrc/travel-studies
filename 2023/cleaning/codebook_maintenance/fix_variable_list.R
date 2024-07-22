# this script compares the list of HTS variables in the codebook and the elmer views
library(tidyverse)
library(psrcelmer)

# codebook
# cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_working_version_JL.xlsx")
cb2021_path = str_glue("C:/Users/JLin/Downloads/Combined_Codebook_2021.xlsx")
cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx")

compare_variables <- function(table_name, view_name){
  # table_name: hh, person, day, trip, vehicle
  # view_name: v_households_labels,v_persons_labels,v_days_labels,v_trips_labels,v_vehicles_labels
  
  # get variables from codebook
  var_codebook <- readxl::read_xlsx(cb_path, sheet = 'variable_list') %>% filter(.[[table_name]]==1)
  
  # get subset of table from view
  var_view <- get_query(sql= paste0("select TOP (10) * from HHSurvey.", view_name)  )
  
  # compare lists of variables
  var_match <- data.frame(vars = var_codebook$variable,
                          codebook = "codebook") %>% 
    full_join(data.frame(vars = colnames(var_view),
                         view = "view"), by = "vars") %>% 
    filter(!is.na(vars)) %>%
    arrange(codebook,view)
  
  return(var_match)
}


# households
match_hh_names <- compare_variables('hh','v_households_labels')
# persons
match_person_names <- compare_variables('person','v_persons_labels')
# days
match_day_names <- compare_variables('day','v_days_labels')
# trips
match_trip_names <- compare_variables('trip','v_trips_labels')
# vehicles
match_vehicle_names <- compare_variables('vehicle','v_vehicles_labels')
