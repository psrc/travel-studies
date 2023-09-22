# https://

# docs.microsoft.com/en-us/bingmaps/rest-services/routes/calculate-a-distance-matrix

import pandas as pd
import urllib.request
import json
import pyodbc
import numpy as np
import time
import random



# Globals
time_unit = 'minute'
distanceUnit = 'mile'
key_file =r'C:\Users\SChildress\OneDrive - Puget Sound Regional Council\Documents\HHSurvey\bing-key\bing-key-23-survey.txt'
output_file =r'C:\Users\SChildress\Documents\GitHub\travel-studies\2023\summary\trip-distances-2023.csv'


def construct_url(row,api_key):
    #construct a url like this:
    # https:
    # # //dev.virtualearth.net/REST/v1/Routes/DistanceMatrix?origins={lat0,long0;lat1,lon1;latM,lonM}&destinations={lat0,lon0;lat1,lon1;latN,longN}&travelMode={travelMode}&startTime={startTime}&timeUnit={timeUnit}&key={BingMapsAPIKey}
    origin_string=''
    destination_string=''

    this_origin=str(row['ORIGIN_LAT'])+','+str(row['ORIGIN_LNG'])+';'
    origin_string=origin_string+this_origin

    this_destination=str(row['DEST_LAT'])+','+str(row['DEST_LNG'])+';'
    destination_string=destination_string+this_destination

    mode='driving'
    origin_string = origin_string[:-1]
    destination_string = destination_string[:-1]
    first_part_url = 'https:'
    next_part_url ='//dev.virtualearth.net/REST/v1/Routes/DistanceMatrix?origins='
    # put the origins into a list like this {lat0,long0;lat1,lon1;latM,lonM}
    #origin_lat_long =
    #destinations_lat_long =
    od_part_url = origin_string+'&destinations='+destination_string
    mode_part_url = '&travelMode='+mode
    #time_unit_part_url = '&timeUnit='+time_unit
    key_part_url = '&key='+api_key

    the_url = first_part_url + next_part_url+od_part_url +mode_part_url+key_part_url
    return the_url




def get_distances(trips, output_file, api_key):
  
        count=0

        for index, row in trips.iterrows():
                distance_url = construct_url(row,api_key)
                print(distance_url)
                try:
                    response = urllib.request.urlopen(distance_url, timeout=100)
                    r = response.read().decode(encoding="utf-8")
                    result = json.loads(r)
                    result_df=pd.io.json.json_normalize(result['resourceSets'],record_path=['resources','results'])
                    results_w_ids = pd.concat([result_df.reset_index(drop=True), pd.DataFrame(row).transpose().reset_index(drop=True)], axis=1)
                    if count==0:
                        distance_results= results_w_ids
                    else:
                        distance_results = pd.concat([distance_results, results_w_ids])
                    print(str(count))
                except Exception as e:
                    print(str(e))
                    results_w_ids.to_csv(output_file)
                    break
                count=count+1

        return distance_results

api_key = open(key_file).read()

# read in trips form sql server
sql_conn = pyodbc.connect('DRIVER={ODBC Driver 17 for SQL Server}; SERVER=AWS-PROD-SQL\Sockeye;DATABASE=HouseholdTravelSurvey2023;trusted_connection=yes')


trip_table_name= "combined_data.v_trip"
trips  = pd.read_sql('SELECT TRIPID, ORIGIN_LAT, ORIGIN_LNG, DEST_LAT, DEST_LNG FROM '+trip_table_name, con = sql_conn)



trip_distances = get_distances(trips, output_file, api_key)

#update the dataset

# updates sql table fields on the persons table
# UPDATE PERSONS SET commute_drive_time = travelDuration INNER JOIN PERSONS ON PERSONS.PERSONID = drive_times_work.personid
