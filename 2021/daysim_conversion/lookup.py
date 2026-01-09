

# Take median age
age_map = {
    'Under 5 years old': 2,
    '5-11 years': 8,
    '12-15 years': 14,
    '16-17 years': 17,
    '18-24 years': 21,
    '25-34 years': 30,
    '35-44 years': 40,
    '45-54 years': 50,
    '55-64 years': 60,
    '65-74 years': 70,
    '75-84 years': 80,
    '85 or years older': 85
}

gender_map = {
    'Male': 1,    # male: male
    'Female': 2,    # female: female
    'Non-Binary': 9,    # another: missing
    'Not listed here / prefer not to answer': 9     # prefer not to answer: missing
}

pstyp_map = {    # student
    'No, not a student': 0,    # Not a student
    'Full-time student': 1,    # Full time student
    'Part-time student': 2     # Part time student
}

hownrent_map = {     # rent_own
    'Own/paying mortgage': 1,  # owned
    'Rent': 2,  # rented
    'Prefer not to answer': 3,  # other
    'Provided by family, relative, or friend without payment or rent': 3,
    'Provided by job or military': 3,
    'Other': 3
}

mode_dict = {
    'Walk': 1,
    'Bike': 2,
    'SOV': 3,
    'HOV2': 4,
    'HOV3+': 5,
    'Transit': 6,
    'School_Bus': 8,
    'TNC': 9,   # Note that 9 was other in older Daysim records
    'Other': 10
    }

auto_mode_list = ['Household vehicle 1', 'Household vehicle 2','Household vehicle 3', 'Household vehicle 4',
                  'Household vehicle 5', 'Household vehicle 6', 'Household vehicle 7', 'Household vehicle 8',
                  "Friend/colleague's car", 'Other non-household vehicle','Rental car','Other vehicle in household',
                  'Vanpool','Car from work','Other motorcycle/moped']

transit_mode_list = ['Bus (public transit)','Urban Rail (e.g., Link light rail, monorail, streetcar)','Ferry or water taxi',
                     'Commuter rail (Sounder, Amtrak)']

commute_mode_dict = {
    'Drive alone': 3, # SOV
    'Carpool ONLY with other household members': 4, # HOV (2 or 3)
    'Carpool with other people not in household (may also include household members)': 4, # HOV (2 or 3)
    'Motorcycle/moped/scooter': 3, # Motorcycle, assume drive alone 
    'Vanpool': 5, # vanpool, assume HOV3+
    'Bicycle or e-bike': 2, # bike
    'Walk, jog, or wheelchair': 1, # walk
    'Bus (public transit)': 6, # bus -> transit
    'Private bus or shuttle': 10, # private bus -> other
    'Paratransit': 10, # paratransit -> other
    'Commuter rail (Sounder, Amtrak)': 6, # commuter rail
    'Urban rail (Link light rail, monorail, streetcar)': 6, # urban rail
    #13: 6, # streetcar
    'Ferry or water taxi': 6, # ferry
    #15: 10, # taxi -> other
    'Other hired service (Uber, Lyft, or other smartphone-app car service)': 9, # TNC
    'Airplane or helicopter': 10, # plane -> other
    'Scooter or e-scooter (e.g., Lime, Bird, Razor)': 10, # other
    'Missing: Skip Logic': 10 # other
    }

day_map = {
    'Monday': 1,
    'Tuesday': 2,
    'Wednesday': 3,
    'Thursday': 4
}

purpose_map = {
    'Went home': 0, # home
    'Went to school/daycare (e.g., daycare, K-12, college)': 2, # school
    "Dropped off/picked up someone (e.g., son at a friend's house, spouse at bus stop)": 3, # escort
    'Went to primary workplace': 1, # work
    'Went to work-related place (e.g., meeting, second job, delivery)': 1, # work-related
    #14: 1, # work-related
    'Went grocery shopping': 5, # grocery -> shop
    'Went to other shopping (e.g., mall, pet store)': 5, # other shopping -> shop
    'Conducted personal business (e.g., bank, post office)': 4, # personal business
    'Other purpose': 4,   # personal business
    'Went to medical appointment (e.g., doctor, dentist)': 4, # medical is combined with personal business (4)
    'Went to restaurant to eat/get take-out': 6, # restaurant -> meal
    'Attended recreational event (e.g., movies, sporting event)': 7, # recreational is combined with social (7)
    'Attended social event (e.g., visit with friends, family, co-workers)': 7, # socail
    #53: 7, # recreational is combined with social (7)
    'Went to religious/community/volunteer activity': 7, # religious/community/volunteer -> social
    "Went to a family activity (e.g., child's softball game)": 7, # family activity -> social
    'Transferred to another mode of transportation (e.g., change from ferry to bus)': 10, # change mode
    #61: 4, # personal business
    #62: 7, # other social
    'Went to exercise (e.g., gym, walk, jog, bike ride)': 7,   # rec/social/
    #97: 4 # other, setting as personal business for now (4) ?
}

dorp_map = {
    'Driver': 1,
    'Passenger': 2,
    'Missing: Skip Logic': 9,
    'Both (switched drivers during trip)' : 9
}

# Household

hhrestype_map = {'Single-family house (detached house)':1, # SFH: SFH
                 'Townhouse (attached house)':2, # Townhouse (attached house): duplex/triplex/rowhouse
                 'Building with 3 or fewer apartments/condos':2, # Building with 3 or fewer apartments/condos: duplex/triplex/rowhouse
                 'Building with 4 or more apartments/condos':3, # Building with 4 or more apartments/condos: apartment/condo
                 'Mobile home/trailer':4, # Mobile home/trailer: Mobile home/trailer
                 'Dorm or institutional housing':5, # Dorm or institutional housing: Dorm room/rented room
                 'Other (including boat, RV, van, etc.)':6, # other: other
                   }

# Use the midpoint of the ranges provided since DaySim uses actual values
income_map = {
    'Under $10,000': 5000,
    '$10,000-$24,999': 17500,
    '$25,000-$34,999': 30000,
    '$35,000-$49,999': 42500,
    '$50,000-$74,999': 62500,
    '$75,000-$99,999': 87500,
    '$100,000-$149,999': 125000,
    '$150,000-$199,999': 175000,
    '$200,000-$249,999': 225000,
    '$250,000 or more': 250000,
    'Prefer not to answer': -1
}

hhveh_map = {
    '0 (no vehicles)': 0,
    '1 vehicle': 1,
    '2 vehicles': 2,
    '3 vehicles': 3,
    '4 vehicles': 4,
    '5 vehicles': 5,
    '6 vehicles': 6,
    '7 vehicles': 7,
    '8 vehicles': 8,
    }