import pandas as pd
import math
import matplotlib.pyplot as plt
import numpy as np
#import hh_survey_config

def merge_hh_person_trip(hh, person,trip):
    hh_person =pd.merge(hh, person, on= 'hhid', suffixes=['', 'person'], how ='right')
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

#def code_age(trip):
#    trip['age_category'] = [(person['Age']== 'Under 5 years old') | (person['race_other']==1.0)|(person['race_aiak']==1.0)| (person['race_hapi']==1.0)] ='Preferred not to answer or other'
 
    return trip

def lookup_names(df, names):
    for col in df:
        names_col = pd.DataFrame(names.loc[names.Field == col])
        if not names_col.empty:
            df_named = pd.merge(df, names_col, how='left', left_on = col, right_on = 'Variable')
            df[names_col['Label'].iloc[0]] = df_named.Value

    return df

def prep_data(df, codebook):
    var_names= make_codebook(codebook)
    df_w_names = lookup_names(df, var_names)
    return df_w_names 

#create_cross_tab_with_weights
def cross_tab(table, var1, var2, wt_field, type):
        if type == 'total':
            print var1
            print var2
            raw = table.groupby([var1, var2]).count()[wt_field].reset_index()
            raw.columns = [var1, var2, 'sample_count']
            
            # this isn't working
            N_hh = table.groupby([var1])['hhid'].nunique().reset_index()
            
            expanded = table.groupby([var1, var2]).sum()[wt_field].reset_index()
            expanded_tot = expanded.groupby(var1).sum()[wt_field].reset_index()
            expanded.columns = [var1, var2, 'estimate']
            expanded = pd.merge(expanded, expanded_tot, on = var1)
            print expanded.head()
            expanded['share']= expanded['estimate']/expanded[wt_field]
            expanded = pd.merge(expanded,N_hh, on = var1).reset_index()
            print expanded.head()
            expanded['in'] = (expanded['share']*(1-expanded['share']))/expanded['hhid']
            expanded['MOE'] = z*np.sqrt(expanded['in'])
            crosstab = pd.merge(raw, expanded, on =[var1, var2]).reset_index()
        if type == 'mean':
            table [var2] = pd.to_numeric(table[var2], errors=coerce)
            table = table.dropna(subset=[var2])
            table = table[(table[var2] !=0)]
            table = table[(table[var2] < 100)]
            table['weighted_total'] = table[wt_field]*table[var2]
            expanded = table.groupby([var1]).sum()['weighted_total'].reset_index()
            expanded_tot = table.groupby([var1]).sum()[wt_field].reset_index()
            #expanded.columns = [var1, var2, 'we']
            expanded = pd.merge(expanded, expanded_tot, on = var1)
            expanded['mean']= expanded['weighted_total']/expanded[wt_field]
            crosstab = expanded

        return crosstab



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
    print 'reading excel files'
    hh = pd.read_excel(survey_2017_dir+hh_file_name, skiprows=1)
    person= pd.read_excel(survey_2017_dir+person_file_name, skiprows=1)
    trip = pd.read_excel(survey_2017_dir+trip_file_name, skiprows=1)

    codebook_hh = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_hh_name)
    codebook_person = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_person_name)
    codebook_trip = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_trip_name)
    
    purpose_lookup = pd.read_excel(purpose_lookup_f)
    mode_lookup = pd.read_excel(mode_lookup_f)

    print 'prepping data codes'
    hh_df = prep_data(hh, codebook_hh)
    person =code_race(person)
    person_df = prep_data(person, codebook_person)
    trip_df = prep_data (trip, codebook_trip)


    print 'merging data'
    person_detail = merge_hh_person(hh_df, person_df)
    trip_detail = merge_hh_person_trip(hh_df, person_df, trip_df)

    trip_detail = pd.merge(trip_detail, purpose_lookup, how= 'left', on = 'Destination purpose')
    trip_detail = pd.merge(trip_detail, mode_lookup, how ='left', on = 'Primary Mode')
    trip_detail = code_sov(trip_detail)
    #hh_df.to_csv(r'C:\travel-studies\2017\summary\household_2017.csv')
    #person_df.to_csv(r'C:\travel-studies\2017\summary\person_2017.csv', encoding = 'utf-8')
    #trip_detail.to_csv(r'C:\travel-studies\2017\summary\trip_2017.csv', encoding = 'utf-8')

    print 'doing summaries'
    for col  in compare_person:
          print col
          cross = cross_tab(person_detail, analysis_variable,col ,  'hh_wt_revised', 'total')
          sm_df = cross[[analysis_variable, col, 'share']]
          sm_df =sm_df.pivot(index=col, columns = analysis_variable, values ='share')
          cross= cross.pivot(index=col, columns = analysis_variable)
          ax = sm_df.plot.bar(rot=0, title = col, fontsize =8)
          fig =ax.get_figure()
          col = col.replace('/', '_')
          col = col[-12:]
          fig.savefig(output_file_loc + '/'+ analysis_variable_name +'_'+ col +'.pdf')
          cross.to_csv(output_file_loc + '/'+ analysis_variable_name +'_'+ col +'.csv')

    for col  in compare_trip:
              print col
              cross = cross_tab(trip_detail, analysis_variable,col ,  'trip_weight_revised', 'total')
              sm_df = cross[[analysis_variable, col, 'share']]
              sm_df =sm_df.pivot(index=col, columns = analysis_variable, values ='share')
              cross= cross.pivot_table(index=col, columns = [analysis_variable])
              ax = sm_df.plot.bar(rot=0, title = col, fontsize =8)
              fig =ax.get_figure()
              col = col.replace('/', '_')
              col = col[-8:]
              fig.savefig(output_file_loc + '/'+ analysis_variable_name +'_'+ col +'.pdf')
              cross.to_csv(output_file_loc + '/'+ analysis_variable_name +'_'+ col +'.csv')

    for col  in trip_means:
              print col
              cross = cross_tab(trip_detail, analysis_variable,col ,  'trip_weight_revised', 'mean')
              cross.to_csv(output_file_loc + '/'+ analysis_variable_name +'_'+ col +'.csv')

    
          

