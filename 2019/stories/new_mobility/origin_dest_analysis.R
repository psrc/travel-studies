# This script computes  O-D pairs for TNCs and carshare trips
library(data.table)
library(tidyverse)
library(odbc)
library(DBI)
library(sf)
library(leaflet)
library(tigris)

db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\Sockeye",
                                database = "Elmer",
                                trusted_connection = "yes"
  )
}

read.dt <- function(astring, type =c('table_name', 'sqlquery')) {
  elmer_connection <- db.connect()
  if (type == 'table_name') {
    dtelm <- dbReadTable(elmer_connection, SQL(astring))
  } else {
    dtelm <- dbGetQuery(elmer_connection, SQL(astring))
  }
  dbDisconnect(elmer_connection)
  setDT(dtelm)
}

#read in the trip data
sql.query <- paste("SELECT * FROM HHSurvey.v_trips_2017_2019_in_house")
trips = read.dt(sql.query, 'sqlquery')

#new mobility trips - TNC and carshare
trips_new_mobility = trips %>%  
  filter(mode_1 == "Other hired service (Uber, Lyft, or other smartphone-app car service)"|
           mode_1 == "Carshare service (e.g., Turo, Zipcar, ReachNow)")  

#table of TNC trips origins and destination for mapping
trips_tnc_o = trips_new_mobility %>% filter(mode_1 == "Other hired service (Uber, Lyft, or other smartphone-app car service)") %>% 
  select(trip_id,origin_lat,origin_lng,trip_wt_combined)

trips_tnc_d = trips_new_mobility %>% filter(mode_1 == "Other hired service (Uber, Lyft, or other smartphone-app car service)") %>% 
  select(trip_id,dest_lat,dest_lng,trip_wt_combined)

# set points as sf
locations_sf_o <- st_as_sf(trips_tnc_o, coords = c("origin_lng", "origin_lat"), crs=4326)
locations_sf_d <- st_as_sf(trips_tnc_d, coords = c("dest_lng", "dest_lat"), crs=4326)

#read in PSRC parcel data
psrc_tracts <- tracts("WA", county = c(033,035,053,061), cb = TRUE) %>%
  st_as_sf() %>%
  st_transform(crs=4326)

# spatial join origin and destination points with PSRC region
trip_in_tract_orig <- st_join(locations_sf_o, psrc_tracts)
trip_in_tract_dest <- st_join(locations_sf_d, psrc_tracts)

#count number of origins and destinations in each of the tracts - not correct since we need to use weights
#tnc_counts_d <- count(trip_in_tract_dest, TRACTCE, sort = TRUE)
#tnc_counts_o <- count(trip_in_tract_orig, TRACTCE, sort = TRUE)

#sum trip weights by tract
temp_d = trip_in_tract_dest %>% group_by(TRACTCE)
tnc_counts_d = temp_d %>%  summarise(sum_wt_comb = sum(trip_wt_combined),n = n(),)

temp_o = trip_in_tract_orig %>% group_by(TRACTCE)
tnc_counts_o = temp_o %>%  summarise(sum_wt_comb = sum(trip_wt_combined),n = n())

# Drop the geometry column
tnc_counts_d_no_geometry <- st_set_geometry(tnc_counts_d, NULL)
tnc_counts_o_no_geometry <- st_set_geometry(tnc_counts_o, NULL)

#join counts and psrc geography
tnc_counts_tract_d <- inner_join(psrc_tracts,tnc_counts_d_no_geometry, by = c("TRACTCE" = "TRACTCE"))
tnc_counts_tract_o <- inner_join(psrc_tracts,tnc_counts_o_no_geometry, by = c("TRACTCE" = "TRACTCE"))

# map check - destinations
bins <- c(0,10, 100, 500, 1000, 3000, 5000, max(tnc_counts_tract_d$sum_wt_comb))
pal <- colorBin("YlOrRd", domain = tnc_counts_tract_d$sum_wt_comb, bins = bins)

tracts_dest <- leaflet(tnc_counts_tract_d)%>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data=tnc_counts_tract_d,
              stroke = T,
              opacity = 1,
              weight = 1,
              fillColor = ~pal(tnc_counts_tract_d$sum_wt_comb),
              fillOpacity = 0.7,
              popup = paste("Number of destinations: ", tnc_counts_tract_d$sum_wt_comb, "<br>",
                            "Sample size: ", tnc_counts_tract_d$n )) %>% 
  addLegend(pal = pal, values = tnc_counts_tract_d$sum_wt_comb, opacity = 0.7, title = NULL,
            position = "bottomright")
print(tracts_dest)

# map check - origin
bins <- c(0,10, 100, 500, 1000, 3000, 5000, max(tnc_counts_tract_o$sum_wt_comb))
pal <- colorBin("YlOrRd", domain = tnc_counts_tract_o$sum_wt_comb, bins = bins)

tracts_orig <- leaflet(tnc_counts_tract_o)%>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data=tnc_counts_tract_o,
              stroke = T,
              opacity = 1,
              weight = 1,
              fillColor = ~pal(tnc_counts_tract_o$sum_wt_comb),
              fillOpacity = 0.7,
              popup = paste("Number of origins: ", tnc_counts_tract_o$sum_wt_comb, "<br>",
                            "Sample size: ", tnc_counts_tract_o$n )) %>% 
  addLegend(pal = pal, values = tnc_counts_tract_o$sum_wt_comb, opacity = 0.7, title = NULL,
            position = "bottomright")
print(tracts_orig)


#zipcodes

zipcode_shp <- zctas(cb = TRUE, starts_with = c("98"))%>%
  st_transform(crs=4326)
plot(zipcode_shp)

zipcode_cropped <- st_join(zipcode_shp,psrc_tracts )
zipcode_cropped_upd = zipcode_cropped %>% group_by(ZCTA5CE10)

# spatial join origin and destination points with PSRC region
trip_in_zip_orig <- st_join(locations_sf_o, zipcode_shp)
trip_in_zip_dest <- st_join(locations_sf_d, zipcode_shp)

#count number of origins and destinations in each of the tracts - not correct since we need to use weights
#tnc_counts_d <- count(trip_in_tract_dest, TRACTCE, sort = TRUE)
#tnc_counts_o <- count(trip_in_tract_orig, TRACTCE, sort = TRUE)

#sum trip weights by tract
temp_d = trip_in_zip_dest %>% group_by(ZCTA5CE10)
tnc_counts_d = temp_d %>%  summarise(sum_wt_comb = sum(trip_wt_combined),n = n(),)

temp_o = trip_in_zip_orig %>% group_by(ZCTA5CE10)
tnc_counts_o = temp_o %>%  summarise(sum_wt_comb = sum(trip_wt_combined),n = n())

# Drop the geometry column
tnc_counts_d_no_geometry <- st_set_geometry(tnc_counts_d, NULL)
tnc_counts_o_no_geometry <- st_set_geometry(tnc_counts_o, NULL)

#join counts and psrc geography
tnc_counts_tract_d <- inner_join(zipcode_shp,tnc_counts_d_no_geometry, by = c("ZCTA5CE10" = "ZCTA5CE10"))
tnc_counts_tract_o <- inner_join(zipcode_shp,tnc_counts_o_no_geometry, by = c("ZCTA5CE10" = "ZCTA5CE10"))

# map check - destinations
bins <- c(0,10, 100, 500, 1000, 3000, 5000, max(tnc_counts_tract_d$sum_wt_comb))
pal <- colorBin("YlOrRd", domain = tnc_counts_tract_d$sum_wt_comb, bins = bins)

zip_dest <- leaflet(tnc_counts_tract_d)%>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data=tnc_counts_tract_d,
              stroke = T,
              opacity = 1,
              weight = 1,
              fillColor = ~pal(tnc_counts_tract_d$sum_wt_comb),
              fillOpacity = 0.7,
              popup = paste("Number of destinations: ", tnc_counts_tract_d$sum_wt_comb, "<br>",
                            "Sample size: ", tnc_counts_tract_d$n )) %>% 
  addLegend(pal = pal, values = tnc_counts_tract_d$sum_wt_comb, opacity = 0.7, title = NULL,
            position = "bottomright")
print(zip_dest)

# map check - origin
bins <- c(0,10, 100, 500, 1000, 3000, 5000, max(tnc_counts_tract_o$sum_wt_comb))
pal <- colorBin("YlOrRd", domain = tnc_counts_tract_o$sum_wt_comb, bins = bins)

zip_orig <- leaflet(tnc_counts_tract_o)%>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data=tnc_counts_tract_o,
              stroke = T,
              opacity = 1,
              weight = 1,
              fillColor = ~pal(tnc_counts_tract_o$sum_wt_comb),
              fillOpacity = 0.7,
              popup = paste("Number of origins: ", tnc_counts_tract_o$sum_wt_comb, "<br>",
                            "Sample size: ", tnc_counts_tract_o$n )) %>% 
  addLegend(pal = pal, values = tnc_counts_tract_o$sum_wt_comb, opacity = 0.7, title = NULL,
            position = "bottomright")
print(zip_orig)

