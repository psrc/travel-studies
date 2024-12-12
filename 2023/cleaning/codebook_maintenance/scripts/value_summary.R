library(tidyverse)
library(psrcelmer)
library(gt)
library(gtsummary)

# save to files for manual update
generate_spreadsheet <- TRUE

# location of full list of variables
variable_list_path <- "variable_lists/PSRC_HTS_variables_full_2023_logic.csv"
cb_path <- "J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx"

# codebook pages
# variable_list <- read_csv(variable_list_path)
variable_list <- readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels <- readxl::read_xlsx(cb_path, sheet = 'value_labels')

# list of table names and view names for each data table
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households_labels','v_persons_labels','v_days_labels','v_trips_labels','v_vehicles_labels')
names(view_names) <- table_names

df_view_name <- data.frame(table = table_names,
                           Elmer.view.name = view_names,
                           row.names = NULL)

# import all views
hh_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['hh']))
person_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['person']))
day_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['day']))
trip_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['trip']))
vehicle_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['vehicle']))

# find all variables to be included in value labels
# geography_variables <- variable_list %>% filter(grepl("county|jurisdiction|rgcname|state",variable))

factor_variables <- variable_list %>% 
  filter(data_type == "integer/categorical",
         !grepl("hhmember",variable)
         # !variable %in% geography_variables$variable # no geography names
         )



# require factor_variables and value_labels objects
compare_values <- function(view_data, t_name){
  
  t_variable_list <- factor_variables %>% filter(.[[t_name]]==1)
  t_value_labels <-  value_labels %>% filter(variable %in% t_variable_list$variable)
    
  t_data <- view_data %>% select(any_of(c("survey_year",factor_variables$variable)))
  
  t_data_values <- data.frame()
  for(var in names(t_data)){
  
    v_values <- t_data %>%
      group_by(.[[var]]) %>%
      summarise(year_2017 = sum(survey_year==2017),
                year_2019 = sum(survey_year==2019),
                year_2021 = sum(survey_year==2021),
                year_2023 = sum(survey_year==2023)) %>%
      ungroup() %>%
      mutate(variable = var)
    colnames(v_values) <- c("label_view","year_2017","year_2019","year_2021","year_2023","variable")
    t_data_values <- rbind(t_data_values,v_values)
    
    }
  
  t_data_values <- t_data_values %>% 
    filter(variable != "survey_year") %>%
    select(c("variable", "label_view","year_2017","year_2019","year_2021","year_2023"))
  
  values_match <- t_value_labels %>%
      full_join(t_data_values, by = c("variable","label"="label_view"), keep = TRUE) %>%
      mutate(variable = ifelse(!is.na(variable.x),variable.x,variable.y)) %>%
      select(variable,value,label,label_view,year_2017,year_2019,year_2021,year_2023) %>%
      arrange(variable,value,label_view,label)
  
  return(values_match)
  
}

compare_values_hh <- compare_values(hh_data,'hh')
compare_values_person <- compare_values(person_data,'person')
compare_values_day <- compare_values(day_data,'day')
compare_values_trip <- compare_values(trip_data,'trip')
compare_values_vehicle <- compare_values(vehicle_data,'vehicle')

# save to 
if(generate_spreadsheet){
  l <- list("hh edit" = compare_values_hh, 
          "person edit" = compare_values_person,
          "day edit" = compare_values_day, 
          "trip edit" = compare_values_trip, 
          "vehicle edit" = compare_values_vehicle)
  openxlsx::write.xlsx(l, file = "manual_changes/values_summary.xlsx")
}


