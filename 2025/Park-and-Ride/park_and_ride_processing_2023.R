source("../util.R")
library(psrcelmer)
library(leaflet)
library(logger)
library(glue)
library(sf)

  
# get HTS and location data
year <- 2023
source("park_and_ride_data.R")
  
  
if(file.exists("locations_all_pnr_times.rds") & file.exists("all_pnr_trips_est.rds")){
  log_info("Reading final datasets from RDS files...")
  
  locations_all_pnr_times <- readRDS("locations_all_pnr_times.rds")
  all_pnr_trips_est <- readRDS("all_pnr_trips_est.rds")
  
} else{
  
  log_info("Data processing script starting up...")
  
  log_info("All data loaded successfully. Now starting data manipulation...")
  
  # ---- data manipulation ----
  
  # get potential park and ride trips ----
  
  # cleaned trip table: all park and ride trips
  all_pnr_trips <- df_trip %>% filter(
    str_detect(mode_acc,"Drove and parked") | str_detect(mode_egr,"Drove"),
    # can't be drove onto ferry trips
    mode_acc != "Drove onto ferry"
  ) %>%
    mutate(trip_id = as.character(trip_id))
  
  # all_pnr_trips <- all_pnr_trips[c(1:10),]
  
  # filter locations: filter to person and only time points during existing trips
  locations_all_pnr_times <- locations[0, ] %>%
    add_column(trip_id = character(0), 
               person_id = character(0),
               depart_datetime = as.POSIXct(character(0), tz = tz_pdt),
               arrive_datetime = as.POSIXct(character(0), tz = tz_pdt))
  for(trip in all_pnr_trips$trip_id){
    
    # get person ID and depart/arrive times
    # print(all_pnr_trips[all_pnr_trips$trip_id == trip,"trip_id"][[1]])
    
    person <- substr(trip, 1, 10)
    depart_datetime <- all_pnr_trips[all_pnr_trips$trip_id == trip,"depart_datetime"][[1]]
    arrive_datetime <- all_pnr_trips[all_pnr_trips$trip_id == trip,"arrive_datetime"][[1]]
    
    # get trip locations by person within depart/arrive times
    trip_locations <- locations %>% 
      filter(
        # person
        substr(tripid, 1, 10) == person) %>% 
      filter(
        # all time points between trip departure and arrival
        between(collect_time_pdt, depart_datetime, arrive_datetime)) %>%
      # add trips columns for reference
      mutate(trip_id = trip,
             person_id = person,
             depart_datetime = depart_datetime,
             arrive_datetime = arrive_datetime)
    
    # print(nrow(trip_locations))
    locations_all_pnr_times <- locations_all_pnr_times %>% add_row(trip_locations)
  }
  
  # overlay with park and ride lots
  sf_locations_all_pnr_times <- locations_all_pnr_times %>%
    filter(!is.na(lat) & !is.na(lon)) %>%
    st_as_sf(coords = c("lon","lat"), crs = 4326) %>%
    st_transform(crs = 2285) %>% 
    st_join(pnr_centroids %>% select(PSRCjunctID,JunctionType,P_RStalls,EditNotes), 
            join = st_is_within_distance,
            dist = 600)
  
  pnr_est <- sf_locations_all_pnr_times %>%
    st_drop_geometry() %>%
    distinct(trip_id,PSRCjunctID,JunctionType,P_RStalls,EditNotes) %>%
    arrange(EditNotes) %>%
    slice_head(n = 1, by = trip_id)
  # sum(test$JunctionType,na.rm = TRUE)/7
  # 143/248 with matching lots
  
  # final table
  all_pnr_trips_est <- all_pnr_trips %>%
    left_join(pnr_est, by="trip_id") %>%
    select(trip_id:survey_year,depart_datetime,arrive_datetime,PSRCjunctID,EditNotes,origin_lat:dest_purpose,
           mode_1:mode_egr,mode_class)
  
  saveRDS(locations_all_pnr_times, "locations_all_pnr_times.rds")
  saveRDS(all_pnr_trips_est, "all_pnr_trips_est.rds")
}


# for manual park and ride choosing
# list of all park and ride trips: use `all_pnr_trips_est` that includes inferred lot choices 
# all locations for trips: use `locations_all_pnr_times` filter by trip IDs
write.csv(all_pnr_trips_est, "all_pnr_trips_est.csv")

