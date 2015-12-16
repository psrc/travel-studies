# Join HHID, PersonId and commute mode

import pandas as pd
import numpy as np
import HHSurveyToPandas as survey_df    # Load survey data
import process_survey as ps
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

# Load the person file
hh_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Household\1_PSRC2014_HH_2014-08-07_v3.xlsx'
trip_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Trip\4_PSRC2014_Trip_2014-08-07_v2-7.xlsx'
linked_file = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Trip\4_PSRC2014_Trip_2014-08-07_v2-8_linked.xlsx'
work_loc = r'D:\Survey\HouseholdSurvey2014\Joined Data\Release 1\Workers.xlsx'
person_loc = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Export\Release 1\General Release\Unzipped\2014-pr1-hhsurvey-persons.xlsx'

hh = pd.read_excel(hh_loc)
person = pd.read_excel(person_loc)
trip = pd.read_excel(trip_loc, 'Data')
work = pd.read_excel(work_loc, 'Sheet1')
linked_trips = pd.read_excel(linked_file, sheetname='Linked Trips Combined')

linked_trips = pd.merge(linked_trips, pd.DataFrame(hh[['hhid', 'h_county_name', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip',''])


linked_trips = linked_trips[linked_trips.gdist > 0.05]   # remove any trip less ~ 250 ft
linked_trips = linked_trips[linked_trips.gdist < 200] # remove any tips over 200 miles

# Remove exercise trips (d_purpose = 10)
linked_trips = linked_trips[linked_trips.d_purpose != 10]

trip.replace('.',"",inplace=True)
# Make all column titles lowercase so we can join them 
linked_trips.columns =  [x.lower() for x in linked_trips.columns]
person.columns =  [x.lower() for x in person.columns]




person_commute_modes = mode_splits(person_commute, 'mode', 'expwt_final')
worker_only_commute_modes = mode_splits(worker_only_commute, 'mode', 'expwt_final')

weighted_pivot_shares(worker_only_commute, 'mode', 'h_county_name', 'expwt_final', 'sum')
pd.pivot_table(worker_only_commute, values = 'expwt_final', rows='mode',columns='h_county_name',aggfunc=np.sum)


ps.clip(person_commute_modes)




ps.clip(person_commute)

# look at duplicates

# Sometimes there are multiple records per person. Get unique records
a = person_commute.groupby('personid').count()

# join the commute mode to the person file
#person_commute_mode = person[['personid', 'hhid', 'worker']].join(commute_home2work[['personid','mode']],on='personid',lsuffix='',rsuffix='_trip', how='right')

# Join to he commute to 


#person['work_commute_mode'] = commute_home2work['mode']
#person['tripid'] = commute_home2work['tripid']
#person['work_commute_mode'].fillna(0, inplace=True)
#person['tripid'].fillna(0, inplace=True)

#ps.clip(person[['personid', 'hhid', 'tripid','worker','work_commute_mode']])

## Trip file with unlinked files removed and converted to linked trips
#linked_trips_combined = pd.read_excel(linked_file, sheetname='Linked Trips Combined')
#linked_trips_combined = pd.merge(linked_trips_combined,
#                                pd.DataFrame(hh[['hhid', 'expwt_final', 'h_rgc_name']]),
#                                left_on='hhid',right_on='hhid',
#                                how="left", suffixes =['_trip',''])

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
