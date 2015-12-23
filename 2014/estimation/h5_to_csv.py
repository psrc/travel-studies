import pandas as pd
import numpy as np 
import h5py
import os, sys

group_dict={
	'HouseholdDay': 'hday',
	'Household': 'hrec' ,
	'PersonDay': 'pday',
	'Person': 'prec',
	'Tour': 'tour',
	'Trip': 'trip'
}

overwrite=True

def h5_to_df(h5_file):
    '''Convert daysim outputs and survey h5 tables into dataframes.
        Inputs are expected as tables with single-column sub-tables.'''
    dataframes = {}
    for data_table in h5_file.keys():
        dataframes[data_table] = pd.DataFrame()
        # Write each column to a dataframe
        for col in h5_file[data_table].keys():
            dataframes[data_table][col] = [i[0] for i in h5_file[data_table][col][:]]
    		# Note that some h5 data is structured slightly differently
    		# if errors here, try [i for i... instead of i[0] for i...]
    return dataframes


def main(argv):
	# Convert h5 tables to individual csv files
	h5_dir, output_tag = argv

	h5_file = h5py.File(h5_dir, 'r')
	dataframes = h5_to_df(h5_file)

	for df in dataframes.keys():
		fname = group_dict[df] + output_tag + '.csv'
		if overwrite and os.path.isfile(fname):
			os.remove(fname)
		dataframes[df].to_csv(path_or_buf=fname)
		print fname + ' written'
	h5_file.close()

if __name__=="__main__":
	main(sys.argv[1:])