import pandas as pd
import numpy as np
import config
import process_survey as ps

# Load survey data to memory
person = ps.load_data(config.person_file)
trip = ps.load_data(config.trip_file)

# Add household records to person file
person_trip = pd.merge(person, trip, 
                    left_on='personid', right_on='personid', 
                    suffixes=('_person', '_trip'))

avg_trip_dist = person_trip['gdist'].mean()
avg_trip_time = person_trip['gtime'].mean()

# Mode Shares
mode_shares = person_trip.groupby('mode').count()['o_purpose']

# Trip Purpose
trip_purp = person_trip.groupby('d_purpose').count()['personid']

# total trips
tot_trips = np.float(trip['personid'].count())
tot_samples = np.float(person['personid'].count())

avg_trips = np.math(tot_trips/tot_samples)

# Age
age_dist = person.groupby('age').count()['personid']

# Affiliation
affiliation = person.groupby('affiliation').count()['personid']

# campus and mode
campus_mode = pd.pivot_table(person_trip, values='', rows='NAME',    # RGC name
                                    columns='carpool_ga', aggfunc=np.sum) 