library(tidyverse)
library(plotly) 
library(psrc.travelsurvey)
library(psrcelmer)
library(psrcplot)
library(sf)
library(spatialEco)
library(kableExtra)
library(leaflet)


# calculate centers and region area
sf_use_s2(FALSE)

# get all layers
bg2020.lyr <- st_read_elmergeo("BLOCKGRP2020_NOWATER")
block2020.lyr <- st_read_elmergeo("BLOCK2020") %>% select(county_name,geoid20,placename,land_acres,total_pop20)
uga.lyr <- st_read_elmergeo("urban_growth_area_evw") %>% select(county_name,sum_acres,SDE_STATE_ID,Shape) %>% mutate(UGA = "UGA")
center.lyr <- st_read_elmergeo('URBAN_CENTERS')



# ofm data: get uga ofm population data
# ofm_2020 <- get_table(schema = 'ofm', tbl_name = 'v_estimates_2020') # 2010 geoid
# block2010.lyr <- st_read_elmergeo("BLOCK2010") %>% select(county_name,geoid10,placename,land_acres,total_pop10)
# 
# match_geog <- st_join(st_centroid(block2010.lyr),uga.lyr[,c("UGA")]) %>%
#   st_join(.,center.lyr[,c("name","category","Shape")]) %>%
#   full_join(ofm_2020, by=c("geoid10"="block_geoid")) %>%
#   mutate(UGA = replace_na(UGA,"not UGA"))
# 
# test <- match_geog %>% 
#   group_by(UGA) %>%
#   summarise(sum(total_pop10,na.rm = TRUE),sum(household_population,na.rm = TRUE))
# 
# test <- match_geog %>% 
#   group_by(name,category) %>%
#   summarise(sum(total_pop10,na.rm = TRUE),sum(household_population,na.rm = TRUE))

# 2018 lodes data: get uga employment data
# p_lodes_folder <- "C:/Users/JLin/OneDrive - Puget Sound Regional Council/Documents/psrc_work_files/travel_modeling/lodes_240128/LODES WAC Files"
# lodes_2018 <- read_csv(file.path(p_lodes_folder,"wa_wac_S000_JT00_2018.csv"),col_select  =c("w_geocode","C000")) %>%
#   mutate(w_geocode = as.character(w_geocode))
# 
# match_geog <- st_join(st_centroid(block2020.lyr),uga.lyr[,c("UGA")]) %>%
#   st_join(.,center.lyr[,c("name","category","Shape")]) %>%
#   full_join(lodes_2018, by=c("geoid20"="w_geocode")) %>%
#   mutate(UGA = replace_na(UGA,"not UGA"))
# 
# test <- match_geog %>%
#   group_by(UGA) %>%
#   summarise(sum(C000,na.rm = TRUE))


# calculate geography area
psrc_region_area <- sum(bg2020.lyr$land_acres)
uga_area <- sum(uga.lyr$sum_acres)
centers_area <- sum(center.lyr$acres)

center_data <- center.lyr
st_geometry(center_data) <- NULL
# areas: individual rgcs, rgc, urban/metro
rgc_indv_area <- center_data %>%
  mutate(d_rgcname="RGC") %>% 
  select(name,d_rgcname,category,acres) %>%
  add_row(data.frame(name=c("Not RGC"),
                     d_rgcname=c("Not RGC"),
                     category=c("Not RGC"),
                     acres=c(uga_area-centers_area)))

rgc_area <- rgc_indv_area %>%
  group_by(d_rgcname) %>%
  summarise_at(vars(acres),sum)

metro_urban_area <- rgc_indv_area %>%
  group_by(category) %>%
  summarise_at(vars(acres),sum)

# population and employment

# uga population using block-level 2020 ofm table:       3626798.3
# total population from carol ofm excel data:            4027090
# uga employment data using block-level 2018 lodes data: 1989680
# total employment data from carol:                      2134488
pop_uga = 3626798.3
emp_uga = 1989680

df_rgc <- data.frame(year=c("2020","2020"), # 2020 population
                     d_rgcname=c("RGC","Not RGC"),
                     population=c(266490,pop_uga),
                     employment=c(713302,emp_uga-713302)) %>% #TODO: get employment data in UGA
  left_join(rgc_area,by="d_rgcname") %>%
  mutate(activity_unit=population+employment)

df_centers <- read_csv("indv_center_pop_emp_2020.csv") %>%
  # add not rgc data
  add_row(df_rgc %>% select(d_rgcname,population,employment) %>% rename(d_rgcname_indv=d_rgcname) %>% filter(d_rgcname_indv=="Not RGC")) %>%
  left_join(rgc_indv_area[,c("name","acres")], by=c("d_rgcname_indv"="name")) %>%
  mutate(activity_unit=population+employment)

df_metro_urban <- read_csv("indv_center_pop_emp_2020.csv") %>%
  # add not rgc data
  add_row(df_rgc %>% select(d_rgcname,population,employment) %>% rename(d_rgcname_indv=d_rgcname) %>% filter(d_rgcname_indv=="Not RGC")) %>%
  left_join(rgc_indv_area[,c("name","category","acres")], by=c("d_rgcname_indv"="name")) %>%
  group_by(category) %>%
  summarise_at(vars(population,employment,acres),sum) %>%
  ungroup() %>%
  mutate(activity_unit=population+employment)

# get 2017/2019 trip data
trip_vars = c("trip_id","driver","mode_1","mode_simple",'dest_purpose_cat', 'origin_purpose_cat',
              "google_duration", 'trip_path_distance',
              "origin_lat","origin_lng","o_rgcname","dest_lat","dest_lng","d_rgcname")

trip_data_17_19 <- get_hhts("2017_2019", "t", vars=trip_vars) %>%
  left_join(rgc_indv_area %>% select(name,category), by = c("d_rgcname"="name")) %>%
  mutate(trip_type = case_when(dest_purpose_cat %in% c("Errand/Other","Shop","Social/Recreation","Escort","Meal")~"Non-work", 
                               dest_purpose_cat %in% c("Work","Work-related","School")~"Work",
                               TRUE~NA),
         d_rgcname_indv = ifelse(is.na(d_rgcname), "Not RGC", d_rgcname),
         d_rgcname = factor(ifelse(is.na(d_rgcname), "Not RGC", "RGC"), levels=c("RGC", "Not RGC")),
         category = factor(ifelse(is.na(category), "Not RGC", category), levels=c("Metro","Urban", "Not RGC"))) %>%
  filter(!is.na(trip_type),!is.na(dest_lat))

# include only UGA trips
sf_trip <- st_as_sf(trip_data_17_19, coords = c("dest_lng","dest_lat"),crs=4326)
sf_trip_uga <- sf_trip %>%
  st_join(., uga.lyr[,c("UGA")]) %>%
  mutate(UGA = replace_na(UGA,"not UGA")) %>%
  filter(UGA=="UGA")

trip_data_uga_17_19 <- trip_data_17_19 %>% filter(trip_id %in% sf_trip_uga$trip_id)
