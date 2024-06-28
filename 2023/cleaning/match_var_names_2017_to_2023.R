library(tidyverse)
library(psrcelmer)

# codebook variables
cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_working_version_JL.xlsx")
# cb_path2 = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx")

# households ----
hh_sheet = readxl::read_xlsx(cb_path, sheet = 'hh')
hh_combined <- get_query(sql= "select TOP (10) * from HHSurvey.v_households_labels")  

match_hh_names <- data.frame(vars = hh_sheet$variable,
                             codebook = "codebook") %>% 
  full_join(data.frame(vars = colnames(hh_combined),
                       combined = "combined"), by = "vars") %>% 
  filter(!is.na(vars))

# persons ----
person_sheet = readxl::read_xlsx(cb_path, sheet = 'person')
person_combined <- get_query(sql= "select TOP (10) * from HHSurvey.v_persons_labels")

match_person_names <- data.frame(vars = person_sheet$variable,
                                 codebook = "codebook") %>% 
  full_join(data.frame(vars = colnames(person_combined),
                       combined = "combined"), by = "vars") %>% 
  filter(!is.na(vars))

# days ----
day_sheet = readxl::read_xlsx(cb_path, sheet = 'day')
day_combined <- get_query(sql= "select TOP (10) * from HHSurvey.v_days_labels")

match_day_names <- data.frame(vars = day_sheet$variable,
                                 codebook = "codebook") %>% 
  full_join(data.frame(vars = colnames(day_combined),
                       combined = "combined"), by = "vars") %>% 
  filter(!is.na(vars))

# trips ----
trip_sheet = readxl::read_xlsx(cb_path, sheet = 'trip')
trip_combined <- get_query(sql= "select TOP (10) * from HHSurvey.v_trips_labels")

match_trip_names <- data.frame(vars = trip_sheet$variable,
                              codebook = "codebook") %>% 
  full_join(data.frame(vars = colnames(trip_combined),
                       combined = "combined"), by = "vars") %>% 
  filter(!is.na(vars))

# vehicles ----
vehicle_sheet <- readxl::read_xlsx(cb_path, sheet = 'vehicle')
vehicle_combined <- get_query(sql= "select TOP (10) * from HHSurvey.v_vehicles_labels")

match_vehicle_names <- data.frame(vars = vehicle_sheet$variable,
                               codebook = "codebook") %>% 
  full_join(data.frame(vars = colnames(vehicle_combined),
                       combined = "combined"), by = "vars") %>% 
  filter(!is.na(vars))

# match other variables ----
variable_list <- match_hh_names %>% add_row(match_person_names) %>% add_row(match_day_names) %>% 
  add_row(match_trip_names) %>% add_row(match_vehicle_names)

other_var_sheet <- readxl::read_xlsx(cb_path, sheet = 'other')
match_other_names <- variable_list %>% 
  full_join(data.frame(vars = other_var_sheet$variable,
                       other_codebook = "other_codebook"), by = "vars")
