library(tidyverse)
library(psrcelmer)
library(gt)
library(gtsummary)

# save to files for manual update
generate_spreadsheet <- TRUE


variable_col <- c("variable","hh","person","day","trip","vehicle","data_type","description","logic")
value_col <- c("variable","value","label")

# newest codebook pages

# 2023 codebook
# variable_list <- read_csv("../2023/cleaning/codebook_maintenance/2023_codebook/2023_01_HTS_Codebook_variable_list.csv") %>%
#   select(all_of(variable_col))
variable_list <- read_csv("../HTS_codebook/2025_codebook/final_variable_list_2025.csv")
rsg_variable_list <- read_csv("../HTS_codebook/2025_codebook/cleaning codebook/rsg_variable_description.csv") %>%
  mutate(value=1) %>%
  pivot_wider(id_cols=c("variable","data_type","logic","description"), names_from = "table", values_from = "value", values_fill = 0) %>%
  arrange(variable) %>%
  rename(trip = trip_unlinked) %>%
  select(all_of(variable_col))


rsg_value_labels <- read_csv("../HTS_codebook/2025_codebook/cleaning codebook/rsg_value_labels.csv") %>%
  select(all_of(value_col))
# value_labels <- read_csv("../2023/cleaning/codebook_maintenance/2023_codebook/2023_02_HTS_Codebook_value_labels.csv") %>%
#   select(all_of(value_col))
value_labels <- read_csv("../HTS_codebook/2025_codebook/final_value_labels_2025.csv")%>%
    select(all_of(value_col))


# list of table names and view names for each data table
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households','v_persons','v_days','v_trips','v_vehicles')
names(view_names) <- table_names

# df_view_name <- data.frame(table = table_names,
#                            Elmer.view.name = view_names,
#                            row.names = NULL)

# import all views
hh_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['hh']))
person_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['person']))
day_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['day']))
trip_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['trip']))
vehicle_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['vehicle']))

# find all variables to be included in value labels
# geography_variables <- variable_list %>% filter(grepl("county|jurisdiction|rgcname|state",variable))

get_categorical_variables <- function(.data){
  .data %>%
      filter(data_type == "integer/categorical",
             !grepl("hhmember",variable)
             # !variable %in% geography_variables$variable # no geography names
             )

} 



# require factor_variables and value_labels objects
compare_values <- function(view_data, t_name){
  
  # variable list
  t_rsg_variable_list <- rsg_variable_list %>% get_categorical_variables() %>% filter(.[[t_name]]==1)
  t_variable_list <- variable_list %>% get_categorical_variables() %>% filter(.[[t_name]]==1)
  # value labels
  t_rsg_value_labels <-  rsg_value_labels %>% filter(variable %in% t_rsg_variable_list$variable) %>%
    rename(label_rsg = label) %>%
    select(c("variable","value","label_rsg"))
  t_value_labels <-  value_labels %>% filter(variable %in% t_variable_list$variable)  %>%
    select(c("variable","label"))
  # data from elmer
  t_data <- view_data %>% select(any_of(c("survey_year",c(t_rsg_variable_list$variable,t_variable_list$variable))))
  t_data_values <- data.frame()
  for(var in names(t_data)){
  
    v_values <- t_data %>%
      group_by(.[[var]]) %>%
      summarise(year_2017 = sum(survey_year==2017),
                year_2019 = sum(survey_year==2019),
                year_2021 = sum(survey_year==2021),
                year_2023 = sum(survey_year==2023),
                year_2025 = sum(survey_year==2025)) %>%
      ungroup() %>%
      mutate(variable = var)
    colnames(v_values) <- c("label_view","year_2017","year_2019","year_2021","year_2023","year_2025","variable")
    t_data_values <- rbind(t_data_values,v_values)
    
    }
  t_data_values <- t_data_values %>% 
    filter(variable != "survey_year") %>%
    select(c("variable", "label_view","year_2017","year_2019","year_2021","year_2023","year_2025"))
  
  # match values
  values_match <- t_value_labels %>%
    full_join(t_data_values, by = c("variable","label"="label_view"), keep=TRUE) %>%
    mutate(variable = ifelse(!is.na(variable.x),variable.x,variable.y)) %>%
    select(-c("variable.x","variable.y")) %>%
    full_join(t_rsg_value_labels, by = c("variable","label_view"="label_rsg"), keep=TRUE) %>%
    mutate(variable = ifelse(!is.na(variable.x),variable.x,variable.y)) %>%
    select(-c("variable.x","variable.y")) %>%
    select(variable,label,label_rsg,label_view,year_2017,year_2019,year_2021,year_2023,year_2025) %>%
    arrange(variable,label_view,label_rsg,label)
  
  return(values_match)
  
}

compare_values_hh <- compare_values(hh_data,'hh')
compare_values_person <- compare_values(person_data,'person') %>% 
  filter(!variable %in% c("license", "hours_work","school_freq","work_county"))
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
  openxlsx::write.xlsx(l, file = "2025_value_summary.xlsx")
}

