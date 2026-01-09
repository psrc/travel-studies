import pandas as pd
import numpy as np
#import HHSurveyToPandas as survey_df    # Load survey data
import process_survey as ps
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
import datetime

# Load the person file
hh_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Export\Release 2\2014-pr2-hhsurvey-households.xlsx'
trip_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Export\Release 2\2014-pr2-hhsurvey-trips.xlsx'
person_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Export\Release 2\2014-pr2-hhsurvey-persons.xlsx'
trip_with_rgc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Maps\Release 2\trips_with_rgc.csv'

expwt_name = 'expwt_2'

# This may need to be updated with the latest HH file?
work_loc = r'D:\Survey\HouseholdSurvey2014\Joined Data\Release 1\Workers.xlsx'

# load trip file with rgc info on it

hh = pd.read_excel(hh_loc, 'Data')
trip = pd.read_excel(trip_loc, 'Data')
person = pd.read_excel(person_loc, 'Data')
work = pd.read_excel(work_loc, 'Sheet1')
trip_rgc = pd.read_csv(trip_with_rgc)

work.columns =  [x.lower() for x in work.columns]
trip.columns =  [x.lower() for x in trip.columns]
person.columns =  [x.lower() for x in person.columns]

trip.replace('.',"",inplace=True)
trip.fillna(0,inplace=True)

# Join the trip file with 

# Clean the data by removing very long and very short trips
# Keep track of the number of rows being removed
min_trip_len = 0.05
max_trip_len = 200

trip = trip[trip['gdist'] > min_trip_len]   # remove any trip less ~ 250 ft
trip = trip[trip['gdist'] < max_trip_len] # remove any tips over 200 miles

# Creat an integer version of gdist so we can plot frequency distributions
trip['gdist_int'] = trip['gdist'].astype(int)

# Remove exercise trips (d_purpose = 10)
# Should we actually remove these? 
exercise_trips = trip[trip['d_purpose'] == 10]
trip = trip[trip['d_purpose'] != 10]
trip = trip[trip['d_purpose'] != 15]
walk_trips = trip[trip['mode'] == 7]

# Get commute trips
commute_home2work = trip.query("o_purpose == 1 & d_purpose == 2")
commute_work2home = trip.query("o_purpose == 2 & d_purpose == 1")
all_commute = trip.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")

# Get trips by purpose
school_trips = trip.query("d_purpose == 6")
meal_trips = trip.query("d_purpose == 11")
home_trips = trip.query("d_purpose == 1")
personal_business_trips = trip.query("d_purpose == 8 or d_purpose == 7 or d_purpose == 14")
shop_trips = trip.query("d_purpose == 4 or d_purpose == 5")
social_trips = trip.query('d_purpose == 12 or d_purpose == 13')
other_trips = trip.query("d_purpose == 16 or d_purpose == 15 or d_purpose == 13 or d_purpose == 10 or d_purpose == 9 or d_purpose == 3")
escort_trips = trip.query("d_purpose == 9")


# Make some summaries of these files
def mode_splits(df, mode_col, expwt_col):
    return df.groupby(mode_col).sum()[expwt_col]/(df.groupby(mode_col).sum()[expwt_col].sum())

def weighted_pivot_shares(df, pivot_row, pivot_col, expwt_col, aggfunc):
    sums = pd.pivot_table(df, values=expwt_col, rows=pivot_row,columns=pivot_col,aggfunc=aggfunc)
    return sums/sums.sum()

# Trips by Mode
trip_mode_splits = mode_splits(trip, 'mode', expwt_name)
trips_x_mode = trip.groupby('mode').sum()[expwt_name]

# Trips by Purpose
trip_purp_splits = mode_splits(trip, 'd_purpose', expwt_name)
trips_x_purpose = trip.groupby('d_purpose').sum()[expwt_name]

# Trip Length Distribution
trip_len_dist = trip[['gdist_int',expwt_name]].groupby('gdist_int').sum()[expwt_name].astype(int)

# Walk len dist
trip_len_dist = walk_trips[['gdist_int',expwt_name]].groupby('gdist_int').sum()[expwt_name].astype(int)

# Create some trip distributions by purpose or trip type
work_len_dist = all_commute[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
school_len_dist = school_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
meal_len_dist = meal_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
home_len_dist = home_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
personal_business_len_dist = personal_business_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
shop_trips_len_dist = shop_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
social_trips_len_dist = social_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
other_trips_len_dist = other_trips[['gdist_int','expwt_final']].groupby('gdist_int').sum()['expwt_final'].astype(int)
escort_trips_len_dist = escort_trips[['gdist_int',expwt_name]].groupby('gdist_int').sum()[expwt_name].astype(int)

# Split by TOD
# Pull our hour from the datestamp
timetrip = trip[trip['time_start_hhmm'] != 0]

timetrip['hour_start'] = np.empty_like(timetrip.index)

# Awful loop!!! Need to figure out how to do this with arrays
for row in xrange(len(timetrip.index)):
    print row
    timetrip['hour_start'].iloc[row] = timetrip['time_start_hhmm'].values[row].hour


# Look at trips by RGC
rgc_modes = pd.pivot_table(trip_rgc, values='expwt_final', rows='mode',    
                                    columns='rgc_name', aggfunc='count')

# Commute trips by RGC
commute_trips_rgc = trip_rgc.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")
rgc_commute_modes = pd.pivot_table(commute_trips_rgc, values='expwt_final', rows='mode',    
                                    columns='rgc_name', aggfunc=np.sum)














































# Join the worker location file to trip file to get information about commute shares to RGC

# Merge work loc records to trip file
trip_work = trip.join(work, on='personid', lsuffix= '_trip', rsuffix ='_work')
trip_work.fillna(0,inplace=True)

# Look at mode splits by RGC home location
rgc_modes = pd.pivot_table(trip_work, values='expwt_final', rows='mode',    
                                    columns='rgcname', aggfunc=np.sum)




















# Trip distribution by mode
walk_len_dist = pd.value_counts(walk_trips['gdist_int'],sort=True,normalize=True).sort_index()






# Join to person file to get info on worker
person_commute = pd.merge(commute_home2work,person[['worker','personid']],on='personid',suffixes=['_trip',''])
person_commute.fillna(0, inplace=True)

# Remove non worker
worker_only_commute = person_commute.query("worker == 1")





#trip_len_dist = pd.value_counts(a.values,sort=True).sort_index()
#trip_len_dist_normalized = pd.value_counts(wt_gdist_int,sort=True,normalize=True).sort_index()

# Trip file with unlinked files removed and converted to linked trips
linked_trips_combined = pd.read_excel(linked_file, sheetname='Linked Trips Combined')
linked_trips_combined = pd.merge(linked_trips_combined,
                                pd.DataFrame(hh[['hhid', 'expwt_final', 'h_rgc_name']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip',''])

# Trips without unlinked or linked trips
linked_trips_removed = pd.read_excel(linked_file, sheetname='All Unlinked Trips Removed')
linked_trips_removed = pd.merge(linked_trips_removed,
                                pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip',''])

# Linked Trips only
linked_trips_only = pd.read_excel(linked_file, sheetname='Linked Trips Only')
linked_trips_only = pd.merge(linked_trips_only,
                                pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip',''])

# Original trip file
original_trip = pd.merge(trip, pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip',''])

# Unlinked Trips only
unlinked_trips_only = pd.read_excel(linked_file, sheetname='Unlinked Trips Only')

unlinked_trips_only = pd.merge(unlinked_trips_only,
                                pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip',''])

# Let's do some data cleaning
linked_trips_combined = linked_trips_combined[linked_trips_combined.gdist > 0.05]   # remove any trip less ~ 250 ft
linked_trips_combined = linked_trips_combined[linked_trips_combined.gdist < 200] # remove any tips over 200 miles
linked_trips_combined = linked_trips_combined[linked_trips_combined.gdist < 200] # Get rid of mode-change trips?



# Remove exercise trips (d_purpose = 10)
no_exercise = linked_trips_combined[linked_trips_combined.d_purpose != 10]
exercise_only = linked_trips_combined[linked_trips_combined.d_purpose == 10]

# Remove rows with "." in fields - indicates Neil changed these and they don't have time or dist
for column in original_trip.columns:
    if type(original_trip[column].iloc[0]) == np.int:
        print column
        original_trip = original_trip[original_trip[column] <> '.']

original_trip.fillna(0, inplace=True)
original_trip.replace('', 0, inplace=True)
original_trip = original_trip[original_trip.gdist > 0.05]
original_trip = original_trip[original_trip.gdist < 200]

#original_trip['gdist'] = original_trip[field].astype("int64")
original_trip['gtime'] = original_trip['gtime'].astype("float64")

def summaries(df, expwt):
    results = {}
    results['gdist'] = df['gdist'].mean()
    results['gtime'] = df['gtime'].mean()
    results['mode'] = df.groupby('mode').sum()[expwt]
    results['purpose'] = df.groupby('d_purpose').sum()[expwt]
    results['purp_x_mode'] = pd.pivot_table(df, values=expwt, rows='mode', 
                                    columns='d_purpose', aggfunc=np.sum)
    return results

def weighted_summaries(df, expwt):
    results = {}
    #a = ((df['gidst']*df['expwt_final'])/df['expwt_final'].count()).mean()
    results['gdist'] = ((df['gdist']*df[expwt])/(df[expwt].count())).mean()
    results['gtime'] = ((df['gtime']*df[expwt])/df[expwt].count()).mean()
    #results['mode']

    return results

# summaries of all trips (including exercise)
basic_summary = summaries(linked_trips_combined, 'expwt_final')
no_exercise_summary = summaries(no_exercise, 'expwt_final')
exercise_summary = summaries(exercise_only, 'expwt_final')

# weighted summaries
linked_trips_combined_wsum = weighted_summaries(linked_trips_combined, 'expwt_final_per')
linked_trips_removed_wsum = weighted_summaries(linked_trips_removed, 'expwt_final_per')
original_trip_wsum = weighted_summaries(original_trip, 'expwt_final')

# Trimmed trip lengths
under_5 = no_exercise[no_exercise.gdist < 5]
under_5 = under_5[under_5['mode'] < 5]
under_30 = no_exercise[no_exercise.gdist < 30]
under_30 = under_30[under_30['mode'] < 5]
only_auto = no_exercise[no_exercise['mode'] < 5]

# Trip length distribution
f, (ax1) = plt.subplots(1, 1, sharex=True, figsize=(8, 6))
c1, c2 = sns.color_palette("Set1", 2)

sns.kdeplot(only_auto['gdist'], label="Original", ax=ax1)
#sns.kdeplot(walk_trips_no_unlinked['gdist'], label="No unlinked", ax=ax1)
#sns.kdeplot(walk_trips_combined['gdist'], label="Linked Added", ax=ax1)
plt.show()

def wt_avg(df, col):
    ''' computes weighted average for a specified column (col) of a dataframe (df) '''
    try:
        return (df[col]*df['expwt_final']).sum()/(df['expwt_final']).sum()
    except:
        return 0

# What are the average trip lengths for walk and biking?
wt_avg(exercise_only, 'gdist')
wt_avg(no_exercise, 'gdist')

# walk only exercise trips
wt_avg(exercise_only[exercise_only['mode'] == 7], 'gdist')

# walk only no exercise
wt_avg(no_exercise[no_exercise['mode'] == 6], 'gdist')

# bike only exercise trips
wt_avg(exercise_only[exercise_only['mode'] == 6], 'gdist')

# bike only no exercise
wt_avg(no_exercise[no_exercise['mode'] == 7], 'gdist')

# RGC mode share of those LIVING in each RGC
linked_trips_combined['h_rgc_name'].fillna("Not an RGC", inplace=True)
rgc_share = pd.pivot_table(linked_trips_combined, values='expwt_final', rows='h_rgc_name',    # RGC name
                                    columns='mode', aggfunc=np.sum) 

no_exercise['h_rgc_name'].fillna("Not an RGC", inplace=True)
no_exercise = pd.merge(no_exercise,
                                pd.DataFrame(hh[['hhid', 'expwt_final', 'h_rgc_name']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip',''])




# Commute trips

commute_trips = no_exercise.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")




mode = original_trip_sum['mode']
ps.clip(linked_trips_combined_sum['mode'])


# Look at all walk trips
walk_trips_original = original_trip[original_trip['mode'] == 7]
walk_trips_no_unlinked = linked_trips_removed[linked_trips_removed['mode'] == 7]
walk_trips_combined = linked_trips_combined[linked_trips_combined['mode'] == 7]

# We probably also want to restrict the crazy long walk trips... How about less than 2 miles?
max_walk_dist = 2
walk_trips_original = original_trip[original_trip['gdist'] < max_walk_dist]
walk_trips_no_unlinked = linked_trips_removed[linked_trips_removed['gdist'] < max_walk_dist]
walk_trips_combined = linked_trips_combined[linked_trips_combined['gdist'] < max_walk_dist]

# Regular average trip distsnaces
avg_original_walk = walk_trips_original['gdist'].mean()
avg_no_unlinked_walk = walk_trips_no_unlinked['gdist'].mean()
avg_trips_combined_walk = walk_trips_combined['gdist'].mean()

# Join all the results together for comparison
walk_dists = pd.DataFrame([walk_trips_original['gdist'], walk_trips_no_unlinked['gdist'], walk_trips_combined['gdist']], index=['Original', 'Unlinked Removed', 'Linked Added']).T

f, (ax1) = plt.subplots(1, 1, sharex=True, figsize=(8, 6))
c1, c2 = sns.color_palette("Set1", 2)

sns.kdeplot(walk_trips_original['gdist'], label="Original", ax=ax1)
sns.kdeplot(walk_trips_no_unlinked['gdist'], label="No unlinked", ax=ax1)
sns.kdeplot(walk_trips_combined['gdist'], label="Linked Added", ax=ax1)
plt.show()

# compute weighted averages




# Number of walk trips by purpose
walk_trips_original.groupby('d_purpose').sum()['expwt_final']
walk_trips_no_unlinked.groupby('d_purpose').sum()['expwt_final_per']
walk_trips_combined.groupby('d_purpose').sum()['expwt_final_per']

# Avg trip distance by purpose
def avg_dist_x_purp(df):
    avg_dist_x_purp = {} ; newlist = []
    for i in xrange(1, 16 + 1):
        #if i != 10: # skip exercise trips...
        avg_dist_x_purp[i] = df[df['d_purpose'] == i]['gdist'].mean()
        newlist.append(df[df['d_purpose'] == i]['gdist'].mean())
    return pd.DataFrame(newlist)

avg_dist_x_purp_original = avg_dist_x_purp(walk_trips_original)
avg_dist_x_purp_no_unlinked = avg_dist_x_purp(walk_trips_no_unlinked)
avg_dist_x_purp_no_combined = avg_dist_x_purp(walk_trips_combined)

# Avg WEIGHTED trip distance by purpose 
def wtavg_dist_x_purp(df, col):
    avg_dist_x_purp = {} ; newlist = []
    for i in xrange(1, 16 + 1):
        if i != 10: # skip exercise trips...
            dfnew = df[df['d_purpose'] == i]
            avg_dist_x_purp[i] = wt_avg(dfnew, col)
            newlist.append(wt_avg(dfnew, col))

    return pd.DataFrame(newlist)

# Average weighted trip distance by purpose for WALK trips
wtavg_dist_x_purp_original_walk = wtavg_dist_x_purp(walk_trips_original, 'gdist')
wtavg_dist_x_purp_no_unlinked_walk = wtavg_dist_x_purp(walk_trips_no_unlinked, 'gdist')
wtavg_dist_x_purp_no_combined_walk = wtavg_dist_x_purp(walk_trips_combined, 'gdist')

# Average weighted trip distance by purpose for ALL trips
wtavg_dist_x_purp_original = wtavg_dist_x_purp(original_trip, 'gdist')
wtavg_dist_x_purp_no_unlinked = wtavg_dist_x_purp(linked_trips_removed, 'gdist')
wtavg_dist_x_purp_no_combined = wtavg_dist_x_purp(linked_trips_combined, 'gdist')

##################### Transit trips by purpose
# Look at all walk trips ----- Select modes between 7 and 12 (exclusive)
trans_trips_original = original_trip[original_trip['mode'] > 7]
trans_trips_original = trans_trips_original[trans_trips_original['mode'] < 12]

trans_unlinked_removed = linked_trips_removed[linked_trips_removed['mode'] > 7]
trans_unlinked_removed = trans_unlinked_removed[trans_unlinked_removed['mode'] < 12]

trans_trips_combined = linked_trips_combined[linked_trips_combined['mode'] > 7]
trans_trips_combined = trans_trips_combined[trans_trips_combined['mode'] < 12]


trans_trips_original.groupby('d_purpose').sum()['expwt_final']
trans_unlinked_removed.groupby('d_purpose').sum()['expwt_final_per']
trans_trips_combined.groupby('d_purpose').sum()['expwt_final_per']

################### Auto Trips by purpose

auto_trips_original = original_trip[original_trip['mode'] < 5]

auto_unlinked_removed = linked_trips_removed[linked_trips_removed['mode'] < 5]

auto_trips_combined = linked_trips_combined[linked_trips_combined['mode'] < 5]

auto_trips_original.groupby('d_purpose').sum()['expwt_final']
auto_unlinked_removed.groupby('d_purpose').sum()['expwt_final_per']
auto_trips_combined.groupby('d_purpose').sum()['expwt_final_per']

######### Commute trips #####
# Only want origin of home, d of work
commute_linked_trips_removed = linked_trips_removed.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")
commute_linked_trips_combined = linked_trips_combined.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")
commute_original_trip = original_trip.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")

# summaries of commute trips
commute_linked_trips_combined_sum = summaries(commute_linked_trips_combined,'expwt_final_per')
commute_linked_trips_removed_sum = summaries(commute_linked_trips_removed, 'expwt_final_per')
#linked_trips_only_sum = summaries(linked_trips_only)
commute_original_trip_sum = summaries(commute_original_trip, 'expwt_final')

# weighted summaries
commute_linked_trips_combined_wsum = weighted_summaries(commute_linked_trips_combined,'expwt_final_per')
commute_linked_trips_removed_wsum = weighted_summaries(commute_linked_trips_removed,'expwt_final_per')
commute_original_trip_wsum = weighted_summaries(commute_original_trip,'expwt_final')

# Print out to excel
#output_sheet = "Linked Trip Summaries.xlsx"
#workbook = xlsxwriter.Workbook(output_sheet)
#worksheet = workbook.add_worksheet()

#worksheet.write("")

# Active transportation summaries


################## MODE SPLIT PIVOT TABLES

# join trip to person file
trip.replace('.',"",inplace=True)
person.replace('.',"",inplace=True)
trip.fillna(0,inplace=True)
person.fillna(0,inplace=True)
trip_person['personid_p'] = trip_person['personid_p'].astype(int)
trip_person = pd.merge(trip, person, on='personid', suffixes=['_t','_p'])
trip_person.fillna(0,inplace=True)

# join trip to hh file
hh.replace('.',"",inplace=True)
hh.fillna(0,inplace=True)
trip_hh = pd.merge(trip, hh, on='hhid', suffixes=['_t','_h'])
trip_hh.fillna(0,inplace=True)

commute_trips = trip_person.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")
commute_trips_hh = trip_hh.query("o_purpose == 1 & d_purpose == 2 or o_purpose == 2 & d_purpose == 1")

modes_by_age = pd.pivot_table(trip_person, values='expwt_2_t', rows='mode',    
                                    columns='age', aggfunc="count")

commute_modes_by_age = pd.pivot_table(commute_trips, values='expwt_2_t', rows='mode',    
                                    columns='age', aggfunc="sum")

################## 
# Mode split by Home Type
modes_by_hometype = pd.pivot_table(trip_hh, values='expwt_2_t', rows='mode',    
                                    columns='res_type', aggfunc="sum")
commute_modes_by_hometype = pd.pivot_table(commute_trips_hh, values='expwt_2_t', rows='mode',    
                                    columns='res_type', aggfunc="count")

# Mode split by rent/own
modes_by_rentown = pd.pivot_table(trip_hh, values='expwt_2_t', rows='mode',    
                                    columns='rent_own', aggfunc="sum")
commute_modes_by_rentown = pd.pivot_table(commute_trips_hh, values='expwt_2_t', rows='mode',    
                                    columns='rent_own', aggfunc="sum")


# People who moved from a multi-family house to a single-family house in the past 5 years
new_sfh = trip_hh.query('prev_res_type != 1 and res_type == 1')
new_sfh_modes = new_sfh.groupby('mode').sum()['expwt_2_t']

# Vehicle count
modes_vehcount = pd.pivot_table(trip_hh, values='expwt_2_t', rows='mode',    
                                    columns='vehicle_count', aggfunc="sum")

# HH Size
modes_hhsize = pd.pivot_table(trip_hh, values='expwt_2_t', rows='mode',    
                                    columns='hhsize', aggfunc="sum")

# Number of Children
modes_numchild = pd.pivot_table(trip_hh, values='expwt_2_t', rows='mode',    
                                    columns='numchildren', aggfunc="sum")

# Income
modes_income = pd.pivot_table(trip_hh, values='expwt_2_t', rows='mode',    
                                    columns='hh_income_detailed_imp', aggfunc="sum")

# County
modes_county = pd.pivot_table(trip_hh, values='expwt_2_t', rows='mode',    
                                    columns='h_county_name', aggfunc="sum")

# RGC
modes_rgc = pd.pivot_table(trip_hh, values='expwt_2_t', rows='mode',    
                                    columns='h_rgc_name', aggfunc="sum")

# Education


# Employment


# gender


################ BUILD SOME COHORTS
# 1 Car, 2+ Adults
# No Car, 1 Adult
# No Car, 2+ Adults
# RGC Residents
# Transit Riders / Transit Commuters
transit_trips = trip.query('mode == 8 or mode == 9 or mode == 9 or mode == 10 or mode == 11')
transit_commute_trips = trip.query('mode == 8 or mode == 9 or mode == 9 or mode == 10 or mode == 11')

def travel_patterns(df, origin, dest, expwt, scan_size):
    ''' Travel patterns O -> D '''
    # Pivot table for all O-D travel
    table = pd.pivot_table(df, values=expwt, rows=origin, columns=dest, aggfunc="sum")
    # Extract the largest values from the pivot table and remove the intra-zonal trips (same O and D)
    # scan_size refers to number of largest values to extract. Most are intra-zonal so use a large scan_size value.
    largest = pd.DataFrame(table.stack().nlargest(scan_size))
    return largest.query(origin + ' != ' + dest)

# Get travel patterns for all Zip Code O-Ds, all trips
pattern_zip = travel_patterns(trip_hh, "ozip", "dzip", "expwt_2_t", 150)
# All trips by ZIP and by transit only
pattern_zip_bus = travel_patterns(transit_trips, "ozip", "dzip", "expwt_2", 150)
# Commute trips by ZIP and by transit only
pattern_zip_bus_commute = travel_patterns(transit_commute_trips, "ozip", "dzip", "expwt_2", 150)
# Commute trips by ZIP
pattern_zip_commute = travel_patterns(commute_trips_hh, "ozip", "dzip", "expwt_2_t", 150)
# Car commuters by ZIP

# Travel patterns for all Cities, all trips
pattern_city = travel_patterns(trip_hh, "ocity", "dcity", "expwt_2_t", 150)
# All trips by ZIP and by transit only
pattern_city_bus = travel_patterns(transit_trips, "ocity", "dcity", "expwt_2", 150)
# Commute trips by ZIP and by transit only
pattern_city_bus_commute = travel_patterns(transit_commute_trips, "ocity", "dcity", "expwt_2", 150)
# Commute trips by City
pattern_city_commute = travel_patterns(commute_trips_hh, "ocity", "dcity", "expwt_2_t", 150)




# How does smartphone use, travel info use, and fare payment vary with language, income, and/or age?
pd.pivot_table(person, values='expwt_2', rows='smartphone',  columns='education', aggfunc="sum")
pd.pivot_table(person, values='expwt_2', rows='smartphone',  columns='age', aggfunc="sum")


# join person to hh
person_hh = pd.merge(person, hh, on='hhid', suffixes=['_p','_h'])
pd.pivot_table(person_hh, values='expwt_2_p', rows='smartphone',  columns='hh_income_detailed_imp', aggfunc="sum")

# Transit payment type by age, income
pd.pivot_table(person, values='expwt_2', rows='smartphone',  columns='transitpay_orca', aggfunc="sum")

pd.pivot_table(person_hh, values='expwt_2_p', rows='hh_income_detailed_imp',  columns='transitpay_orca', aggfunc="sum")