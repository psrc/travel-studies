# this script compares the list of HTS variables in the codebook and the elmer views
library(tidyverse)
library(psrcelmer)

# 2024/10/17: add information variables back to codebook
new_full_list_path <- "manual_changes/create_description/HTS_variable_description.xlsx"
descriptions <- readxl::read_xlsx(new_full_list_path, sheet = 'descriptions')
logic <- readxl::read_xlsx(new_full_list_path, sheet = 'logic')

test <- descriptions %>%
  left_join(logic, by ="variable")
write.csv(test,"manual_changes/create_description/description_logic_merge.csv",na = "",row.names = FALSE)

# 2024/10/17: add logic back to codebook
# csv files
full_list_path <- "variable_lists/PSRC_HTS_variables_full_2023.csv"
variable_full_list <- read_csv(full_list_path)

logic_path <- "manual_changes/create_description/HTS_variable_description.xlsx"
logic <- readxl::read_xlsx(new_full_list_path, sheet = 'logic')

test <- variable_full_list %>%
  select(-c(logic)) %>%
  left_join(logic,by="variable")
write.csv(test,"manual_changes/create_description/variable_logic_merge.csv",na = "",row.names = FALSE)

# 2024/10/17: check new variables

mode_variables <- c("mode_1","mode_2","mode_3","mode_4","mode_class","mode_class_5")
mode <- trip_data %>%
  select(all_of(mode_variables)) %>%
  unique()
#okay
na_purpose <- trip_data %>%
  filter(is.na(origin_purpose))
origin_variables <- c("origin_purpose","origin_purpose_cat","origin_purpose_cat_5")
origin <- trip_data %>%
  select(all_of(origin_variables)) %>%
  unique()

dest_variables <- c("dest_purpose","dest_purpose_cat","dest_purpose_cat_5")
dest <- trip_data %>%
  select(all_of(dest_variables)) %>%
  unique()


# 2024/10/17 check day weights
library(tidyverse)
library(psrcelmer)

# read data
day_data <- get_query(sql= "select * from HHSurvey.v_days_labels")
trip_data <- get_query(sql= "select * from HHSurvey.v_trips_labels")

# person-days with 0 day weight
test_day <- day_data %>% filter(day_weight==0 | is.na(day_weight))

vars_list <- c("trip_id","household_id","person_id","day_id","day_iscomplete","svy_complete",
  "speed_mph","speed_flag","dest_purpose_cat",
  "survey_year","hh_day_iscomplete","trip_weight","trip_weight_2017_2019_combined")
# all trips made in test_day with valid trip weights
test_trip <- trip_data %>% 
  filter(day_id %in% test_day$day_id & trip_weight!=0) %>%
  select(all_of(vars_list)) %>%
  # add day weights
  left_join(day_data %>% select(day_id,day_weight), by="day_id")


# 2024/10/17 check kirkland trips
hh_data <- get_query(sql= paste0("select * from HHSurvey.v_households_labels"))

kirkland_hh <- hh_data %>%filter(home_jurisdiction=="Kirkland", survey_year==2023)
kirkland_day <- day_data %>% filter(day_weight>0, household_id %in% kirkland_hh$household_id)
kirkland_trip <- trip_data %>% 
  filter(day_id %in% kirkland_day$day_id) %>%
  group_by(day_id) %>%
  summarise(n())
test <- trip_data %>% filter(day_id==231494450101  ) 

# 2024/10/18 RGC check: moved to rgc_check.qmd
library(psrc.travelsurvey)
library(tidyverse)
library(psrcelmer)
library(sf)
sf_use_s2(TRUE)

# list of table names and view names for each data table
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households_labels','v_persons_labels','v_days_labels','v_trips_labels','v_vehicles_labels')
names(view_names) <- table_names

df_view_name <- data.frame(table = table_names,
                           Elmer.view.name = view_names,
                           row.names = NULL)

region_center <- st_read_elmergeo('urban_centers_evw') %>%
  st_transform(2926) %>%
  select(name,category)
hh_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['hh']))
person_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['person']))
trip_data <- get_query(sql= paste0("select * from HHSurvey.", view_names['trip']))

trip_dest_rgc_vars <- c("trip_id","household_id","person_id","day_id","survey_year",
                        "dest_lng","dest_lat","dest_x_coord","dest_y_coord",
                        "dest_rgcname")
trip_origin_rgc_vars <- c("trip_id","household_id","person_id","day_id","survey_year",
                        "origin_lng","origin_lat","origin_x_coord","origin_y_coord",
                        "origin_rgcname")

# dest rgc: correct
trip_dest_rgc <- trip_data %>% 
  filter(trip_weight>0, !is.na(dest_lng)) %>%
  select(all_of(trip_dest_rgc_vars)) %>%
  st_as_sf(coords = c("dest_lng", "dest_lat"), crs = 4326, remove=FALSE) %>%
  st_transform(2926) %>% 
  st_join(region_center, join = st_intersects) %>%
  mutate(rgc_check = ifelse(dest_rgcname==name,"correct","wrong"))

# origin rgc: correct
trip_origin_rgc <- trip_data %>% 
  filter(trip_weight>0, !is.na(origin_lng)) %>%
  select(all_of(trip_origin_rgc_vars)) %>%
  st_as_sf(coords = c("origin_lng", "origin_lat"), crs = 4326, remove=FALSE) %>%
  st_transform(2926) %>% 
  st_join(region_center, join = st_intersects) %>%
  mutate(rgc_check = ifelse(origin_rgcname==name,"correct","wrong"))

# home rgc: wrong (192 households)
home_rgc_vars <- c("household_id","survey_year","home_rgcname","home_lat","home_lng")
home_rgc <- hh_data %>% 
  filter(hh_weight>0, !is.na(home_lng)) %>%
  select(all_of(home_rgc_vars)) %>%
  st_as_sf(coords = c("home_lng", "home_lat"), crs = 4326, remove=FALSE) %>%
  st_transform(2926) %>% 
  st_join(region_center, join = st_intersects) %>%
  mutate(rgc_check = ifelse(home_rgcname==name,"correct","wrong"))

# plot rgc map
library(leaflet)
region_center_plot <- st_read_elmergeo('urban_centers_evw')

plot_location <- function(rgc_name,lng,lat){
  leaflet(region_center_plot%>%filter(name==rgc_name)) %>%
    addPolygons(
      stroke = FALSE) %>%
    addTiles() %>%
    addMarkers(lng,lat)
}

plot_location("Redmond Downtown",-122.1290, 47.67278)
