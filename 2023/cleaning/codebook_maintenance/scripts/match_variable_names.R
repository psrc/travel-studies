# this script compares the list of HTS variables in the codebook and the elmer views
library(tidyverse)
library(psrcelmer)

# ---- parameters ----
# list of table names and corresponding view names for each data table
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households_labels','v_persons_labels','v_days_labels','v_trips_labels','v_vehicles_labels')
# 2025/12/26: lables views not completed yet
# view_names <- c('v_households','v_persons','v_days','v_trips','v_vehicles')
names(view_names) <- table_names


# ---- load codebook ----
# analyst version codebook
analyst_cb_2023 <- "2023_codebook/2023_01_HTS_Codebook_variable_list.csv"
final_cb_2023 <- read_csv(analyst_cb_2023) %>%
  select(-c("is_checkbox", "location", "shared_name"))
# RSG delivered codebook for data cleaning
rsg_cb_path <- "../../../2025/2025_codebook/rsg_variable_description.csv"
rsg_var_codebook <- read_csv(rsg_cb_path) %>%
  filter(table!="trip_linked") # ignore trip_linked

# clean up codebook format
rsg_var_codebook <- rsg_var_codebook %>%
  # list all tables the variables are in
  summarise(count = n(), 
            all_tables = paste(table,collapse = " "),
            .by = names(.)[names(.) != "table"]) %>%
  # check same variable name/table with different description or logic 
  mutate(count_var = n(), .by = "variable") %>%
  mutate(hh = case_when(grepl("hh", all_tables)~ "1",
                        TRUE~"0"),
         person = case_when(grepl("person", all_tables)~ "1",
                        TRUE~"0"),
         day = case_when(grepl("day", all_tables)~ "1",
                            TRUE~"0"),
         trip = case_when(grepl("trip", all_tables)~ "1",
                            TRUE~"0"),
         vehicle = case_when(grepl("vehicle", all_tables)~ "1",
                            TRUE~"0"),
         ) %>%
  select(names(final_cb_2023))

all_cb <- list(
  "2023 final codebook" = final_cb_2023,
  "2025 RSG codebook" = rsg_var_codebook
)


# ---- read data tables in Elmer views ----
# import all views
hh_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['hh']))
person_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['person']))
day_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['day']))
trip_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['trip']))
vehicle_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['vehicle']))

# basic summary fr views
f_view_summary <- function(view_data, view_name){
  
  t_data_values <- data.frame()
  for(var in names(view_data)){
    
    v_values <- view_data[,c("survey_year",var)] %>%
      filter(!is.na(.[[var]])) %>%
      summarise(year_2017 = sum(survey_year==2017),
                year_2019 = sum(survey_year==2019),
                year_2021 = sum(survey_year==2021),
                year_2023 = sum(survey_year==2023),
                year_2025 = sum(survey_year==2025)
                ) %>%
      ungroup() %>%
      mutate(vars = var,
             # table = view_name,
             view = "view",
             .before="year_2017")
    t_data_values <- rbind(t_data_values,v_values)
  
  }
  
  return(t_data_values)
}

# all variables in views plus summary
var_view <- f_view_summary(hh_data, "hh") %>%
  add_row(f_view_summary(person_data, "person")) %>%
  add_row(f_view_summary(day_data, "day")) %>%
  add_row(f_view_summary(trip_data, "trip")) %>%
  add_row(f_view_summary(vehicle_data, "vehicle")) %>%
  group_by(vars) %>%
  summarise_all(~first(.)) %>% # remove duplicate variables in different tables
  ungroup()


# ---- match variables from codebooks and views ---
var_match <- data.frame(vars = final_cb_2023$variable,
                                             csv = "csv") %>% 
  full_join(data.frame(vars = rsg_var_codebook$variable,
                       rsg_codebook = "rsg_codebook"), by = "vars") %>%
  full_join(var_view, by = "vars") %>%
  distinct() %>%
  arrange(view,
          csv,
          # codebook,
          vars)


# l <- list("all variables" = var_match)
# openxlsx::write.xlsx(l, file = "manual_changes/var_match2.xlsx")


