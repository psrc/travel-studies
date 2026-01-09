# This file is a hack version of trip_linking.py to create linked trips from a list of manually-identified sets.
# It reads in a list of trips that should be linked and creates a spreadsheet of these linked trips. 
# Save a text file of trip IDs and trip set IDs in link_list.txt and run the script.

import pandas as pd
import numpy as np
import HHSurveyToPandas as survey_df    # Load survey data
import process_survey as ps

# Load the previously linked trip data
file_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Linked Trip Edits\V7\Trips Linked v7 1-24-15.xlsx'
base_trips = pd.read_excel(file_loc, "Linked Trips Combined")
unprocessed_unlinked = pd.read_excel(file_loc, "Unprocessed Unlinked Trips")
#link_list_loc = 'link_list.txt'
link_list_csv = 'link_list.csv'


link_list_df = pd.read_csv(link_list_csv)


## Update the linked_flag values on the base_trips and unprocessed_unlinked files with those from the link_list
## This is necessary because the link_list includes new trips we've added manually to a set
#base_trip
# Join link li

#link_list_df['linked_flag'] = link_list_df['linked_flag'].astype("int64")
#base_trips['new_linked_flag'] = link_list_df['linked_flag']
#unprocessed_unlinked['new_linked_flag'] = link_list_df['linked_flag']


#base_trips.fillna(0, inplace=True)
#unprocessed_unlinked.fillna(0, inplace=True)

def unique_ordered_list(seq):
    seen = set()
    seen_add = seen.add
    return [ x for x in seq if not (x in seen or seen_add(x))]

# Select the trips to be linked from the base_trips file

# List of bad links is the manually ID'ed linked_flag value of trips that look incorrect.
# Remove these from the auto-linked trip and keep in the unlinked trip file\
#bad_links = pd.read_csv(bad_trips)
#with open(link_list_loc, 'r') as f:
#    link_list = []
#    for item in f:
#        link_list.append(int(item[:-1]))

# Get trips from the base trip file
# These are trips that need to be deleted from the base trip file since they're being merged with other records
base_trips_pulled = base_trips[base_trips['tripID'].isin(link_list_df['tripID'].tolist())]

# Get trips from the unprocessed unlinked sheet
unprocessed_trips_pulled = unprocessed_unlinked[unprocessed_unlinked['tripID'].isin(link_list_df['tripID'].tolist())]

# Combine all the unlinked trips together in a single dataframe for processing
unlinked_trips = base_trips_pulled.append(unprocessed_trips_pulled)
unlinked_trips.fillna(0,inplace=True)
#unlinked_trips.columns = list(base_trips_pulled)

# Join with link_list_df to import new linked_flag id
unlinked_trips = pd.merge(unlinked_trips,link_list_df,on="tripID",sort=True,suffixes=['','_new'])


# Update linked_flag ID to fill 0 values on new_linked_flag with old linked_flag values
#unlinked_trips['new_linked_flag'].replace(0,unlinked_trips['linked_flag'],inplace=True)

#unlinked_trips[unlinked_trips['new_linked_flag'] == 0]['new_linked_flag'] = unlinked_trips['linked_flag']

# Update linked_flag ID to fill NaN values on new_linked_flag with old linked_flag values
#unlinked_trips['linked_flag'] = unlinked_trips['linked_flag'].astype("int64")
#unlinked_trips['new_linked_flag'] = unlinked_trips['new_linked_flag'].astype("int64")
#unlinked_trips['new_linked_flag'].apply(lambda x: x.fillna(value=unlinked_trips['linked_flag']))

# Remove the pulled trips from the base trip file
base_trips = base_trips[-base_trips['tripID'].isin(base_trips_pulled.tripID)]


# Now let's merge the unlinked trips together


# Want the sum of all trips in a set for these values
sum_fields = ['gdist', 'gtime', 'trip_dur_reported']

# Want the max of all trips in a set for these values (to capture any instance of use)
# This captures any instance of use in the trip set and assumes only 1 instance per set.
max_fields = ['taxi_type', 'taxi_fare', 'vehicle', 'driver', 'toll', 'pool_start', 'pr_lot1_a', 'pr_lot1',
              'change_vehicles', 'park', 'pr_lot2_a', 'pr_lot2', 'park_pay', 'mode_acc', 'mode_egr']

# Convert to consistent type - float 64
for field in sum_fields:
    unlinked_trips[field] = unlinked_trips[field].astype("float64")

# Convert transitline data into integer
for field in ['transitline' + str(x) for x in xrange(1,5)]:
    unlinked_trips[field] = unlinked_trips[field].astype("int")

# Get the sums and max values of trips grouped by each person's set
sums = unlinked_trips.groupby('linked_flag_new').sum()
maxes = unlinked_trips.groupby('linked_flag_new').max()

# Now we want to squish those unlinked trips together!
# The "primary trip" will inherit characeristics of associated trips
# Return list of primary trips and max distance for each set
#primary_trips = linked_trips_df.groupby('linked_flag').max()[['tripID','gdist']]

# change index to be trip ID because this is the number we ultimately want
df = pd.DataFrame(unlinked_trips)
df.index = unlinked_trips['tripID']
# Find the trip ID of the longest trip in each set
primary_trips = pd.DataFrame(df.groupby('linked_flag_new')['gdist'].agg(lambda x: x.idxmax()))
#unlinked_trips_max4.groupby('linked_flag_new')

# Select only the primary trip from each set
primary_trips_df = unlinked_trips[df['tripID'].isin(primary_trips['gdist'])]
primary_trips_df.index = primary_trips_df.linked_flag_new   # Reset index to trip set ID

# Change primary trip start time to time of first in linked trip set
for field in ['time_start_mam', 'time_start_hhmm', 'o_purpose', 'place_start', 'ocity', 'ocnty', 'ozip', 'address_start', 'olat', 'olng']:
    # Save the original data in a new column
    #primary_trips_df.loc[:,field + '_original'] = primary_trips_df[field]
    primary_trips_df.loc[:,field] = df.groupby('linked_flag_new').apply(lambda x: x[field].iloc[0])

# Change primary trip start time to time of last in linked trip set
# Change primary purpose and activity duration to that of the last trip in the set
for field in ['time_end_hhmm', 'time_end_hhmm', 'a_dur', 'd_purpose', 'place_end', 'dcity', 'dcnty', 'dzip', 'address_end', 'dlat', 'dlng']:
    # Save the original data in a new column
    #primary_trips_df.loc[:,field + '_original'] = primary_trips_df[field]
    primary_trips_df.loc[:,field] = df.groupby('linked_flag_new').apply(lambda x: x[field].iloc[-1])
    
for field in sum_fields:
    # Save original primary trip info in a new column appened with "_original"
    #primary_trips_df.loc[:,field + '_original'] = primary_trips_df[field]
    # Replace the primary trip fields with summed data
    primary_trips_df.loc[:,field] = sums[field]

for field in max_fields:
    # Save original primary trip info in a new column appened with "_original"
    #primary_trips_df.loc[:,field + '_original'] = primary_trips_df[field]
    # Replace the primary trip fields with summed data
    primary_trips_df.loc[:,field] = maxes[field]

# Collect all transitline1 values for a set in a single array
tr1 = pd.DataFrame(df.groupby('linked_flag_new')[['transitline1']].agg(lambda x: x.tolist()))
tr2 = pd.DataFrame(df.groupby('linked_flag_new')[['transitline2']].agg(lambda x: x.tolist()))
tr3 = pd.DataFrame(df.groupby('linked_flag_new')[['transitline3']].agg(lambda x: x.tolist()))
tr4 = pd.DataFrame(df.groupby('linked_flag_new')[['transitline4']].agg(lambda x: x.tolist()))
ts1 = pd.DataFrame(df.groupby('linked_flag_new')[['transitsystem1']].agg(lambda x: x.tolist()))
ts2 = pd.DataFrame(df.groupby('linked_flag_new')[['transitsystem2']].agg(lambda x: x.tolist()))
ts3 = pd.DataFrame(df.groupby('linked_flag_new')[['transitsystem3']].agg(lambda x: x.tolist()))
ts4 = pd.DataFrame(df.groupby('linked_flag_new')[['transitsystem4']].agg(lambda x: x.tolist()))

# Add together all the transitline values (1 through 4)
combined_transitlines = pd.DataFrame(tr1['transitline1'] + tr2['transitline2'] + tr3['transitline3'] + tr4['transitline4'])
combined_transitsys = pd.DataFrame(ts1['transitsystem1'] + ts2['transitsystem2'] + ts3['transitsystem3'] + ts4['transitsystem4'])
#combined_transitlines[0].iloc[0]

combined_transitlines["tr1"] = ""
combined_transitlines["tr2"] = ""
combined_transitlines["tr3"] = ""
combined_transitlines["tr4"] = ""
combined_transitsys["ts1"] = ""
combined_transitsys["ts2"] = ""
combined_transitsys["ts3"] = ""
combined_transitsys["ts4"] = ""

# Number of columns for transit lines or transit systems (4 in 2014 survey design)
num_transitlines = 4
num_transys = 4

for row in xrange(0, len(combined_transitlines)):
    # Add all unlinked trips' transitline data into a list
    combined_transitlines[0].iloc[row] = unique_ordered_list(combined_transitlines[0].iloc[row])  #[0] selects df column
    combined_transitsys[0].iloc[row] = unique_ordered_list(combined_transitsys[0].iloc[row])  #[0] selects df column
    # Remove zeros that might be at beginning of the list
    combined_transitlines[0].iloc[row] = [x for x in combined_transitlines[0].iloc[row] if x != 0]
    combined_transitsys[0].iloc[row] = [x for x in combined_transitsys[0].iloc[row] if x != 0]
    # But we want to pad the rest with zeros for consistent array shape
    combined_transitlines[0].iloc[row] = np.pad(combined_transitlines[0].iloc[row],
                                                (0,num_transitlines-len(combined_transitlines[0].iloc[row])),
                                                mode='constant')
    combined_transitsys[0].iloc[row] = np.pad(combined_transitsys[0].iloc[row],
                                                (0,num_transitlines-len(combined_transitsys[0].iloc[row])),
                                                mode='constant')

    for i in xrange(4):
        combined_transitlines["tr" + str(i + 1)].iloc[row] = combined_transitlines[0].iloc[row][i]
        combined_transitsys["ts" + str(i + 1)].iloc[row] = combined_transitsys[0].iloc[row][i]

# Add the transitline values to the primary trip record
for i in xrange(1,5):
    primary_trips_df['transitline' + str(i)] = combined_transitlines['tr' + str(i)]
    primary_trips_df['transitsystem' + str(i)] = combined_transitsys['ts' + str(i)]


# Send to excel
writer = pd.ExcelWriter('List Link Results.xlsx')

# 
primary_trips_df.to_excel(writer, "Linked Trips Combined", cols=list(primary_trips_df.columns))

# Unlinked trips that need to be edited by hand
writer.close()


# Test some stuff
