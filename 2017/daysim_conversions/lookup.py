

# Take median age
age_map = {
    1: 2,
    2: 8,
    3: 14,
    4: 17,
    5: 21,
    6: 30,
    7: 40,
    8: 50,
    9: 60,
    10: 70,
    11: 80,
    12: 85
}

gender_map = {
    1: 1,    # male: male
    2: 2,    # female: female
    3: 9,    # another: missing
    4: 9     # prefer not to answer: missing
}

pstyp_map = {
    1: 0,
    2: 1,
    3: 2
}

hownrent_map = {
    1: 1,
    2: 2,
    3: 3,
    4: 3,
    4: 3
}

mode_dict = {
    'Walk': 1,
    'Bike': 2,
    'SOV': 3,
    'HOV2': 4,
    'HOV3+': 5,
    'Transit': 6,
    'TNC': 9,
    'Other': 10
    }

day_map = {
    'Monday': 1,
    'Tuesday': 2,
    'Wednesday': 3,
    'Thursday': 4
}

purpose_map = {
    1: 0, # home
    6: 2, # school
    9: 3, # escort
    10: 1, # work
    11: 1, # work-related
    14: 1, # work-related
    30: 5, # grocery -> shop
    32: 5, # other shopping -> shop
    33: 4,
    34: 9, # medical
    50: 6, # restaurant -> meal
    51: 8, 
    52: 7,
    53: 8,
    54: 7, # religious/community/volunteer -> social
    56: 7, # family activity -> social
    60: 10, # change mode
    61: 4,
    62: 7, # other social
    97: -1 # other
}

dorp_map = {
    1: 1,
    2: 2,
    3: 9
}