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

# Get distribution of telecommute hours for those who telecommuted
expanded_hrs = person.groupby('telecommute_hours').sum()['expwt_final']    # expanded numbers
sample_hrs = person.groupby('telecommute_hours').count()['expwt_final']  # sample numbers

# Compare telecommute rates and commute distance by trip
# Select work trips only
work_trips = trip_person_hh.query('d_purpose == 2')
hrs_by_dist_exp = pd.pivot_table(work_trips, values=config.p_exp_wt, 
               rows='telecommute_hours', columns='trip_dur_reported', aggfunc=np.sum)
hrs_by_dist_samp = pd.pivot_table(work_trips, values=config.p_exp_wt, 
               rows='telecommute_hours', columns='trip_dur_reported', aggfunc='count')


# Compare general willingness to telecommute and yes/no telecommute response