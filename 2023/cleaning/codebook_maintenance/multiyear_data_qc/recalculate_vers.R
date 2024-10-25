library(data.table)
library(stringr)
library(tidyverse)
library(psrcelmer)

### Update num_trips and num_complete_trip_surveys-----

# read HTS data
# list of table names and view names for each data table
table_names <- c('hh','person','day','trip','vehicle')
view_names <- c('v_households_labels','v_persons_labels','v_days_labels','v_trips_labels','v_vehicles_labels')
names(view_names) <- table_names

hh <- get_query(sql= paste0("select * from HHSurvey.", view_names['hh']))
person <- get_query(sql= paste0("select * from HHSurvey.", view_names['person']))
trip <- get_query(sql= paste0("select * from HHSurvey.", view_names['trip']))
day <- get_query(sql= paste0("select * from HHSurvey.", view_names['day']))
setDT(hh)
setDT(person)
setDT(day)
setDT(trip)

day_delivered <- read_csv("C:/Users/JLin/Downloads/day.csv") %>%
  mutate(hhid = as.integer(hhid))

# update num_trips in hh table
hh_trips = trip[, .(num_trips = .N), 'household_id']
hh[, num_trips := NULL]
hh = merge(hh, hh_trips, by = 'household_id', all.x = TRUE)
hh[, num_trips := tidyr::replace_na(num_trips, 0)]

# update num_trips in person table
person_trips = trip[, .(num_trips = .N), 'person_id']
person[, num_trips := NULL]
person = merge(person, person_trips, by = 'person_id', all.x = TRUE)
person[, num_trips := tidyr::replace_na(num_trips, 0)]

# update num_trips in day table
day_trips = trip[, .(num_trips = .N), 'day_id']
day[, num_trips := NULL]
day = merge(day, day_trips, by = 'day_id', all.x = TRUE)
day[, num_trips := tidyr::replace_na(num_trips, 0)]

# update num_complete_trip_surveys in day table
trip[, trip_survey_complete := as.numeric(svy_complete)]
trip_svys_complete = trip[, .(num_complete_trip_surveys = sum(trip_survey_complete, na.rm = TRUE)),
                          'day_id']
day[, num_complete_trip_surveys := NULL]
day = merge(day, trip_svys_complete, by = 'day_id', all.x = TRUE)
day = day[, num_complete_trip_surveys := tidyr::replace_na(num_complete_trip_surveys, 0)]
trip[, trip_survey_complete := NULL]

### Calculate day-level completion--------

# Is the day complete?
day[, day_iscomplete := 0]

# Anyone with all of their trip surveys complete is definitely complete
day[
  is_participant == 1 &
    summary_complete == 1 &
    num_complete_trip_surveys == num_trips,
  day_iscomplete := 1]

# Add non-participants (proxied)
day[
  is_participant == 0 &
    proxy_complete == 1 &
    num_complete_trip_surveys == num_trips,
  day_iscomplete := 1]


### Calculate household-level completion------

# How many people are complete on each hh-day
test <- day %>%
  filter(day_weight>0) %>%
  select(household_id,travel_date,travel_day,day_iscomplete,surveyable,is_participant,day_weight) %>%
  group_by(household_id, travel_date) %>%
  summarise(num_people_complete = case_when(travel_day == "Yes"~sum((day_iscomplete==1) * (surveyable=="Yes"))))

hh_days_complete = day[
  travel_day == 1,
  .(num_people_complete = sum(day_iscomplete * surveyable),
    num_participants_complete = sum(is_participant * day_iscomplete * surveyable)),
  by = .(household_id, travel_date)]


# Identify number of surveyable people in hh
hh[
  person[surveyable == 1, .N, .(hhid)],
  num_surveyable_people := i.N,
  on = .(hhid)]

hh[, num_surveyable_people := NULL]

hh_days_complete[
  hh,
  num_surveyable := i.num_surveyable,
  on = .(hhid)]

# hh day is complete if all surveyable members are complete
hh_days_complete[, day_iscomplete := 1 * (num_people_complete == num_surveyable)]

# Merge hh_day_complete into day and trip
n_days = day[, .N]
day[, hh_day_iscomplete := NULL]
day = merge(
  day,
  unique(hh_days_complete[, .(hhid, travel_date, hh_day_iscomplete = day_iscomplete)]),
  by = c('hhid', 'travel_date'),
  all.x = TRUE)

n_trips = trip[, .N]
trip[, hh_day_iscomplete := NULL]
trip = merge(
  trip,
  unique(hh_days_complete[, .(hhid, travel_date, hh_day_iscomplete = day_iscomplete)]),
  by = c('hhid', 'travel_date'),
  all.x = TRUE)

### Recalculate remaining variables-------

# recalculate numdayscomplete in hh table
hh_days_complete = day[pernum == 1 & hh_day_iscomplete == 1, .(numdayscomplete = .N), 'hhid']
hh[, numdayscomplete := NULL]
hh = merge(hh, hh_days_complete, by = 'hhid', all.x = TRUE)
hh[, numdayscomplete := tidyr::replace_na(numdayscomplete, 0)]

# recalculate numdayscomplete in person table
person_days_complete = day[day_iscomplete == 1, .(numdayscomplete = .N), 'person_id']
person[, numdayscomplete := NULL]
person = merge(person, person_days_complete, by = 'person_id', all.x = TRUE)
person[, numdayscomplete := tidyr::replace_na(numdayscomplete, 0)]

person[, person_is_complete := 1 * (numdayscomplete >= 1)]

# recalculate num_complete_x in hh table
dow_complete = day[pernum == 1 & hh_day_iscomplete == 1, .(num_complete_mon = sum(travel_dow == 1),
                                                           num_complete_tue = sum(travel_dow == 2),
                                                           num_complete_wed = sum(travel_dow == 3),
                                                           num_complete_thu = sum(travel_dow == 4),
                                                           num_complete_fri = sum(travel_dow == 5),
                                                           num_complete_sat = sum(travel_dow == 6),
                                                           num_complete_sun = sum(travel_dow == 7)), 'hhid']
hh[, c('num_complete_mon', 'num_complete_tue', 'num_complete_wed', 'num_complete_thu',
       'num_complete_fri', 'num_complete_sat', 'num_complete_sun') := NULL]
hh = merge(hh, dow_complete, by = 'hhid', all.x = TRUE)

# recalculate num_days_complete_weekday/weekend
hh[, ':=' (num_days_complete_weekday = num_complete_mon + num_complete_tue +
             num_complete_wed + num_complete_thu + num_complete_fri,
           num_days_complete_weekend = num_complete_sat + num_complete_sun)]

# replace nas in cols
replace_na_cols = c("num_complete_mon", "num_complete_tue", "num_complete_wed", 
                    "num_complete_thu", "num_complete_fri", "num_complete_sat",
                    "num_complete_sun", "num_days_complete_weekday", "num_days_complete_weekend")
hh[, (replace_na_cols) := lapply(.SD, function(x) ifelse(is.na(x), 0, x)), .SDcols = replace_na_cols]

# calculate numdayscomplete and hh_is_complete
hh[, numdayscomplete := num_days_complete_weekday + num_days_complete_weekend]
hh[, hh_is_complete := 1 * (num_complete_mon + num_complete_tue + num_complete_wed + num_complete_thu >= 1)]

person[, hh_is_complete := NULL]
person = merge(person, hh[, c('hhid', 'hh_is_complete')], by = 'hhid', all.x = TRUE)

# recalculate trips_yesno
day[, trips_yesno := ifelse(num_trips == 0, 0, 1)]

# recalculate trip_num
trip[, trip_num := seq_len(.N), by = person_id]

# recalculate trip_id
trip[, trip_id := as.numeric(person_id) * 1000 + tripnum]

hh = hh[hh_is_complete == 1,]
person = person[hhid %in% hh$hhid]
day = day[hhid %in% hh$hhid]
trip = trip[hhid %in% hh$hhid]
vehicle = vehicle[hhid %in% hh$hhid]
