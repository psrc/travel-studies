library(tidyverse)
library(odbc)
library(DBI)
library(sf)

# Read in workers with work locations from Elmer
elmer_conn <- dbConnect(odbc::odbc(),
                        driver = "ODBC Driver 17 for SQL Server",
                        server = "AWS-PROD-SQL\\Sockeye",
                        database = "Elmer",
                        trusted_connection = "yes"
)

workers <- dbGetQuery(elmer_conn,
                      "SELECT *
                       FROM [Elmer].[HHSurvey].[v_persons]
                       WHERE worker <> 'No jobs'
                       AND age_category <> 'Under 18 years'
                       AND workplace IN ('Usually the same location (outside home)',
                                         'Telework some days and travel to a work location some days')"
)

dbDisconnect(elmer_conn)

workers_loc <- filter(workers, !is.na(work_lng))
workers_loc$person_id <- as.numeric(workers_loc$person_id)

# Read in shapefile of workers with regional geographies created in ArcMap
# (see telecommuters_by_work_location_queries.sql for worker definition and other filtering)
workers_geo <- st_read("J:/Projects/Home_Work_Connections/HHTS/GIS/workers_region_sea_subareas.shp",
                       crs = 2285, stringsAsFactors = FALSE) %>% 
  st_drop_geometry %>% 
  rename(jurisdiction = juris) %>% 
  replace_na(list(county = "Out of Region", jurisdiction = "Out of Region"))

workers_geo$subarea <- case_when(workers_geo$subarea == "Sea-Shore" ~ "Seattle-Shoreline",
                                 workers_geo$subarea == "South-King" ~ "South King",
                                 TRUE ~ workers_geo$subarea)

workers_geo$king_cities <- case_when(workers_geo$jurisdiction == "Seattle" ~ "Seattle",
                                     workers_geo$jurisdiction %in% c("Bellevue", "Redmond") ~ "Bellevue and Redmond",
                                     workers_geo$county == "King" ~ "Other King County")

workers_geo$rgc_name[!is.na(workers_geo$rgc_name)] <- "Central Seattle"

workers_loc <- left_join(workers_loc, workers_geo, by = c("person_id" = "person_id"))

workers_loc$survey <- ifelse(workers_loc$survey_year %in% c(2017, 2019), "2017/2019", "2021")
workers_loc$telecommute <- ifelse(workers_loc$telecommute_freq %in% c("1 day a week", "2 days a week", "3 days a week",
                                                                      "4 days a week", "5 days a week", "6-7 days a week",
                                                                      "1-2 days", "3-4 days", "5+ days"),
                                  "Telecommuter", "Not regular telecommuter")

workers_loc$county <- ordered(workers_loc$county,
                              levels = c("King", "Kitsap", "Pierce", "Snohomish", "Out of Region"))

workers_loc$king_cities <- ordered(workers_loc$king_cities,
                                   levels = c("Seattle", "Bellevue and Redmond", "Other King County"))

# Analysis
# all workers
workers %>% 
  filter(survey_year %in% c(2017, 2019)) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers %>% 
  filter(survey_year == 2021) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# workers with work coords
workers_loc %>% 
  filter(survey == "2017/2019") %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021") %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# workers by county
workers_loc %>% 
  filter(survey == "2017/2019") %>% 
  group_by(county) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021") %>% 
  group_by(county) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# telecommuters by county
workers_loc %>% 
  filter(survey == "2017/2019"
         & telecommute == "Telecommuter") %>% 
  group_by(county) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & telecommute == "Telecommuter") %>% 
  group_by(county) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# workers in King Co
workers_loc %>% 
  filter(survey == "2017/2019"
         & county == "King") %>% 
  group_by(king_cities) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & county == "King") %>% 
  group_by(king_cities) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# telecommuters in King Co
workers_loc %>% 
  filter(survey == "2017/2019"
         & county == "King"
         & telecommute == "Telecommuter") %>% 
  group_by(king_cities) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & county == "King"
         & telecommute == "Telecommuter") %>% 
  group_by(king_cities) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# workers in King subareas
workers_loc %>% 
  filter(survey == "2017/2019"
         & county == "King") %>% 
  group_by(subarea) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & county == "King") %>% 
  group_by(subarea) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# telecommuters in King subareas
workers_loc %>% 
  filter(survey == "2017/2019"
         & county == "King"
         & telecommute == "Telecommuter") %>% 
  group_by(subarea) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & county == "King"
         & telecommute == "Telecommuter") %>% 
  group_by(subarea) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# workers in Seattle
workers_loc %>% 
  filter(survey == "2017/2019"
         & jurisdiction == "Seattle") %>% 
  group_by(rgc_name) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & jurisdiction == "Seattle") %>% 
  group_by(rgc_name) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# telecommuters in Seattle
workers_loc %>% 
  filter(survey == "2017/2019"
         & jurisdiction == "Seattle"
         & telecommute == "Telecommuter") %>% 
  group_by(rgc_name) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & jurisdiction == "Seattle"
         & telecommute == "Telecommuter") %>% 
  group_by(rgc_name) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# workers in Seattle-Shoreline
workers_loc %>% 
  filter(survey == "2017/2019"
         & subarea == "Seattle-Shoreline") %>% 
  group_by(rgc_name) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & subarea == "Seattle-Shoreline") %>% 
  group_by(rgc_name) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))

# telecommuters in Seattle-Shoreline
workers_loc %>% 
  filter(survey == "2017/2019"
         & subarea == "Seattle-Shoreline"
         & telecommute == "Telecommuter") %>% 
  group_by(rgc_name) %>% 
  summarize(count = n(),
            total = sum(hh_weight_2017_2019_v2021_adult))

workers_loc %>% 
  filter(survey == "2021"
         & subarea == "Seattle-Shoreline"
         & telecommute == "Telecommuter") %>% 
  group_by(rgc_name) %>% 
  summarize(count = n(),
            total = sum(person_weight_2021_ABS_Panel_adult))
