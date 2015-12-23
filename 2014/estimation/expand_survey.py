# This script is used to expand a survey sample by growing each record according to its expansion weight.
# records are expanded on column containing 'expfac' 
# argv[1] is input file (dat or space-delimited survey sample)
# argv[2] is output csv
 
import sys
import os
import getopt
import pandas as pd
import numpy as np 
import h5py

def main(argv):
	try:
		file_in, file_out = argv
	except:
		print 'Error: provide input and output file data as arguments'
		sys.exit(2)

	# Read file_in as tab-delimited array
	data_content = open(file_in, 'r')
	lines = np.asarray(data_content.read().split('\n'))

	# Initialize array for appending expanded records
	df_array = np.asarray(lines[0].split(' ')) 

	# Retrieve column number of expansion factor from header row
	col_num = [i for i, s in enumerate(df_array) if 'expfac' in s]

	# Copy each sample row based on (rounded) expansion factor value
	for j in range(1,len(lines)-1):  
	    print ' processing sample row: ' + str(j)
	    
	    # Convert space-delimited line into array
	    subarray = np.asarray(lines[j].split(' '))

	    # Retrieve expansion factor value, round, convert to integer
	    factor = int(round(float(subarray[col_num][0]),0))
	    
	    # Exclude rows with negative expansion factors
	    if factor < 0:
	    	continue

	    subarray = [subarray]*factor    # Copy the sample 'factor' times
	    df_array = np.vstack((df_array, subarray)) # Append expanded samples to master array

	output = pd.DataFrame(df_array[1:-1], columns=lines[0].split(' '))
	
	# Write ouput as csv; overwrite existing file if needed
	if os.path.isfile(file_out):
		os.remove(file_out)
	output.to_csv(file_out)

if __name__ == "__main__":
	main(sys.argv[1:])
