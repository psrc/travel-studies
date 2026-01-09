import pandas as pd
import numpy as np
import config
import process_survey as ps

# Load survey data to memory
hh = ps.load_data(config.household_file)
person = ps.load_data(config.person_file)

# Add household records to person file
person_hh = ps.join_hh2per(person, hh)

# Create instances of summary class
perhh = ps.Person(person_hh)

# Get some basic descriptive tables
hhsize = hh.groupby("hhsize").sum()['expwt_final']
numadults = hh.groupby("numadults").sum()['expwt_final']
numchildren = hh.groupby("numchildren").sum()['expwt_final']
numworkers = hh.groupby("numworkers").sum()['expwt_final']
hh_inc_detailed_imp = hh.groupby("hh_income_detailed_imp").sum()['expwt_final']   # imputed income
vehs = hh.groupby("vehicle_count").sum()['expwt_final']
county = hh.groupby("h_county_name").sum()['expwt_final']

