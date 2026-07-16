

trip_columns <- c("tripid","trip_id",
                  "day_id","person_id","survey_year",
                  "depart_date","depart_time_hour","depart_time_minute","depart_time_second",
                  "arrive_date","arrival_time_hour","arrival_time_minute","arrival_time_second",
                  "origin_lat","origin_lng","dest_lat","dest_lng",
                  "origin_purpose","dest_purpose","distance_miles",
                  "mode_1","mode_2","mode_3","mode_4","mode_acc","mode_egr",
                  "mode_other_specify","mode_type","mode_class","trip_weight")

tz_pdt <- "America/Los_Angeles"


# park and ride lots ----
pnr_db_path <- "T:/60day-TEMP/Joanne_temp/NetworkJunctionDB.gdb"

if(file.exists("pnr_centroids.rds")){
  
  pnr_centroids <- readRDS("pnr_centroids.rds")
  
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
  saveRDS(pnr_centroids, "pnr_centroids.rds")
}
  
# change to long/lat for leaflet mapping
pnr_centroids_ll <- st_transform(pnr_centroids, 4326)


# potential location data for park and ride choice ----

get_location <- function(data){
  locations <- data %>%
    mutate(collect_time_pdt = collect_time)
  attr(locations$collect_time_pdt, "tzone") <- tz_pdt
  # locations$collect_time_pdt <- force_tz(locations$collect_time_pdt, "UTC")
  # attr(locations$collect_time_pdt, "tzone") <- tz_pdt
  
  # check histogram to make sure time zone is correct
  # hist(hour(locations$collect_time_pdt))
  
  return(locations)
}

# 2025 datasets ----
# trace data
locations <- get_location(get_table(db_name = "HouseholdTravelSurvey2025", schema = "delivered_20251021", tbl_name = "ex_location"))

# get trip data
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


# unlinked trip: used for identify trip IDs (can't be used to infer lots)
# unlinked_trips <- get_table(db_name = "HouseholdTravelSurvey2025", schema = "delivered_20251021", tbl_name = "ex_trip_unlinked") %>%
#   select(any_of(trip_columns)) %>%
#   mutate(arrive_datetime = as.POSIXct(arrive_date, tz = tz_pdt) +
#            arrival_time_hour * 3600 +
#            arrival_time_minute * 60 +
#            arrival_time_second,
#          depart_datetime = as.POSIXct(depart_date, tz = tz_pdt) +
#            depart_time_hour * 3600 +
#            depart_time_minute * 60 +
#            depart_time_second)

