# 2014 Survey Estimation Tools

## Notebooks
This directory contains notebooks for analyzing and comparing expanded survey results.
These notebooks are designed to analyze **expanded** survey results (one record for each person in the region).
It is expected that the weights will be applied through creating a synethic population based on sample weights.
Scripts are provided to convert samples (with weight fields) into synthetic expanded files, in both CSV and h5 formats.
The notebooks expect data in h5 formats, which should also match Soundcast's Daysim output format. 
When survey results are expanded to h5 format, it provides a consistent comparison format between 2006 and 2014 surveys,
and Daysim model results. 

## Scripts
Four scripts are contained in this directory. 

- expand_survey.py
	- converts survey sample records into full-length expanded records. Inputs are expected in 
	Daysim format, where column titles and file names correspond to Daysim outputs. The script should be
	run from a directory containing only the input files desired to be processed. The script copies all sample records
	*x* number of times, based on each record's expansion factor *x*. Outputs are saved in csv format. To run the script,
	**provide both an input and output file name as command line arguments**: e.g., python input_name.dat output_name.csv

- expand_all_tables.sh  
	- bash script to automate expansion of multiple survey files. This script passes all .dat files in the current directory to expand_survey.py, generating outputs with an appended file name of "...-expanded.csv". This file should be run from the directory where all files are contained. Outputs will be stored in the same directory. 

- csv_to_h5.py
	- combines a set of csv files into an h5 file, to match the structure of Daysim, and as required by the notebooks and other Soundcast summary scripts. This script will combine individual survey files (either samples or expanded files resulting from expand_survey.py). The script will attempt to combine and local csv files into an h5 file. The result will be a 'expanded-survey.h5' which will contain and CSV files as tables in the h5 file. All columns are created as unique tables to match Daysim format.

- h5_to_csv.py
	- reverse of csv_to_h5; this script is necessary to convert h5-formatted survey samples into csv records that are inputs for expand_survey.py. The primary usage for this script is converting 2006 survey samples, but it could be useful in future situations where only h5 sample files are available for input into expand_survey.py  