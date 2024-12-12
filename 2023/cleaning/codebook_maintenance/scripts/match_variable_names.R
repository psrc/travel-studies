# this script compares the list of HTS variables in the codebook and the elmer views
library(tidyverse)
library(psrcelmer)

# ---- variable lists to check ----
# csv files
full_list_path <- "variable_lists/PSRC_HTS_variables_full_2023_logic.csv"
variable_full_list <- read_csv(full_list_path)

# 2024/10/17: add information variables back to codebook
# new_full_list_path <- "manual_changes/create_description/HTS_variable_description.xlsx"
# new_variable_full_list <- readxl::read_xlsx(new_full_list_path, sheet = 'variable_list')

# codebook
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx"
var_codebook <- readxl::read_xlsx(cb_path, sheet = 'variable_list')

# ---- list of table names and corresponding view names for each data table ----
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households_labels','v_persons_labels','v_days_labels','v_trips_labels','v_vehicles_labels')
names(view_names) <- table_names

# ---- start comparing variable lists to data tables in Elmer views ----
# import all views
hh_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['hh']))
person_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['person']))
day_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['day']))
trip_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['trip']))
vehicle_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['vehicle']))

# basic summary
f_view_summary <- function(view_data){
  
  t_data_values <- data.frame()
  for(var in names(view_data)){
    
    v_values <- view_data[,c("survey_year",var)] %>%
      filter(!is.na(.[[var]])) %>%
      summarise(year_2017 = sum(survey_year==2017),
                year_2019 = sum(survey_year==2019),
                year_2021 = sum(survey_year==2021),
                year_2023 = sum(survey_year==2023)) %>%
      ungroup() %>%
      mutate(vars = var,
             view = "view",
             .before="year_2017")
    t_data_values <- rbind(t_data_values,v_values)
  
  }
  
  return(t_data_values)
}

# all variables in views plus summary
var_view <- f_view_summary(hh_data) %>%
  add_row(f_view_summary(person_data)) %>%
  add_row(f_view_summary(day_data)) %>%
  add_row(f_view_summary(trip_data)) %>%
  add_row(f_view_summary(vehicle_data)) %>%
  group_by(vars) %>%
  summarise_all(~first(.)) %>%
  ungroup()

var_match <- data.frame(vars = var_codebook$variable,
                        codebook = "codebook") %>% 
  full_join(data.frame(vars = variable_full_list$variable,
                       csv = "csv"), by = "vars") %>%
  full_join(var_view, by = "vars") %>%
  arrange(view,csv,codebook,vars)


# l <- list("all variables" = var_match)
# openxlsx::write.xlsx(l, file = "manual_changes/var_match2.xlsx")
