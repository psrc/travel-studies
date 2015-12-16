# Queries related to commute benefits provided by employers
# Segmented by county, age, and income

import pandas as pd
import numpy as np
import HHSurveyToPandas as survey_df    # Load survey data

# Load the survey data per HHSurveyToPandas.py
household = survey_df.load_survey_sheet(survey_df.household_file, survey_df.household_sheetname)
vehicle = survey_df.load_survey_sheet(survey_df.vehicle_file, survey_df.vehicle_sheetname)
person = survey_df.load_survey_sheet(survey_df.person_file, survey_df.person_sheetname)
trip = survey_df.load_survey_sheet(survey_df.trip_file, survey_df.trip_sheetname)

# Merge household records to person file
person_hh = pd.merge(person, household, left_on=['hhid'], right_on=['hhid'], suffixes=('_per', '_hh'))

# Merge person-household records to trip file
trip_person_hh = pd.merge(trip, person_hh, left_on=['personID'], 
                          right_on=['personid'], suffixes=('_trip', '_person_hh'))

# --- Pivot Table Queries ---
# 
# Aggregating on expwt sums to represent total households, not just survey results


# --- Benefits ---
# Flextime
benefits_flextime_county = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_flextime', 
                                    columns='h_county_name', aggfunc=np.sum)
benefits_flextime_age = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_flextime', 
                                    columns='age', aggfunc=np.sum)
benefits_flextime_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_flextime', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Compressed workweek
benefits_compressed_county = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_compressed', 
                                    columns='h_county_name', aggfunc=np.sum)
benefits_compressed_age = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_compressed', 
                                    columns='age', aggfunc=np.sum)
benefits_compressed_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_compressed', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Parking benefits
benefits_parking_county = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_parking', 
                                    columns='h_county_name', aggfunc=np.sum)
benefits_parking_age = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_parking', 
                                    columns='age', aggfunc=np.sum)
benefits_parking_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_parking', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Transit benefits
benefits_transit_county = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_transit', 
                                    columns='h_county_name', aggfunc=np.sum)
benefits_transit_age = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_transit', 
                                    columns='age', aggfunc=np.sum)
benefits_transit_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_transit', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Commute benefits
benefits_commute_county = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_commute', 
                                    columns='h_county_name', aggfunc=np.sum)
benefits_commute_age = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_commute', 
                                    columns='age', aggfunc=np.sum)
benefits_commute_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='benefits_commute', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

def end_sound():
    ws.Beep(932, 250)
    sleep(0.25)
    ws.Beep(698, 166)
    ws.Beep(659, 166)
    ws.Beep(698, 167)
    ws.Beep(784, 500)
    ws.Beep(698, 500)
    sleep(0.5)
    ws.Beep(880, 250)
    sleep(0.25)
    ws.Beep(932, 250)
    sleep(0.25)
    ws.Beep(233, 500)