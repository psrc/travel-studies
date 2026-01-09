# Replace field values with label strings (e.g., mode value of 7 replaced with "bus"
# Adds labels to all 2014 Survey fields and saves results in a local Excel workbook in the "labeled" directory

import json
import pandas as pd
import numpy as np
import config
import utils.process_survey as ps
import os

# Load latest data

# Load the survey data per HHSurveyToPandas.py
household = ps.load_data(config.household_file)
person = ps.load_data(config.person_file)
trip = ps.load_data(config.trip_file)
veh = ps.load_data(config.vehicle_file)
worker = ps.load_data(config.worker_file)    # Data on workplace location for employed survey respondents only


def json_to_dictionary(dict_name, sheet):
    input_filename = os.path.join('dictionary/', sheet, dict_name+'.json').replace("\\","/")
    my_dictionary = json.load(open(input_filename))

    return(my_dictionary)


# List of dictionary files
onlyfiles = [f for f in os.listdir(os.getcwd() + r'\dictionary') 
             if os.path.isfile(os.path.join(os.getcwd() + r'\dictionary',f))]

# yes/no dataframe - applied to multiple survey responses
# UNBELIEVABLY... some yes/no responses are coded with 0/1 and others are coded 1/2.
# So we have two yes/no lists

yesno01 = pd.DataFrame(data=["No", "Yes"], index=[0, 1], columns=["label"])
yesno12 = pd.DataFrame(data=["No", "Yes"], index=[1, 2], columns=["label"])

# selected/unselected binary dictionary - applied to multiple survey responses
select_unselect = pd.DataFrame(data=["Not selected", "Selected"], index=[0, 1], columns=["label"])

yesno_list_01 = ['worker', 'license', 'added_trip_flag', 'prepop', 'child_under5']
yesno_list_12 = ['prev_home_wa', 'trips_yesno', 'purchase', 'telecommute', 'drive_living',
                 'night_shift']
select_unselect_list = ['prev_home_loc_x', 'added_loop', 'added_quick', 'added_stop', 'added_dropoff',
                        'added_parking', 'added_other', 'transitpay_orca', 'transitpay_cash', 
                        'transitpay_tickets', 'transitpay_upass', 'transitpay_permit', 'transitpay_flex',
                        'transitpay_access', 'transitpay_school', 'transitpay_govt', 'transitpay_other',
                        'transitpay_dontknow', 'prev_work_loc_x', 'web_bing', 'web_google', 'web_mapquest',
                        'web_traffic', 'web_wsdot', 'web_county', 'web_city', 'web_transit', 'web_other',
                        'apps_seattletraffic', 'apps_waze', 'apps_wsdot', 'apps_onebusaway', 'apps_inrix',
                        'apps_carshare', 'apps_taxi', 'apps_other', 'info_travelroutes', 'info_traveltime',
                        'info_congestion', 'info_arrivaltime', 'info_transitoptions', 'info_parking',
                        'info_carshare', 'info_other', 'wbt_transitsafety', 'wbt_transitfreq', 'wbt_reliability',
                        'wbt_bikesafety', 'wbt_walksafety', 'wbt_other', 'wbt_other_specify', 'wbt_none',
                        'wbt_na', 'carpool_gascost', 'carpool_parkingcost', 'carpool_tolls', 'carpool_hov',
                        'transit_avail', 'carpool_other', 'carpool_none', 'carpool_na']

# Add dictionaries to list by survey sheet (e.g., person, trip, vehicle)
def build_label_list(survey_file):
    label_list = []
    for label in onlyfiles:
        if label.split('.')[0] in survey_file.columns:    # Get column name only - strip file extension
            label_list.append(label.split('.')[0])

    return label_list


def label(survey_file, label_list):
    ''' apply labels to survey values '''
    for field in label_list:    # Loop through each data field in the survey file
        # load dict
        field_label = pd.read_csv(r"dictionary/" + field + ".csv", index_col="value", 
                                  encoding='Windows-1252')  # Windows encoding set for special characters
        for field_value in survey_file[field].unique():
            if str(field_value) not in ["nan", "-99.0"]:    # Ignore values not defined in dictionary
                # replace value with label
                survey_file[field].replace(to_replace=field_value, 
                                       value=field_label.loc[int(field_value)].label,
                                       inplace=True)

    # label yes/no fields for 0/1 repsonses
    for field in yesno_list_01:
        if field in survey_file.columns:
            for field_value in [0, 1]:
                survey_file[field].replace(to_replace=field_value,
                                           value=yesno01.loc[int(field_value)].label,
                                           inplace=True)

    # label yes/no fields for 1/2 repsonses
    for field in yesno_list_12:
        if field in survey_file.columns:
            for field_value in [1, 2]:
                survey_file[field].replace(to_replace=field_value,
                                           value=yesno12.loc[int(field_value)].label,
                                           inplace=True)


    # Label selected/not selected 
    for field in select_unselect_list:
        if field in survey_file.columns:
            for field_value in [0, 1]:
                survey_file[field].replace(to_replace=field_value,
                                           value=select_unselect.loc[int(field_value)].label,
                                           inplace=True)

person_labels = build_label_list(person)
hh_labels = build_label_list(household)
trip_labels = build_label_list(trip)
veh_labels = build_label_list(veh)
worker_labels = build_label_list(worker)

label(household, hh_labels)
label(person, person_labels)
label(veh, veh_labels)
label(trip, trip_labels)

# To Excel
writer = pd.ExcelWriter(r'labeled\Survey-Release1-Labeled.xlsx')
household.to_excel(writer, "Household", engine='openpyxl')
person.to_excel(writer, "Person", engine='openpyxl')
trip.to_excel(writer, "Trip", engine='openpyxl')
veh.to_excel(writer, "Vehicle")
writer.save()