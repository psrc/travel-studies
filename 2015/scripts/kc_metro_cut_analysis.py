import json
import pandas as pd
import numpy as np
#import household, person, vehicle, trip
import config
import process_survey as ps
import os

# Load latest data

# Load the survey data per HHSurveyToPandas.py
household = ps.load_data(config.household_file)
person = ps.load_data(config.person_file)
trip = ps.load_data(config.trip_file)

# Load dictionary to relate route name to survey ID
deleted_routes = pd.read_excel('kcmetrocuts.xlsx', 'Deleted')
revised_routes = pd.read_excel('kcmetrocuts.xlsx', 'Revised')

# Count trips on each transit route (using the survey ID)
trips_by_route = trip.groupby('transitline1').count()['expwt_final']
# Join 
deleted_route_trips = deleted_routes.join(trips_by_route,on='surveyID')
revised_route_trips = revised_routes.join(trips_by_route,on='surveyID')

# Total trips on these affected lines
print "total trips on deleted routes " + str(deleted_route_trips.sum()['expwt_final'])
print "total trips on revised routes " + str(revised_route_trips.sum()['expwt_final'])

# do it for the connecting trips too by changing the "transit line" number

trips_by_route = trip.groupby('transitline4').count()['expwt_final']
# Join 
deleted_route_trips = deleted_routes.join(trips_by_route,on='surveyID')
revised_route_trips = revised_routes.join(trips_by_route,on='surveyID')

# Total trips on these affected lines
print "total trips on deleted routes " + str(deleted_route_trips.sum()['expwt_final'])
print "total trips on revised routes " + str(revised_route_trips.sum()['expwt_final'])