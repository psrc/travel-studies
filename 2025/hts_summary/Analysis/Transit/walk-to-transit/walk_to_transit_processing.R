source("../../util.R")
library(psrcelmer)
library(leaflet)
library(logger)
library(glue)
library(sf)

  
# ---- get park and ride, transit stop layers ----
source("walk_to_transit_data.R")
  
# ---- if exist: get location and stop estimation datatables ----

f_locations_all_walk_transit <-  file.path("data","locations_all_walk_transit.rds") 
f_all_walk_transit_est <-  file.path("data","all_walk_transit_est.rds") 

if(file.exists(f_locations_all_walk_transit) & file.exists(f_all_walk_transit_est)){
  
  # if data already exist in folder
  log_info("Reading final datasets from RDS files...")
  
  all_walk_transit_est <- readRDS(f_all_walk_transit_est)
  locations_all_walk_transit <- readRDS(f_locations_all_walk_transit)
  
} else{
  
# ---- genereate location and stop estimation datatables ----
  
  log_info("Data processing script starting up...")
  
  ## ---- walk to transit trip table: all walk to transit trips ----
  all_walk_transit <- get_all_walk_transit_data()
  ## ---- location table: filter to person and only time points during existing trips ----
  locations_all_walk_transit <- get_locations_data(all_walk_transit)
  
  log_info("All data loaded successfully. Now starting stop estimation...")
  
  
  ## ---- estimate boarding and alighting rail stops ----
  
  # get spatial layers of rail stops
  sf_rail_stops <- transit_stops %>% 
    filter(type_name %in% c("Light Rail","Commuter Rail")) %>%
    st_as_sf(coords = c("stop_lon","stop_lat"), crs = 4326) %>%
    st_transform(crs = 2285)
  
  # dest stop
  dest_stop <- all_walk_transit %>%
    filter(!is.na(dest_lat) & !is.na(dest_lng),
           transit_submode == "Rail") %>%
    
    # create projected layer with trip destinations
    st_as_sf(coords = c("dest_lng","dest_lat"), crs = 4326) %>%
    st_transform(crs = 2285) %>%
    
    mutate(
      # spatial overlay with rail stops:
      # to calculate estimated alighting rail stop nearest to trip destination
      dest_stop_idx = st_nearest_feature(., sf_rail_stops),
      
      dest_stop_id = sf_rail_stops$stop_id[dest_stop_idx],
      dest_type_name = sf_rail_stops$type_name[dest_stop_idx],
      dest_stop_name = sf_rail_stops$stop_name[dest_stop_idx],
      # calculate distance between alighting rail stop and trip destination
      egr_dist_ft = as.numeric( 
        st_distance(geometry, 
                    sf_rail_stops$geometry[dest_stop_idx],
                    by_element = TRUE)
        )
    ) %>%
    st_drop_geometry() %>%
    select(trip_id,dest_stop_id,dest_type_name,dest_stop_name,egr_dist_ft)
  
  # origin stop
  origin_stop <- all_walk_transit %>%
    filter(!is.na(origin_lat) & !is.na(origin_lng),
           transit_submode == "Rail") %>%
    st_as_sf(coords = c("origin_lng","origin_lat"), crs = 4326) %>%
    st_transform(crs = 2285) %>%
    mutate(
      origin_stop_idx = st_nearest_feature(., sf_rail_stops),
      origin_stop_id = sf_rail_stops$stop_id[origin_stop_idx],
      origin_type_name = sf_rail_stops$type_name[origin_stop_idx],
      origin_stop_name = sf_rail_stops$stop_name[origin_stop_idx],
      acc_dist_ft = as.numeric(
        st_distance(
          geometry,
          sf_rail_stops$geometry[origin_stop_idx],
          by_element = TRUE)
        )
    ) %>%
    st_drop_geometry() %>%
    select(trip_id,origin_stop_id,origin_type_name,origin_stop_name,acc_dist_ft)
  
  # merge estimated boarding and alighting stops
  origin_dest_stop <- origin_stop %>%
    inner_join(dest_stop, by="trip_id") %>%
    mutate(acc_walk_min = acc_dist_ft / 264,
           egr_walk_min = egr_dist_ft / 264) #%>%
    # remove outliers
    # filter(acc_walk_min < 120)
  
  # final table
  all_walk_transit_est <- all_walk_transit %>%
    left_join(origin_dest_stop, by="trip_id")
  
  saveRDS(locations_all_walk_transit, f_locations_all_walk_transit)
  saveRDS(all_walk_transit_est, f_all_walk_transit_est)
}

# save stop estimation as CSV: for manual stops choosing
# write.csv(all_walk_transit_est, "all_walk_transit_est.csv")

