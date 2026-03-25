library(tidyverse)
library(psrc.travelsurvey)
library(psrcelmer)
library(psrcplot)
library(sf)

# ---- get data ----

## ---- centers and UGA layers from ElmerGeo ----
# elmergeo connection
library(odbc)
library(DBI)
library(sf)
elmer_geo_connection <- dbConnect(odbc::odbc(),
                                  driver = "ODBC Driver 17 for SQL Server",
                                  server = "AWS-PROD-SQL\\Sockeye",
                                  database = "ElmerGeo",
                                  trusted_connection = "yes")

bg2020.lyr <- st_read(dsn=elmer_geo_connection, 
                      query="SELECT geoid20, land_acres, Shape.STAsBinary() as Shape 
                             FROM dbo.block2020_nowater_evw")
center.lyr <- st_read(dsn=elmer_geo_connection, 
                      query="SELECT name, category, acres, Shape.STAsBinary() as Shape 
                             FROM dbo.urban_centers_evw")
uga.lyr <- st_read(dsn=elmer_geo_connection,
                   query="SELECT county_name,sum_acres,SDE_STATE_ID, Shape.STAsBinary() as Shape 
                          FROM dbo.urban_growth_area_evw") %>%
  mutate(UGA = "UGA")
uga.lyr <- st_set_crs(uga.lyr, 2285)

rg.lyr <- st_read(dsn=elmer_geo_connection,
                   query="SELECT class_desc, Shape.STAsBinary() as Shape 
                          FROM dbo.regional_geographies_evw") 
rg.lyr <- rg.lyr %>%
  mutate(acres = as.numeric(st_area(rg.lyr)/43560),
         regional_geog = class_desc)
rg.lyr <- st_set_crs(rg.lyr, 2285)

# calculate geography area
psrc_region_area <- sum(bg2020.lyr$land_acres)
uga_area <- sum(uga.lyr$sum_acres)
centers_area <- sum(center.lyr$acres)


df_center_area <- data.frame(rgcname = c("RGC","Rest of UGA","not UGA"),
                          acres = c(centers_area, uga_area-centers_area, psrc_region_area-uga_area))
df_metro_urban_area <- center.lyr %>%
  group_by(category) %>%
  summarise(acres = sum(acres))
st_geometry(df_metro_urban_area) <- NULL
df_metro_urban_area <- df_metro_urban_area %>%
  add_row(df_center_area %>% filter(rgcname %in% c("Rest of UGA","not UGA")) %>% rename(category = rgcname))
df_regional_geog_area <- rg.lyr %>%
  group_by(regional_geog) %>%
  summarise(acres=sum(acres))
st_geometry(df_regional_geog_area) <- NULL
df_regional_geog_area <- df_regional_geog_area %>%
  add_row(df_center_area %>% filter(rgcname %in% c("not UGA")) %>% rename(regional_geog = rgcname) %>% mutate(regional_geog="Rural"))

# centers grouping
df <- center.lyr
st_geometry(df) <- NULL

center_data <- df %>% 
  select(name,acres,category) %>%
  add_row(data.frame(
    name = "Not RGC",
    category = "Not RGC"
  )) %>%
  rename(c(rgcname = "name", category_mu = "category")) %>%
  mutate(
    # group RGCs by Metro,Urban,Not RGC
    category_mu = factor(replace_na(category_mu,"Not RGC"), levels=c("Metro","Urban","Not RGC")),
    # group RGCs by RGC,Not RGC
    category = factor(case_when(category_mu=="Not RGC"~"Not RGC",
                                TRUE~"RGC"), 
                      levels=c("RGC","Not RGC")))

# calculate areas
## fill in "Not RGC" acres
center_data[center_data$rgcname=="Not RGC","acres"] <- sum(uga.lyr$sum_acres)-sum(center_data$acres, na.rm = TRUE)

# rgc_area <- center_data %>%
#   group_by(category) %>%
#   summarise(acres=sum(acres))
# metro_urban_area <- center_data %>%
#   group_by(category_mu) %>%
#   summarise(acres=sum(acres))


## ---- HTS data ----
vars <- c(
  # hh
  "home_rgcname","home_lat","home_lng",
  # person
  "transit_freq","walk_freq","walk_freq_pre_2023","age",
  # trip
  "dest_lat","dest_lng","dest_rgcname", "dest_purpose_cat",
  "mode_class", "mode_class_5", "duration_minutes", "distance_miles",
  "distance_miles", "travelers_total",
  # 2017/2019 weights
  "person_weight_2017_2019_combined","trip_weight_2017_2019_combined"
  )
hts_data <- get_psrc_hts(survey_vars = vars) 

# ---- data processing ----

sf_hh <- st_as_sf(hts_data$hh %>% filter(!is.na(home_lng)), coords = c("home_lng","home_lat"),crs=4326)
sf_hh <- st_transform(sf_hh, 2285)
sf_hh_uga <- sf_hh %>%
  st_join(., uga.lyr[,c("UGA")]) %>%
  st_join(., rg.lyr[,c("regional_geog")]) %>%
  mutate(home_UGA = replace_na(UGA,"not UGA"),
         home_regional_geog = replace_na(regional_geog,"Rural"),) %>%
  select(hh_id,home_UGA,home_regional_geog)

home_hh_uga <- sf_hh_uga
st_geometry(home_hh_uga) <- NULL

df_hh <- hts_data$hh %>%
  mutate(survey_year = as.character(survey_year)) %>%
  # group home RGC
  left_join(center_data %>% rename_with(~paste0("home_",.)), by = "home_rgcname") %>%
  left_join(home_hh_uga, by = "hh_id") %>%
  mutate(home_in_UGA_mu = factor(case_when(home_UGA=="not UGA"~"not UGA",
                                           home_UGA=="UGA" & home_category_mu =="Not RGC"~"Rest of UGA",
                                           TRUE~home_category_mu),
                                 levels=c("Metro","Urban","Rest of UGA","not UGA")),
         home_in_UGA_center = factor(case_when(home_UGA=="not UGA"~"not UGA",
                                           home_UGA=="UGA" & home_category_mu =="Not RGC"~"Rest of UGA",
                                           TRUE~home_category),
                                 levels=c("RGC","Rest of UGA","not UGA")))

df_person <- hts_data$person %>%
  mutate(survey_year = as.character(survey_year),
         transit_freq_simple = case_when(age %in% c("Under 5 years old","5-11 years","12-15 years","16-17 years")~NA,
                                         transit_freq %in% c("1 day a week","2 days a week","3 days a week","4 days a week",
                                                             "5 days a week","2-4 days a week","6-7 days a week")~"At least 1 day/week",
                                         transit_freq %in% c("1-3 times in the past 30 days","1-3 days in the past month")~"Less than 1 day/week",
                                         TRUE~"Never"),
         walk_freq_simple = case_when(age %in% c("Under 5 years old","5-11 years","12-15 years","16-17 years")~NA,
                                      walk_freq %in% c("1 day a week","2 days a week","3 days a week","4 days a week",
                                                       "5 days a week","2-4 days a week","6-7 days a week")~"At least 1 day/week",
                                      walk_freq %in% c("1-3 times in the past 30 days","1-3 days in the past month")~"Less than 1 day/week",
                                      walk_freq_pre_2023 %in% c("1 day a week","2-4 days a week","5 days a week","6-7 days a week")~"At least 1 day/week",
                                      walk_freq_pre_2023 %in% c("1-3 times in the past 30 days")~"Less than 1 day/week",
                                      TRUE~"Never"))
df_day <- hts_data$day %>%
  mutate(survey_year = as.character(survey_year))
# trip
# test data: google_duration
test_data <- get_query("SELECT [trip_id]
,[google_duration]
,[trip_path_distance]
FROM [Elmer].[HHSurvey].[trips_2021]") %>% 
  mutate(trip_id = as.character(trip_id),
         google_duration = as.numeric(google_duration))

sf_trip <- st_as_sf(hts_data$trip %>% filter(!is.na(dest_lng)), coords = c("dest_lng","dest_lat"),crs=4326)
sf_trip <- st_transform(sf_trip, 2285)
sf_trip_uga <- sf_trip %>%
  st_join(., uga.lyr[,c("UGA")]) %>%
  st_join(., rg.lyr[,c("regional_geog")]) %>%
  mutate(dest_UGA = replace_na(UGA,"not UGA"),
         dest_regional_geog = replace_na(regional_geog,"Rural")) %>%
  select(trip_id,dest_UGA,dest_regional_geog)

dest_trip_uga <- sf_trip_uga
st_geometry(dest_trip_uga) <- NULL

df_trip <- hts_data$trip %>%
  # group destination RGC
  mutate(dest_rgcname = replace_na(dest_rgcname,"Not RGC")) %>%
  left_join(center_data %>% rename_with(~paste0("dest_",.)), by = "dest_rgcname") %>%
  mutate(survey_year = as.character(survey_year),
         mode_class_5 = factor(mode_class_5, levels=c("Drive","Transit","Walk","Bike/Micromobility","Other")),
         mode_class_simple = factor(case_when(mode_class_5 %in% c("Walk","Bike/Micromobility")~"Walk/Bike/Micromobility",
                                              mode_class_5=="Missing Response"~"Other",
                                              TRUE~mode_class_5),
                                    levels=c("Drive","Transit","Walk/Bike/Micromobility","Other")),
         dest_purpose_work = case_when(dest_purpose_cat %in% c("Work","Work-related","School","School-related")~"Work",
                                       dest_purpose_cat %in% c("Personal Business/Errand/Appointment",
                                                               "Shopping",
                                                               "Social/Recreation",
                                                               "Escort",
                                                               "Meal",
                                                               "Other")~"Non-work",
                                       TRUE~NA),
         duration_minutes = ifelse(duration_minutes<0,0,duration_minutes)) %>%
  left_join(dest_trip_uga, by = "trip_id") %>%
  mutate(dest_in_UGA_mu = factor(case_when(dest_UGA=="not UGA"~"not UGA",
                                           dest_UGA=="UGA" & dest_category_mu =="Not RGC"~"Rest of UGA",
                                           TRUE~dest_category_mu),
                                 levels=c("Metro","Urban","Rest of UGA","not UGA")),
         dest_in_UGA_center = factor(case_when(dest_UGA=="not UGA"~"not UGA",
                                           dest_UGA=="UGA" & dest_category_mu =="Not RGC"~"Rest of UGA",
                                           TRUE~dest_category),
                                 levels=c("RGC","Rest of UGA","not UGA"))) %>%
  left_join(test_data, by="trip_id") %>% 
  # filter to the trips that should be included in the vmt calculation
  mutate(if_drive = ifelse(grepl("^Ride|Drive",mode_class) & distance_miles<200,1,0)) %>%
  mutate(travelers_total_num = replace_na(as.numeric(substring(travelers_total,1,1)),1),
         travelers_total_num_7 = ifelse(travelers_total_num>=5, 7, travelers_total_num)) %>% # have to make some assumption for 5+
  mutate(weighted_vmt = replace_na(if_drive*distance_miles*trip_weight/travelers_total_num,0),
         weighted_vmt_7 = replace_na(if_drive*distance_miles*trip_weight/travelers_total_num_7,0))


# make 2017/2019 combined
df_hh_2017_2019 <- df_hh %>%
  filter(survey_year %in%c("2017","2019") & hh_weight>0) %>%
  mutate(survey_year = "2017/2019",
         hh_weight = hh_weight/2)
df_person_2017_2019 <- df_person %>%
  filter(person_weight_2017_2019_combined>0) %>%
  mutate(survey_year = "2017/2019",
         person_weight = person_weight/2)
df_trip_2017_2019 <- df_trip %>%
  filter(trip_weight_2017_2019_combined>0) %>%
  mutate(survey_year = "2017/2019",
         trip_weight = trip_weight/2)
  
  
df_hts_data <- hts_data
df_hts_data$hh <- df_hh %>% add_row(df_hh_2017_2019) %>% filter(!survey_year %in% c("2017","2019"))
df_hts_data$trip <- df_trip %>% add_row(df_trip_2017_2019) %>% filter(!survey_year %in% c("2017","2019"))
df_hts_data$person <- df_person %>% add_row(df_person_2017_2019) %>% filter(!survey_year %in% c("2017","2019"))
df_hts_data$day <- df_day

df_hts_data_17_19 <- hts_data
df_hts_data_17_19$hh <- df_hh %>% filter(survey_year %in% c("2017","2019"))
df_hts_data_17_19$trip <- df_trip %>% filter(survey_year %in% c("2017","2019"))
df_hts_data_17_19$person <- df_person %>% filter(survey_year %in% c("2017","2019"))
df_hts_data_17_19$day <- df_day %>% filter(survey_year %in% c("2017","2019"))

