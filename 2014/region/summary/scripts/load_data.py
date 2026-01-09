# Control file for iPython notebook scripts

import numpy as np
import pandas as pd

# Load survey data into Pandas
hh = pd.read_csv('households.csv')
trip = pd.read_csv('trips.csv', low_memory=False)
person = pd.read_csv('persons.csv', low_memory=False)

# Clean the data?

# Join Household to Trip data
trip_hh = pd.merge(trip, hh, on='hhid', suffixes=['_t','_h'])

# Join Household to Person Data
person_hh = pd.merge(person, hh, on='hhid', suffixes=['_p','_h'])

