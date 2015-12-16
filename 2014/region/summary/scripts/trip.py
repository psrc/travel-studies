import pandas as pd
import numpy as np
import config
import process_survey as ps

# Load survey data to memory
hh = ps.load_data(config.household_file)
person = ps.load_data(config.person_file)
trip = ps.load_data(config.trip_file)

# Add household records to person file
person_hh = ps.join_hh2per(person, hh)

# Merge person-household records to trip file
trip_per_hh = ps.join_hhper2trip(trip, person_hh)

####################################################
# Basic summaries
# Purpose (main purpose of trip - destination purpose)
purpose = trip_per_hh.groupby('d_purpose').sum()['expwt_final']    # Aggregate trip purpose table
mode = trip_per_hh.groupby('mode').sum()['expwt_final']             # Main way traveled on trip
trip_dur_reported = trip_per_hh['trip_dur_reported']    # Trip duration in minutes (derived)
gdist = trip_per_hh['gdist']         # Driving distance (miles) from origin to destination (Google estimate) (derived)
gtime = trip_per_hh['gtime']        # Driving travel time (minutes) from origin to destination (Google estimate) (derived)
implied_speed_mph = trip_per_hh['implied_speed_mph'] # Implied speed (mph): distance over reported travel time (derived)
activity_duration = trip_per_hh['a_dur']    # Activity duration at destination (derived)

# Taxi trips
taxi_type = trip_per_hh.groupby('taxi_type').sum()['expwt_final']
taxi_fare = trip_per_hh.groupby('taxi_type').sum()['expwt_final']

# Tolls
toll = trip_per_hh.groupby('toll').sum()['expwt_final']

# Parking
park = trip_per_hh.groupby('park').sum()['expwt_final'] # Parked at destination
park_pay = trip_per_hh.groupby('park_pay').sum()['expwt_final'] # Paid for parking

# Transit access and egress
transit_access = trip_per_hh.groupby('mode_acc').sum()['expwt_final']    # Access mode
transit_egress = trip_per_hh.groupby('mode_egr').sum()['expwt_final']    # Egress mode

# Park and ride lots
pnr_pool = trip_per_hh.groupby('pr_lot1_a').sum()['expwt_final']    # Joined a vanpool/carpool from these lots
pnr_park = trip_per_hh.groupby('pr_lot2_a').sum()['expwt_final']    # Parked at this park and ride lot


t = ps.Trip(trip_per_hh)

# Pivot tables

#####################################################
# geographic flows
countyflows = t.pivot_table('ocnty','dcnty')
zipflows = t.pivot_table('ozip','dzip')


####################################################
# Visualize results
countyflows_viz = sns.heatmap(countyflows)
zipflows_viz = sns.heatmap(zipflows)

# Show a plot
plt.show(zipflows_viz)

 




