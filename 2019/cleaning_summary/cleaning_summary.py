import pandas as pd
import pyodbc


# File names and directories

sql_conn = pyodbc.connect('DRIVER={SQL Server}; SERVER=AWS-PROD-SQL\COHO;DATABASE=Sandbox;trusted_connection=true')
trip_table_name = "HHSurvey.Tripx"
trip  = pd.read_sql('SELECT * FROM '+trip_table_name, con = sql_conn)

survey_2017_dir = 'C:/Users/SChildress/Documents/GitHub/travel-studies/2019/cleaning_summary/'

##uncleaned
#trip = pd.read_csv(r'J:\Projects\Surveys\HHTravel\Survey2017\Data\Cleaning Process\5-Tripx.csv')
#cleaned
#trip = pd.read_excel(r'J:\Projects\Surveys\HHTravel\Survey2017\Data\Export\Version 1\Restricted\In-house\2017-internal1-R-5-trip-revised.xlsx',skiprows=1)
codebook_file_name = 'PSRC2019_Codebook_Draft.xlsx'
codebook_values_name = 'Values'
codebook_null_values_name = 'Null Values'
codebook_variables_name = 'Data Overview'
codebook_
mode_lookup_f = r'C:\Users\SChildress\Documents\GitHub\travel-studies\2019\cleaning_summary\transit_simple.xlsx'
purpose_lookup_f = r'C:\Users\SChildress\Documents\GitHub\travel-studies\2019\cleaning_summary\destination_simple.xlsx'
output_file_loc = r'C:\Users\SChildress\Documents\GitHub\travel-studies\2019\cleaning_summary\survey_cleaning_summary.xlsx'


def code_sov(trip):
    trip['Main Mode'] = trip['Mode Simple']
    trip['Main Mode'][(trip['Mode Simple'] =='Drive')] = 'SOV'
    trip['Main Mode'][(trip['Mode Simple'] =='Drive')&(trip['travelers_total'] >1)]='HOV'
 
    return trip

def simple_table(table,var2, wt_field, type):
        if type == 'total':
            print(var2)
            raw = table.groupby(var2).sum()[wt_field].reset_index()
            raw.columns =  [var2, 'sample_count']
            raw['share']= raw['sample_count']/raw['sample_count'].sum()

        return raw

def lookup_names(df, names):
    for col in df:
        names_col = pd.DataFrame(names.loc[names.variable == col])
        if not names_col.empty:
            try: 
                    df_named = pd.merge(df, names_col, how='left', left_on = col, right_on = 'Variable')
                    df[names_col['label'].iloc[0]] = df_named.Value
            except Exception:
                    pass
    return df


if __name__ == "__main__":
    print('reading excel files')
    
    codebook_values = pd.read_excel(survey_2017_dir+codebook_file_name, sheetname = codebook_values_name)
    codebook_null_values = pd.read_excel(survey_2017_dir+codebook_file_name, sheetname = codebook_null_values_name)
    codebook_variables = pd.read_excel(survey_2017_dir+codebook_file_name, sheetname = codebook_variables_name)
    purpose_lookup = pd.read_excel(purpose_lookup_f)
    mode_lookup = pd.read_excel(mode_lookup_f)
   
    print ('prepping data codes')

    for the_variable in codebook_values.variable.unique():
        codebook_null_values['variable'] = the_variable
        codebook_values= codebook_values.append(codebook_null_values)

    labeled_codebook = pd.merge(codebook_variables, codebook_values, left_on = 'Variable', right_on= 'variable')
    trip_detail = lookup_names(trip, labeled_codebook)

    
    


    trip_detail = pd.merge(trip_df, purpose_lookup, how= 'left', on = 'Destination purpose')
    trip_detail = pd.merge(trip_detail, mode_lookup, how ='left', on = 'Primary Mode')
    trip_detail = code_sov(trip_detail)

    trip_detail['ones'] = 1

    with pd.ExcelWriter(output_file_loc, engine = 'xlsxwriter') as writer:
        simple_table(trip_detail, 'Main Mode', 'ones', 'total').to_excel(writer, sheet_name ='Mode')
        simple_table(trip_detail, 'Transit trip: Travel mode to transit', 'ones', 'total').to_excel(writer, sheet_name = 'Access Mode')
        simple_table(trip_detail, 'dest_purpose_simple', 'ones', 'total').to_excel(writer, sheet_name = 'Destination Purpose')
        simple_table(trip_detail, 'Part 2 participation group', 'ones', 'total').to_excel(writer, sheet_name = 'Participation Group')
        simple_table(trip_detail, 'travelers_hh', 'ones', 'total').to_excel(writer, sheet_name = 'Household Travelers')
        simple_table(trip_detail, 'Auto trip, non-taxi: Park location at end of trip', 'ones', 'total').to_excel(writer, sheet_name = 'Parking location')
        simple_table(trip_detail, 'Travel day of week', 'ones', 'total').to_excel(writer, sheet_name = 'Travel Day')
        simple_table(trip_detail, 'copied_trip', 'ones', 'total').to_excel(writer, sheet_name = 'Copied')
        pd.DataFrame(pd.to_numeric(trip_detail['trip_path_distance'], errors = 'coerce').dropna(how='all').describe()).to_excel(writer, sheet_name = 'Trip Lengths')
        pd.DataFrame(pd.to_numeric(trip_detail['speed_mph'], errors = 'coerce').dropna(how='all').describe()).to_excel(writer, sheet_name = 'Speed')
        pd.DataFrame(pd.to_numeric(trip_detail['google_duration'], errors = 'coerce').dropna(how='all').describe()).to_excel(writer, sheet_name = 'Duration')



    
          

