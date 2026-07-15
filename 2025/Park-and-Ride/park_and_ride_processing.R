source("../util.R")
library(psrcelmer)
library(leaflet)
library(logger)
library(glue)
library(sf)


log_info("Data processing script starting up...")

# get HTS and location data
year <- 2025
source("park_and_ride_data.R")

# park and ride lots
gdb_path <- "NetworkJunction.gdb"
# st_layers(gdb_path) # List all internal layers, geometry types, and row counts
zone_centroids <- st_read(dsn = gdb_path, layer = "zone_centroids")
pnr_centroids <- zone_centroids %>% 
  filter(JunctionType == 7,
         # remove future park and ride lots
         !(str_detect(EditNotes,"Future") | str_detect(EditNotes,"future")))
pnr_centroids_ll <- st_transform(pnr_centroids, 4326)


log_info("HTS data loaded successfully. Now starting data manipulation...")

# ---- data manipulation ----

# get initial trip ID
initial_id <- trips %>%
  select(tripid, initial_tripid) %>%
  mutate(tripid = as.character(tripid),
         initial_tripid = as.character(initial_tripid))

df_trip <- hts_data$trip %>%
  left_join(initial_id, by = c("trip_id" = "tripid")) %>%
  mutate(
    distance_bins = case_when(distance_miles<=1~ "0-1 miles",
                              distance_miles<=2~ "1-2 miles",
                              distance_miles<=5~ "2-5 miles",
                              distance_miles<=15~ "5-15 miles",
                              distance_miles>15~ "more than 15 miles"),
    arrive_datetime = as.POSIXct(arrive_date, tz = "UTC") +
      arrival_time_hour * 3600 +
      arrival_time_minute * 60 +
      arrival_time_second,
    depart_datetime = as.POSIXct(depart_date, tz = "UTC") +
      depart_time_hour * 3600 +
      depart_time_minute * 60 +
      depart_time_second
  )
df_trip$arrive_datetime <- force_tz(df_trip$arrive_datetime, "PDT")
df_trip$depart_datetime <- force_tz(df_trip$depart_datetime, "PDT")
# df_hts_data <- hts_data
# df_hts_data$trip <- df_trip



# get potential park and ride trips ----

# cleaned trip table: all park and ride trips
all_pnr_trips <- df_trip %>% filter(str_detect(mode_acc,"Drove and parked") | str_detect(mode_egr,"Drove"))

# unlinked trip table: all trips in days with at least one park and ride trip
df <- unlinked_trips %>% filter(tripid %in% all_pnr_trips$initial_tripid)
unlinked_trips_all_pnr_days <- unlinked_trips %>% 
  filter(day_id %in% df$day_id,
         !is.na(dest_lat),
         !is.na(dest_lng),
         dest_lat>46,
         mode_type==3)

sf_unlinked_trips_all_pnr_days <- unlinked_trips_all_pnr_days %>%
  st_as_sf(coords = c("dest_lng","dest_lat"), crs = 4326) %>%
  st_transform(crs = 2285)

# trace table: all locations in days with at least one park and ride trip
locations_all_pnr_days <- locations %>% 
  filter(tripid %in% unlinked_trips_all_pnr_days$tripid)

sf_locations_all_pnr_days <- locations_all_pnr_days %>%
  filter(!is.na(lat) & !is.na(lon)) %>%
  st_as_sf(coords = c("lon","lat"), crs = 4326) %>%
  st_transform(crs = 2285)

# stricter filter on locations: filter to only times during trips
locations_all_pnr_times <- locations_all_pnr_days[0, ]
for(trip in unlinked_trips_all_pnr_days$tripid){
  
  # get person ID and depart/arrive times
  person <- substr(trip, 1, 10)
  depart_datetime <- unlinked_trips_all_pnr_days[unlinked_trips_all_pnr_days$tripid == trip,"depart_datetime"][[1]]
  arrive_datetime <- unlinked_trips_all_pnr_days[unlinked_trips_all_pnr_days$tripid == trip,"arrive_datetime"][[1]]
  
  # get trip locations by person within depart/arrive times
  trip_locations <- locations_all_pnr_days %>% 
    filter(substr(tripid, 1, 10) == person,
           between(collect_time_pdt, depart_datetime, arrive_datetime))
  
  locations_all_pnr_times <- locations_all_pnr_times %>% add_row(trip_locations)
}

sf_locations_all_pnr_times <- locations_all_pnr_times %>%
  filter(!is.na(lat) & !is.na(lon)) %>%
  st_as_sf(coords = c("lon","lat"), crs = 4326) %>%
  st_transform(crs = 2285)

# overlay with park and ride lots
sf_locations_all_pnr_times<- sf_locations_all_pnr_times %>% 
  st_join(pnr_centroids %>% select(PSRCjunctID,JunctionType,P_RStalls,EditNotes), join = st_is_within_distance,
          dist = 600)

test <- sf_locations_all_pnr_times %>%
  st_drop_geometry() %>%
  distinct(tripid,PSRCjunctID,JunctionType,P_RStalls,EditNotes) %>%
  arrange(EditNotes) %>%
  slice_head(n = 1, by = tripid)
# 100/261 with matching lots

view_unlinked_trips <- unlinked_trips_all_pnr_days %>%
  select(tripid,day_id,person_id,depart_datetime,arrive_datetime,
         origin_lat,origin_lng,dest_lat,dest_lng,
         dest_purpose,
         mode_1,mode_2,mode_3,mode_4,mode_acc,mode_egr,mode_other_specify,mode_type) %>%
  left_join(test, by="tripid")




