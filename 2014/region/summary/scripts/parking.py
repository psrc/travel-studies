# Queries related to parking cost
# Segmented by county, age, income, and trip purpose

import pandas as pd
import numpy as np
import HHSurveyToPandas as survey_df    # Load survey data
import process_survey as ps

# Load the survey data per HHSurveyToPandas.py
household = survey_df.load_survey_sheet(survey_df.household_file, survey_df.household_sheetname)
vehicle = survey_df.load_survey_sheet(survey_df.vehicle_file, survey_df.vehicle_sheetname)
person = survey_df.load_survey_sheet(survey_df.person_file, survey_df.person_sheetname)
trip = survey_df.load_survey_sheet(survey_df.trip_file, survey_df.trip_sheetname)

# Merge household records to person file
person_hh = pd.merge(person, household, left_on=['hhid'], right_on=['hhid'], suffixes=('_per', '_hh'))

# --- Parking Cost ---
# By trip purpose
park_cost = trip_person_hh.groupby('park_pay').sum()['expwt_final']
park_cost_sample = trip_person_hh.groupby('park_pay').count()['expwt_final']
park_cost_by_county = pd.pivot_table(trip_person_hh, values='expwt_final_per', index='park_pay', 
                                    columns='h_county_name', aggfunc=np.sum)
park_cost_by_purpose = pd.pivot_table(trip_person_hh, values='expwt_final_per', index='park_pay', 
                                    columns='d_purpose', aggfunc=np.sum)
park_cost_by_inc = pd.pivot_table(trip_person_hh, values='expwt_final_per', index='park_pay', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
park_cost_by_age = pd.pivot_table(trip_person_hh, values='expwt_final_per', index='park_pay', 
                                    columns='age', aggfunc=np.sum)

# Parking facility type
park_facility = trip_person_hh.groupby('park').sum()['expwt_final']
park_facility_sample = trip_person_hh.groupby('park').count()['expwt_final']

# Cost by facility type
park_cost_by_age = pd.pivot_table(trip_person_hh, values='expwt_final_per', index='park_pay', 
                                    columns='park', aggfunc=np.sum)
