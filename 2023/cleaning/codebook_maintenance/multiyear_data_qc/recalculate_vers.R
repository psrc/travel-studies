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


# 20241030: geographies all years

all_geographies <- c("school_in_region", "school_county", "school_jurisdiction", "school_rgcname", "school_tract20",
"work_in_region", "work_county", "work_jurisdiction", "work_rgcname", "work_tract20",
"d_in_region", "dest_county", "dest_jurisdiction", "dest_rgcname", "dest_tract10", "dest_tract20", "dest_x_coord", "dest_y_coord",
"o_in_region", "origin_county", "origin_jurisdiction", "origin_rgcname", "origin_tract10", "origin_tract20", "origin_x_coord", "origin_y_coord",
"home_county", "home_jurisdiction", "home_rgcname", "home_tract20",
"prev_home_county", "prev_home_jurisdiction", "prev_home_rgcname", "prev_home_tract20",
"prev_home_notwa_city", "prev_home_notwa_state", "prev_home_notwa_zip", "prev_home_wa",
"second_home_in_region")

hh_vars <- c("household_id","survey_year","hh_weight")
person_vars <- c("household_id","person_id","survey_year","person_weight")
trip_vars <- c("household_id","person_id","trip_id","survey_year","trip_weight")

hh_geo <- hh_data %>% select(any_of(c(hh_vars,all_geographies)))
person_geo <- person_data %>% select(any_of(c(person_vars,all_geographies)))
trip_geo <- trip_data %>% select(any_of(c(trip_vars,all_geographies)))

test <- hh_geo %>%
  filter(hh_weight>0) %>%
  group_by(survey_year) %>%
  summarise_at(vars(home_jurisdiction:prev_home_wa), ~sum(!is.na(.)))
test2 <- person_geo %>%
  filter(person_weight>0) %>%
  group_by(survey_year) %>%
  summarise_at(vars(school_in_region:second_home_in_region), ~sum(!is.na(.)))
test3 <- trip_geo %>%
  filter(trip_weight>0) %>%
  group_by(survey_year) %>%
  summarise_at(vars(dest_county:origin_y_coord), ~sum(!is.na(.)))

test4 <- hh_geo %>%
  filter(home_rgcname=="Not RGC") 

# 20241105: hh_day_iscomplete
test <- day %>% group_by(household_id, daynum, hh_day_iscomplete) %>%
  reframe(check = case_when("No" %in% day_iscomplete~"No",
                              TRUE~"Yes")) %>%
  mutate(same = hh_day_iscomplete==check)
  
  
# 11/13/2024
test_trip <- trip %>% 
  select(trip_id,mode_1,mode_characterization:mode_class,travelers_total:travelers_nonhh,driver,trip_weight,survey_year)

df <- test_trip %>% 
  group_by(survey_year,travelers_total,travelers_hh,travelers_nonhh) %>% 
  summarise(trip_count = n()) %>%
  pivot_wider(id_cols = c("travelers_total","travelers_hh","travelers_nonhh"), names_from = "survey_year", values_from = "trip_count") %>%
  arrange(travelers_total,travelers_hh,travelers_nonhh)


test_person <- person %>%
  group_by(consolidated_transit_pass,benefits_3,commute_subsidy_1,survey_year) %>%
  summarise(person_count = n()) %>%
  pivot_wider(id_cols = c("consolidated_transit_pass","benefits_3","commute_subsidy_1"), names_from = "survey_year", values_from = "person_count") %>%
  arrange(desc(consolidated_transit_pass),desc(commute_subsidy_1),desc(benefits_3)) %>%
  select(c("consolidated_transit_pass","benefits_3","commute_subsidy_1","2017","2019","2021","2023"))
  

test_person <- person %>%
  group_by(commute_subsidy_3,workpass,survey_year) %>%
  summarise(person_count = n()) %>%
  pivot_wider(id_cols = c("consolidated_transit_pass","benefits_3","transit_pass"), names_from = "survey_year", values_from = "person_count") %>%
  arrange(desc(consolidated_transit_pass),desc(transit_pass),desc(benefits_3)) %>%
  select(c("consolidated_transit_pass","benefits_3","transit_pass","2017","2019","2021","2023"))



# 11/21/2024
# check mode value labels in 2023
trip_delivered <- read_csv("J:/Projects/Surveys/HHTravel/Survey2023/Data/old_stuff/data_deliverable_81823/2023/delivered_230907/trip.csv")
unique(trip_delivered$mode_1)
labels_delivered <- read_csv("J:/Projects/Surveys/HHTravel/Survey2023/Data/old_stuff/data_deliverable_81823/codebook_guide/value_labels_2023_08162023.csv")

mode_labels <- labels_delivered %>% 
  filter(variable =="mode_1") %>%
  select(value,final_label)

trip_mode <- trip_delivered %>%
  select(hhid,person_id,tripid,mode_1:mode_other_specify,survey_year) %>%
  left_join(mode_labels %>% rename(final_label_1 = final_label), by=c("mode_1"="value")) %>%
  left_join(mode_labels %>% rename(final_label_2 = final_label), by=c("mode_2"="value")) %>%
  left_join(mode_labels %>% rename(final_label_3 = final_label), by=c("mode_3"="value")) %>%
  left_join(mode_labels %>% rename(final_label_4 = final_label), by=c("mode_4"="value"))

unique_modes_2023 <- sort(unique(c(trip_mode$final_label_1,trip_mode$final_label_2,trip_mode$final_label_3,trip_mode$final_label_4)))


# 12/05/2024: freq
frequency_values <- c("1 day a week",
                      "2-4 days a week",
                      "5 days a week",
                      "6-7 days a week",
                      "1-3 days in the past month",
                      "Never in the past 30 days",
                      "Missing Response")
all_freq_vars <- colnames(person_data)[grepl("freq",colnames(person_data))]
# "commute_freq",
# "telecommute_freq",
# "school_freq"       
# "remote_class_freq",
# 
# "tnc_freq",
# "carshare_freq",
# 
# "transit_freq",
# "transit_frequency" 
# "bike_freq"         
# "bike_frequency",
# "bike_freq_pre_2023",
# "walk_freq"         
# "walk_frequency",
# "walk_freq_pre_2023"



freq_transit <- person_data %>%
  select(c("survey_year",colnames(person_data)[grepl("transit_freq",colnames(person_data))])) %>%
  unique() %>%
  mutate(transit_frequency = factor(transit_frequency,levels=frequency_values))
freq_bike <- person_data %>%
  select(c("survey_year",colnames(person_data)[grepl("bike_freq",colnames(person_data))])) %>%
  unique() %>%
  mutate(bike_frequency = factor(bike_frequency,levels=frequency_values))
freq_walk <- person_data %>%
  select(c("survey_year",colnames(person_data)[grepl("walk_freq",colnames(person_data))])) %>%
  unique() %>%
  mutate(walk_frequency = factor(walk_frequency,levels=frequency_values))


# 12/05/2024: deliver
all_deliver_vars <- colnames(day_data)[grepl("deliver",colnames(day_data))]  
deliver <- day_data %>%
  select(c("survey_year",colnames(day_data)[grepl("deliver",colnames(day_data))]))# %>%
  # mutate_at(vars(matches("freq")), ~case_when(.=="0 (none)"~"No",
  #                                             . %in% c("1","2","3","4","5 or more")~"Yes",
  #                                             .=="Missing: Skip Logic"~"Missing: Skip Logic",
  #                                             TRUE~NA))
deliver_package_2017 <- deliver %>%
  select(survey_year,deliver_package,delivery_pkgs_freq) %>%
  filter(survey_year==2017) %>%
  unique()

deliver_package <- deliver %>%
  select(survey_year,deliver_package,delivery_pkgs_freq) %>%
  unique()

# 2024/12/18
# compare mode_class and mode_characterization
test <- trip_data %>%
  filter(survey_year==2023) %>%
  group_by(mode_characterization,mode_class) %>%
  summarise(n())
bike <- trip_data %>%
  filter(survey_year==2023, mode_characterization=="Bike/Micromobility") %>%
  group_by(mode_characterization,mode_class,mode_1,mode_2,mode_3,mode_4, travelers_total) %>%
  summarise(n())
missing <- trip_data %>%
  filter(survey_year==2023, mode_characterization=="Missing Response") %>%
  group_by(mode_characterization,mode_class,mode_1,mode_2,mode_3,mode_4, travelers_total) %>%
  summarise(n())

purpose <- trip_data %>%
  group_by(dest_purpose_cat,dest_purpose_cat_5) %>%
  summarise(n())

test <- readRDS("C:/Users/JLin/Downloads/shinyapp_var_def.rds")
