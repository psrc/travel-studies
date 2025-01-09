library(tidyverse)
library(psrcelmer)

# ---- read data results from survey conversion ----
output_dir <- "R:/e2projects_two/2023_base_year/2023_survey/daysim_format/updated_weights_12_30_24/cleaned/skims_attached"
hh_convert <-readr::read_tsv(file.path(output_dir,"_household.tsv"))
person_convert <-readr::read_tsv(file.path(output_dir,"_person.tsv"))
day_convert <-readr::read_tsv(file.path(output_dir,"_person_day.tsv"))
trip_convert <-readr::read_tsv(file.path(output_dir,"_trip.tsv"))

hh_convert_tag <- hh_convert %>% distinct(hhid_elmer) %>% 
  mutate(hhid_elmer = as.character(hhid_elmer),
         convert = 1)
person_convert_tag <- person_convert %>% distinct(person_id_original) %>% 
  mutate(person_id_original = as.character(person_id_original),
         convert = 1)
day_convert_tag <- day_convert %>% distinct(day_id) %>% 
  mutate(day_id = as.character(day_id),
         convert = 1)
trip_convert_tag <- trip_convert %>% distinct(trip_id) %>% 
  mutate(trip_id = as.character(trip_id),
         convert = 1)

# ---- list of table names and corresponding view names for each data table ----
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households_labels','v_persons_labels','v_days_labels','v_trips_labels','v_vehicles_labels')
names(view_names) <- table_names

# ---- start comparing variable lists to data tables in Elmer views ----
# import all views
read_2023 <- " where survey_year = 2023"
hh_data <- get_query(sql= paste0("select household_id, hh_weight, home_jurisdiction, hhsize from HHSurvey.", view_names['hh'], read_2023)) %>%
  mutate(household_id = as.character(household_id)) %>%
  full_join(hh_convert_tag, by=c("household_id"="hhid_elmer"))
person_data <- get_query(sql= paste0("select person_id, household_id, person_weight from HHSurvey.", view_names['person'], read_2023)) %>%
  mutate(person_id = as.character(person_id),
         household_id = as.character(household_id)) %>%
  full_join(person_convert_tag, by=c("person_id"="person_id_original"))
day_data <- get_query(sql= paste0("select day_id, household_id, day_weight from HHSurvey.", view_names['day'], read_2023)) %>%
  mutate(day_id = as.character(day_id),
         household_id = as.character(household_id)) %>%
  full_join(day_convert_tag, by="day_id")
trip_data <- get_query(sql= paste0("select trip_id, day_id, household_id, trip_weight from HHSurvey.", view_names['trip'], read_2023)) %>%
  mutate(trip_id = as.character(trip_id),
         household_id = as.character(household_id)) %>%
  full_join(trip_convert_tag, by="trip_id")

test <- trip_data %>% 
  filter(convert>0) %>%
  filter(!day_id %in% day_convert_tag$day_id)
hhsize_test <- person_data %>% 
  filter(convert>0) %>%
  group_by(household_id) %>%
  summarise(hhsize_daysim = n()) %>%
  left_join(hh_data %>% select(household_id,hhsize), by="household_id")
  

# ---- summary of datasets ----
count_records <- function(table, weight_name, table_name){
  test <- table %>% summarise(n_elmer = sum(.[[weight_name]]>0, na.rm = TRUE),
                              n_daysim = sum(convert, na.rm = TRUE),
                              sum_weight_elmer = sum(.[[weight_name]], na.rm = TRUE),
                              sum_weight_daysim = sum(.[[weight_name]] * convert, na.rm = TRUE)) %>%
    mutate(per_daysim = scales::percent(n_daysim/n_elmer),
           per_daysim_weighted = scales::percent(sum_weight_daysim/sum_weight_elmer)) %>%
    mutate(table = table_name)
}
test <- count_records(hh_data, "hh_weight", "household") %>%
  add_row(count_records(person_data, "person_weight", "person")) %>%
  add_row(count_records(day_data, "day_weight", "day")) %>%
  add_row(count_records(trip_data, "trip_weight", "trip"))
  

# ---- save daysim record IDs for reweighting ----
hh_ids <- hh_data %>% filter(convert>0) %>% select(household_id)
person_ids <- person_data %>% filter(convert>0) %>% select(person_id)
day_ids <- day_data %>% filter(convert>0) %>% select(day_id)
trip_ids <- trip_data %>% filter(convert>0) %>% select(trip_id)

saveRDS(hh_ids, "R:/e2projects_two/2023_base_year/2023_survey/daysim_format/updated_weights_12_30_24/daysim_record_ids/hh_IDs.rds")
saveRDS(person_ids, "R:/e2projects_two/2023_base_year/2023_survey/daysim_format/updated_weights_12_30_24/daysim_record_ids/person_IDs.rds")
saveRDS(day_ids, "R:/e2projects_two/2023_base_year/2023_survey/daysim_format/updated_weights_12_30_24/daysim_record_ids/day_IDs.rds")
saveRDS(trip_ids, "R:/e2projects_two/2023_base_year/2023_survey/daysim_format/updated_weights_12_30_24/daysim_record_ids/trip_IDs.rds")


# ---- BKR ----
hh_data_BKR <- hh_data %>% filter(home_jurisdiction %in% c("Bellevue","Kirkland","Redmond"))
person_data_BKR <- person_data %>% filter(household_id %in% hh_data_BKR$household_id)
day_data_BKR <- day_data %>% filter(household_id %in% hh_data_BKR$household_id)
trip_data_BKR <- trip_data %>% filter(household_id %in% hh_data_BKR$household_id)

test_BKR <- count_records(hh_data_BKR, "hh_weight", "household") %>%
  add_row(count_records(person_data_BKR, "person_weight", "person")) %>%
  add_row(count_records(day_data_BKR, "day_weight", "day")) %>%
  add_row(count_records(trip_data_BKR, "trip_weight", "trip"))
