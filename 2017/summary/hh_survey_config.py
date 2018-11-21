
# File names and directories
survey_2017_dir = 'J:/Projects/Surveys/HHTravel/Survey2017/Data/Export/Version 2/Public/'
hh_file_name = '2017-pr2-1-household.xlsx'
person_file_name = '2017-pr2-2-person.xlsx'
vehicle_file_name = '2017-pr2-3-vehicle.xlsx'
day_file_name = '2017-pr2-4-day.xlsx'
trip_file_name = '2017-pr2-5-trip.xlsx'
codebook_file_name = '2017-pr2-codebook.xlsx'
codebook_hh_name = '1-HH'
codebook_person_name = '2-PERSON'
codebook_vehicle_name = '3-VEHICLE'
codebook_day_name = '4-DAY'
codebook_trip_name = '5-TRIP'
mode_lookup_f = 'C:/travel-studies/2017/summary/transit_simple.xlsx'
purpose_lookup_f = 'C:/travel-studies/2017/summary/destination_simple.xlsx'
output_file_loc = 'C:/travel-studies/2017/summary/output'

analysis_variable = 'Gender'
analysis_variable_name = 'gender'
compare_person =  ['Number of vehicles', 'HH belongs to carshare program', 
                      'Off-street parking spaces at residence',
                      'How important when chose current home: Being within a 30-minute commute to work',
                      'How important when chose current home: Affordability',
                      'How important when chose current home: Being close to family or friends',
                      'How important when chose current home: Being close to the highway',
                      'How important when chose current home: Quality of schools (K-12)',
                      'How important when chose current home: Being close to public transit',
                      'How important when chose current home: Having a walkable neighborhood and being near local activities',
                      'Employed, fixed/varied workplace: Usual way of commuting to current location/office',
                      'Employed, fixed workplace: How long has been commuting to current location/office',
                      'Employed, fixed/varied workplace: How often telecommutes',
                      'Parks at work: Usual way of paying for parking at work',
                      'Times ridden transit in past 30 days',
                      'Times ridden a bike in past 30 days',
                      'Times gone for a walk in past 30 days',
                      'Age 16+: Times used rideshare in past 30 days',
                      'Employer commuter benefits: Flextime',
                      'Employer commuter benefits: Compressed Week',
                      'Employer commuter benefits: Other subsidized commute (vanpool, bike, etc.)',
                      'Age 18+, proxy <> 3: Autonomous car interest: Taxi, no driver present',
                      'Age 18+, proxy <> 3:Autonomous car interest: Taxi, backup driver present',
                      'Age 18+, proxy <> 3:Autonomous car interest: Commute alone',
                      'Age 18+, proxy <> 3:Autonomous car interest: Own autonomous car',
                      'Age 18+, proxy <> 3:Autonomous car interest: Autonomous carshare',
                      'Age 18+, proxy <> 3:Autonomous car interest: Autonomous short trips',
                      'Age 18+, proxy <> 3:Autonomous car concern: Equipment and safety',
                      'Age 18+, proxy <> 3:Autonomous car concern: Legal liability',
                      'Age 18+, proxy <> 3:Autonomous car concern: System and security',
                      'Age 18+, proxy <> 3:Autonomous car concern: Reaction to driving environment', 'Participant number of trips']

compare_trip=  ['Destination purpose', 'dest_purpose_simple', 'Primary Mode', 'Auto trip, non-taxi: Park cost at end of trip', 
                'Used toll on trip: toll fare','Approximate taxi trip fare',
                'travelers_hh', 'travelers_nonhh', 'travelers_total', 'driver', 'Transit trip: Travel mode from transit',
                'Transit trip: Travel mode to transit', 'Auto trip, non-taxi: Park location at end of trip',
                'Mode Simple'
                ]