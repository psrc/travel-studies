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


