import pandas as pd
import pyodbc


# File names and directories

#sql_conn = pyodbc.connect('DRIVER={SQL Server}; SERVER=sql2016\DSADEV;DATABASE=Sandbox;trusted_connection=true')
#trip_table_name = 'Mike.trip_nk'
#trip  = pd.read_sql('SELECT * FROM '+trip_table_name, con = sql_conn)

survey_2017_dir = 'J:/Projects/Surveys/HHTravel/Survey2017/Data/Export/Version 2/Public/'

#uncleaned
trip = pd.read_csv(r'J:\Projects\Surveys\HHTravel\Survey2017\Data\Cleaning Process\5-Tripx.csv')
#cleaned
#trip = pd.read_excel(r'J:\Projects\Surveys\HHTravel\Survey2017\Data\Export\Version 1\Restricted\In-house\2017-internal1-R-5-trip-revised.xlsx',skiprows=1)
codebook_file_name = '2017-pr2-codebook.xlsx'
codebook_trip_name = '5-TRIP'
mode_lookup_f = 'C:/travel-studies/2017/summary/transit_simple.xlsx'
purpose_lookup_f = 'C:/travel-studies/2017/summary/destination_simple.xlsx'
output_file_loc = 'C:/travel-studies/2017/summary/output/travel_survey_simple.xlsx'

def code_sov(trip):
    trip['Main Mode'] = trip['Mode Simple']
    trip['Main Mode'][(trip['Mode Simple'] =='Drive')] = 'SOV'
    trip['Main Mode'][(trip['Mode Simple'] =='Drive')&(trip['travelers_total'] >1)]='HOV'
 
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

def simple_table(table,var2, wt_field, type):
        if type == 'total':
            print var2
            raw = table.groupby(var2).sum()[wt_field].reset_index()
            raw.columns =  [var2, 'sample_count']
            raw['share']= raw['sample_count']/raw['sample_count'].sum()

        return raw

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

   

    codebook_trip = pd.read_excel(survey_2017_dir+codebook_file_name, skiprows=2, sheetname = codebook_trip_name)
    purpose_lookup = pd.read_excel(purpose_lookup_f)
    mode_lookup = pd.read_excel(mode_lookup_f)

    print 'prepping data codes'
    trip_df = prep_data (trip, codebook_trip)

    trip_detail = pd.merge(trip_df, purpose_lookup, how= 'left', on = 'Destination purpose')
    trip_detail = pd.merge(trip_detail, mode_lookup, how ='left', on = 'Primary Mode')
    trip_detail = code_sov(trip_detail)

    trip_detail['ones'] = 1

    with pd.ExcelWriter(output_file_loc, engine = 'xlsxwriter') as writer:
        simple_table(trip_detail, 'Main Mode', 'ones', 'total').to_excel(writer, sheet_name ='Mode')
        simple_table(trip_detail, 'Transit trip: Travel mode to transit', 'ones', 'total').to_excel(writer, sheet_name = 'Access Mode')
        simple_table(trip_detail, 'dest_purpose_simple', 'ones', 'total').to_excel(writer, sheet_name = 'Purpose')
        simple_table(trip_detail, 'Part 2 participation group', 'ones', 'total').to_excel(writer, sheet_name = 'Participation Group')
        simple_table(trip_detail, 'travelers_hh', 'ones', 'total').to_excel(writer, sheet_name = 'Household Travelers')
        pd.DataFrame(pd.to_numeric(trip_detail['trip_path_distance'], errors = 'coerce').dropna(how='all').describe()).to_excel(writer, sheet_name = 'Trip Lengths')
        pd.DataFrame(pd.to_numeric(trip_detail['speed_mph'], errors = 'coerce').dropna(how='all').describe()).to_excel(writer, sheet_name = 'Speed')
        



    
          

