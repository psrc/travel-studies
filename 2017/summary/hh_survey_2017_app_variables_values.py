import os
import pandas as pd

currdir = os.getcwd()
newdir = r'C:\Users\CLam\Desktop\travel-studies\2017\summary'
out_dir = 'C:/Users/CLam/Desktop/travel-study-stories/shiny'
codebook_lookup_name = 'variables_values.xlsx'

os.chdir(newdir)
from hh_survey_2017_summary import *

print 'reading excel files'
hh = pd.read_excel(survey_2017_dir+hh_file_name, skiprows=1)
person= pd.read_excel(survey_2017_dir+person_file_name, skiprows=1)
trip = pd.read_excel(survey_2017_dir+trip_file_name, skiprows=1)

codebook_hh = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_hh_name)
codebook_person = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_person_name)
codebook_trip = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_trip_name)

var_names_hh = make_codebook(codebook_hh)
var_names_person = make_codebook(codebook_person)
var_names_trip = make_codebook(codebook_trip)

df = var_names_hh.copy()
df = df.append([var_names_person, var_names_trip])

df['Label'] = df['Label'].str.replace(',', '_')
df['Label'] = df['Label'].str.replace(':', '_')
df['Label'] = df['Label'].str.replace('/', '_')
df['Label'] = df['Label'].str.replace('<>', '_')
df['Label'] = df['Label'].str.replace('<', '_')

#dup_ind = df.duplicated()
#df_dup = df[dup_ind]

# remove duplicate rows by all columns
df2 = df.drop_duplicates(inplace = False)

df2.to_excel(os.path.join(out_dir, codebook_lookup_name), index = False)

os.chdir(currdir)