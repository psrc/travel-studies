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

# Look at mode splits by RGC home location
rgc_modes = pd.pivot_table(trip_person_hh, values='expwt_final', rows='mode',    
                                    columns='h_rgc_name', aggfunc=np.sum)

rgc_modes_count = pd.pivot_table(trip_person_hh, values='expwt_final', rows='mode',    
                                    columns='h_rgc_name', aggfunc="count")



trip_person_hh.groupby('mode')

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

# Factors influencing carpool behavior
# Commute by carpool, vanpool or transit more if: The price of gas increased to $5 or more per gallon

# By regional growth centers
carpool_gascost_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='carpool_gascost', aggfunc=np.sum)
carpool_gascost_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_ga', aggfunc=np.sum)   # Confirm these col names are right
# Live+Work in same RGC
carpool_gascost_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_ga', aggfunc=np.sum) 
# Live in any RGC and Work in any RGC
carpool_gascost_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_ga', aggfunc=np.sum) 
# Don't live or work in any RGC
carpool_gascost_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_ga', aggfunc=np.sum) 
# by county
carpool_gascost_county_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURNM', 
                                    columns='carpool_ga', aggfunc=np.sum)


# Commute by carpool, vanpool or transit more if: The price of parking increased by 50% (over what I pay now)
carpool_parkingcost_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='carpool_parkingcost', aggfunc=np.sum)
carpool_parkingcost_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_pa', aggfunc=np.sum)   # Confirm these col names are right
# Live+Work in same RGC
carpool_parkingcost_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_pa', aggfunc=np.sum) 
# Live in any RGC and Work in any RGC
carpool_parkingcost_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_pa', aggfunc=np.sum) 
# Don't live or work in any RGC
carpool_parkingcost_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_pa', aggfunc=np.sum)
carpool_parkingcost_county_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURNM',   
                                    columns='carpool_pa', aggfunc=np.sum)

# Commute by carpool, vanpool or transit more if: Tolls on my route cost $5 or more per trip
carpool_tolls_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='carpool_tolls', aggfunc=np.sum)
carpool_tolls_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_to', aggfunc=np.sum)   # Confirm these col names are right
# Live+Work in same RGC
carpool_tolls_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_to', aggfunc=np.sum) 
# Live in any RGC and Work in any RGC
carpool_tolls_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_to', aggfunc=np.sum) 
# Don't live or work in any RGC
carpool_tolls_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_to', aggfunc=np.sum) 
carpool_tolls_county_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURNM',  
                                    columns='carpool_to', aggfunc=np.sum)

# Commute by carpool, vanpool or transit more if: HOV (high occupancy vehicle) lanes saved me 10 minutes per trip (over driving alone)
transit_avail_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='transit_avail', aggfunc=np.sum)
transit_avail_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='transit_av', aggfunc=np.sum)   # Confirm these col names are right
# Live+Work in same RGC
transit_avail_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='transit_av', aggfunc=np.sum) 
# Live in any RGC and Work in any RGC
transit_avail_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='transit_av', aggfunc=np.sum) 
# Don't live or work in any RGC
transit_avail_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='transit_av', aggfunc=np.sum) 
transit_avail_county_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURNM',
                                    columns='transit_av', aggfunc=np.sum) 


# Commute by carpool, vanpool or transit more if: Other
carpool_other_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='carpool_other', aggfunc=np.sum)
carpool_other_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_ot', aggfunc=np.sum)   # Confirm these col names are right
# Live+Work in same RGC
carpool_other_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_ot', aggfunc=np.sum) 
# Live in any RGC and Work in any RGC
carpool_other_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_ot', aggfunc=np.sum) 
# Don't live or work in any RGC
carpool_other_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_ot', aggfunc=np.sum) 
carpool_other_county_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURNM',
                                    columns='carpool_ot', aggfunc=np.sum)


# Commute by carpool, vanpool or transit more if: None of these would get me to commute more by carpool, vanpool, and/or transit
carpool_none_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='carpool_none', aggfunc=np.sum)
carpool_none_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_no', aggfunc=np.sum)   # Confirm these col names are right
# Live+Work in same RGC
carpool_none_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_no', aggfunc=np.sum) 
# Live in any RGC and Work in any RGC
carpool_none_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_no', aggfunc=np.sum) 
# Don't live or work in any RGC
carpool_none_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_no', aggfunc=np.sum) 
carpool_none_county_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURNM',    # RGC name
                                    columns='carpool_no', aggfunc=np.sum)


# Commute by carpool, vanpool or transit more if: Not applicable – I already regularly carpool, vanpool, and/or take transit

carpool_na_rgc = pd.pivot_table(person_hh, values='expwt_final_per', rows='h_rgc_name', 
                                    columns='carpool_na', aggfunc=np.sum)
carpool_na_rgc_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_na', aggfunc=np.sum)   # Confirm these col names are right
# Live+Work in same RGC
carpool_na_rgc_same = pd.pivot_table(work_home_same_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_na_trip', aggfunc=np.sum) 
# Live in any RGC and Work in any RGC
carpool_na_rgc_both = pd.pivot_table(work_home_both_rgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_na_trip', aggfunc=np.sum) 
# Don't live or work in any RGC
carpool_na_rgc_both_nonrgc = pd.pivot_table(work_home_both_nonrgc, values='expwt_fi_1', rows='NAME',    # RGC name
                                    columns='carpool_na_trip', aggfunc=np.sum) 
carpool_na_county_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURNM',    # RGC name
                                    columns='carpool_na', aggfunc=np.sum) 