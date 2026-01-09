import pandas as pd

# Set base path for survey spreadsheets
base_path = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\College database'

# Set spreadsheet file name [0] and worksheet for import [1]
person_file = [r'\1_PSRC_College_PersonDataset_2015-1-23', 'PersonData']
trip_file = [r'\2_PSRC_College_TripDataset_2015-1-23_v1-0', 'TripData']

# Column names (might change for next survey, so keeping this flexible) 
# - Using "p" for person file, "h" for household file", "t" for trip file, and "v" for vehicle file
# 
#p_hhid = "hhid"                 # Household ID on person file
#h_hhid = "hhid"                 # Household ID on household file
#t_personid = "personID"         # Person ID on trip file
#p_personid = "personid"         # Person ID on person file

## Household columns
#h_hhsize = 'hhsize'                     # Household size
#h_numadults = 'numadults'               # Number of adults per household
#h_numchildren = 'numchildren'           # Number of children per household
#h_numworkers = 'numworkers'             # Number of workers per household
#h_numtrips = 'hhnumtrips'               # Household number of trips on travel day (derived) per household
#h_veh_count = 'vehicle_count'           # Number of vehicles per household
#h_income_det_imp = 'hh_income_detailed_imp'     # Detailed household income (imputed)
#h_exp_wt = 'expwt_final'                # Household expansion weight

## Person columns
#p_age = "age"
#p_gender = "gender"
#p_employment = "employment"             # Employment status
#p_jobs_count = "jobs_count"             # Number of jobs
#p_worker = "worker"                     # Worker (yes/no)
#p_student = "student"                   # Student (adult: yes/no/part-time/full-time/vocational)
#p_school = "school"                     # Type of school attended (adult or child)
#p_education = "education"               # Educational attainment
#p_smartphone = "smartphone"             # Age 16+: Has smartphone
#p_license = "license"                   # Age 16+: Has valid drivers license
#p_numtrips = "numtrips"                 # Number of trips made on travel day (derived)
#p_hours_work = "hours_work"             # Work: Hours per week
#p_exp_wt = "expwt_final"                # Person expansion weight


# # Set full path to survey spreadsheet data
survey_list = [person_file, trip_file]
for f in survey_list:
    f[0] = base_path + f[0] + '.xls.'