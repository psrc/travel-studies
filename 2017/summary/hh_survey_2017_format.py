import pandas as pd
import math
import matplotlib.pyplot as plt
import numpy as np
from scipy import stats as st
from  hh_survey_config_format import *

def merge_hh_person_trip(hh_person, trip):
    #hh_person =pd.merge(hh, person, on= 'hhid', suffixes=['', 'person'], how ='right')
    hh_person_trip = pd.merge(hh_person, trip, on= ['hhid', 'personid'], suffixes=['','trip'], how ='right')
    return hh_person_trip

def merge_hh_person(hh, person):
    hh_person =pd.merge(hh, person, on= 'hhid', suffixes=['', 'person'], how ='right')
    return hh_person

def code_race(person):
   
    person['race_category'] ='Children or missing'
    person['race_category'][(person['race_noanswer']==1.0) | (person['race_other']==1.0)|(person['race_aiak']==1.0)| (person['race_hapi']==1.0)] ='African-American, Hispanic, Multiracial, and Other'
    person['race_category'][(person['race_hisp'] ==1.0)] = 'African-American, Hispanic, Multiracial, and Other'
    person['race_category'][(person['race_afam']==1.0)]='African-American, Hispanic, Multiracial, and Other'
    person['race_category'][(person['race_afam']!=1.0) & (person['race_aiak'] !=1.0) &
                            (person['race_asian'] ==1.0) & (person['race_hapi'] !=1.0) &
                            (person['race_hisp'] !=1.0) &(person['race_white'] !=1.0)&
                            (person['race_other'] !=1.0)]= 'Asian Only'
    person['race_category'][(person['race_afam']!=1.0) & (person['race_aiak'] !=1.0) &
                            (person['race_asian'] !=1.0) & (person['race_hapi'] !=1.0) &
                            (person['race_hisp'] !=1.0) &(person['race_white'] ==1.0)&
                            (person['race_other'] !=1.0)]='White Only'
    
    return person

def code_sov(trip):
    trip['Main Mode'] = trip['Mode Simple']
    trip['Main Mode'][(trip['Mode Simple'] =='Drive')] = 'SOV'
    trip['Main Mode'][(trip['Mode Simple'] =='Drive')&(trip['travelers_total'] >1)]='HOV'
 
    return trip

def code_age(person):
   person['age_category'] = '18-64 years'
   person['age_category'] [(person['Age']== 'Under 5 years old') | (person['Age']== '5-11 years')] = 'Under 18 years'
   person['age_category'] [(person['Age']== '12-15 years') | (person['Age']== '16-17 years')] = 'Under 18 years'
   person['age_category'] [(person['Age']== '65-74 years') ] = '65 years+'
   person['age_category'] [(person['Age']== '75+ years')|(person['Age']== '75-84 years') | (person['Age']== '85 or years older')] = '65 years+'
   return person

def code_seattle(person):
   person['seattle_home'] = 'Home Not in Seattle'
   person['seattle_home'][person['Final home address: PUMA 2010'].str.startswith('Seattle City')] = 'Home in Seattle'
   return person


def lookup_names(df, names):
    for col in df:
        names_col = pd.DataFrame(names.loc[names.Field == col])
        if not names_col.empty:
                try: 
                    df_named = pd.merge(df, names_col, how='left', left_on = col, right_on = 'Variable')
                    df[names_col['Label'].iloc[0]] = df_named.Value
                except Exception:
                    pass

    return df

def prep_data(df, codebook):
    var_names= make_codebook(codebook)
    df_w_names = lookup_names(df, var_names)
    return df_w_names 


def make_codebook(codebook):
    var_names = pd.DataFrame(columns=['Field', 'Variable', 'Value', 'Label'])
    count = 1
    var_names_dict = []
    for index, row in codebook.iterrows():
        if count == 1:
            last_row = row
        elif row['Field'] == 'Valid Values' or row['Field'] == 'Labeled Values':
        # the field name comes in the row befor valid values, get it
            field_name = last_row['Field']
            label = last_row['Label']
            var_names_dict.append({'Field' : field_name, 'Variable': row['Variable'], 'Value':row['Value'],
                                   'Label' : label})
        elif not(pd.isnull((row['Variable']))):
        # this happens when your getting another variable value)
             var_names_dict.append({'Field' : field_name, 'Variable': row['Variable'], 'Value':row['Value'],
                                    'Label' : label})
        last_row = row
        count = count + 1
    var_names = var_names.append(var_names_dict)
    var_names['Variable'] =pd.to_numeric(var_names['Variable'], errors='coerce').fillna(1).astype(int)

    # this is a hack to find the trip file, and add the mode values because they are missing
    if var_names['Field'].str.contains('mode_4').any():
        for x in range(1,4):
            mode_vars = var_names.loc[var_names['Field']=='mode_4']
            mode_vars['Field']=mode_vars['Field'].replace({'mode_4': 'mode_'+str(x)})
            if x == 1:
                mode_vars['Label'] = 'Primary Mode'

            var_names = var_names.append(mode_vars,ignore_index =True)

    return var_names


if __name__ == "__main__":
    print('reading excel files')
    hh = pd.read_excel(survey_2017_dir+hh_file_name, skiprows=1)
    person= pd.read_excel(survey_2017_dir+person_file_name, skiprows=1)
    trip = pd.read_excel(survey_2017_dir+trip_file_name, skiprows=1)

    codebook_hh = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_hh_name)
    codebook_person = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_person_name)
    codebook_trip = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_trip_name)
    
    purpose_lookup = pd.read_excel(purpose_lookup_f)
    mode_lookup = pd.read_excel(mode_lookup_f)

    print('prepping data codes')
    hh_df = prep_data(hh, codebook_hh)
    person_df = prep_data(person, codebook_person)
    person_df =code_race(person_df)
    person_df = code_age(person_df)
    
    trip_df = prep_data (trip, codebook_trip)


    print('merging data')
    person_detail = merge_hh_person(hh_df, person_df)
    person_detail = code_seattle(person_detail)
    trip_detail = merge_hh_person_trip(person_detail, trip_df)

    trip_detail = pd.merge(trip_detail, purpose_lookup, how= 'left', on = 'Destination purpose')
    trip_detail = pd.merge(trip_detail, mode_lookup, how ='left', on = 'Primary Mode')
    trip_detail = code_sov(trip_detail)

    person_detail.columns = person_detail.columns.str.replace(',', '_')
    person_detail.columns = person_detail.columns.str.replace(':', '_')
    person_detail.columns = person_detail.columns.str.replace('/', '_')
    person_detail.columns = person_detail.columns.str.replace('<>', '_')
    person_detail.columns = person_detail.columns.str.replace('<', '_')

    trip_detail.columns = trip_detail.columns.str.replace(',', '_')
    trip_detail.columns = trip_detail.columns.str.replace(':', '_')
    trip_detail.columns = trip_detail.columns.str.replace('/', '_')
    trip_detail.columns = trip_detail.columns.str.replace('<>', '_')
    trip_detail.columns = trip_detail.columns.str.replace('<', '_')

    #hh_df.to_csv(r'C:\travel-studies\2017\summary\household_2017.csv')
    person_detail.to_csv(output_person_file_loc, encoding='utf-8-sig' )
    trip_detail.to_csv(output_trip_file_loc, encoding='utf-8-sig')

   

    
          

