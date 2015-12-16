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

######################################################################

# Transit subsidy
# Employer or school pays for part or all of transit pass or E-purse value

transit_subsidy = person.groupby('transit_subsidy').sum()['expwt_final']
transit_subsidy_sample = person.groupby('transit_subsidy').count()['expwt_final']

# by work county
# Import spreadsheet with workplace location data from work_location.py 
from work_location import person_work_loc
transit_subsidy_county_work = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='transit_su', 
                                    columns='JURNM', aggfunc=np.sum)
transit_subsidy_county_work_samples = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='transit_su', 
                                    columns='JURNM', aggfunc='count')

# by rgc
# Look at mode splits by RGC home location
transit_subsidy_rgc_work = pd.pivot_table(person_work_hh, values='expwt_fi_1', rows='transit_su',    
                                    columns='h_rgc_name', aggfunc=np.sum)
transit_subsidy_rgc_samples = pd.pivot_table(person_work_hh, values='expwt_fi_1', rows='transit_su',    
                                    columns='h_rgc_name', aggfunc='count')