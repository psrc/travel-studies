# Queries for residence types and factors influencing residence locations.
# Segmented by county, age, income, residence type, household size, household vehicle count, and education.

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

# -- Residence Types --
# Residence types by county (at household level)
res_type_by_county = pd.pivot_table(household, values='expwt_final', rows='res_type', 
                                    columns='h_county_name', aggfunc=np.sum)
res_type_by_age = pd.pivot_table(person_hh, values='expwt_final_per', index='res_type', 
                                 columns='age', aggfunc=np.sum)


# -- Residence Factors --
# Months per year lived in residence
res_months_by_county = pd.pivot_table(household, values='expwt_final', index='res_months', 
                                    columns='h_county_name', aggfunc=np.sum)
res_months_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_months', 
                                    columns='age', aggfunc=np.sum)
res_months_by_restype = pd.pivot_table(household, values='expwt_final', index='res_months', 
                                    columns='res_type', aggfunc=np.sum)
res_months_by_veh = pd.pivot_table(household, values='expwt_final', index='res_months', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_months_by_size = pd.pivot_table(household, values='expwt_final', index='res_months', 
                                    columns='hhsize', aggfunc=np.sum)
res_months_by_inc = pd.pivot_table(household, values='expwt_final', index='res_months', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_months_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_months', 
                                    columns='education', aggfunc=np.sum)

# How long lived in current residence
res_dur_by_county = pd.pivot_table(household, values='expwt_final', index='res_dur', 
                                    columns='h_county_name', aggfunc=np.sum)
res_dur_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_dur', 
                                    columns='age', aggfunc=np.sum)
res_dur_by_restype = pd.pivot_table(household, values='expwt_final', index='res_dur', 
                                    columns='res_type', aggfunc=np.sum)
res_dur_by_veh = pd.pivot_table(household, values='expwt_final', index='res_dur', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_dur_by_size = pd.pivot_table(household, values='expwt_final', index='res_dur', 
                                    columns='hhsize', aggfunc=np.sum)
res_dur_by_inc = pd.pivot_table(household, values='expwt_final', index='res_dur', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_dur_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_dur', 
                                    columns='education', aggfunc=np.sum)

# Residence tenure status
rent_own_by_county = pd.pivot_table(household, values='expwt_final', index='rent_own', 
                                    columns='h_county_name', aggfunc=np.sum)
rent_own_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='rent_own', 
                                    columns='age', aggfunc=np.sum)
rent_own_by_restype = pd.pivot_table(household, values='expwt_final', index='rent_own', 
                                    columns='res_type', aggfunc=np.sum)
rent_own_by_veh = pd.pivot_table(household, values='expwt_final', index='rent_own', 
                                    columns='vehicle_count', aggfunc=np.sum)
rent_own_by_size = pd.pivot_table(household, values='expwt_final', index='rent_own', 
                                    columns='hhsize', aggfunc=np.sum)
rent_own_by_inc = pd.pivot_table(household, values='expwt_final', index='rent_own', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
rent_own_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='rent_own', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: A change in family size or marital/ partner status
res_factors_hhchange_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_hhchange', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_hhchange_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_hhchange', 
                                    columns='age', aggfunc=np.sum)
res_factors_hhchange_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_hhchange', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_hhchange_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_hhchange', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_hhchange_by_size = pd.pivot_table(household, values='expwt_final', index='res_factors_hhchange', 
                                    columns='hhsize', aggfunc=np.sum)
res_factors_hhchange_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_hhchange', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_hhchange_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_hhchange', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: Affordability
res_factors_afford_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_afford', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_afford_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_afford', 
                                    columns='age', aggfunc=np.sum)
res_factors_afford_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_afford', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_afford_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_afford', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_afford_by_size = pd.pivot_table(household, values='expwt_final', index='res_factors_afford', 
                                    columns='hhsize', aggfunc=np.sum)
res_factors_afford_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_afford', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_afford_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_afford', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: Quality of schools (K-12)
res_factors_school_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_school', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_school_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_school', 
                                    columns='age', aggfunc=np.sum)
res_factors_school_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_school', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_school_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_school', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_school_by_size = pd.pivot_table(household, values='expwt_final', index='res_factors_school', 
                                    columns='hhsize', aggfunc=np.sum)
res_factors_school_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_school', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_school_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_school', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: Having a walkable neighborhood and being near local activities
res_factors_walk_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_walk', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_walk_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_walk', 
                                    columns='age', aggfunc=np.sum)
res_factors_walk_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_walk', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_walk_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_walk', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_walk_by_size = pd.pivot_table(household, values='expwt_final', index='res_factors_walk', 
                                    columns='hhsize', aggfunc=np.sum)
res_factors_walk_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_walk', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_walk_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_walk', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: Having a walkable neighborhood and being near local activities
res_factors_space_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_space', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_space_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_space', 
                                    columns='age', aggfunc=np.sum)
res_factors_space_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_space', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_space_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_space', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_space_by_size = pd.pivot_table(household, values='expwt_final', index='res_factors_space', 
                                    columns='hhsize', aggfunc=np.sum)
res_factors_space_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_space', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_space_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_space', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: Being close to family or friends
res_factors_closefam_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_closefam', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_closefam_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_closefam', 
                                    columns='age', aggfunc=np.sum)
res_factors_closefam_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_closefam', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_closefam_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_closefam', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_closefam_by_size = pd.pivot_table(household, values='expwt_final', index='res_factors_closefam', 
                                    columns='hhsize', aggfunc=np.sum)
res_factors_closefam_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_closefam', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_closefam_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_closefam', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: Being close to public transit
res_factors_transit_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_transit', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_transit_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_transit', 
                                    columns='age', aggfunc=np.sum)
res_factors_transit_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_transit', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_transit_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_transit', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_transit_by_size = pd.pivot_table(household, values='expwt_final', index='res_factors_transit', 
                                    columns='hhsize', aggfunc=np.sum)
res_factors_transit_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_transit', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_transit_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_transit', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: Being close to the highway
res_factors_hwy_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_hwy', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_hwy_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_hwy', 
                                    columns='age', aggfunc=np.sum)
res_factors_hwy_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_hwy', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_hwy_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_hwy', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_hwy_by_size = pd.pivot_table(household, values='expwt_final', index='res_factors_hwy', 
                                    columns='hhsize', aggfunc=np.sum)
res_factors_hwy_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_hwy', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_hwy_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_hwy', 
                                    columns='education', aggfunc=np.sum)

# How important when chose current home: Being within a 30-minute commute to work
res_factors_30min_by_county = pd.pivot_table(household, values='expwt_final', index='res_factors_30min', 
                                    columns='h_county_name', aggfunc=np.sum)
res_factors_30min_by_age = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_30min', 
                                    columns='age', aggfunc=np.sum)
res_factors_30min_by_restype = pd.pivot_table(household, values='expwt_final', index='res_factors_30min', 
                                    columns='res_type', aggfunc=np.sum)
res_factors_30min_by_veh = pd.pivot_table(household, values='expwt_final', index='res_factors_30min', 
                                    columns='vehicle_count', aggfunc=np.sum)
res_factors_30min_by_inc = pd.pivot_table(household, values='expwt_final', index='res_factors_30min', 
                                    columns='hh_income_detailed', aggfunc=np.sum)
res_factors_30min_by_edu = pd.pivot_table(person_hh, values='expwt_final_hh', index='res_factors_30min', 
                                    columns='education', aggfunc=np.sum)