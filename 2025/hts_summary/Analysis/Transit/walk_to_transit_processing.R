source("../util.R")
library(psrcelmer)
library(leaflet)
library(logger)
library(glue)
library(sf)

  
# get HTS and location data
source("walk_to_transit_data.R")
  
  
if(file.exists("locations_all_walk_transit.rds") & file.exists("all_walk_transit_est.rds")){
  
  # if data already exist in folder
  log_info("Reading final datasets from RDS files...")
  
  locations_all_walk_transit <- readRDS("locations_all_walk_transit.rds")
  all_walk_transit_est <- readRDS("all_walk_transit_est.rds")
  
} else{
  
  log_info("Data processing script starting up...")
  
  log_info("All data loaded successfully. Now starting data manipulation...")
  
  # ---- data manipulation ----
  
  # get potential walk to transit trips ----
  
  # cleaned trip table: all walk to transit trips
  all_walk_transit <- df_trip %>% filter(
    
    mode_class == "Transit",
    # only consider walk access and egress modes
    mode_acc=="Walked or jogged" | mode_egr=="Walked or jogged"
    
  ) %>%
    mutate(trip_id = as.character(trip_id),
           
           # get transit submodes
           rail = str_detect(paste(mode_1,mode_2,mode_3,mode_4,sep=","),"Rail"),
           bus = str_detect(paste(mode_1,mode_2,mode_3,mode_4,sep=","),"Bus"),
           rail_bus = str_detect(paste(mode_1,mode_2,mode_3,mode_4,sep=","),"Rail") & str_detect(paste(mode_1,mode_2,mode_3,mode_4,sep=","),"Bus"),
           ferry = str_detect(paste(mode_1,mode_2,mode_3,mode_4,sep=","),"Ferry"),
           transit_submode = case_when(
             ferry~"Ferry",
             rail_bus~"Rail and Bus",
             rail~"Rail",
             bus~"Bus"
           ))
  # TODO: identify transit submode
  
  
  # filter locations: filter to person and only time points during existing trips
  locations_all_walk_transit <- locations[0, ] %>%
    add_column(trip_id = character(0), 
               person_id = character(0),
               depart_datetime = as.POSIXct(character(0), tz = tz_pdt),
               arrive_datetime = as.POSIXct(character(0), tz = tz_pdt))
  for(trip in all_walk_transit$trip_id){
    
    # get person ID and depart/arrive times
    print(all_walk_transit[all_walk_transit$trip_id == trip,"trip_id"][[1]])
    
    person <- substr(trip, 1, 10)
    depart_datetime <- all_walk_transit[all_walk_transit$trip_id == trip,"depart_datetime"][[1]]
    arrive_datetime <- all_walk_transit[all_walk_transit$trip_id == trip,"arrive_datetime"][[1]]
    
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
    locations_all_walk_transit <- locations_all_walk_transit %>% add_row(trip_locations)
  }
  
  # TODO: fix this section with transit stops layer
  # overlay with park and ride lots
  # sf_locations_all_pnr_times <- locations_all_pnr_times %>%
  #   
  #   # projection
  #   filter(!is.na(lat) & !is.na(lon)) %>%
  #   st_as_sf(coords = c("lon","lat"), crs = 4326) %>%
  #   st_transform(crs = 2285) %>%
  #   
  #   # spatial overlay with distance within 600 ft
  #   st_join(pnr_centroids %>% select(PSRCjunctID,JunctionType,P_RStalls,EditNotes),
  #           join = st_is_within_distance,
  #           dist = 600)
  # 
  # # organize spatial calculated pnr estimates
  # pnr_est <- sf_locations_all_pnr_times %>%
  #   st_drop_geometry() %>%
  #   distinct(trip_id,PSRCjunctID,JunctionType,P_RStalls,EditNotes) %>%
  #   arrange(EditNotes) %>%
  #   slice_head(n = 1, by = trip_id)
  
  # final table
  # all_pnr_trips_est <- all_pnr_trips %>%
  #   left_join(pnr_est, by="trip_id") %>%
  #   select(trip_id:survey_year,depart_datetime,arrive_datetime,PSRCjunctID,EditNotes,origin_lat:dest_purpose,
  #          mode_1:mode_egr,mode_class)
  
  saveRDS(locations_all_walk_transit, "locations_all_walk_transit.rds")
  saveRDS(all_walk_transit, "all_walk_transit_est.rds")
}


# for manual park and ride choosing
# list of all park and ride trips: use `all_pnr_trips_est` that includes inferred lot choices 
# all locations for trips: use `locations_all_pnr_times` filter by trip IDs
# write.csv(all_pnr_trips_est, "all_pnr_trips_est.csv")

