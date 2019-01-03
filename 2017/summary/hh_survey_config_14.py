
# File names and directories
survey_2017_dir = 'J:/Projects/Surveys/HHTravel/Survey2014/Data/Export/Release 3/General Release/Unzipped/'
hh_file_name = '2014-pr3-hhsurvey-households.xlsx'
person_file_name = '2014-pr3-hhsurvey-persons.xlsx'
vehicle_file_name = '2014-pr3-hhsurvey-vehicles.xlsx'
trip_file_name = '2014-pr3-hhsurvey-trips.xlsx'
codebook_file_name = '2014-pr3-hhsurvey-codebook.xlsx'
codebook_hh_name = 'Table1-Households'
codebook_person_name = 'Table3-Persons'
codebook_vehicle_name = 'Table2a-Vehicles meta'
codebook_trip_name = 'Table4-Trips'
mode_lookup_f = 'C:/travel-studies/2017/summary/transit_simple_14.xlsx'
purpose_lookup_f = 'C:/travel-studies/2017/summary/destination_simple_14.xlsx'
output_file_loc = 'C:/travel-studies/2017/summary/output'

analysis_variable = 'Final home county'
analysis_variable_name = 'county_14'
compare_person =  ['Age 16+: Has valid drivers license',]


compare_trip=  ['Main Mode', 'travelers_hh', 'travelers_nonhh', 'How often in past 30 days: Ridden transit (bus, rail, ferry)', 
                'How often in past 30 days: Ridden a bike (for 15 minutes or or more)', 
                'How often in past 30 days: Gone for a walk (for 15 minutes or more)',
                'Work: Commutes: How often telecommute','Work benefit: Free or subsidized parking',
                'Walk, bike or ride transit more if: Safer ways to get to transit stops (e.g. more sidewalks, lighting, etc.)',
                'Walk, bike or ride transit more if: Increased frequency of transit (e.g. how often the bus arrives)',
                'Walk, bike or ride transit more if: Safer bicycle routes (e.g. protected bike lanes)'
                ' Walk, bike or ride transit more if: Safer walking routes (e.g. more sidewalks, protected crossings, etc.)'


                ]

trip_means = ['gdist']

z = 1.96