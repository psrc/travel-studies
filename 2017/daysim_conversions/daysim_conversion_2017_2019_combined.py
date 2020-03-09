# NOTE: run with Python 3 for proper behavior in pandas lib

import os, sys
import numpy as np
import pandas as pd


# Set current working directory to script location
#working_dir = r'C:\Users\bnichols\travel-studies\2017\daysim_conversions'
#os.chdir(working_dir)

# Import local module variables
from lookup import *

# Set input paths
hh_file_dir = r'J:\Projects\Surveys\HHTravel\Survey2019\Data\PSRC_2019_HTS_Deliverable_022020\Weighted_Data_022020\geocoded\1_household.csv'
person_file_dir = r'J:\Projects\Surveys\HHTravel\Survey2019\Data\PSRC_2019_HTS_Deliverable_022020\Weighted_Data_022020\geocoded\2_person.csv'
trip_file_dir = r'J:\Projects\Surveys\HHTravel\Survey2019\Data\PSRC_2019_HTS_Deliverable_022020\Weighted_Data_022020\geocoded\5_trip.csv'

# FIXME - which columns to use?:
hh_wt_col = 'hh_wt_combined'

# Output directory
#output_dir = r'C:\Users\bnichols\travel-studies\2017\daysim_conversions'
output_dir = r'R:\e2projects_two\SoundCastDocuments\2017Estimation\survey\geocoded'

# Flexible column names, given that these may change in future surveys
hhno = 'hhid'
hownrent = 'rent_own'
hrestype = 'res_type'
hhincome = 'hhincome_detailed'
hhtaz = 'final_home_taz'
hhparcel = 'final_home_parcel'
hhexpfac = 'hh_wt_revised'
hhwkrs = 'numworkers'
hhvehs = 'vehicle_count'
pno = 'pernum'

def process_person_file(person_file_dir):
    """ Create Daysim-formatted person file from Survey Excel file. """

    person = pd.read_csv(person_file_dir, encoding='latin-1')

    # Full time worker
    person.loc[person['employment'] == 1, 'pptyp'] = 1

    # Part-time worker
    person.loc[person['employment'] == 2, 'pptyp'] = 2

    # Non-working adult age 65+
    person.loc[(person['worker'] == 0) &  (person['age'].isin([5,6,7,8,9])), 'pptyp'] = 3

    # Non working adult age <65
    person.loc[(person['worker'] == 0) &  (person['age'].isin([10,11,12])), 'pptyp'] = 4

    # university student (full-time)
    person.loc[(person['schooltype'].isin([6,7])) & (person['student'] == 3), 'pptyp'] = 5

    # High school student age 16+
    person.loc[(person['age'] >= 4) & (person['schooltype'].isin([3,4,5])), 'pptyp'] = 6

    # Child age 5-15
    person.loc[person['age'].isin([2,3]), 'pptyp'] = 7

    # child under 5
    person.loc[person['age']==1, 'pptyp'] = 8

    # 
    person.loc[person['pptyp'].isnull(), 'pptyp'] = -1

    # Person worker type
    person.loc[person['employment'].isin([1]), 'pwtyp'] = 1
    person.loc[person['employment'].isin([2]), 'pwtyp'] = 2
    person.loc[person['employment'].isin([3,4,5,6,7]), 'pwtyp'] = 0
    person['pwtyp'].fillna(0,inplace=True)
    person['pwtyp'] = person['pwtyp'].astype('int')

    # Transit pass availability
    person['ptpass'] = 0
    person.loc[(person['tran_pass_12'].isin([1,2])) | (person['benefits_3'].isin([2,3])),'ptpass'] = 1

    # Paid parking at work (any level of subsidy counts as 'paid')
    person['ppaidprk'] = 0
    person.loc[person['workpass'].isin([3,4]), 'ppaidprk'] = 1

    ### FIXME:
    # usual arrival/departure time to/from work
    # Derive this from the day record file and trip files 
    # typical_day = 1 (true) and look at the commute trip



    # Map other variables from lookup tables
    person['puwmode'] = person['commute_mode'].map(commute_mode_dict)   # Note that all HOV trips are lumped into HOV2 besides vanpool, should use occupancy to sort this out
    person['age'] = person['age'].astype('int')
    person['pagey'] = person['age'].map(age_map)
    person['pgend'] = person['gender'].map(gender_map)
    person['pstyp'] = person['student'].map(pstyp_map)
    person['pstyp'].fillna(0,inplace=True)
    person['hhno'] = person['hhid']
    person['pno'] = person['pernum']
    person['psexpfac'] = person['hh_wt_combined']

    # Get the TAZ and parcel data from the survey (must be added from the locate_parcels.py script first!)
    person['pwtaz'] = person['work_taz']
    person['pstaz'] = person['school_loc_taz']
    person['pwpcl'] = person['work_parcel']
    person['pspcl'] = person['school_loc_parcel']

    daysim_cols = ['hhno', 'pno', 'pptyp', 'pagey', 'pgend', 'pwtyp', 'pwpcl', 'pwtaz', 'pwautime',
               'pwaudist', 'pstyp', 'pspcl', 'pstaz', 'psautime', 'psaudist', 'puwmode', 'puwarrp', 
               'puwdepp', 'ptpass', 'ppaidprk', 'pdiary', 'pproxy', 'psexpfac']

    # Add empty columns to fill in later with skims
    for col in daysim_cols:
        if col not in person.columns:
            person[col] = -1
        else:
            person[col] = person[col].fillna(-1)
        
    person = person[daysim_cols]

    return person

def total_persons_to_hh(hh, person, daysim_field, filter_field, 
                        filter_field_list, hhid_col='hhno', wt_col='hhexpfac'):
    
    """Use person field to calculate total number of person in a household for a given field
    e.g., total number of full-time workers"""
    
    df = person[person[filter_field].isin(filter_field_list)]
    df = df.groupby(hhid_col).count().reset_index()[[wt_col,hhid_col]]
    df.rename(columns={wt_col: daysim_field}, inplace=True)
    
    # Join to households
    hh = pd.merge(hh, df, how='left', on=hhid_col)
    hh[daysim_field].fillna(0, inplace=True)
    
    return hh

def process_household_file(hh_file_dir, person):

    hh = pd.read_csv(hh_file_dir, encoding='latin-1')
    hh['hhno'] = hh['hhid']
    hh['hhexpfac'] = hh[hh_wt_col]

    # Workers hhwkrs
    hh = total_persons_to_hh(hh, person, daysim_field='hhwkrs', 
                            filter_field='pwtyp', filter_field_list=[1,2],
                            hhid_col='hhno', wt_col='psexpfac')

    # Full-time workers
    hh = total_persons_to_hh(hh, person, daysim_field='hhftw', 
                             filter_field='pwtyp', filter_field_list=[1],
                             hhid_col='hhno', wt_col='psexpfac')

    ## Part-time workers
    hh = total_persons_to_hh(hh, person, daysim_field='hhptw', 
                            filter_field='pwtyp', filter_field_list=[2],
                            hhid_col='hhno', wt_col='psexpfac')

    ## Retirees
    hh = total_persons_to_hh(hh, person, daysim_field='hhret', 
                        filter_field='pptyp', filter_field_list=[3],
                        hhid_col='hhno', wt_col='psexpfac')
    
    ## Other Adults
    hh = total_persons_to_hh(hh, person, daysim_field='hhoad', 
                        filter_field='pptyp', filter_field_list=[4],
                        hhid_col='hhno', wt_col='psexpfac')
    
    # University Students
    hh = total_persons_to_hh(hh, person, daysim_field='hhuni', 
                    filter_field='pptyp', filter_field_list=[5],
                    hhid_col='hhno', wt_col='psexpfac')

    # High school students
    hh = total_persons_to_hh(hh, person, daysim_field='hhhsc', 
                    filter_field='pptyp', filter_field_list=[6],
                    hhid_col='hhno', wt_col='psexpfac')

    # k12 age 5-15
    hh = total_persons_to_hh(hh, person, daysim_field='hh515', 
                    filter_field='pptyp', filter_field_list=[7],
                    hhid_col='hhno', wt_col='psexpfac')

        ## age under 5
    hh = total_persons_to_hh(hh, person, daysim_field='hhcu5', 
                filter_field='pptyp', filter_field_list=[8],
                hhid_col='hhno', wt_col='psexpfac')

    hh['hownrent'] = hh[hownrent].map(hownrent_map) 
    hh['hrestype'] = hh[hrestype].map(hhrestype_map) 
    hh['hhincome'] = hh[hhincome].map(income_map) 
    hh['hhtaz'] = hh[hhtaz]
    hh['hhparcel'] = hh[hhparcel]
    hh['hhwkrs'] = hh[hhwkrs]
    hh['hhno'] = hh[hhno]
    hh['hhvehs'] = hh[hhvehs]
    hh['samptype'] = 1

    # Remove households without parcels
    hh = hh[-hh['hhparcel'].isnull()]

    daysim_fields = ['hhno','hhsize','hhvehs','hhwkrs','hhftw','hhptw','hhret','hhoad','hhuni','hhhsc','hh515',
                 'hhcu5','hhincome','hownrent','hrestype','hhtaz','hhparcel','hhexpfac','samptype']

    hh = hh[daysim_fields]

    return hh

def process_trip_file(trip_file_dir, person):
    """ Convert trip records to Daysim format."""

    trip = pd.read_csv(trip_file_dir, encoding='latin-1')

    trip['trexpfac'] = trip['trip_wt_combined']
    # Filter out trips that have weight of zero or null
    trip = trip[-trip['trexpfac'].isnull()]
    trip = trip[trip['trexpfac'] > 0]

    # Filter out trips that started before 0 mam
    trip = trip[trip['depart_time_mam'] >= 0] 

    trip['hhno'] = trip['hhid']
    trip['pno'] = trip['pernum']
    trip['day'] = trip['daynum'].astype('int')
    trip['tsvid'] = trip['tripnum']
    trip['unique'] = trip['recid']

    # Select only weekday trips (M-Th)
    # 1 is Monday, 2 T, 3 W, 4 Th
    trip = trip[trip['dayofweek'].isin([1,2,3,4])] 

    trip['day'] = trip['dayofweek']

    trip['opurp'] = trip['o_purpose'].map(purpose_map)
    trip['dpurp'] = trip['d_purpose'].map(purpose_map)

    trip['dorp'] = trip['driver'].map(dorp_map)
    # Dorp of N/A is e in daysim, fillna with this value
    trip['dorp'] = trip['dorp'].fillna(3)

    # Assuming trip otaz, dtaz, opcl, dpcl are added from locate_parcels.py

    ##############################
    # Start and end time
    ##############################
    # Filter out rows with None
    trip = trip[-trip['depart_time_mam'].isnull()]
    trip = trip[-trip['arrival_time_mam'].isnull()]
    trip['arrtm'] = trip['arrival_time_mam']
    trip['deptm'] = trip['depart_time_mam']
    # if arrtm/deptm > 24*60, subtract that value to normalize to a single day
    # for some reason values can extend to a full day later
    for colname in ['arrtm','deptm']:
        for i in range(2,int(np.ceil(trip[colname]/(24*60)).max())+1):
            filter = (trip[colname] > (24*60)) & (trip[colname] < (24*60)*i)
            trip.loc[filter, colname] = trip.loc[filter, colname] - 24*60*(i-1)
    
    # Calculate start of next trip (ENDACTTM: trip destination activity end time)
    # FIXME: there are negative values in the activity_duration field
    trip['endacttm'] = trip['activity_duration'].abs() + trip['arrtm']


    ##############################
    # Mode
    ##############################
    trip['mode'] = 'Other'

    # Get HOV2/HOV3 based on total number of travelers
    auto_mode_list = [3,4,5,6,7,8,9,10,11,12,16,17,18,21,22,33,34]
    trip.loc[(trip['travelers_total'] == 1) & (trip['mode_1'].isin(auto_mode_list)),'mode'] = 'SOV'
    trip.loc[(trip['travelers_total'] == 2) & (trip['mode_1'].isin(auto_mode_list)),'mode'] = 'HOV2'
    trip.loc[(trip['travelers_total'] > 2) & (trip['mode_1'].isin(auto_mode_list)),'mode'] = 'HOV3+'
    # transit etc
    trip.loc[trip['mode_1'].isin([23,32,41,42,52]),'mode'] = 'Transit'
    trip.loc[trip['mode_1'].isin([1]),'mode'] = 'Walk'
    trip.loc[trip['mode_1'].isin([2]),'mode'] = 'Bike'
    trip.loc[trip['mode_1'].isin([24]),'mode'] = 'School_Bus'
    trip.loc[trip['mode_1'].isin([37]),'mode'] = 'TNC' # Should this also include traditonal Taxi?
    trip['mode'] = trip['mode'].map(mode_dict)
    

    ##############################
    # Origin and Destination Types
    ##############################

    # Assume "other" by default
    trip.loc[:,'oadtyp'] = 4
    trip.loc[:,'dadtyp'] = 4

    # Trips with origin/destination purpose of "Home" (0) have a origin/destination address type of "Home" (1)
    trip.loc[trip['opurp'] == 0,'oadtyp'] = 1
    trip.loc[trip['dpurp'] == 0,'dadtyp'] = 1

    # Trips to/from work are considered "usual workplace" only if dpcl == workplace parcel
    #### FIX ME: do not have PARCELS, only using TAZ
    # must join person records to get usual work and school location
    trip = trip.merge(person[['hhno','pno','pwtaz','pstaz']], on=['hhno','pno'], how='left')

    # If trip is to/from TAZ of usual workplace and trip purpose is work
    trip.loc[(trip['opurp'] == 0) & (trip['otaz'] == trip['pwtaz']),'oadtyp'] = 2
    trip.loc[(trip['dpurp'] == 0) & (trip['dtaz'] == trip['pwtaz']),'dadtyp'] = 2

    # usual school
    trip.loc[(trip['opurp'] == 0) & (trip['otaz'] == trip['pstaz']),'oadtyp'] = 3
    trip.loc[(trip['dpurp'] == 0) & (trip['dtaz'] == trip['pstaz']),'dadtyp'] = 3

    # Change mode
    trip.loc[trip['opurp'] == 10,'oadtyp'] = 6
    trip.loc[trip['dpurp'] == 10,'dadtyp'] = 6

    ##############################
    # Set Skim Values
    ##############################

    trip['travcost'] = -1
    trip['travtime'] = -1
    trip['travdist'] = -1

    # Add pathtype by analyzing transit submode
    # FIXME: Note that this field doesn't exist for some trips, should really be analyzed by grouping on the trip day or tour
    trip['pathtype'] = 1
    for index, row in trip.iterrows():
        if len([i for i in list(row[['mode_1','mode_2','mode_3','mode_4']].values) if i in [23, 32, 41, 42, 52]]):

            # ferry or water taxi
            if 32 in row[['mode_1','mode_2','mode_3','mode_4']].values:
                trip.loc[index,'pathtype'] = 7
            # commuter rail
            elif 41 in row[['mode_1','mode_2','mode_3','mode_4']].values:
                trip.loc[index,'pathtype'] = 6
            # 'Urban rail (e.g., Link light rail, monorail)'
            elif [42 or 52] in row[['mode_1','mode_2','mode_3','mode_4']].values:
                trip.loc[index,'pathtype'] = 4
            else:
                trip.loc[index,'pathtype'] = 3

            # FIXME
            # Note that we also need to include KnR and TNC
        
    
    trip_cols = ['hhno','pno','tsvid','day','mode','opurp','dpurp','deptm',
            'otaz','opcl','dtaz','dpcl','oadtyp','dadtyp',
            'arrtm','trexpfac','travcost','travtime','travdist',
        'pathtype','mode_acc','mode_egr','dorp','endacttm','unique']    # only include access mode temporarily

    trip = trip[-trip['mode'].isnull()]
    trip = trip[-trip['opurp'].isnull()]
    trip = trip[-trip['dpurp'].isnull()]
    trip = trip[-trip['otaz'].isnull()]
    trip = trip[-trip['dtaz'].isnull()]

    # Write to file
    trip = trip[trip_cols]

    return trip

def build_tour_file(trip, person):
    """ Generate tours from Daysim-formatted trip records. """

    # Filter out trips that have the same origin and destination of home
    trip = trip[-((trip['opurp'] == trip['dpurp']) & (trip['opurp'] == 0))]
    trip = trip[(trip['dpurp'] >= 0)]
    trip = trip[(trip['opurp'] >= 0)]

    # For now, filter out trips that go from work to work
    # FIXME: we actually want to keep these work-related trips; change logic so we can keep them
    trip = trip[-((trip['opurp'] == trip['dpurp']) & (trip['opurp'] == 1))]

    trip['dpurp'] = trip['dpurp'].astype('int')

    tour_dict = {}
    bad_trips = []
    tour_id = 0

    #for personid in trip['personid'].value_counts().index.values:
    #for personid in ['171244111']:    # complicated trip sequence
    for personid in ['1910168961']:
        print('xxxxxxxxxxxxxxxxxxx')
        print(personid)
        person_df = trip.loc[trip['personid'] == personid]

        # Loop through each day
        for day in person_df['day'].unique():
            df = person_df.loc[person_df['day'] == day]
            print('ddddddddddd')
            print(day)
            # First o and last d of person's travel day should be home; if not, skip this trip set
            if (df.groupby('personid').first()['opurp'].values[0] != 0) or df.groupby('personid').last()['dpurp'].values[0] != 0:
                bad_trips += df['unique'].to_list()
                continue

            # identify home-based tours 
            home_tours_start = df[df['opurp'] == 0]
            home_tours_end = df[df['dpurp'] == 0]

            # skip person if they have a different number of tour starts/ends at home
            if len(home_tours_start) != len(home_tours_end):
                bad_trips += df['unique'].to_list()
                continue

            tour_id_value = 1
            tour_id_value_subtour = 0

            # Loop through each set of home-based tours
            for local_tour_index in range(len(home_tours_start)):

                #tour_id_value = tour_id_value + tour_id_value_subtour

                tour_dict[tour_id] = {}       

                # start row for this set
                start_row_id = home_tours_start.index[local_tour_index]
        #         print start_row
                end_row_id = home_tours_end.index[local_tour_index]
        #         print '-----'
                # iterate between the start row id and the end row id to build the tour

                # Select slice of trips that correspond to a trip set
                _df = df.loc[start_row_id:end_row_id]

                #################################
                # Skip this trip set under certain conditions
                #################################

                if len(_df) == 0:
                    bad_trips += _df['unique'].to_list()
                    continue
               
                # First row contains origin information for the primary tour
                tour_dict[tour_id]['tlvorig'] = _df.iloc[0]['deptm']                
                tour_dict[tour_id]['totaz'] = _df.iloc[0]['otaz']
                tour_dict[tour_id]['topcl'] = _df.iloc[0]['opcl']
                tour_dict[tour_id]['toadtyp'] = _df.iloc[0]['oadtyp']

                # Last row contains return information
                tour_dict[tour_id]['tarorig'] = _df.iloc[-1]['arrtm'] 

                # Household and person info
                tour_dict[tour_id]['hhno'] = _df.iloc[0]['hhno']
                tour_dict[tour_id]['pno'] = _df.iloc[0]['pno']
                tour_dict[tour_id]['day'] = day

                # calculate duration at location, as difference between arrival at a place and start of next trip
                _df['duration'] = _df.shift(-1).iloc[:-1]['deptm']-_df.iloc[:-1]['arrtm']

                # For sets with only 2 trips, the halves are simply the first and second trips
                if len(_df) == 2:
                    if _df.iloc[0]['dpurp'].isin([0,10]):   # ignore tours that have purposes to home or changemode
                        bad_trips += _df['unique'].to_list()
                        continue
                    tour_dict[tour_id]['pdpurp'] = _df.iloc[0]['dpurp']
                    tour_dict[tour_id]['tripsh1'] = 1
                    tour_dict[tour_id]['tripsh2'] = 1
                    tour_dict[tour_id]['tdadtyp'] =  _df.iloc[0]['dadtyp']
                    tour_dict[tour_id]['odadtyp'] =  _df.iloc[0]['oadtyp']
                    tour_dict[tour_id]['tpathtp'] = _df.iloc[0]['pathtype']
                    tour_dict[tour_id]['tdtaz'] = _df.iloc[0]['dtaz']
                    tour_dict[tour_id]['tdpcl'] = _df.iloc[0]['dpcl']
                    tour_dict[tour_id]['tlvdest'] = _df.iloc[-1]['deptm']
                    tour_dict[tour_id]['tarorig'] = _df.iloc[-1]['arrtm']
                    tour_dict[tour_id]['parent'] = 0    # No subtours for 2-leg trips
                    tour_dict[tour_id]['subtrs'] = 0    # No subtours for 2-leg trips

                    # Set tour half and tseg within half tour for trips
                    # for tour with only two records, there will always be two halves with tseg = 1 for both
                    trip.loc[trip['unique'] == _df.iloc[0]['unique'], 'half'] = 1
                    trip.loc[trip['unique'] == _df.iloc[-1]['unique'], 'half'] = 2
                    trip.loc[trip['unique'].isin(_df['unique']),'tseg'] = 1

                # For tour groups with > 2 trips, calculate primary purpose and halves
                else: 

                    # Could be dealing with work-based subtours

                    # subtours exist if dpurp==1 more than 2 times

                    #if (len(_df) >= 4) & (tour_dict[tour_id]['pdpurp'] == 1):
                    # FIXME: maybe calculat whether or not this is overall a work tour based on longer duration? 
                    if (len(_df) >= 4) & (len(_df[_df['dpurp'] == 1]) > 2):
                        subtour_index_start_values = _df[(_df['opurp'] == 1) & (-_df['dpurp'].isin([0,1]))].index.values  

                        subtours_df = pd.DataFrame()

                        # Loop through each potential subtour
                        # the following trips must eventually return to work for this to qualify as a subtour
                        

                        for subtour_start_value in subtour_index_start_values:
                            print(subtour_start_value)
                            # Potential subtour
                            for i in range(1,_df.index.max()-subtour_start_value):
                                next_row = _df.loc[subtour_start_value+i]
                                if next_row['dpurp'] == 1:
                                    subtour_df = _df.loc[subtour_start_value:subtour_start_value+i]

                                    subtour_id = tour_id + 1
                                    tour[subtour_id] = {}
                                    # Process this subtour
                                    # Create a new tour record for the subtour
                                    subtour_df['subtour_id'] = subtour_start_value
                                    subtours_df = subtours_df.append(subtour_df)
                                    ## delete this for now, keep it after all this stuff
                                    #break
                                    # add this as a tour
                                    tour_dict[subtour_id]['tour'] = subtour_id
                                    tour_dict[subtour_id]['hhno'] = subtour_df.iloc[0]['hhno']
                                    tour_dict[subtour_id]['pno'] = subtour_df.iloc[0]['pno']
                                    tour_dict[subtour_id]['day'] = day
                                    tour_dict[subtour_id]['tlvorig'] = subtour_df.iloc[0]['deptm']
                                    tour_dict[subtour_id]['tarorig'] = subtour_df.iloc[-1]['arrtm']
                                    
                                    if len(subtour_df) == 2:
                                        if subtour_df.iloc[0]['dpurp'].isin([0,10]):   # ignore tours that have purposes to home or changemode
                                            bad_trips += _df['unique'].to_list()
                                            continue
                                        tour_dict[subtour_id]['pdpurp'] = subtour_df.iloc[0]['dpurp']
                                        tour_dict[subtour_id]['tripsh1'] = 1
                                        tour_dict[subtour_id]['tripsh2'] = 1
                                        tour_dict[subtour_id]['tdadtyp'] =  subtour_df.iloc[0]['dadtyp']
                                        tour_dict[subtour_id]['odadtyp'] =  subtour_df.iloc[0]['oadtyp']
                                        tour_dict[subtour_id]['tpathtp'] = subtour_df.iloc[0]['pathtype']
                                        tour_dict[subtour_id]['tdtaz'] = subtour_df.iloc[0]['dtaz']
                                        tour_dict[subtour_id]['tdpcl'] = subtour_df.iloc[0]['dpcl']
                                        tour_dict[subtour_id]['tlvdest'] = subtour_df.iloc[-1]['deptm']
                                        tour_dict[subtour_id]['tardest'] = subtour_df.iloc[0]['arrtm']
                                        tour_dict[subtour_id]['parent'] = tour_id    # Parent is the main tour ID
                                        tour_dict[subtour_id]['subtrs'] = 0    # No subtours for subtours

                                        # Set tour half and tseg within half tour for trips
                                        # for tour with only two records, there will always be two halves with tseg = 1 for both
                                        trip.loc[trip['unique'] == subtour_df.iloc[0]['unique'], 'half'] = 1
                                        trip.loc[trip['unique'] == subtour_df.iloc[-1]['unique'], 'half'] = 2
                                        trip.loc[trip['unique'].isin(_df['unique']),'tseg'] = 1

                                    # If subtour length > 2, find the primary purpose
                                    else:
                                        subtour_df['duration'] = subtour_df.shift(-1).iloc[:-1]['deptm']-subtour_df.iloc[:-1]['arrtm']
                                        primary_subtour_purp_index = subtour_df[subtour_df['dpurp']!=10]['duration'].idxmax()

                                        tour_dict[subtour_id]['pdpurp'] = subtour_df.loc[primary_subtour_purp_index]['dpurp']
                
                                        # Get the data based on the primary destination trip
                                        # We know the tour destination parcel/TAZ field from that primary trip, as well as destination type
                                        tour_dict[subtour_id]['tdtaz'] = subtour_df.loc[primary_subtour_purp_index]['dtaz']
                                        tour_dict[subtour_id]['tdpcl'] = subtour_df.loc[primary_subtour_purp_index]['dpcl']
                                        tour_dict[subtour_id]['tdadtyp'] = subtour_df.loc[primary_subtour_purp_index]['dadtyp']
                
                                        # Pathtype is defined by a heirarchy, where highest number is chosen first
                                        # Ferry > Commuter rail > Light Rail > Bus > Auto Network
                                        # Note that tour pathtype is different from trip path type (?)
                                        tour_dict[subtour_id]['tpathtp'] = subtour_df.loc[subtour_df['mode'].idxmax()]['pathtype']

                                        # Calculate tour halves, etc
                                        tour_dict[subtour_id]['tripsh1'] = len(subtour_df.loc[0:primary_subtour_purp_index])
                                        tour_dict[subtour_id]['tripsh2'] = len(subtour_df.loc[primary_subtour_purp_index+1:])

                                        # Set tour halves on trip records
                                        trip.loc[trip['unique'].isin(subtour_df.loc[0:primary_subtour_purp_index].unique),'half'] = 1
                                        trip.loc[trip['unique'].isin(subtour_df.loc[primary_subtour_purp_index+1:].unique),'half'] = 2

                                        # set trip segment within half tours
                                        trip.loc[trip['unique'].isin(subtour_df.loc[0:primary_subtour_purp_index].unique),'tseg'] = range(1,len(subtour_df.loc[0:primary_subtour_purp_index])+1)
                                        trip.loc[trip['unique'].isin(subtour_df.loc[primary_subtour_purp_index+1:].unique),'tseg'] = range(1,len(subtour_df.loc[primary_subtour_purp_index+1:])+1)

                                        # Departure/arrival times
                                        tour_dict[subtour_id]['tlvdest'] = subtour_df.loc[primary_subtour_purp_index]['deptm']
                                        tour_dict[subtour_id]['tardest'] = subtour_df.loc[primary_subtour_purp_index]['arrtm']
                                        
                                        # Identify subtour mode
                                        # Primary mode is the first one from a heirarchy list found in the tour
                                        mode_list = subtour_df['mode'].value_counts().index.astype('int').values
                                        mode_heirarchy = [6,8,5,4,3,2,1,10]
                                        for mode in mode_heirarchy:
                                            if mode in mode_list:
                                                # If transit, check whether access mode is walk to transit or drive to transit
                                                if mode==6:

                                                    # Try to use the access mode field values to get access mode
                                                    if len(subtour_df[-subtour_df['mode_acc'].isnull()]) > 0:
                                                        if  len([i for i in subtour_df['mode_acc'].values if i in [1,2]]):
                                                            tour_dict[subtour_id]['tmodetp'] = 6    # walk (or bike) to transit
                                                            print('mode_acc walk')
                                                        else:
                                                            print('mode_acc drive')
                                                            tour_dict[subtour_id]['tmodetp'] = 7    # park and ride
                                                        break
                                                    else:
                                                        # otherwise, use a simpler check; if auto is used on any of the other trips, assume drive to transit, else assign walk to transit
                                                        if len([i for i in mode_list if i in [3,4,5]]) > 0:
                                                            tour_dict[subtour_id]['tmodetp'] = 7   # park and ride
                                                        else:
                                                            tour_dict[subtour_id]['tmodetp'] = 6   # walk (or bike) to transit
                                                        break 

                                                # For non-transit modes, add first mode from the heirarchical list
                                                tour_dict[subtour_id]['tmodetp'] = mode
                                                break


                                    # Done with this subtour 
                                    subtour_id += 1
                                    break
                                else:
                                    break
                                    
                        # The main tour destination arrival will be the trip before subtours
                        # the main tour destination departure will be the trip after subtours
                        main_tour_start_index = subtours_df.index[0]-1   # trip when they arrive to work
                        main_tour_end_index = subtours_df.index[-1]+1    # trip when leave work

                        # If there were subtours, this is a work tour
                        tour_dict[tour_id]['pdpurp'] = 1
                        tour_dict[tour_id]['tdtaz'] = _df.loc[main_tour_start_index]['dtaz']
                        tour_dict[tour_id]['tdpcl'] = _df.loc[main_tour_start_index]['dpcl']
                        tour_dict[tour_id]['tdadtyp'] = _df.loc[main_tour_start_index]['dadtyp']

                        # Pathtype is defined by a heirarchy, where highest number is chosen first
                        # Ferry > Commuter rail > Light Rail > Bus > Auto Network
                        # Note that tour pathtype is different from trip path type (?)
                        pd.concat([df.loc[start_row_id:main_tour_start_index], df.loc[main_tour_end_index:end_row_id]]).loc[df['mode'].idxmax()]['pathtype']
                        subtours_excluded_df = pd.concat([df.loc[start_row_id:main_tour_start_index], df.loc[main_tour_end_index:end_row_id]])
                        tour_dict[tour_id]['tpathtp'] = subtours_excluded_df.loc[subtours_excluded_df['mode'].idxmax()]['pathtype']

                        # Calculate tour halves, etc
                        tour_dict[tour_id]['tripsh1'] = len(_df.loc[0:main_tour_start_index])
                        tour_dict[tour_id]['tripsh2'] = len(_df.loc[main_tour_end_index:])

                        # Set tour halves on trip records
                        trip.loc[trip['unique'].isin(_df.loc[0:main_tour_start_index].unique),'half'] = 1
                        trip.loc[trip['unique'].isin(_df.loc[main_tour_end_index:].unique),'half'] = 2

                        # set trip segment within half tours
                        trip.loc[trip['unique'].isin(_df.loc[0:main_tour_start_index].unique),'tseg'] = range(1,len(_df.loc[0:main_tour_start_index])+1)
                        trip.loc[trip['unique'].isin(_df.loc[main_tour_end_index:].unique),'tseg'] = range(1,len(_df.loc[main_tour_end_index:])+1)

                        # Departure/arrival times
                        tour_dict[tour_id]['tlvdest'] = _df.loc[main_tour_end_index]['deptm']
                        tour_dict[tour_id]['tardest'] = _df.loc[main_tour_start_index]['arrtm']

                        # Number of subtours 
                        tour_dict[tour_id]['subtrs'] = len(subtour_index_start_values)
                        tour_dict[tour_id]['parent'] = 0

                        # Mode
                        mode_list = subtours_excluded_df['mode'].value_counts().index.astype('int').values
                        mode_heirarchy = [6,8,5,4,3,2,1,10]
                        for mode in mode_heirarchy:
                            if mode in mode_list:
                                # If transit, check whether access mode is walk to transit or drive to transit
                                if mode==6:

                                    # Try to use the access mode field values to get access mode
                                    if len(subtours_excluded_df[-subtours_excluded_df['mode_acc'].isnull()]) > 0:
                                        if  len([i for i in subtours_excluded_df['mode_acc'].values if i in [1,2]]):
                                            tour_dict[tour_id]['tmodetp'] = 6    # walk (or bike) to transit
                                            print('mode_acc walk')
                                        else:
                                            print('mode_acc drive')
                                            tour_dict[tour_id]['tmodetp'] = 7    # park and ride
                                        break
                                    else:
                                        # otherwise, use a simpler check; if auto is used on any of the other trips, assume drive to transit, else assign walk to transit
                                        if len([i for i in mode_list if i in [3,4,5]]) > 0:
                                            tour_dict[tour_id]['tmodetp'] = 7   # park and ride
                                        else:
                                            tour_dict[tour_id]['tmodetp'] = 6   # walk (or bike) to transit
                                        break 

                                # For non-transit modes, add first mode from the heirarchical list
                                tour_dict[tour_id]['tmodetp'] = mode
                                break
                                                # add tour ID to the trip records
                        trip.loc[trip['unique'].isin(_df['unique'].values),'tour'] = local_tour_index+1
                        tour_dict[tour_id]['tour'] = local_tour_index+1
                    else:
                        # No subtours
                        tour_dict[tour_id]['subtrs'] = 0

                        # Identify the primary purpose
                        primary_purp_index = subtour_df[-subtour_df['dpurp'].isin([0,10])]['duration'].idxmax()

                        tour_dict[tour_id]['pdpurp'] = subtour_df.loc[primary_purp_index]['dpurp']

                        tour_dict[tour_id]['tlvdest'] = _df.loc[primary_purp_index]['deptm']
                   
                        tour_dict[tour_id]['tripsh1'] = len(_df.loc[0:primary_purp_index])
                        tour_dict[tour_id]['tripsh2'] = len(_df.loc[primary_purp_index+1:])

                        # Set tour halves on trip records
                        trip.loc[trip['unique'].isin(_df.loc[0:primary_purp_index].unique),'half'] = 1
                        trip.loc[trip['unique'].isin(_df.loc[primary_purp_index+1:].unique),'half'] = 2

                        # set trip segment within half tours
                        trip.loc[trip['unique'].isin(_df.loc[0:primary_purp_index].unique),'tseg'] = range(1,len(_df.loc[0:primary_purp_index])+1)
                        trip.loc[trip['unique'].isin(_df.loc[primary_purp_index+1:].unique),'tseg'] = range(1,len(_df.loc[primary_purp_index+1:])+1)

                        # Extract main mode type

                        # Heirarchy order for tour mode, per DaySim docs: https://www.psrc.org/sites/default/files/2015psrc-modechoiceautomodels.pdf
                        # Drive to Transit > Walk to Transit > School Bus > HOV3+ > HOV2 > SOV > Bike > Walk > Other

                        # Get a list of transit modes and identify primary mode
                        # Primary mode is the first one from a heirarchy list found in the tour
                        mode_list = _df['mode'].value_counts().index.astype('int').values
                        mode_heirarchy = [6,8,5,4,3,2,1,10]
                        for mode in mode_heirarchy:
                            if mode in mode_list:
                                # If transit, check whether access mode is walk to transit or drive to transit
                                if mode==6:

                                    # Try to use the access mode field values to get access mode
                                    if len(_df[-_df['mode_acc'].isnull()]) > 0:
                                        if  len([i for i in _df['mode_acc'].values if i in [1,2]]):
                                            tour_dict[tour_id]['tmodetp'] = 6    # walk (or bike) to transit
                                            print('mode_acc walk')
                                        else:
                                            print('mode_acc drive')
                                            tour_dict[tour_id]['tmodetp'] = 7    # park and ride
                                        break
                                    else:
                                        # otherwise, use a simpler check; if auto is used on any of the other trips, assume drive to transit, else assign walk to transit
                                        if len([i for i in mode_list if i in [3,4,5]]) > 0:
                                            tour_dict[tour_id]['tmodetp'] = 7   # park and ride
                                        else:
                                            tour_dict[tour_id]['tmodetp'] = 6   # walk (or bike) to transit
                                        break 

                                # For non-transit modes, add first mode from the heirarchical list
                                tour_dict[tour_id]['tmodetp'] = mode
                                break

                

                        # add tour ID to the trip records
                        trip.loc[trip['unique'].isin(_df['unique'].values),'tour'] = local_tour_index+1
                        tour_dict[tour_id]['tour'] = local_tour_index+1
                
            
                # Increment the tour ID
                if subtour_id == 0:
                    tour_id += 1
                else:
                    tour_id = subtour_id + tour_id

    tour = pd.DataFrame.from_dict(tour_dict, orient='index')


    for col in ['jtindex', 'phtindx1', 'phtindx2', 'fhtindx1', 'fhtindx2']:
        tour[col] = 0

    for col in ['tautotime', 'tautocost', 'tautodist']:
        tour[col] = -1

    # Assign weight toexpfac as hhexpfac (getting it from psexpfac, which is the same as hhexpfac)
    tour['personid'] = tour['hhno'].astype('int').astype('str') + tour['pno'].astype('int').astype('str')
    tour = tour.merge(person[['personid','psexpfac']], on='personid', how='left')
    tour.rename(columns={'psexpfac':'toexpfac'}, inplace=True)

    # remove the trips that weren't included in the tour file
    trip = trip[-trip['unique'].isin(bad_trips)]
    pd.DataFrame(bad_trips).T.to_csv(os.path.join(output_dir,'bad_trips.csv'))

    # Export columns in proper order
    tour_cols = ['hhno','pno','day','tour','jtindex','parent','subtrs','pdpurp','tlvorig',
                 'tardest','tlvdest','tarorig','toadtyp','tdadtyp','topcl','totaz','tdpcl',
                 'tdtaz','tmodetp','tpathtp','tautotime','tautocost','tautodist','tripsh1',
                 'tripsh2','phtindx1','phtindx2','fhtindx1','fhtindx2','toexpfac','personid']
    tour = tour[tour_cols]

    trip_cols = ['hhno','pno','day','tour','half','tseg','tsvid','opurp','dpurp','oadtyp','dadtyp',
                 'opcl','dpcl','otaz','dtaz','mode','pathtype','dorp','deptm','arrtm','endacttm','travtime',
                 'travcost','travdist','trexpfac','personid']
    trip = trip[trip_cols]

    return tour, trip

def process_household_day(tour, hh):

    household_day = tour.groupby(['hhno','day']).count().reset_index()[['hhno','day']]
    
    # add day of week lookup
    household_day['dow'] = household_day['day']

    # Set number of joint tours to 0 for this version of Daysim
    for col in ['jttours','phtours','fhtours']:
        household_day[col] = 0

    # Add expansion factor
    household_day = household_day.merge(hh[['hhno','hhexpfac']], on='hhno', how='left')
    household_day.rename(columns={'hhexpfac': 'hdexpfac'}, inplace=True)

    return household_day

def process_person_day(tour, person, trip, hh):

    # Get the usual workplace column from person records
    tour = tour.merge(person[['hhno','pno','pwpcl']], on=['hhno','pno'], how='left')
    
    pday = pd.DataFrame()
    for person_rec in person['personid'].unique():

        # get this person's tours
        _tour = tour[tour['personid'] == person_rec]
    
        # Loop through each day
        for day in _tour['day'].unique():
    
            day_tour = _tour[_tour['day'] == day]
        
            prec_id = str(person_rec) + str(day)
            pday.loc[prec_id,'hhno'] = day_tour['hhno'].iloc[0]
            pday.loc[prec_id,'pno'] = day_tour['pno'].iloc[0]
            pday.loc[prec_id,'day'] = day
        
            # Begin/End at home-
            # need to get from first and last trips of tour days 
            pday.loc[prec_id,'beghom'] = 0
            pday.loc[prec_id,'endhom'] = 0
            _trip = trip[(trip['personid'] == person_rec) & (trip['day'] == day)]
            if _trip.iloc[0]['opurp'] == 0:
                pday.loc[prec_id,'beghom'] = 1
            if _trip.iloc[-1]['dpurp'] == 0:
                pday.loc[prec_id,'endhom'] = 1
        
            # Number of tours by purpose
            purp_dict = {
                'wk': 1,    
                'sc': 2,
                'es': 3,
                'pb': 4,
                'sh': 5,
                'ml': 6,
                'so': 7,
                're': 8,
                'me': 9
            }
            for purp_name, purp_val in purp_dict.items():
                # Number of tours
                pday.loc[prec_id,purp_name+'tours'] = len(day_tour[day_tour['pdpurp'] == purp_val])
        
                # Number of stops
                day_tour_purp = day_tour[day_tour['pdpurp'] == purp_val]
                if len(day_tour_purp) > 0:
                    nstops = day_tour_purp[['tripsh1','tripsh2']].sum().sum() - 2
                else:
                    nstops = 0
                pday.loc[prec_id,purp_name+'stops'] = nstops
        
            # Home based tours
            pday.loc[prec_id,'hbtours'] = len(day_tour)

            # Work-based tours (subtours)
            pday.loc[prec_id,'wbtours'] = day_tour['subtrs'].sum()

            # Work trips to usual workplace
            pday.loc[prec_id,'uwtours'] = len(day_tour[day_tour['tdpcl'] == day_tour['pwpcl']])

            # Fill in these fields for now:
            for col in ['wkathome']:
                pday[col] = -1

    # Add expansion factor
    pday = pday.merge(hh[['hhno','hhexpfac']], on='hhno', how='left')
    pday.rename(columns={'hhexpfac': 'pdexpfac'}, inplace=True)

    return pday

# Get subtours

def main():
    
        # person day and household day records
    trip = pd.read_csv(os.path.join(output_dir,'tripP17.csv'))
    tour = pd.read_csv(os.path.join(output_dir,'tourP17.csv'))
    #hh = pd.read_csv(os.path.join(output_dir,'hrecP17.csv'))
    person = pd.read_csv(os.path.join(output_dir,'precP17.csv'))
    # household day

    #person = process_person_file(person_file_dir)
    #hh = process_household_file(hh_file_dir, person)
    #trip = process_trip_file(trip_file_dir, person)
    
    trip['personid'] = trip['hhno'].astype('int').astype('str') + trip['pno'].astype('int').astype('str')
    person['personid'] = person['hhno'].astype('int').astype('str') + person['pno'].astype('int').astype('str')

    # Make sure trips are properly ordered, where deptm is increasing for each person's travel day
    trip['personid_int'] = trip['personid'].astype('int')
    trip = trip.sort_values(['personid_int','day','deptm'])
    trip = trip.reset_index()

    # Create tour file and update the trip file with tour info
    tour, trip = build_tour_file(trip, person)


    household_day = process_household_day(tour, hh)

    # person day
    person_day = process_person_day(tour, person, trip, hh)

    ## FIXE: REMOVE
    # temp access to created files

    #person_day = pd.read_csv(os.path.join(output_dir,'pday17.csv'))
    #household_day = pd.read_csv(os.path.join(output_dir,'hhday17.csv'))

    trip.drop('personid', axis=1, inplace=True)
    tour.drop('personid', axis=1, inplace=True)
    person.drop('personid', axis=1, inplace=True)
    trip[['travdist','travcost','travtime']] = "-1.00"

    tour.loc[tour['tmodetp'] == -1, 'tmodetp'] = 10

    for df_name, df in {'prec': person, 'trip': trip, 'tour': tour, 'hrec': hh,
                        'hday': household_day, 'pday': person_day}.items():
        print(df_name)
        #print(df)
        expcol = [col for col in df.columns if 'expfac' in col][0]
        col_list = df.columns.tolist()
        col_list.remove(expcol)
        if df_name == 'trip':
            for col in ['travcost','travdist','travtime']:
                col_list.remove(col)
        df[expcol] = df[expcol].astype('str').apply(lambda row: row.split('.')[0] + "." + row.split('.')[-1][0:2])
        df[col_list] = df[col_list].fillna(-1).astype(dtype='int', errors='ignore')
        df.to_csv(os.path.join(output_dir,df_name+'P14.dat'), index=False, sep=' ')
        df.to_csv(os.path.join(output_dir,df_name+'P17.csv'), index=False, sep=',')

if __name__ == '__main__':
    main()