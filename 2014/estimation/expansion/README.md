# 2014 Survey Estimation Tools

## Notebooks
This directory contains notebooks and scripts for converting and expanding Daysim-formatted survey records. This is required so survey records can be prepared and compared for estimation, calibration, and validation (all of the -ations!). The workflow for producing Daysim-formatted survey files is as follows:

   - Convert survey records into DaySim format. RSG has traditionally done this,
   returning a space-delimited .dat file for persons, households, trips, etc.
   - These records are usually missing skim for travel time, distance, and cost.
   We must attach these, using a base run. For 2014, we do not quite have a full
   base network and population, as of January 2016, so we'll be running the latest
   2010 run to start. Before estimation we need to get 2014 inputs to create 2014 skims. 
   Use the "attach_skim_values.py" script to produce a csv of skim values for each trip and join that to the survey .dat files.
   - Write out the dat files joined with skim values to a new directory.
   - Run the csv_to_h5 script on those files to produce a nicely-formatted h5 file that matches daysim outputs. 

In addition to this workflow, we also developed scripts to "expand" survey records. This process basically copies survey records
according to the size of the expansion factor to create a synthetic "full size" version of survey records. It turns out that processing 
this many records for comparisons is highly memory intensive, so these scripts probably won't be used much. They do contain some useful code snippets.

## Scripts
Five scripts are contained in this directory. 

- attach_skim_values.py
	- extracts skim values based on survey record information of origin and destinatino taz, as well as mode and vot (income) classes.
	This is required to attach modeled skim values to survey records for model estimation (see description above.)

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
