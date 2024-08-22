# this script compares the list of HTS variables in the codebook and the elmer views
library(tidyverse)
library(psrcelmer)

# ---- variable lists to check ----
# csv files
full_list_path <- "variable_lists/PSRC_HTS_variables_full_2023.csv"
variable_full_list <- read_csv(full_list_path)
# codebook
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx"
var_codebook <- readxl::read_xlsx(cb_path, sheet = 'variable_list')

# ---- list of table names and corresponding view names for each data table ----
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households_labels','v_persons_labels','v_days_labels','v_trips_labels','v_vehicles_labels')
names(view_names) <- table_names

# ---- start comparing variable lists to data tables in Elmer views ----
compare_variables <- function(var_list, table_name){
  
  # get variables from codebook
  var_codebook <- var_list %>% filter(.[[table_name]]==1)
  
  # get subset of table from view
  view_name <- view_names[table_name]
  var_view <- get_query(sql= paste0("select TOP (10) * from HHSurvey.", view_name)  )
  
  # compare lists of variables
  var_match <- data.frame(vars = var_codebook$variable,
                          codebook = "codebook") %>% 
    full_join(data.frame(vars = colnames(var_view),
                         view = "view"), by = "vars") %>% 
    # filter(!is.na(vars)) %>%
    arrange(codebook,view)
  
  return(var_match)
}


match_hh_names <- compare_variables(variable_full_list,'hh')
match_person_names <- compare_variables(variable_full_list,'person')
match_day_names <- compare_variables(variable_full_list,'day')
match_trip_names <- compare_variables(variable_full_list,'trip')
match_vehicle_names <- compare_variables(variable_full_list,'vehicle')
