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


# Drivers license data
license = person.groupby('license').sum()['expwt_final']
license_sample = person.groupby('license').count()['expwt_final']

# Drivers license by age
license_by_age = pd.pivot_table(person, values='expwt_final', rows='age',
                                    columns='license', aggfunc=np.sum) 