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
benefits_transit
