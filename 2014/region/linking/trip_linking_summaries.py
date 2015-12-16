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
linked_file = r'J:\Projects\Surveys\HHTravel\Survey2014\Data\Linked Trip Edits\V7\Trips Linked v7 with BN Changes.xlsx'

hh = pd.read_excel(hh_loc)
trip = pd.read_excel(trip_loc, 'Data')

trip.replace('.',"",inplace=True)

# Trip file with unlinked files removed and converted to linked trips
linked_trips_combined = pd.read_excel(linked_file, sheetname='Linked Trips Combined')
linked_trips_combined = pd.merge(linked_trips_combined,
                                pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip','_per'])

# Trips without unlinked or linked trips
linked_trips_removed = pd.read_excel(linked_file, sheetname='All Unlinked Trips Removed')
linked_trips_removed = pd.merge(linked_trips_removed,
                                pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip','_per'])

# Linked Trips only
linked_trips_only = pd.read_excel(linked_file, sheetname='Linked Trips Only')
linked_trips_only = pd.merge(linked_trips_only,
                                pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip','_per'])

# Original trip file
original_trip = pd.merge(trip, pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip','_per'])

# Unlinked Trips only
unlinked_trips_only = pd.read_excel(linked_file, sheetname='Unlinked Trips Only')

unlinked_trips_only = pd.merge(unlinked_trips_only,
                                pd.DataFrame(hh[['hhid', 'expwt_final']]),
                                left_on='hhid',right_on='hhid',
                                how="left", suffixes =['_trip','_per'])

# Let's do some data cleaning
linked_trips_combined = linked_trips_combined[linked_trips_combined.gdist > 0.05]   # remove any trip less ~ 250 ft
linked_trips_combined = linked_trips_combined[linked_trips_combined.gdist < 200] # remove any tips over 200 miles
linked_trips_combined = linked_trips_combined[linked_trips_combined.gdist < 200] # Get rid of mode-change trips?

linked_trips_removed = linked_trips_removed[linked_trips_removed.gdist > 0.05]
linked_trips_removed = linked_trips_removed[linked_trips_removed.gdist < 200]

# Remove exercise trips (d_purpose = 10)
linked_trips_removed = linked_trips_removed[linked_trips_removed.d_purpose != 10]
linked_trips_combined = linked_trips_combined[linked_trips_combined.d_purpose != 10]
original_trip = original_trip[original_trip.d_purpose != 10]

#linked_trips_only = linked_trips_only[linked_trips_only.gdist > 0]
#linked_trips_only = linked_trips_only[linked_trips_only.gdist < 200]

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

# summaries
linked_trips_combined_sum = summaries(linked_trips_combined, 'expwt_final_per')
linked_trips_removed_sum = summaries(linked_trips_removed, 'expwt_final_per')
#linked_trips_only_sum = summaries(linked_trips_only)
original_trip_sum = summaries(original_trip, 'expwt_final')

# weighted summaries
linked_trips_combined_wsum = weighted_summaries(linked_trips_combined, 'expwt_final_per')
linked_trips_removed_wsum = weighted_summaries(linked_trips_removed, 'expwt_final_per')
original_trip_wsum = weighted_summaries(original_trip, 'expwt_final')


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

def wt_avg(df, col):
    ''' computes weighted average for a specified column (col) of a dataframe (df) '''
    try:
        return (df[col]*df['expwt_final']).sum()/(df['expwt_final']).sum()
    except:
        return 0


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
