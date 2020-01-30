# Trip mapping and visualization script based upon RSG's household travel survey (rMove) location dataframe.
# Purpose: to show trip path data on a map fora  given trip or set of trips.
# (C) RSG, 2019


# leaflet map to visualize trip path data
library(leaflet)
library(lubridate)
library(dplyr)
library(geosphere)
library(data.table)
library(odbc)
library(DBI)

map_trips <- function(df, basemap = "OpenStreetMap") {

  # function assumes a location data frame (df) with the following format:
  # tripid (numeric), lat (decimal), lng (decimal), collected_at (timestamp, localtime), speed (point speed; in meters per second),
  # if you want to plot more than 8 trips at a time, you will need to edit the color palette below.

  # function requires leaflet, geosphere, dplyr, and lubridate packages.

  # error handling
  if ( length(unique(df$tripid)) == 0 ) {stop("Please provide tripids")}
  if ( !all(c("tripid", "lat", "lng", "collected_at", "speed") %in% names(df)) ) {stop("Please provide properly formatted location dataframe")}
  tripids <- unique(df[['tripid']])

  # derive helper columns
  df <- df %>%
    group_by(tripid) %>%
    mutate(prior_segment_dist_mi   = geosphere::distGeo(p1 = matrix(c(lng, lat), ncol = 2), p2 = matrix(c(lag(lng), lag(lat)), ncol = 2)) / 1609.34, # 1609.34 meters per mile
           prior_segment_time_sec  = as.numeric(seconds(collected_at - lag(collected_at))),
           prior_segment_speed_mph = round(prior_segment_dist_mi / (prior_segment_time_sec / 60 / 60), 2),
           is_origin = if_else(min(as.numeric(collected_at)) == collected_at, 1L, NA_integer_),
           is_dest   = if_else(max(as.numeric(collected_at))== collected_at, 1L, NA_integer_),
           total_dist_mi      = round(sum(prior_segment_dist_mi, na.rm = TRUE), 2),
           total_duration_min = round(as.numeric(seconds(max(as.numeric(collected_at), na.rm = TRUE)) - seconds(min(as.numeric(collected_at), na.rm = TRUE))) / 60, 2),
           trip_speed = round(total_dist_mi / (total_duration_min / 60), 1),
           personid = trunc(tripid / 1000)
           ) %>%
    group_by(personid) %>%
    mutate(dwell_time = if_else(!is.na(is_dest), round(as.numeric(seconds(lead(collected_at) - collected_at)) / 60, 0), 0))

  # leaflet seems to require individual dataframes for the popups of each feature (waypoint, endpoint, etc).
  df_waypoints   <- df %>% filter(is.na(is_origin) & is.na(is_dest))
  df_startpoints <- df %>% filter(!is.na(is_origin))
  df_endpoints   <- df %>% filter(!is.na(is_dest))

  # create basemap using the full data frame
  map <- leaflet(df) %>% addProviderTiles(basemap)

  # create popups for each type of marker
  popup_way <- paste0("tripid: ", df_waypoints$tripid, "<br>",
                      "time (local?): ", df_waypoints$collected_at, "<br>",
                      "dayofweek: ", wday(df_waypoints$collected_at), "<br>",
                      "trip dist (mi): ", round(df_waypoints$total_dist_mi, 1), "<br>",
                      "duration (min): ", round(df_waypoints$total_duration_min, 1), "<br>",
                      "trip speed (ave): ", round(df_waypoints$trip_speed, 1), "<br>",
                      "prior seg. speed (mph): ", round(df_waypoints$prior_segment_speed_mph, 1),"<br>",
                      "point speed (mph): ", round(df_waypoints$speed * 2.23694, 1),"<br>" # 2.23694 meters per sec to mph conversion

                      # think about adding other data, like mode, purpose, etc
                      )

  popup_beg <- paste0("tripid: ", df_startpoints$tripid, "<br>",
                      "time (local?): ", df_startpoints$collected_at, "<br>",
                      "dayofweek: ", wday(df_startpoints$collected_at), "<br>",
                      "trip dist (mi): ", round(df_startpoints$total_dist_mi, 1), "<br>",
                      "duration (min): ", round(df_startpoints$total_duration_min, 1), "<br>",
                      "trip speed (ave): ", round(df_startpoints$trip_speed, 1), "<br>",
                      "prior seg. speed (mph): ", round(df_startpoints$prior_segment_speed_mph, 1),"<br>",
                      "point speed (mph): ", round(df_startpoints$speed * 2.23694, 1),"<br>",
                      "point is trip origin"
                      )

  popup_end <- paste0("tripid: ", df_endpoints$tripid, "<br>",
                      "time (local?): ", df_endpoints$collected_at, "<br>",
                      "dayofweek: ", wday(df_endpoints$collected_at), "<br>",
                      "trip dist (mi): ", round(df_endpoints$total_dist_mi, 1), "<br>",
                      "duration (min): ", round(df_endpoints$total_duration_min, 1), "<br>",
                      "trip speed (ave): ", round(df_endpoints$trip_speed, 1), "<br>",
                      "prior seg. speed (mph): ", round(df_endpoints$prior_segment_speed_mph, 1),"<br>",
                      "point speed (mph): ", round(df_endpoints$speed * 2.23694, 1),"<br>",
                      "point is trip dest.", "<br>",
                      "dwell time (min): ", df_endpoints$dwell_time, "<br>"
                      )

  # establish unique colors for each trip polyline
  trip_line_colors <- length(tripids) + 1
  line_pal <- colorFactor(palette = "Dark2", domain = 1:trip_line_colors) # can also use "viridis", "Spectral", "Blues", etc

  # # loop through each tripid to add polyline to map. each trip must be added individually.
  # for (trip in tripids) {
  #   map <- map %>%
  #     addPolylines(lng = ~lng[tripid == trip],
  #                  lat = ~lat[tripid == trip],
  #                  color = ~line_pal(trip_line_colors),
  #                  opacity = 1.0, fillOpacity = 0.5,
  #                  weight = 5, smoothFactor = 0.5
  #                  )
  # 
  #   trip_line_colors <- trip_line_colors - 1
  # }

  # add waypoint markers
  marker_pal <- colorBin(palette = c("red", "yellow", "green", "purple"),
                      #domain = df$prior_segment_speed_mph,
                      domain = c(0, 90),
                      bins = 9)

  map <- map %>%
    addCircleMarkers(lng = ~lng,
                     lat = ~lat,
                     radius = 4,
                     color = "black",
                     weight = 1,
                     opacity = 0.8,
                     fillColor = ~marker_pal(prior_segment_speed_mph),
                     fillOpacity = 0.8,
                     popup = popup_way,
                     data = df_waypoints)

  # add trip start/end markers.
  map <- map %>%
    addCircleMarkers(lng = ~lng, lat = ~lat, data = df_startpoints, popup = popup_beg, fillColor = "gray", color = "black", radius = 10,  weight = 1, opacity = 0.8, fillOpacity = 0.8) %>%
    addCircleMarkers(lng = ~lng, lat = ~lat, data = df_endpoints,   popup = popup_end, fillColor = "red",  color = "black", radius = 8,   weight = 1, opacity = 0.8, fillOpacity = 0.8)

  # add minimap
  map <- map %>%
    addMiniMap(tiles = basemap, # providers$OpenStreetMap
               toggleDisplay = TRUE)

  return(map)
}

db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\COHO",
                                database = "HouseholdTravelSurvey2019",
                                trusted_connection = "yes"
  )
}

# read table
read.dt <- function(atable) {
  elmer_connection <- db.connect()
  dtelm <- dbReadTable(elmer_connection, SQL(atable))
  dbDisconnect(elmer_connection)
  setDT(dtelm)
}

psrc_loc_name<- 'HHSurvey.Location'


psrc_loc <- read.dt(psrc_loc_name)


psrc_loc_filtered <- filter(psrc_loc, between(personid, 19100000101,19100000101))
psrc_loc_filtered<- filter(psrc_loc_filtered, between(tripnum, 1, 1))

map_trips(df = psrc_loc_filtered)
# map_trips(df = psrc_loc_filtered, basemap = "Esri.NatGeoWorldMap")
# 
# map_trips(df = psrc_loc_filtered, basemap = "Esri.WorldTopoMap")
# map_trips(df = psrc_loc_filtered, basemap = "Esri.WorldImagery")
# map_trips(df = psrc_loc_filtered, basemap = "Stamen.TonerLite")
# map_trips(df = psrc_loc_filtered, basemap = "Hydda.RoadsAndLabels")

# you can save leaflet maps as standalone files using htmlwidgets::saveWidget().

# all basemap providers (not all of them actually work)
names(providers)

