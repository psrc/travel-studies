# This script contains various query functions for the 2014 Household Survey data. 
# These functions allow replicable query tools to respond to and reference specific data requests. 

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


# --- Travel information ---
# Website use: How often get travel info from: Websites (e.g. Google Maps, WSDOT website, etc.)
benefits_commute_county = pd.pivot_table(person_hh, values='expwt_final_per', index='apps_use', 
                                    columns='h_county_name', aggfunc=np.sum)

# --- Walk, bike, or ride transit more if: ---
# Walk, bike or ride transit more if: Safer ways to get to transit stops (e.g. more sidewalks, lighting, etc.)
wbt_transitsafety_county = pd.pivot_table(person_hh, values='expwt_final_per', index='wbt_transitsafety', 
                                    columns='h_county_name', aggfunc=np.sum)
# Walk, bike or ride transit more if: Increased frequency of transit (e.g. how often the bus arrives)
# Walk, bike or ride transit more if: Increased reliability of transit (e.g. the bus always arrives at exactly the scheduled time)
# Walk, bike or ride transit more if: Safer bicycle routes (e.g. protected bike lanes)
# Walk, bike or ride transit more if: Safer walking routes (e.g. more sidewalks, protected crossings, etc.)
# Walk, bike or ride transit more if: None of these would get me to walk, bike, and/or take transit more
# Walk, bike or ride transit more if: Not applicable - I already regularly walk, bike, and/or take transit
# --- Commute by carpool, vanpool, or transit more if: ---
# Commute by carpool, vanpool or transit more if: The price of gas increased to $5 or more per gallon
# Commute by carpool, vanpool or transit more if: The price of parking increased by 50% (over what I pay now)
# Commute by carpool, vanpool or transit more if: Tolls on my route cost $5 or more per trip
# Commute by carpool, vanpool or transit more if: HOV (high occupancy vehicle) lanes saved me 10 minutes per trip (over driving alone)
# Commute by carpool, vanpool or transit more if: High-speed transit saved me 10 minutes per trip (over driving alone)
# Commute by carpool, vanpool or transit more if: None of these would get me to commute more by carpool, vanpool, and/or transit
# Commute by carpool, vanpool or transit more if: Not applicable - I already regularly carpool, vanpool, and/or take transit


# Send to clipboard for pasting into Excel
def outclip(file):
    file.to_clipboard()


