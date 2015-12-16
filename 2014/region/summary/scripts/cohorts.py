# Contains pre-made cohorts for easy importing into other scripts

import numpy as np
import pandas as pd
import load_data as data

# MODE --------------------------------------------------------------------------
# All transit
transit_trips = data.trip.query("mode == 8 or mode == 9 or mode == 10 or mode == 11")

# PURPOSE --------------------------------------------------------------------------
# Commute to work
home2work =  data.trip.query("d_purpose == 2")