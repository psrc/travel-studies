# QAQC of PSRC 2021 HTS dataset 

# Author: RSG

library(data.table)
library(lubridate)
library(magrittr)

# Update data folder path
user = Sys.getenv('USERNAME')
data_folder_path = sprintf('C:/Users/%s/Resource Systems Group, Inc/Transportation MR - 21016_PSRC_HTS/Internal/3.DataAnalysis/1.Data/SurveyData/Unweighted_Deliverable/Draft_Tables', user)

hts_hh = readRDS(file.path(data_folder_path, "hts_hh.rds"))
hts_person  = readRDS(file.path(data_folder_path,"hts_person.rds"))
hts_vehicle = readRDS(file.path(data_folder_path,"hts_vehicle.rds"))
hts_day     = readRDS(file.path(data_folder_path,"hts_day.rds"))
hts_trip    = readRDS(file.path(data_folder_path,"hts_trip.rds"))

# function
get_distance_meters = function(
  location_1,
  location_2,
  radius = 6378137) {
  
  # convert to matrix if not already a matrix
  location_1 = matrix(location_1, ncol = 2)
  location_2 = matrix(location_2, ncol = 2)
  
  # do some checks on inputs
  # longitudes should be numeric and between -180 & 180
  stopifnot(is.numeric(location_1[, 1]))
  stopifnot(is.numeric(location_2[, 1]))
  stopifnot(location_1[!is.na(location_1[, 1]), 1] %between% c(-180, 180))
  stopifnot(location_2[!is.na(location_2[, 1]), 1] %between% c(-180, 180))
  
  # latitudes should be numeric and between -90 & 90
  stopifnot(is.numeric(location_1[, 2]))
  stopifnot(is.numeric(location_2[, 2]))
  stopifnot(location_1[!is.na(location_1[, 2]), 2] %between% c(-90, 90))
  stopifnot(location_2[!is.na(location_2[, 2]), 2] %between% c(-90, 90))
  
  lon_1 = location_1[, 1] * pi / 180 # converts to radian
  lon_2 = location_2[, 1] * pi / 180
  
  lat_1 = location_1[, 2] * pi / 180
  lat_2 = location_2[, 2] * pi / 180
  
  dLat = lat_2 - lat_1
  dLon = lon_2 - lon_1
  
  a = sin(dLat / 2) ^ 2 + cos(lat_1) * cos(lat_2) * sin(dLon / 2) ^ 2
  a = pmin(a, 1)
  dist = 2 * atan2(sqrt(a), sqrt(1 - a)) * radius
  
  return(dist)
}

# Check summaries for unexpected values, NAs, etc.
str(hts_hh)
summary(hts_hh)

str(hts_person)
summary(hts_person)

str(hts_vehicle)
summary(hts_vehicle)

str(hts_day)
summary(hts_day)

str(hts_trip)
summary(hts_trip)  

# Check for uniqueness

hts_hh[, .N, .(hhid)][N>1]
hts_person[, .N, .(personid)][N>1]
hts_person[, .N, .(hhid, pernum)][N>1]
hts_vehicle[, .N, .(hhid, vehnum)][N>1]
hts_vehicle[, .N, .(vehid)][N>1]
hts_day[, .N, .(personid, daynum)][N>1]
hts_day[, .N, .(hhid, pernum, daynum)][N>1]
hts_trip[, .N, .(hhid, pernum, tripnum)][N>1]
hts_trip[, .N, .(tripid)][N>1]


# Check timestamps

hts_trip[, .N, .(hour(depart_time_timestamp))][order(hour)]
hts_trip[, .N, .(hour(arrival_time_timestamp))][order(hour)]

hts_trip[difftime(arrival_time_timestamp, depart_time_timestamp, units= c("mins")) != reported_duration, 
         .(arrival_time_timestamp, depart_time_timestamp, reported_duration)]

# Check speeds
hts_trip[, mode_type_labeled := factor(mode_type, 
                                      levels = c(1:10, 12:13),
                                      labels = c('walk', 
                                                 'bike',
                                                 'car',
                                                 'taxi',
                                                 'transit',
                                                 'school bus',
                                                 'other',
                                                 'shuttle/vanpool',
                                                 'tnc',
                                                 'carshare',
                                                 'scooter',
                                                 'ld passenger'
                                                 ))]
hts_trip[, .(mean(speed_mph), median(speed_mph), .N), by = .(mode_type_labeled)][order(mode_type_labeled)]

# Check purpose/purpose category alignment

hts_trip[, .N, .(dest_purpose, dest_purpose_cat)][order(dest_purpose, dest_purpose_cat)]
hts_trip[, uniqueN(dest_purpose_cat), .(dest_purpose)][V1 > 1]
hts_trip[, uniqueN(origin_purpose_cat), .(origin_purpose)][V1 > 1]

# Check mode/mode_type alignment

hts_trip[, uniqueN(mode_type), .(mode_1)][V1 > 1]


# check income/income broad alignment
hts_hh[, uniqueN(hhincome_broad), .(hhincome_detailed)][V1 > 1] # only PNTA shows up
hts_hh[, uniqueN(hhincome_broad), .(hhincome_followup)][V1 > 1] # only missing shows up


# Check consistency in num trips

nrow(hts_trip) == hts_day[, .(sum(num_trips))]
nrow(hts_trip) == hts_person[, .(sum(num_trips))]
nrow(hts_trip) == hts_hh[, .(sum(num_trips))]


# Check consistency in household counts

hts_hh[, sum(numchildren)] == hts_person[age < 5, .N]
hts_hh[, sum(numworkers)] == hts_person[jobs_count %in% c(1:994), .N]
hts_hh[, sum(hhsize)] == hts_person[, .N]

# Review derived kid trips and days (keep random so that I look at a variety; don't set seed)
rbindlist(list(hts_trip[personid %in% hts_person[age <=4, personid]][sample(.N, size = 10)], 
               hts_trip[personid %in% hts_person[age >=5, personid]][sample(.N, size = 10)])) %>% View()

rbindlist(list(hts_day[personid %in% hts_person[age == 1, personid]][sample(.N, size = 5)],
               hts_day[personid %in% hts_person[age %in% 2:4, personid]][sample(.N, size = 5)],
               hts_day[personid %in% hts_person[age >=5, personid]][sample(.N, size = 10)])) %>% View()

# Review days for <5 kids
sample_persons = hts_person[age <=4 & sample_source == 1 & num_trips > 0, .(personid)][sample(.N, size = 3)]

hts_trip[personid %in% sample_persons[, personid]] 

# some incomplete days where not all trips were reported by other hh members.

#  check 0 trip days

hts_day[trips_yesno == 2, .N] == hts_day[num_trips == 0, .N]

# review trips that end at home but purpose isn't home

hts_trip[hts_hh, `:=` (home_lat = reported_lat, home_lng =  reported_lng), on = .(hhid)]

hts_trip[dest_purpose_cat != 1 & get_distance_meters(c(home_lng, home_lat), c(dest_lng, dest_lat)) < 100, 
         .N, dest_purpose_cat] %>%
  .[order(dest_purpose_cat)]

hts_trip[dest_purpose_cat != 1 & get_distance_meters(c(home_lng, home_lat), c(dest_lng, dest_lat)) < 100, 
         .N, dest_name] %>%
  .[order(-N)]

# 387 that end close to home and are labeled HOME but purpose != home

# Check for overlapping times
hts_trip = hts_trip[order(hhid, pernum, depart_time_timestamp, arrival_time_timestamp)]
hts_trip[, prev_deptime := shift(depart_time_timestamp, type = 'lag'), by = .(hhid, pernum)]
hts_trip[, next_deptime := shift(depart_time_timestamp, type = 'lead'), by = .(hhid, pernum)]
hts_trip[, prev_arrtime := shift(arrival_time_timestamp, type = 'lag'), by = .(hhid, pernum)]
hts_trip[, next_arrtime := shift(arrival_time_timestamp, type = 'lead'), by = .(hhid, pernum)]

hts_trip[depart_time_timestamp < prev_arrtime, .N]
hts_trip[arrival_time_timestamp >  next_deptime, .N]

# Additional review consists of reviewing frequency tables, reviewing cross-tabs by sample source, and eyeballing the data tables



