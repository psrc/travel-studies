# Queries for factors influencing walking, bike, and transit use
# Segmented by regional center, major center, and non-center

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
                          right_on=['personid'], suffixes=('_x', '_y'))

# Also want to evaluate results by workplace location
# Import spreadsheet with workplace location data from work_location.py 
from work_location import person_work_loc

# Also interested in case where household and work location is in same RGC
# Need to join person_work_loc data to household data
person_work_hh = pd.merge(person_work_loc, person_hh, left_on=['hhid_x'], 
                          right_on=['hhid'], suffixes=('_trip', '_person_hh'))

# Replace blank with NaN
person_work_hh.replace(' ', np.nan, inplace=True)
person_work_hh.fillna(-9999, inplace=True)

# Query for respondents with home and work in same RGC
work_home_same_rgc = person_work_hh.query('(NAME == h_rgc_name) & (NAME != -9999)')

# Rrespondents work and live in ANY combination of RGCs (e.g., live downtown Seattle, work Bellevue)
work_home_both_rgc = person_work_hh.query('(NAME != -9999) & (h_rgc_name != -9999)')

# Respondents work and live BOTH outside any regional center
work_home_both_nonrgc = person_work_hh.query('(NAME == -9999) & (h_rgc_name == -9999)')

# Send to clipboard for pasting into Excel
def outclip(file):
    file.to_clipboard()

# Factors influencing mode choice

# wbt_transitsafety
# Walk, bike or ride transit more if: Safer ways to get to transit stops (e.g. more sidewalks, lighting, etc.)

# By regional growth centers
wbt_transitsafety_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='wbt_transitsafety', aggfunc=np.sum)
wbt_transitsafety_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_transi', aggfunc=np.sum)   # Confirm these col names are right
# Live+Work in same RGC
wbt_transitsafety_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_transi', aggfunc=np.sum) 
# Live in any RGC and Work in any RGC
wbt_transitsafety_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_transi', aggfunc=np.sum) 
# Don't live or work in any RGC
wbt_transitsafety_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_transi', aggfunc=np.sum) 

# wbt_transitfreq
# Walk, bike or ride transit more if: Increased frequency of transit (e.g. how often the bus arrives)
wbt_transitfreq_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='wbt_transitfreq', aggfunc=np.sum)
wbt_transitfreq_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_tran_1', aggfunc=np.sum)
wbt_transitfreq_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_tran_1', aggfunc=np.sum)
wbt_transitfreq_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_tran_1', aggfunc=np.sum)
wbt_transitfreq_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_tran_1', aggfunc=np.sum)

# wbt_reliability
# Walk, bike or ride transit more if: Increased reliability of transit (e.g. the bus always arrives at exactly the scheduled time)
wbt_reliability_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='wbt_reliability', aggfunc=np.sum)
wbt_reliability_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_reliab', aggfunc=np.sum)
wbt_reliability_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_reliab', aggfunc=np.sum)
wbt_reliability_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_reliab', aggfunc=np.sum)
wbt_reliability_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_reliab', aggfunc=np.sum)

# wbt_bikesafety
# Walk, bike or ride transit more if: Safer bicycle routes (e.g. protected bike lanes)
wbt_bikesafety_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='wbt_bikesafety', aggfunc=np.sum)
wbt_bikesafety_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_bikesa', aggfunc=np.sum)
wbt_bikesafety_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_bikesa', aggfunc=np.sum)
wbt_bikesafety_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_bikesa', aggfunc=np.sum)
wbt_bikesafety_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_bikesa', aggfunc=np.sum)

# wbt_walksafety
# Walk, bike or ride transit more if: Safer walking routes (e.g. more sidewalks, protected crossings, etc.)
wbt_walksafety_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='wbt_walksafety', aggfunc=np.sum)
wbt_walksafety_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_walksa', aggfunc=np.sum)
wbt_walksafety_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_walksa', aggfunc=np.sum)
wbt_walksafety_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_walksa', aggfunc=np.sum)
wbt_walksafety_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_walksa', aggfunc=np.sum)

# wbt_other
# Walk, bike or ride transit more if: Other
wbt_other_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='wbt_other', aggfunc=np.sum)
wbt_other_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_other', aggfunc=np.sum)
wbt_other_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_other_trip', aggfunc=np.sum)
wbt_other_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_other_trip', aggfunc=np.sum)
wbt_other_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_other_trip', aggfunc=np.sum)

# wbt_none
# Walk, bike or ride transit more if: None of these would get me to walk, bike, and/or take transit more
wbt_none_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='wbt_none', aggfunc=np.sum)
wbt_none_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_none', aggfunc=np.sum)
wbt_none_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_none_trip', aggfunc=np.sum)
wbt_none_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_none_trip', aggfunc=np.sum)
wbt_none_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_none_trip', aggfunc=np.sum)

# wbt_na
# Walk, bike or ride transit more if: Not applicable  I already regularly walk, bike, and/or take transit
wbt_na_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='wbt_na', aggfunc=np.sum)
wbt_na_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_na', aggfunc=np.sum)
wbt_na_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_na_trip', aggfunc=np.sum)
wbt_na_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_na_trip', aggfunc=np.sum)
wbt_na_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='wbt_na_trip', aggfunc=np.sum)

# Work benefit: Free or subsidized transit use
benefits_transit_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='benefits_transit', aggfunc=np.sum)
benefits_transit_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='benefits_t', aggfunc=np.sum)
benefits_transit_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='benefits_transit', aggfunc=np.sum)
benefits_transit_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='benefits_transit', aggfunc=np.sum)
benefits_transit_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='benefits_transit', aggfunc=np.sum)