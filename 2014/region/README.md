HouseholdSurvey2014
===================

These scripts import PSRC's 2014 household survey from spreadsheets to Python Pandas dataframes.

"process_survey.py" is the primary script that loads data into memory and computes basic statistics. Its functions are imported by the individual query scripts. These query scripts create pivot table summaries for a specific topic, e.g., residence types by income, age, and education. 

The "config.py" script points to the input data (i.e., the latest survey releases in spreadsheet format) and other assumptions.

Raw survey data is separated into 4 separate files:

Household
Vehicle
Person
Trip

These files are imported into Python and further merged and joined for more complicated data queries. This script automatically created a joined Person-Household and a Person-Houshold-Trip dataset in memory. The Person-Household file joins household-level data to each person record, using the person ID as a common parameter. This data allows segmentation across certain variables available in only person- or household-level detail. The Person-Household-Trip file joins the Person-Household data with each trip record, allowing further analysis and segmentation. These joined datasets may be exported easily to Excel form as needed. 

This repository contains scattered scripts used for specific queries. This will be cleaned up or removed at some point. 

The "labels.py" script is useful for replacing survey response values (e.g., "5" for an income group) with labels (e.g. "$50,000 - $65,000). 

