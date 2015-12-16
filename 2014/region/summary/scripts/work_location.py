import pandas as pd
import numpy as np

# Work location is reported in x-y coordinates, but no data is aggregated at this level.
# For instance, we can segment income and mode choice by household location and county/city/regional center,
# but not yet for work location.

# To find work location, we spatially join x-y coordinate data in the Person file for work location with any 
# geographic bounds we want to evaluate. The geographies considered here will be:

# County, regional centers, TAZ, districts

# To prepare this data for spatial joining in GIS, it needs to be integrated.
# Public-release data excludes x-y coordinates for the Person file, so these data need to be joined from a restricted file
# to a public file. This is done below

# Set path for the restricted and public-release Person files
# Using Release 1 Data
base_path = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Export\Release 1\General Release'
person_public_dir = base_path + r'\Unzipped\2014-pr1-hhsurvey-persons.xlsx'
person_restricted_dir = base_path + r'\Restricted\3_PSRC2014_Person_2014-12-02_X-Y_release_1.xlsx'
output_dir = r'D:\Survey\HouseholdSurvey2014\Joined Data\Release 1\person_all_release1.csv'

# Load each file into memory
person_public = pd.io.excel.read_excel(person_public_dir, sheetname='Data1')
person_restricted = pd.io.excel.read_excel(person_restricted_dir, sheetname='Data1')

# Merge file and export to CSV
person_all = pd.merge(person_public, person_restricted, left_on=['personid'], right_on=['personid'], suffixes=('_x', '_y'))
person_all.to_csv(output_dir, encoding='utf-8') # set encoding to utf-8 - some strange unicode results otherwise 

# The results CSV is processed in GIS and a spatially-joined spreadsheet is used for queries involving workplace location.

# Load the spatially-joined file
person_work_loc_dir = r'D:\Survey\HouseholdSurvey2014\Joined Data\Release 1\personWorkLocSpatiallyJoined_Release1.xlsx'
person_work_sheet = "Sheet1"
person_work_loc = pd.io.excel.read_excel(person_work_loc_dir, sheetname=person_work_sheet)

impact_sametrip_workloc_county = pd.pivot_table(person_work_loc, values='expwt_fi_1', rows='JURLBL', 
                                    columns='impact_sam', aggfunc=np.sum) # Column names were truncated by ArcGIS