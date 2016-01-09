# This script attaches skim values to Daysim records

# Extract skim values based on Daysim attributes
import pandas as pd
import numpy as np
import h5py
from EmmeProject import *

# Hardcoded paths, yippee!

# Read the h5-formatted 2014 survey data
# Note that the trip-record tables needs a unique trip ID field
# this will need to be added to the DAT files sent by Mark Bradley.
input_data = h5py.File(r'R:\SoundCast\estimation\2014\P5\survey14.h5')

matrix_dict_loc = r'D:\tmp\soundcast-master\inputs\skim_params\demand_matrix_dictionary.json'
working_dir = r'R:\SoundCast\releases\TransportationFutures2010\inputs'
project_dir = r'R:\SoundCast\releases\TransportationFutures2010\projects\7to8\7to8.emp'
skim_output_file = 'skim_travel_time_output.csv'
# Are we processing a daysim or survey file? Each have slightly different formats
daysim = False
tollclass = 'nt'

# List of fields to extract from trip records
tripdict={	'Household ID': 'hhno',
            'Person Number': 'pno',
            'Trip ID': 'tripid',
            'Travel Time':'travtime',
            'Travel Cost': 'travcost',
            'Travel Distance': 'travdist',
            'Mode': 'mode',
            'Purpose':'dpurp',
            'Departure Time': 'deptm',
            'Origin TAZ': 'otaz',
            'Destination TAZ': 'dtaz',
            'Departure Time': 'deptm',
            'Expansion Factor': 'trexpfac'}

# List of fields to extract from household records
hhdict={'Household ID': 'hhno',
        'Household Size': 'hhsize',
        'Household Vehicles': 'hhvehs',
        'Household Workers': 'hhwkrs',
        'Household Income': 'hhincome',
        'Household TAZ': 'hhtaz',
        'Expansion Factor': 'hhexpfac'}

# lookup for departure time to skim times
tod_dict = {
    3: '20to5',
    4: '20to5',
    5: '5to6',
    6: '6to7',
    7: '7to8',
    8: '8to9',
    9: '9to10',
    10: '10to14',
    11: '10to14',
    12: '10to14',
    13: '10to14',
    14: '14to15',
    15: '15to16',
    16: '16to17',
    17: '17to18',
    18: '18to20',
    19: '18to20',
    20: '20to5',
    21: '20to5',
    22: '20to5',
    23: '20to5',
    24: '20to5',
    25: '20to5',
    26: '20to5'
}

# Create an ID to match skim naming method
mode_dict = {
    1: 'walk',
    2: 'bike',
    3: 'sv',
    4: 'h2',
    5: 'h3',
    6: 'tr',
    7: 'ot',
    8: 'ot',
    9: 'ot'
}

def build_df(h5file, h5table, var_dict, survey_file=False):
    ''' Convert H5 into dataframe '''
    data = {}
    if survey_file:
        # survey h5 have nested data structure, different than daysim_outputs
        for col_name, var in var_dict.iteritems():
            data[col_name] = [i[0] for i in h5file[h5table][var][:]]
    else:
        for col_name, var in var_dict.iteritems():
            data[col_name] = [i for i in h5file[h5table][var][:]]

    return pd.DataFrame(data)

def text_to_dictionary(input_filename):
	''' Convert text input to Python dictionary'''
	my_file=open(input_filename)
	my_dictionary = {}

	for line in my_file:
		k, v = line.split(':')
    	my_dictionary[eval(k)] = v.strip()

	return(my_dictionary)

def write_skims(df, skim_dict):
	'''Look up skim values from trip records and export as csv'''

	# Open Emme project to acquire zone numbers for lookup to skim indeces
	my_project = EmmeProject(project_dir)
	zones = my_project.current_scenario.zone_numbers
	dictZoneLookup = dict((value,index) for index,value in enumerate(zones))
	
	bikewalk_tod = '5to6'   # bike and walk are only assigned in 5to6
	distance_skim_tod = '7to8'    # distance skims don't change over time, only saved for a single time period

	output_array = []

	for i in xrange(len(df)):
		print i
		rowdata = df.iloc[i]
		rowresults = {}

		rowresults['tripID'] = rowdata['Trip ID']
		rowresults['skimid'] = rowdata['skim_id']

		for skim_type in ['d','t','c']:

			tod = rowdata['dephr']
			
			# assign atlernate tod value for special cases
			if skim_type == 'd':
				tod = distance_skim_tod
			
			if rowdata['mode code'] in ['bike','walk']:
				tod = '5to6'
			
			rowresults['tod_orig'] = rowdata['dephr']
			rowresults['tod_pulled'] = tod

			# write results out 
			try:
				my_matrix = skim_dict[tod]['Skims'][rowdata['skim_id']+skim_type]
				otaz=rowdata['Origin TAZ']
				dtaz=rowdata['Destination TAZ']
				
				skim_value = my_matrix[dictZoneLookup[otaz]][dictZoneLookup[dtaz]]
				rowresults[skim_type] = skim_value
			# if value unavailable, keep going and assign -99 to the field
			except:
				rowresults[skim_type] = '-99'

		output_array.append(rowresults)
       
	
	# write results to a csv
	try:
		pd.DataFrame(output_array).to_csv(skim_output_file)
	except:
		print 'failed on export of output'


def main():

	# Extract daysim data from h5 files, for specified files
	trip = build_df(h5file=input_data, h5table='Trip', var_dict=tripdict, survey_file=False)
	hh = build_df(h5file=input_data, h5table='Household', var_dict=hhdict, survey_file=False)

	# Join household to trip data to get income
	trip_hh = pd.merge(trip,hh, on='Household ID')

	# Build a lookup variable to find skim value
	matrix_dict  = text_to_dictionary(matrix_dict_loc)
	uniqueMatrices = set(matrix_dict.values())

	# Extract relevant columns
	df = trip_hh[['Mode', 'Departure Time', 'Origin TAZ', 'Destination TAZ', 'Household Income','Trip ID']]


	############ Get a subsample for testing
	# df = df.iloc[0:100]

	# Add a field for skims based on mode, vot, and tollpath
	# tollpath is always set to 1
	df['Toll Class'] = np.ones(len(df))

	# Convert continuous VOT into bins 
	if daysim:
		df['VOT Bin'] = pd.cut(df['Value of Time'], bins=[0,15,25,9999999999999], right=True, labels=[1,2,3], 
													retbins=False, precision=3, include_lowest=True)
		df['VOT Bin'] = df['VOT Bin'].astype('int')

		# Convert departure time in min after 3 am to hours past midnight
		df['min after midnight'] = df['Departure Time'] + 180
		df['hr after midnight'] = (df['min after midnight']/60).astype('int')

		# Note that hours midnight to 3 am will be recorded as 24-26
		# print max(df['hr after midnight'])
		# print min(df['hr after midnight'])

		# Convert departure time into a TOD period
		hours = np.asarray(df['hr after midnight'])
		df['dephr'] = [tod_dict[hours[i]] for i in xrange(len(hours))]
	else:
		# Classify VOT bin based on household income 
		# These are based on the VOT bins used by soundcast applied to daysim_outputs
		# To compute bin values, convert continuous VOT to bins (0-15,15-25,25+)
		# and group by these bins, taking average household income of each bin

		# Note that all households with -1 (missing income) represent university students
		# These households are lumped into the lowest VOT bin 1,
		df['VOT Bin'] = pd.cut(df['Household Income'], 	bins=[-1,84500,108000,9999999999], right=True, labels=[1,2,3], 
												retbins=False, precision=3, include_lowest=True)
	
		df['VOT Bin'] = df['VOT Bin'].astype('int')
		print min(df['VOT Bin'])

		# Remove last two digits from time in hhmm to retrieve departure hour
		hours = np.asarray(df['Departure Time'].astype('str').str[:-2].astype('int'))
		df['dephr'] = [tod_dict[hours[i]] for i in xrange(len(hours))]


	# Lookup mode keyword
	modes = np.asarray(df['Mode'].astype('int'))
	df['mode code'] = [mode_dict[modes[i]] for i in xrange(len(modes))]

	# Concatenate to produce ID to use with skim tables
	# but not for walk or bike modes
	final_df = pd.DataFrame()
	for mode in np.unique(df['mode code']):
	    print "processing skim lookup ID: " + mode
	    mylen = len(df[df['mode code'] == mode])
	    tempdf = df[df['mode code'] == mode]
	    if mode not in ['walk','bike']:
	        tempdf['skim_id'] = tempdf['mode code'] + tollclass + tempdf['VOT Bin'].astype('str')
	    else:
	        tempdf['skim_id'] = tempdf['mode code']
	    final_df = final_df.append(tempdf)
	    print 'number of ' + mode + 'trips: ' + str(len(final_df))
	df = final_df; del final_df

	# Load skim data from h5 into a dictionary
	tods = set(tod_dict.values())
	skim_dict = {}
	for tod in tods:
	    contents = h5py.File(working_dir + r'/'+ tod + '.h5')
	    skim_dict[tod] = contents


	# If the skim output file doesn't already exist, create it
	if not os.path.isfile(skim_output_file):
		write_skims(df, skim_dict)


	# join skim data to original .dat files

if __name__ == "__main__":
	main()