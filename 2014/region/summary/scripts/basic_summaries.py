import json
import pandas as pd
import numpy as np
#import household, person, vehicle, trip
import config
import process_survey as ps
import os

# Load latest data

# Load the survey data per HHSurveyToPandas.py
household = ps.load_data(config.household_file)
person = ps.load_data(config.person_file)
trip = ps.load_data(config.trip_file)
veh = ps.load_data(config.vehicle_file)
worker = ps.load_data(config.worker_file)    # Data on workplace location for employed survey respondents only
person_hh = ps.join_hh2per(person, household)
trip_person_hh = ps.join_hhper2trip(trip, person_hh)

# Total person trips
# Multiple ways of calculating this
tot_trips = trip['expwt_final'].sum()
weighted_person_trips = person['numtrips']*person['expwt_final']
tot_person_trips = weighted_person_trips.sum()

# Total persons
tot_persons = person['expwt_final'].sum()

# weighted trips
wt_trip = trip[['d_purpose','expwt_final']]
purpose_totals = wt_trip.groupby('d_purpose').sum()

# Specify codes for trip purposes (4K trip purposes)
hbw_id = 2
hbschool_id = 6
hbshop_id = [4, 5]  # includes groecery and other shopping
hbother_id = [7, 8, 9, 10, 11, 12, 13, 14, 16]  # includes medical, personal business, drop/off, exercise, eating out, rec, and volunteer event + other

# Trip totals
hbw = purpose_totals["expwt_final"].ix[hbw_id]
hbschool = purpose_totals["expwt_final"].ix[hbschool_id]
hbshop = purpose_totals["expwt_final"].ix[hbshop_id].sum()
hbother = purpose_totals["expwt_final"].ix[hbother_id].sum()

# Trip ratesper person by purpose
hbw_rate = hbw/tot_persons
hbschool_rate = hbschool/tot_persons
hbshop_rate = hbshop/tot_persons
hbother_rate = hbother/tot_persons
tot_trip_rate = tot_trips/tot_persons

# Soundcast trip purposes
escort_id = 9
meal_id = 11
none_home_id = 1
personal_business_id = 8
school_id = 6
shop_id = 5 # not including grocery shopping, just other
social_id = 12 # I think this should include more trip types?
work_id = 2

escort = purpose_totals["expwt_final"].ix[escort_id]
meal = purpose_totals["expwt_final"].ix[meal_id]
none_home = purpose_totals["expwt_final"].ix[none_home_id].sum()
personal_business = purpose_totals["expwt_final"].ix[personal_business_id].sum()
school = purpose_totals["expwt_final"].ix[school_id].sum()
shop = purpose_totals["expwt_final"].ix[shop_id].sum()
social = purpose_totals["expwt_final"].ix[social_id].sum()
work = purpose_totals["expwt_final"].ix[work_id].sum()

# Mode shares
trips_by_mode = trip.groupby(['mode']).sum()['expwt_final']

sov = trips_by_mode.loc[1]
hov = trips_by_mode.loc[[2,3]].sum()  # Drove/rode ONLY with other household members + Drove/rode with people not in household (may also include household members)
vanpool = trips_by_mode.loc[5]
walk = trips_by_mode.loc[7]
bike = trips_by_mode.loc[6]
other = trips_by_mode.loc[[4,17,13,14,15,16]].sum()
transit = trips_by_mode.loc[[8,9,10,11,14,15]].sum()

# Trips by household size
trips_by_size = trip_person_hh.groupby('hhsize').sum()['expwt_final_hh']
persons_by_hhsize = person_hh.groupby('hhsize').sum()['expwt_final']
trips_per_person_hhsize = trips_by_size/persons_by_hhsize

# Avg. person-trips by HH size
numtrips_by_hhsize = household.groupby('hhsize').sum()['hhnumtrips']