

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

if(file.exists("pnr_centroids.rds")){
  
  pnr_centroids <- readRDS("pnr_centroids.rds")
  
} else{
  gdb_path <- "NetworkJunction.gdb"
  # st_layers(gdb_path) # List all internal layers, geometry types, and row counts
  zone_centroids <- st_read(dsn = gdb_path, layer = "zone_centroids")
  pnr_centroids <- zone_centroids %>% 
    filter(JunctionType == 7,
           # remove future park and ride lots
           !(str_detect(EditNotes,"Future") | str_detect(EditNotes,"future")))
  
  saveRDS(pnr_centroids, "pnr_centroids.rds")
}
  

pnr_centroids_ll <- st_transform(pnr_centroids, 4326)


# potential location data for park and ride choice ----

get_location <- function(data){
  locations <- data %>%
    mutate(collect_time_pdt = collect_time)
  attr(locations$collect_time_pdt, "tzone") <- tz_pdt
  locations$collect_time_pdt <- force_tz(locations$collect_time_pdt, "UTC")
  attr(locations$collect_time_pdt, "tzone") <- tz_pdt
  
  return(locations)
}

# 2025 datasets
# trace data
if(year == 2025){
  log_info("reading 2025 data...")
  
  locations <- get_location(readRDS("J:/Projects/Surveys/HHTravel/Survey2025/Data/delivery_20251021/ex_location.RDS"))
  
  # unlinked trip: used for identify trip IDs (can't be used to infer lots)
  unlinked_trips <- readRDS("J:/Projects/Surveys/HHTravel/Survey2025/Data/delivery_20251021/ex_trip_unlinked.RDS") %>%
    select(any_of(trip_columns)) %>%
    mutate(arrive_datetime = as.POSIXct(arrive_date, tz = tz_pdt) +
             arrival_time_hour * 3600 +
             arrival_time_minute * 60 +
             arrival_time_second,
           depart_datetime = as.POSIXct(depart_date, tz = tz_pdt) +
             depart_time_hour * 3600 +
             depart_time_minute * 60 +
             depart_time_second)
  
  trips <- get_table(schema = "HHSurvey",tbl_name = paste0("trips_",year)) %>%
    rename(trip_id = tripid) %>%
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
}



# 2023
# trace data
if(year == 2023){
  log_info("reading 2023 data...")
  
  locations <- read_csv("J:/Projects/Surveys/HHTravel/Survey2023/Data/old_stuff/data_deliverable_81823/2023/delivered_230907/location.csv") %>%
    mutate(collect_time_pdt = collect_time)
  attr(locations$collect_time_pdt, "tzone") <- tz_pdt

  trips <- get_table(schema = "HHSurvey",tbl_name = paste0("trips_",year)) %>%
    filter(trip_weight>0) %>%
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
}


# 2025 HTS codebook: https://github.com/psrc/travel-studies/tree/master/HTS_codebook/2025_codebook

# specify variables and survey years needed

# variables as topic_vars
# topic_vars <- c(# trip info
#   "initial_trip_id",
#   "dest_purpose","dest_purpose_cat","dest_purpose_cat_5",
#   "mode_1","mode_2","mode_3","mode_4","mode_acc","mode_egr","travelers_total",
#   "mode_class","mode_class_5",
#   "distance_miles","origin_lat","origin_lng","dest_lat","dest_lng",
#   "arrive_date","arrival_time_hour","arrival_time_minute","arrival_time_second",
#   "depart_date","depart_time_hour","depart_time_minute","depart_time_second",
#   "dwell_mins"
#   
# )

# get data
# hts_data <- get_psrc_hts(survey_vars = topic_vars,  # specify HTS variables from quarto doc
#                          survey_years = year
# )


# test person ID matching
# test <- trips %>% 
#   summarise(n_trips = n(), .by = person_id) %>%
#   full_join(locations %>% mutate(person_id = as.integer64(substr(tripid,1,10))) %>%
#               summarise(n_locs = n(), .by = person_id),
#             by="person_id")
# findings: all persons have records in location data
