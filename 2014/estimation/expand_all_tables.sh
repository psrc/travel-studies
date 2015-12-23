#! /usr.bash

clear

echo "Processing all survey tables"

for file in $(ls *.dat); do
	# echo $file
	input=$file

	f=$(echo $file | cut -f 1 -d '.')
	output=$f'-expanded.csv'

	echo processing input $input
	python expand_survey.py $input $output
	echo output saved as $output

done