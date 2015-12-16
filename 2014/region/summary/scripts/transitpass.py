# Queries for transit pass types.
# Segmented by age, county, and income

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

# --- Transit Pass ---
# Typical fare payment: An ORCA card
transitpay_orca_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_orca', 
                                    columns='age', aggfunc=np.sum)
transitpay_orca_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_orca', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_orca_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_orca', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: Cash
transitpay_cash_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_cash', 
                                    columns='age', aggfunc=np.sum)
transitpay_cash_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_cash', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_cash_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_cash', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: Tickets
transitpay_tickets_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_tickets', 
                                    columns='age', aggfunc=np.sum)
transitpay_tickets_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_tickets', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_tickets_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_tickets', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: A U-Pass (or Husky Card)
transitpay_upass_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_upass', 
                                    columns='age', aggfunc=np.sum)
transitpay_upass_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_upass', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_upass_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_upass', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: A Regional Reduced Fare Permit (e.g. Senior or Disability Card/Pass)
transitpay_permit_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_permit', 
                                    columns='age', aggfunc=np.sum)
transitpay_permit_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_permit', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_permit_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_permit', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: FlexPass / Passport
transitpay_flex_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_flex', 
                                    columns='age', aggfunc=np.sum)
transitpay_flex_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_flex', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_flex_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_flex', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: ACCESS Pass
transitpay_access_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_access', 
                                    columns='age', aggfunc=np.sum)
transitpay_access_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_access', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_access_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_access', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: School District Card/Pass
transitpay_school_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_school', 
                                    columns='age', aggfunc=np.sum)
transitpay_school_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_school', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_school_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_school', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: City or County Employee Badge
transitpay_govt_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_govt', 
                                    columns='age', aggfunc=np.sum)
transitpay_govt_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_govt', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_govt_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_govt', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: Other
transitpay_other_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_other', 
                                    columns='age', aggfunc=np.sum)
transitpay_other_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_other', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_other_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_other', 
                                    columns='hh_income_detailed', aggfunc=np.sum)

# Typical fare payment: I don't know
transitpay_dontknow_age = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_dontknow', 
                                    columns='age', aggfunc=np.sum)
transitpay_dontknow_county = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_dontknow', 
                                    columns='h_county_name', aggfunc=np.sum)
transitpay_dontknow_inc = pd.pivot_table(person_hh, values='expwt_final_per', index='transitpay_dontknow', 
                                    columns='hh_income_detailed', aggfunc=np.sum)