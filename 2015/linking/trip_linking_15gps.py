import pandas as pd
import numpy as np

# Load the survey data per HHSurveyToPandas.py
trip_main = pd.read_csv(r'5_PSRC2015_GPS_Trip_v1.0.csv')

# Isolate users with incomplete surveys
# Only link trips for completed surveys
# Add incomplete trips back in at the end
incomplete_trips = trip_main[trip_main['svy_iscomplete'].isin([0,2])]
trip_main = trip_main[trip_main['svy_iscomplete'] == 1]

# Load list of trips with manual flags
# flagged_trips = pd.read_csv('manual_flags.csv', names=['index','tripid'])

# output df
trip_final_dict = {}
trip_with_linked_dict = {}
trip_unlinked_removed_all_dict = {}
primary_trips_df_dict = {}
unlinked_trips_df_dict = {}
unprocessed_unlinked_trips_dict = {}

general_dict = {}
tot_dict = {}

# Filter out by travel date; multiple days, so just re-run this for each 
traveldates = ['19-May-15','20-May-15','21-May-15']
for traveldate in traveldates:
    trip = trip_main[trip_main['traveldate'] == traveldate]

    # Unique flag for each travel date
    tdate = traveldate.split('-')[0]

    # trip.replace('.',0,inplace=True)
    # List of unique personids
    uniquepersonids = trip.groupby('personid').count().index


    # First find the people whose mode changes at all between trips
    # Loop through each person in the survey

    # Ignore trips that are drop-off/pick-up. These might indicate a mode change (SOV to HOV 2 or 3+) but we
    # don't want them to be linked. 

    # Max size of trip sets
    trip_set_max = 3    # 
    # bad_trips = 'bad_trips.txt' # List of linked trips manually identified as [problems

    def unique_ordered_list(seq):
        seen = set()
        seen_add = seen.add
        return [ x for x in seq if not (x in seen or seen_add(x))]

    # Make sure the trip file is sorted by Trip ID first!
    trip.sort('tripid', inplace=True)

    problem_trips = []
    person_counter = 0
    for person in uniquepersonids:
        flag = 1
        #print person_counter
        trip_subsample = trip.query("personid == " + str(person))
        #trip_subsample = trip.query("personid == 1410000801")
        # If there are no mode changes for all trips, ignore this person's trips
        if len(set(trip_subsample['mode'])) > 1:
            # Loop through each person's trips
            for row in xrange(0, len(trip_subsample)-1):
                person_trip = trip_subsample.iloc[row]
                next_pers_trip = trip_subsample.iloc[row+1]

                # Are these 2 trips unlinked?
                if (((person_trip['d_purpose'] == 51)
                	# or (person_trip['tripid'] in flagged_trips['tripid'].values)
                	or ((person_trip['mode'] == 99)
                	or (person_trip['mode'] == next_pers_trip['mode'] == 23 and (
                		person_trip['d_purpose'] == next_pers_trip['d_purpose']) and (person_trip['d_purpose'] != 50))
                	or (person_trip['mode'] == next_pers_trip['mode'] == 29 and (
                		person_trip['d_purpose'] == next_pers_trip['d_purpose']) and (person_trip['d_purpose'] != 50))
                	or (person_trip['mode'] == next_pers_trip['mode'] == 30 and (
                		person_trip['d_purpose'] == next_pers_trip['d_purpose']) and (person_trip['d_purpose'] != 50))
                	# trips with same purpose and different mode, short layover
                	or ((person_trip['mode'] != next_pers_trip['mode']) and (person_trip['a_dur'] <= 15) and (
                		person_trip['d_purpose'] == next_pers_trip['d_purpose']) and (person_trip['d_purpose'] != 50)))
                	# exclude drop-off pickup trips
                	# and (person_trip['d_purpose'] != 50)
                	and (person_trip['a_dur'] <= 15))
                	):
	            	
	            	print person_trip['tripid']
	                # If this looks unlinked, flag it
	                problem_trips.append([tdate + "%05d" % (person_counter,) + "%02d" % (flag,), person_trip['tripid']])
	                problem_trips.append([tdate + "%05d" % (person_counter,) + "%02d" % (flag,), next_pers_trip['tripid']])
	                print len(problem_trips)
                    # Is this trip part of an existing linked trip pair or a new trip pair?
                    # Is the activity duration longer 30 minutes? Then it's probably a separate commute trip
                    # I moved this to the outer loop - originally it was inside the above if statement...
                    # The linked ID is no longer sequential but it is at least unique

                    # move on to new set if the activity duration is long
	                if next_pers_trip['a_dur'] > 30 or (person_trip['d_purpose'] != next_pers_trip['d_purpose']):
	                    flag += 1

                else:
                	flag +=1

                # If there is greater than 30 minutes between these trips, assume we're dealing with a new set of trips for this person
                # if next_pers_trip['a_dur'] > 30:
                # if person_trip['a_dur'] > 30:
                #     flag += 1
                # flag +=1 

        person_counter += 1

    # In the returned array, the first column is a concatentation of person ID in the first 5 columns and the last 2 columns contain the index of the linked trip for each person
    general_dict[traveldate] = pd.DataFrame(problem_trips,columns=['linked_flag', 'tripid'])
    tot_dict[traveldate] = trip


bad_trips = pd.concat([general_dict[traveldate] for traveldate in traveldates])
trip = pd.concat([tot_dict[traveldate] for traveldate in traveldates])

# join tripIDs with trip data
bad_trips = pd.merge(left=bad_trips,right=trip,on='tripid',left_index=True,how='left')
# Trips not selected ("good trips") for evaluation later

bad_trips.drop_duplicates(subset='tripid', inplace=True) # Remove duplicates

# Link the bad trips
# The identified "bad trips" are unlinked. We need to process and "link" them.

# Trips not selected ("good trips") for evaluation later
good_trips = trip[-trip['tripid'].isin(bad_trips['tripid'])]

# Replace 99 mode field with max value from mode1, mode2, mode3, etc.
bad_trips.ix[bad_trips['mode'] == 99, 'mode'] = bad_trips.ix[bad_trips['mode'] == 99][['mode1','mode2','mode3']].max(axis=1)

# Isolate unlinked trips
unlinked_trips = bad_trips.query("linked_flag <> 0")

# List of all linked trip sets and the number of records in each
unlinked_sets = unlinked_trips.groupby('linked_flag').count()['tripid']

# Summary statistics on linked trip sets - gives us an idea of how well we identified linked trips
setsize = {}
for idx in list(unlinked_sets.index):
     # Examine each set of linked trips
     trip_set = unlinked_trips[unlinked_trips['linked_flag'] == idx]
     setsize[idx] = len(trip_set)

# Find distribution of set sizes
df_setsize = pd.DataFrame([setsize.keys(), setsize.values()]).T
df_setsize.index = df_setsize[0]    # Set index equal to the set ID

setsize_dist = df_setsize.groupby(1).count()   # Distribution of set size

unlinked_trips_df = pd.DataFrame(unlinked_trips)
unlinked_trips_df.index = unlinked_trips.linked_flag    # Change index to work with the flag

# Fill zeros so we can convert strings to integer
unlinked_trips_df.fillna(0,inplace=True)

# Get mode combination for each set
unlinked_trips_df['mode'] = unlinked_trips_df['mode'].astype("int64")   # Convert from float to int first
unlinked_trips_df['mode'] = pd.DataFrame(unlinked_trips_df['mode'].astype("str"))     # Convert to string
# Create new column with concatentation of modes
unlinked_trips_df['combined_modes'] = unlinked_trips_df.groupby('linked_flag').apply(lambda x: '-'.join(x['mode']))

# Filter out trips with more than 3 trips in the set
# trip_set_max = 4
# unlinked_trips_df = unlinked_trips_df[unlinked_trips_df['combined_modes'].str.count('-') < trip_set_max]

# Want the sum of all trips in a set for these values
sum_fields = ['distance', 'duration']

# Want the max of all trips in a set for these values (to capture any instance of use)
# This captures any instance of use in the trip set and assumes only 1 instance per set.
# This is sort of okay since we only link 4 trips and it's unlinkely many of these fields will have multiple
# instances, but it should be more methodical in the future. 
max_fields = ['taxi_cost', 'driver', 'park_pay',]

# Convert to consistent type - float 64
for field in sum_fields:
    unlinked_trips_df[field] = unlinked_trips_df[field].astype("float64")

# Convert mode set data into integer
for field in ['mode' + str(x) for x in xrange(1,4)]:
    unlinked_trips_df[field] = unlinked_trips_df[field].astype("int")

# Get the sums and max values of trips grouped by each person's set
sums = unlinked_trips_df.groupby('linked_flag').sum()
maxes = unlinked_trips_df.groupby('linked_flag').max()

# change index to be trip ID because this is the number we ultimately want
df = pd.DataFrame(unlinked_trips_df)
df.index = unlinked_trips_df['tripid']
# Find the trip ID of the longest trip in each set
primary_trips = pd.DataFrame(df.groupby('linked_flag')['distance'].agg(lambda x: x.idxmax()))

# Select only the primary trip from each set
primary_trips_df = unlinked_trips_df[df['tripid'].isin(primary_trips['distance'])]
primary_trips_df.index = primary_trips_df.linked_flag   # Reset index to trip set ID

# Change primary trip start time to time of first in linked trip set
for field in ['min_start', 'time_start', 'o_purpose', 'olat', 'olng']:
    # Save the original data in a new column
    #primary_trips_df.loc[:,field + '_original'] = primary_trips_df[field]
    primary_trips_df.loc[:,field] = df.groupby('linked_flag').apply(lambda x: x[field].iloc[0])

# Change primary trip start time to time of last in linked trip set
# Change primary purpose and activity duration to that of the last trip in the set
for field in ['min_end', 'time_end', 'a_dur', 'd_purpose', 'dlat', 'dlng']:
    # Save the original data in a new column
    #primary_trips_df.loc[:,field + '_original'] = primary_trips_df[field]
    primary_trips_df.loc[:,field] = df.groupby('linked_flag').apply(lambda x: x[field].iloc[-1])

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


# The primary_trips_df are the final linked_trips we want to add to the original data
linked_trips = primary_trips_df


# # Send to excel
writer = pd.ExcelWriter('linked_trips.xlsx')

# # List of unprocessed unlinked trips
# unprocessed_unlinked_trips_tot.to_excel(writer, "Unprocessed Unlinked Trips")



# Add the linked trips to the original "good trips"
final_trips = pd.concat([good_trips,incomplete_trips,linked_trips])
final_trips.to_excel(writer, 'Final Trips')
linked_trips.to_excel(writer, 'Linked Trips')
incomplete_trips.to_excel(writer, 'Incomplete Trips')
bad_trips.to_excel(writer, 'Bad Trips')
good_trips.to_excel(writer, 'Good Trips')

# # Unlinked trips that need to be edited by hand
writer.close()

# Write the final trips directly to csv
final_trips.to_csv('gps2015_linked.csv')
bad_trips.to_csv('bad_trips.csv')
linked_trips.to_csv('linked_trips_only.csv')