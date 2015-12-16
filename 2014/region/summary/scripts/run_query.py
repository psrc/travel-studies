import utils.config as config





import pandas as pd
import numpy as np
#import HHSurveyToPandas as survey_df    # Load survey data
import process_survey as ps
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import datetime

# Load the person file
hh_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Export\Release 2\2014-pr2-hhsurvey-households.xlsx'
trip_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Export\Release 2\2014-pr2-hhsurvey-trips.xlsx'
person_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Export\Release 2\2014-pr2-hhsurvey-persons.xlsx'
trip_with_rgc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Maps\Release 2\trips_with_rgc.csv'

expwt_name = 'expwt_2'

# This may need to be updated with the latest HH file?
work_loc = r'D:\Survey\HouseholdSurvey2014\Joined Data\Release 1\Workers.xlsx'

# load trip file with rgc info on it

hh = pd.read_excel(hh_loc, 'Data')
trip = pd.read_excel(trip_loc, 'Data')
person = pd.read_excel(person_loc, 'Data')
work = pd.read_excel(work_loc, 'Sheet1')
trip_rgc = pd.read_csv(trip_with_rgc)

work.columns =  [x.lower() for x in work.columns]
trip.columns =  [x.lower() for x in trip.columns]
person.columns =  [x.lower() for x in person.columns]

trip.replace('.',"",inplace=True)
trip.fillna(0,inplace=True)

# Join the trip file with 

# Clean the data by removing very long and very short trips
# Keep track of the number of rows being removed
min_trip_len = 0.05
max_trip_len = 200

trip = trip[trip['gdist'] > min_trip_len]   # remove any trip less ~ 250 ft
trip = trip[trip['gdist'] < max_trip_len] # remove any tips over 200 miles

# Creat an integer version of gdist so we can plot frequency distributions
trip['gdist_int'] = trip['gdist'].astype(int)

# Remove exercise trips (d_purpose = 10)
# Should we actually remove these? 
exercise_trips = trip[trip['d_purpose'] == 10]
trip = trip[trip['d_purpose'] != 10]
trip = trip[trip['d_purpose'] != 15]
walk_trips = trip[trip['mode'] == 7]

# Get commute trips
commute_home2work = trip.query("o_purpose == 1 & d_purpose == 2")
commute_work2home = trip.query("o_purpose == 2 & d_purpose == 1")
all_commute = trip.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")

# Get trips by purpose
school_trips = trip.query("d_purpose == 6")
meal_trips = trip.query("d_purpose == 11")
home_trips = trip.query("d_purpose == 1")
personal_business_trips = trip.query("d_purpose == 8 or d_purpose == 7 or d_purpose == 14")
shop_trips = trip.query("d_purpose == 4 or d_purpose == 5")
social_trips = trip.query('d_purpose == 12 or d_purpose == 13')
other_trips = trip.query("d_purpose == 16 or d_purpose == 15 or d_purpose == 13 or d_purpose == 10 or d_purpose == 9 or d_purpose == 3")
escort_trips = trip.query("d_purpose == 9")


# Make some summaries of these files
def mode_splits(df, mode_col, expwt_col):
    return df.groupby(mode_col).sum()[expwt_col]/(df.groupby(mode_col).sum()[expwt_col].sum())

def weighted_pivot_shares(df, pivot_row, pivot_col, expwt_col, aggfunc):
    sums = pd.pivot_table(df, values=expwt_col, rows=pivot_row,columns=pivot_col,aggfunc=aggfunc)
    return sums/sums.sum()

# Trips by Mode
trip_mode_splits = mode_splits(trip, 'mode', expwt_name)
trips_x_mode = trip.groupby('mode').sum()[expwt_name]

# Trips by Purpose
trip_purp_splits = mode_splits(trip, 'd_purpose', expwt_name)
trips_x_purpose = trip.groupby('d_purpose').sum()[expwt_name]

# Trip Length Distribution
trip_len_dist = trip[['gdist_int',expwt_name]].groupby('gdist_int').sum()[expwt_name].astype(int)

# Walk len dist
trip_len_dist = walk_trips[['gdist_int',expwt_name]].groupby('gdist_int').sum()[expwt_name].astype(int)

# Create some trip distributions by purpose or trip type
work_len_dist = all_commute[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
school_len_dist = school_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
meal_len_dist = meal_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
home_len_dist = home_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
personal_business_len_dist = personal_business_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
shop_trips_len_dist = shop_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
social_trips_len_dist = social_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
other_trips_len_dist = other_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
escort_trips_len_dist = escort_trips[['gdist_int',expwt_name]].groupby('gdist_int').sum()[expwt_name].astype(int)

# Split by TOD
# Pull our hour from the datestamp
timetrip = trip[trip['time_start_hhmm'] != 0]

timetrip['hour_start'] = np.empty_like(timetrip.index)

# Awful loop!!! Need to figure out how to do this with arrays
for row in xrange(len(timetrip.index)):
    print row
    timetrip['hour_start'].iloc[row] = timetrip['time_start_hhmm'].values[row].hour


# Look at trips by RGC
rgc_modes = pd.pivot_table(trip_rgc, values='expwt_final', rows='mode',    
                                    columns='rgc_name', aggfunc='count')

# Commute trips by RGC
commute_trips_rgc = trip_rgc.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")
rgc_commute_modes = pd.pivot_table(commute_trips_rgc, values='expwt_final', rows='mode',    
                                    columns='rgc_name', aggfunc=np.sum)














































# Join the worker location file to trip file to get information about commute shares to RGC

# Merge work loc records to trip file
trip_work = trip.join(work, on='personid', lsuffix= '_trip', rsuffix ='_work')
trip_work.fillna(0,inplace=True)

# Look at mode splits by RGC home location
rgc_modes = pd.pivot_table(trip_work, values='expwt_final', rows='mode',    
                                    columns='rgcname', aggfunc=np.sum