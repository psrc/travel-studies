# Queries for factors influencing walking, bike, and transit use
# Segmented by regional center, major center, and non-center

import pandas as pd
import numpy as np
import config
import process_survey as ps

#import process_survey
# visualization imports
import matplotlib as mpl
import matplotlib.pyplot as plt
import seaborn as sns
from pylab import rcParams

# Load survey data to memory
hh = ps.load_data(config.household_file)
person = ps.load_data(config.person_file)
trip = ps.load_data(config.trip_file)

# Add household records to person file
person_hh = ps.join_hh2per(person, hh)

# Merge person-household records to trip file
trip_per_hh = ps.join_hhper2trip(trip, person_hh)

# Create instances of summary class
# Select only households located in the City of Tacoma
tacoma_hh = ps.Household(hh.query('h_city == "TACOMA"'))
tacoma_per_hh = ps.Person(person_hh.query('h_city == "TACOMA"'))
# Select only households located in the Tacoma Downtown Regional Growth Center
tacoma_hh_rgc = ps.Household(hh.query('h_rgc_name == "Tacoma Downtown"'))
# Create instance of HouseholdSummaries for all Regional Households
sum_all_hh = ps.Household(hh)

# Find trip summaries for Tacoma vs Sound
trips_sound = Trip(trip)
trips_tacoma = Trip(trip_person_hh.query('h_city == "TACOMA"'))





# Try some plots
testinc = household['hh_income_detailed_imp']

# Trip duration (in minutes)
def clean_trip_dur(trip):
    tripdur = trip['trip_dur_reported']
    tripdur = tripdur[pd.notnull(tripdur)]      # Remove NaN rows
    max_trip_dur = 80                         # Remove trips that take longer than 2 hours (120 min)
    tripdur = tripdur[tripdur.values < max_trip_dur]
    tripdur = tripdur[tripdur.values >= 0]
    return tripdur

tacoma_trip_dur = clean_trip_dur(trip_person_hh.query('h_city == "TACOMA"'))
tacoma_dwntn_dur = clean_trip_dur(trip_person_hh.query('h_rgc_name == "Tacoma Downtown"'))
sound_trip_dur = clean_trip_dur(trip_person_hh)

# 
sns.violinplot([tacoma_trip_dur, tacoma_dwntn_dur, sound_trip_dur])

plt.show()
