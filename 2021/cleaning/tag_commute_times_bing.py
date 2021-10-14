# https://

# docs.microsoft.com/en-us/bingmaps/rest-services/routes/calculate-a-distance-matrix

import pandas as pd
import urllib.request
import json
import pyodbc
import numpy as np
import time
import random



#before running add: commute_drive_time, commute_transit_time, commute_distance

# Globals
commute_time_day = '2019-03-26T09:00:00-08:00'
time_unit = 'minute'
distanceUnit = 'mile'
key_file =r'C:\Users\SChildress\Documents\GitHub\travel-studies\2021\summary\bing_key.txt'
output_file =r'C:\Users\SChildress\Documents\GitHub\travel-studies\2021\summary\commute_times_2021_based_on_2019tt.csv'


def construct_url(row, mode, commute_time_day, time_unit, api_key, lat_name, long_name):
    #construct a url like this:
    # https:
    # # //dev.virtualearth.net/REST/v1/Routes/DistanceMatrix?origins={lat0,long0;lat1,lon1;latM,lonM}&destinations={lat0,lon0;lat1,lon1;latN,longN}&travelMode={travelMode}&startTime={startTime}&timeUnit={timeUnit}&key={BingMapsAPIKey}
    origin_string=''
    destination_string=''

    this_origin=str(row['REPORTED_LAT'])+','+str(row['REPORTED_LNG'])+';'
    origin_string=origin_string+this_origin

    this_destination=str(row[lat_name])+','+str(row[long_name])+';'
    destination_string=destination_string+this_destination

    origin_string = origin_string[:-1]
    destination_string = destination_string[:-1]
    first_part_url = 'https:'
    next_part_url ='//dev.virtualearth.net/REST/v1/Routes/DistanceMatrix?origins='
    # put the origins into a list like this {lat0,long0;lat1,lon1;latM,lonM}
    #origin_lat_long =
    #destinations_lat_long =
    od_part_url = origin_string+'&destinations='+destination_string
    mode_part_url = '&travelMode='+mode
    time_unit_part_url = '&timeUnit='+time_unit
    key_part_url = '&key='+api_key
    if mode=='driving':
        time_part_url ='&startTime='+commute_time_day
        the_url = first_part_url + next_part_url+od_part_url +mode_part_url+time_part_url+time_unit_part_url +key_part_url
    else:
        the_url = first_part_url + next_part_url+od_part_url +mode_part_url+time_unit_part_url +key_part_url
    return the_url




def get_times(hh_person, mode,purpose):
  
        file_name = 'times_'+ purpose+'_'+mode
        count=0

        for index, row in hh_person.iterrows():
                lat_name = purpose +"_"+ "LAT"
                long_name = purpose+ "_"+"LNG"
                time_url = construct_url(row, mode, commute_time_day, time_unit, api_key,lat_name, long_name)
                print(time_url)
                try:
                    response = urllib.request.urlopen(time_url, timeout=100)
                    r = response.read().decode(encoding="utf-8")
                    result = json.loads(r)
                    result_df=pd.io.json.json_normalize(result['resourceSets'],record_path=['resources','results'])
                    results_w_ids = pd.concat([result_df.reset_index(drop=True), pd.DataFrame(row).transpose().reset_index(drop=True)], axis=1)
                    if count==0:
                        time_results= results_w_ids
                    else:
                         time_results = pd.concat([time_results, results_w_ids])
                    print(str(count))
                except Exception as e:
                    print(str(e))
                    results_w_ids.to_csv(output_file)
                    break
                count=count+1

        return time_results

api_key = open(key_file).read()

# read in households and persons data from sql server
sql_conn = pyodbc.connect('DRIVER={SQL Server}; SERVER=AWS-PROD-SQL\Sockeye;DATABASE=hhts_cleaning;trusted_connection=true')

person_table_name = "HHSurvey.Person"
person_work  = pd.read_sql('SELECT HHID, PERSONID,WORK_LAT, WORK_LNG FROM '+person_table_name + ' WHERE WORK_LAT IS NOT NULL', con = sql_conn)
person_school = pd.read_sql('SELECT HHID, PERSONID,SCHOOL_LOC_LAT, SCHOOL_LOC_LNG FROM ' + person_table_name+' WHERE SCHOOL_LOC_LAT IS NOT NULL', con = sql_conn)
hh_table_name = "HHSurvey.Household"
hh  = pd.read_sql('SELECT HHID, REPORTED_LAT, REPORTED_LNG FROM '+hh_table_name, con = sql_conn)



hh_person_work = pd.merge(hh, person_work, on = 'HHID')
hh_person_school = pd.merge(hh, person_school, on = 'HHID')


drive_times_work = get_times(hh_person_work, 'driving', 'WORK')
drive_times_work.to_csv(output_file)
#transit_times_work = get_times(hh_person_work, 'transit', 'WORK')
#time.sleep(waiting_time)
#drive_times_school = get_times(hh_person_school, 'driving', 'SCHOOL_LOC')
#time.sleep(waiting_time)
#transit_times_school = get_times(hh_person_school, 'transit', 'SCHOOL_LOC')

#update the dataset

# updates sql table fields on the persons table
# UPDATE PERSONS SET commute_drive_time = travelDuration INNER JOIN PERSONS ON PERSONS.PERSONID = drive_times_work.personid