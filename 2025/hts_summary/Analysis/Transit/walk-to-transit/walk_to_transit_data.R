# ---- park and ride lots ----
pnr_db_path <- "T:/60day-TEMP/Joanne_temp/NetworkJunctionDB.gdb"

if(file.exists( file.path("data","pnr_centroids.rds") )){
  
  pnr_centroids <- readRDS( file.path("data","pnr_centroids.rds") )
  
} else{
  
  gdb_path <- "NetworkJunction.gdb"
  # st_layers(gdb_path) # List all internal layers, geometry types, and row counts
  
  # read layer and filter to only park and ride nodes
  zone_centroids <- st_read(dsn = pnr_db_path, layer = "zone_centroids")
  pnr_centroids <- zone_centroids %>% 
    filter(JunctionType == 7,
           # remove future park and ride lots
           !(str_detect(EditNotes,"Future") | str_detect(EditNotes,"future")))
  
  # save to local
  saveRDS(pnr_centroids,  file.path("data","pnr_centroids.rds") )
}
  
# change to long/lat for leaflet mapping
pnr_centroids_ll <- st_transform(pnr_centroids, 4326)


# ---- GTFS data prep ----
transit_stops_by_mode <- function(year, gtfs_feed, data_month = 4) {
  
  hct <- read_csv(file.path("data", "hct_ids.csv"), show_col_types = FALSE) 
  
  # Open Regional GTFS File and load into memory
  print(str_glue("Opening the {year} GTFS archive."))
  gtfs <- tidytransit::read_gtfs(path=gtfs_feed, files = c("trips","stops","stop_times", "routes", "shapes"))
  
  # Load Stops
  print(str_glue("Getting the {year} stops into a tibble." ))
  stops <- as_tibble(gtfs$stops) |> 
    mutate(stop_id = str_to_lower(stop_id)) |>
    select("stop_id", "stop_name", "stop_lat", "stop_lon")
  
  # Load Routes, add HCT modes and update names and agencies
  print(str_glue("Getting the {year} routes into a tibble." ))
  routes <- as_tibble(gtfs$routes) |> 
    mutate(route_id = str_to_lower(route_id)) |>
    select("route_id", "agency_id","route_short_name", "route_long_name", "route_type")
  
  print(str_glue("Adding High-Capacity Transit codes to the {year} routes"))
  routes <- left_join(routes, hct, by="route_id") |>
    mutate(type_code = case_when(
      is.na(type_code) ~ route_type,
      !(is.na(type_code)) ~ type_code)) |>
    mutate(route_name = case_when(
      is.na(route_name) ~ route_short_name,
      !(is.na(route_name)) ~ route_name)) |>
    mutate(type_name = case_when(
      is.na(type_name) ~ "Bus",
      !(is.na(type_name)) ~ type_name)) |>
    mutate(agency_name = case_when(
      !(is.na(agency_name)) ~ agency_name,
      is.na(agency_name) & agency_id == "29" ~ "Community Transit",
      is.na(agency_name) & agency_id == "97" ~ "Everett Transit",
      is.na(agency_name) & agency_id == "1" ~ "King County Metro",
      is.na(agency_name) & agency_id == "20" ~ "Kitsap Transit",
      is.na(agency_name) & agency_id == "19" ~ "InterCity Transit",
      is.na(agency_name) & agency_id == "3" ~ "Pierce Transit",
      is.na(agency_name) & agency_id == "40" ~ "Sound Transit")) |>
    select("route_id", "route_name", "type_name", "type_code", "agency_name")
  
  # Trips are used to get route id onto stop times
  print(str_glue("Getting the {year} trips into a tibble to add route ID to stop times." ))
  trips <- as_tibble(gtfs$trips) |> 
    mutate(route_id = str_to_lower(route_id)) |>
    select("trip_id", "route_id")
  
  trips <- left_join(trips, routes, by=c("route_id"))
  
  # Clean Up Stop Times to get routes and mode by stops served
  print(str_glue("Getting the {year} stop times into a tibble to add route information." ))
  stoptimes <- as_tibble(gtfs$stop_times) |>
    mutate(stop_id = str_to_lower(stop_id)) |>
    select("trip_id", "stop_id")
  
  # Get Mode and agency from trips to stops
  print(str_glue("Getting unique stop list by modes for the {year}." ))
  stops_by_mode <- left_join(stoptimes, trips, by=c("trip_id")) |>
    select("stop_id", "type_code", "type_name", "agency_name") |>
    distinct()
  
  stops_by_mode <- left_join(stops_by_mode, stops, by=c("stop_id")) |>
    mutate(date=mdy(paste0(data_month,"-01-",year)))
  
  print(str_glue("All Done."))
  
  return(stops_by_mode)
  
}


if(file.exists( file.path("data","transit_stops.rds") )){
  
  transit_stops <- readRDS( file.path("data","transit_stops.rds") )
  
} else{
  
  # download gtfs data here: https://gtfs.sound.obaweb.org/prod/gtfs_puget_sound_consolidated.zip
  transit_stops <- transit_stops_by_mode(year = 2025, gtfs_feed = file.path("data","gtfs_puget_sound_consolidated.zip"), data_month = 4)
  
  # save to local
  saveRDS(transit_stops,  file.path("data","transit_stops.rds") )
}


# ---- get location data ----

# PS region timezone
tz_pdt <- "America/Los_Angeles"

get_location <- function(data){
  locations <- data %>%
    mutate(collect_time_pdt = collect_time)
  # correct timezone
  attr(locations$collect_time_pdt, "tzone") <- tz_pdt
  
  # locations$collect_time_pdt <- force_tz(locations$collect_time_pdt, "UTC")
  # attr(locations$collect_time_pdt, "tzone") <- tz_pdt
  
  # !!!!!!check histogram to make sure time zone is correct!!!!!!!
  # hist(hour(locations$collect_time_pdt))
  
  return(locations)
}

# 2025 HTS datasets ----

get_all_walk_transit_data <- function(){

  # get trip data
  trip_columns <- c("tripid","trip_id",
                    "day_id","person_id","survey_year",
                    "depart_date","depart_time_hour","depart_time_minute","depart_time_second",
                    "arrive_date","arrival_time_hour","arrival_time_minute","arrival_time_second",
                    "origin_lat","origin_lng","dest_lat","dest_lng",
                    "origin_purpose","dest_purpose","distance_miles",
                    "mode_1","mode_2","mode_3","mode_4","mode_acc","mode_egr",
                    "mode_other_specify","mode_type","mode_class","trip_weight")
  
  col_list <- paste0(trip_columns[!trip_columns %in% c("tripid", "mode_type")], collapse=",")
  trips <- get_query(glue("SELECT {col_list} FROM HHSurvey.v_trips WHERE survey_year = 2025")) %>%
    select(any_of(trip_columns))
  
  # get trip departure and arrival datetimes
  df_trip <- trips %>%
    mutate(
      distance_bins = case_when(distance_miles<=1~ "0-1 miles",
                                distance_miles<=2~ "1-2 miles",
                                distance_miles<=5~ "2-5 miles",
                                distance_miles<=15~ "5-15 miles",
                                distance_miles>15~ "more than 15 miles"),
      depart_date = as.POSIXct(depart_date, tz = tz_pdt) + 7 * 3600,
      depart_datetime = depart_date +
        depart_time_hour * 3600 +
        depart_time_minute * 60 +
        depart_time_second,
      arrive_date = as.POSIXct(arrive_date, tz = tz_pdt) + 7 * 3600,
      arrive_datetime = arrive_date +
        arrival_time_hour * 3600 +
        arrival_time_minute * 60 +
        arrival_time_second
    )
  
  # walk to transit trip table: all walk to transit trips
  all_walk_transit <- df_trip %>% filter(
    
    mode_class == "Transit",
    # only consider walk access and egress modes
    mode_acc=="Walked or jogged" & mode_egr=="Walked or jogged"
    
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
  
  return(all_walk_transit)
  
}


# trace data
get_locations_data <- function(all_walk_transit){
  
  locations <- get_location(get_table(db_name = "HouseholdTravelSurvey2025", schema = "delivered_20251021", tbl_name = "ex_location"))
  
  # empty dataframe
  locations_all_walk_transit <- locations[0, ] %>%
    add_column(trip_id = character(0), 
               person_id = character(0),
               depart_datetime = as.POSIXct(character(0), tz = tz_pdt),
               arrive_datetime = as.POSIXct(character(0), tz = tz_pdt),
               transit_submode = character(0))
  
  # loop through all walk to transit trips to fill in empty dataframe
  for(trip in all_walk_transit$trip_id){
    
    # get person ID, depart/arrive times and mode type
    print(all_walk_transit[all_walk_transit$trip_id == trip,"trip_id"][[1]])
    
    person <- substr(trip, 1, 10)
    depart_datetime <- all_walk_transit[all_walk_transit$trip_id == trip,"depart_datetime"][[1]]
    arrive_datetime <- all_walk_transit[all_walk_transit$trip_id == trip,"arrive_datetime"][[1]]
    transit_submode <- all_walk_transit[all_walk_transit$trip_id == trip,"transit_submode"][[1]]
    
    # get trip locations by person within depart/arrive times
    trip_locations <- locations %>% 
      filter(
        # person
        substr(tripid, 1, 10) == person) %>% 
      filter(
        # grab all time points that occurred between trip departure and arrival
        between(collect_time_pdt, depart_datetime, arrive_datetime)) %>%
      # add trips attributes for reference
      mutate(trip_id = trip,
             person_id = person,
             depart_datetime = depart_datetime,
             arrive_datetime = arrive_datetime,
             transit_submode = transit_submode)
    
    locations_all_walk_transit <- locations_all_walk_transit %>% add_row(trip_locations)
  }
  
  return(locations_all_walk_transit)
  
}

