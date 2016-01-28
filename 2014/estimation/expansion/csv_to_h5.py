# Convert all expanded csv files to h5

import os
import glob
import pandas as pd
import h5py

# Lookup for group name based on file name
group_dict={
	'hday': 'HouseholdDay',
	'hrec': 'Household',
	'pday': 'PersonDay',
	'prec': 'Person',
	'tour': 'Tour',
	'trip': 'Trip'
}

def main():
	# Create H5 container (overwrite if exists)
	h5name = 'survey-expanded.h5'
	if os.path.isfile(h5name):
		os.remove(h5name)
	f = h5py.File(h5name, 'w')

	# Process all csv files in this directory
	for fname in glob.glob('*.csv'):

		# Read csv data
		df = pd.read_csv(fname,sep=',')

		# Create new group name based on CSV file name
		group_name = [group_dict[i] for i in group_dict.keys() if i in fname][0]
		grp = f.create_group(group_name)

		for column in df.columns: 
			grp.create_dataset(column, data=list(df[column]))
		print "Added to h5 container: " + str(group_name)
	
	f.close()

if __name__=="__main__":
	main()