#! /usr.bash

clear

echo "Processing all survey tables"

for file in $(ls *.dat); do
	# process all .dat files in this dir
	input=$file

	# create output name by removing extension and adding tag
	f=$(echo $file | cut -f 1 -d '.')
	output=$f'-expanded.csv'

	# call the python script to expand the survey sample dat file
	echo processing input $input
	python expand_survey.py $input $output
	echo output saved as $output

done