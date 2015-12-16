import pandas as pd
import numpy as np
import config
import process_survey as ps


# We will still need to reset to trip ids on the trip file by concatenating the fields
# new_trip_num and personID
base_path = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Final database Release 2'
# Load the survey data per process_survey.py
trip = ps.load_data(config.trip_file)
person = ps.load_data(config.person_file)
household = ps.load_data(config.household_file)

hh_in_uga = pd.io.excel.read_excel(io=r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Final database Release 2\SurveyHHinUGA.xlsx', sheetname='SurveyHHinUGA')


hh_uga_or_not= pd.merge(household, hh_in_uga, left_on = 'hhid', right_on = 'hhid', how = 'left')
hh_uga_or_not['InUGA'].fillna(0,inplace=True)

trip_uga_hh =  pd.merge(trip, hh_uga_or_not, left_on = 'hhid', right_on = 'hhid', how = 'left')
drive_trip_uga = trip_uga_hh[trip_uga_hh.driver == 1]
drive_trip_uga['vehicle_miles']= drive_trip_uga['expwt_2_x']*drive_trip_uga['gdist']

vmt_by_loc =pd.pivot_table(drive_trip_uga , values='vehicle_miles', rows='h_county_name', 
                                    columns='InUGA', aggfunc=np.sum)

hh_by_loc = pd.pivot_table(hh_uga_or_not, values = 'expwt_2_x', rows='h_county_name', 
                                    columns='InUGA', aggfunc=np.sum)

persons_hh = pd.merge(person, hh_uga_or_not, left_on = 'hhid', right_on = 'hhid', how = 'left')

persons_by_loc = pd.pivot_table(persons_hh, values = 'expwt_2_x', rows='h_county_name', 
                                    columns='InUGA', aggfunc=np.sum)

vmt_per_hh_by_loc = vmt_by_loc/hh_by_loc

vmt_per_person_by_loc = vmt_by_loc/persons_by_loc

hh_size_by_loc = persons_by_loc/hh_by_loc