# Queries for real-time information and smartphone usage

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

# Merge person-household records to trip file
trip_person_hh = pd.merge(trip, person_hh, left_on=['personID'], 
                          right_on=['personid'], suffixes=('_trip', '_person_hh'))

# Also want to evaluate results by workplace location
# Import spreadsheet with workplace location data from work_location.py 
from work_location import person_work_loc

# Send to clipboard for pasting into Excel
def outclip(file):
    file.to_clipboard()

# Get metadata - number of samples per regional center
#metadata = 

# Replace NaN for regional centers to count number of responses not in centers
person_hh = person_hh.fillna(-1)
person_work_loc = person_work_loc.fillna(-1)
# Impact of real-time information
# By household location in regional growth centers


# Travel info impact on travel plans: I make the same trip I was planning, but it is less stressful
# impact_sametrip
impact_sametrip_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='impact_sametrip', aggfunc=np.sum)
# Sort by work location
impact_sametrip_work_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', # County name
                                    columns='impact_sam', aggfunc=np.sum) # Column names were truncated by ArcGIS
impact_sametrip_work_rgc = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME', # RGC name
                                    columns='impact_sam', aggfunc=np.sum) # Column names were truncated by ArcGIS
impact_sametrip_work_dist = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='SDIST00', # RGC name
                                    columns='impact_sam', aggfunc=np.sum) # Column names were truncated by ArcGIS


# Travel info impact on travel plans: I start my trip earlier
# impact_earlier
impact_earlier_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='impact_earlier', aggfunc=np.sum)
impact_earlier_work_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', # County name
                                    columns='impact_ear', aggfunc=np.sum) # Column names were truncated by ArcGIS
impact_earlier_work_rgc = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME', # RGC name
                                    columns='impact_ear', aggfunc=np.sum) # Column names were truncated by ArcGIS
impact_earlier_work_dist = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='SDIST00', # RGC name
                                    columns='impact_ear', aggfunc=np.sum) # Column names were truncated by ArcGIS


# Travel info impact on travel plans: I start my trip later
# impact_later
impact_later_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='impact_later', aggfunc=np.sum)
impact_later_work_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', # County name
                                    columns='impact_lat', aggfunc=np.sum) 
impact_later_work_rgc = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME', # RGC name
                                    columns='impact_lat', aggfunc=np.sum) 
impact_later_work_dist = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='SDIST00', # RGC name
                                    columns='impact_lat', aggfunc=np.sum)

# Travel info impact on travel plans: I choose a completely different route than originally planned
# impact_diffroute
impact_diffroute_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='impact_diffroute', aggfunc=np.sum)
# Stupid truncation means some column names are the same, can't use this one, along with "impact_diffmode"
#
#impact_diffroute_work_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', # County name
#                                    columns='impact_dif', aggfunc=np.sum) 
#impact_diffroute_work_rgc = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME', # RGC name
#                                    columns='impact_dif', aggfunc=np.sum) 
#impact_diffroute_work_dist = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='SDIST00', # RGC name
#                                    columns='impact_dif', aggfunc=np.sum)

# Travel info impact on travel plans: I take my planned route, but with small changes to avoid congestion
# impact_smallchange
impact_smallchange_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='impact_smallchange', aggfunc=np.sum)
impact_smallchange_work_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', # County name
                                    columns='impact_sma', aggfunc=np.sum) 
impact_smallchange_work_rgc = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME', # RGC name
                                    columns='impact_sma', aggfunc=np.sum) 
impact_smallchange_work_dist = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='SDIST00', # RGC name
                                    columns='impact_sma', aggfunc=np.sum)

# Travel info impact on travel plans: I choose a different travel mode (e.g. I take the bus instead of driving)
# impact_diffmode
impact_diffmode_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='impact_diffmode', aggfunc=np.sum)
#impact_diffmode_work_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', # County name
#                                    columns='impact_diffmode', aggfunc=np.sum) 
#impact_diffmode_work_rgc = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME', # RGC name
#                                    columns='impact_dif', aggfunc=np.sum) 
#impact_diffmode_work_dist = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='SDIST00', # RGC name
#                                    columns='impact_diffmode', aggfunc=np.sum)

# Travel info impact on travel plans: I postpone or cancel my trip
# impact_postpone
impact_postpone_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='impact_postpone', aggfunc=np.sum)
impact_postpone_work_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', # County name
                                    columns='impact_pos', aggfunc=np.sum) 
impact_postpone_work_rgc = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME', # RGC name
                                    columns='impact_pos', aggfunc=np.sum) 
impact_postpone_work_dist = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='SDIST00', # RGC name
                                    columns='impact_pos', aggfunc=np.sum)

# Travel info impact on travel plans: I change the number or order of the stops I plan to make on my trip
# impact_order
impact_order_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='impact_order', aggfunc=np.sum)
impact_order_work_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', # County name
                                    columns='impact_ord', aggfunc=np.sum) 
impact_order_work_rgc = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME', # RGC name
                                    columns='impact_ord', aggfunc=np.sum) 
impact_order_work_dist = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='SDIST00', # RGC name
                                    columns='impact_ord', aggfunc=np.sum)

