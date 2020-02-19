import os, sys
import pandas as pd
import geopandas as gpd
from scipy.spatial import cKDTree
from pysal.lib.weights.distance import get_points_array
from shapely.geometry import LineString
from pyproj import Proj, transform
import pyproj
import numpy as np
from operator import itemgetter

# Set current working directory to script location
working_dir = r'C:\Users\bnichols\travel-studies\2017\daysim_conversions'
os.chdir(working_dir)

# Geographic files
parcel_file_dir = r'R:\e2projects_two\SoundCast\Inputs\lodes\alpha_lodes\2014\landuse\parcels_urbansim.txt'
taz_dir = r'W:\geodata\forecast\taz2010.shp'
# FIXME:
# ADD Census block, county, puma10, tract, bg, rgcnum, uvnum,

#person_file_dir = r'C:\Users\bnichols\travel-studies\2017\daysim_conversions\person17.csv'
person_file_dir = r'\\aws-prod-file01\datateam\Projects\Surveys\HHTravel\Survey2019\Data\Dataset_24_January_2020\PSRC_2019_HTS_Deliverable_012420\PSRC_2019_HTS_Deliverable_012420\Weighted_Dataset_012420\2_person.csv'
trip_file_dir = r'\\aws-prod-file01\datateam\Projects\Surveys\HHTravel\Survey2019\Data\Dataset_24_January_2020\PSRC_2019_HTS_Deliverable_012420\PSRC_2019_HTS_Deliverable_012420\Weighted_Dataset_012420\5_trip.csv'
hh_file_dir = r'\\aws-prod-file01\datateam\Projects\Surveys\HHTravel\Survey2019\Data\Dataset_24_January_2020\PSRC_2019_HTS_Deliverable_012420\PSRC_2019_HTS_Deliverable_012420\Weighted_Dataset_012420\1_household.csv'

# daysim input paths
hh_daysim_dir = r'R:\e2projects_two\SoundCastDocuments\2017Estimation\person17.csv'
person_daysim_dir = r'R:\e2projects_two\SoundCastDocuments\2017Estimation\person17.csv'
trip_daysim_dir = r'R:\e2projects_two\SoundCastDocuments\2017Estimation\trip17.csv'


# Original format output
orig_format_output_dir = r'\\aws-prod-file01\datateam\Projects\Surveys\HHTravel\Survey2019\Data\Dataset_24_January_2020\PSRC_2019_HTS_Deliverable_012420\PSRC_2019_HTS_Deliverable_012420\Weighted_Dataset_012420\geocoded'
daysim_format_output_dir = r'R:\e2projects_two\SoundCastDocuments\2017Estimation\geocoded'

# Spatial join trip lat/lng values to shapefile of parcels
lat_lng_crs = 'epsg:4326'

def nearest_neighbor(df_parcel_coord, df_trip_coord):
    '''  Find 1st nearest parcel location for trip location
    df_parcel: x and y columns of parcels
    df_trip: x and y columns of trip records

    Returns: tuple of distance between nearest points and index of df_parcel for nearest parcel

    '''
   
    kdt_parcels = cKDTree(df_parcel_coord)
    return kdt_parcels.query(df_trip_coord, k=1)

def locate_parcel(_parcel_df, df, xcoord_col, ycoord_col, parcel_filter=None, df_filter=None):
    """ Find nearest parcel for a trip end, return parcelid and distance (assuming consistent xy projection)
        Inputs:
        - parcel_df: full list of parcels with x and y cols (xcoord_p, ycoordp)
        - trip: record to be located
        - trip_filter: filter on which trips to consider
        - parcel_filter: filter for candidate parcels
        - trip_end_type: either 'o' or 'd' to designate origin or destination 
    """

    if parcel_filter is not None:
        _parcel_df = _parcel_df[parcel_filter].reset_index()
    if df_filter is not None:
        df = df[df_filter].reset_index()

    # Calculate distance to nearest neighbor parcel
    _dist, _ix, = nearest_neighbor(_parcel_df[['xcoord_p','ycoord_p']],
                                 df[[xcoord_col,ycoord_col]])

    return _dist, _ix

def locate_person_parcels(person, parcel_df, df_taz):
    """ Locate parcel ID for school, workplace, home location from person records. """

    person_results  = person.copy() # Make local copy for storing resulting joins

    # Find parcels for person fields
    filter_dict_list = [{
        'var_name': 'work',
        'parcel_filter': parcel_df['emptot_p'] > 0,
        'person_filter': -person['work_lng'].isnull()
        },
        {
        # Previous work location
        'var_name': 'prev_work',
        'parcel_filter': parcel_df['emptot_p'] > 0,
        'person_filter': -person['prev_work_lng'].isnull()
        },
        {
        # Student
        # FIXME: consider breaking out students by school type; for now assuming they are where their GPS coords indicate
        'var_name': 'school_loc',
        'parcel_filter': (parcel_df[['stugrd_p','stuhgh_p','stuuni_p']].sum(axis=1) > 0),
        'person_filter': -person['school_loc_lat'].isnull()
        },
        ]

    
    # Find nearest school and workplace
    for i in range(len(filter_dict_list)):

        varname = filter_dict_list[i]['var_name']
        person_filter = filter_dict_list[i]['person_filter']
        parcel_filter = filter_dict_list[i]['parcel_filter']

        # Convert GPS Coordinates to State Plane
        gdf = gpd.GeoDataFrame(person[person_filter], geometry=gpd.points_from_xy(person[person_filter][varname+'_lng'], person[person_filter][varname+'_lat']))
        gdf.crs = {'init' :lat_lng_crs}
        gdf[varname+'_lng_gps'] = gdf[varname+'_lng']
        gdf[varname+'_lat_gps'] = gdf[varname+'_lat']
        gdf = gdf.to_crs({'init': 'epsg:2285'})    # convert to state plane WA 
        # Exclude any location outside the region
        # Spatial join between region TAZ file and person file
        gdf = gpd.sjoin(gdf, df_taz)
        xy_field = get_points_array(gdf.geometry)
        gdf[varname+'_lng_gps'] = gdf[varname+'_lng']
        gdf[varname+'_lat_gps'] = gdf[varname+'_lat']
        gdf[varname+'_lng_fips_4601'] = xy_field[:,0]
        gdf[varname+'_lat_fips_4601'] = xy_field[:,1]

        # Return: (_dist) the distance to the closest parcel that meets given critera,
        # (_ix) list of the indices of parcel IDs from (_df), which is the filtered set of candidate parcels
        _dist, _ix = locate_parcel(parcel_df[parcel_filter], df=gdf, xcoord_col=varname+'_lng_fips_4601', ycoord_col=varname+'_lat_fips_4601')

        # Assign values to person df, extracting from the filtered set of parcels (_df)
        gdf[varname+'_parcel'] = parcel_df[parcel_filter].iloc[_ix].parcelid.values
        gdf[varname+'_parcel_distance'] = _dist
        gdf[varname+'_taz'] = gdf['TAZ']

        # Join the gdf dataframe to the person df
        person_results = person_results.merge(gdf[['personid',varname+'_taz',varname+'_parcel',varname+'_parcel_distance',varname+'_lat_fips_4601',
                                   varname+'_lng_fips_4601',varname+'_lat_gps']], how='left')

    # Export 2 different versions, one for Daysim, one an updated version of the original dataset
    person_daysim = person_results.copy()

    # Rename variables for daysim
    person_daysim['pwpcl'] = person_daysim['work_parcel']
    person_daysim['pwtaz'] = person_daysim['work_taz']
    person_daysim['pspcl'] = person_daysim['school_loc_parcel']
    person_daysim['pstaz'] = person_daysim['school_loc_taz']

    for col in ['pspcl','pstaz','pwpcl','pwtaz']:
        person_daysim[col] = person_daysim[col].fillna(-1).astype('int')

    # Add additional variables for writing file
    daysim_cols = ['hhno','pno', 'pptyp', 'pagey', 'pgend', 'pwtyp', 'pwpcl', 'pwtaz', 'pwautime',
                    'pwaudist', 'pstyp', 'pspcl', 'pstaz', 'psautime', 'psaudist', 'puwmode', 'puwarrp', 
                    'puwdepp', 'ptpass', 'ppaidprk', 'pdiary', 'pproxy', 'psexpfac']

    # Add empty columns to fill in later with skims
    for col in daysim_cols:
        if col not in person_daysim.columns:
            person[col] = -1
        
    person_daysim = person_daysim[daysim_cols]

    return person_results, person_daysim

def locate_hh_parcels(hh, parcel_df, df_taz):

    hh_results = hh.copy()

    filter_dict_list = [{
    
         # Current Home Location
        'var_name': 'final_home',
        'parcel_filter': (parcel_df['hh_p'] > 0),
        'hh_filter': (-hh['final_home_lat'].isnull())
        },
        {
        # Previous Home Location
        'var_name': 'prev_home',
        'parcel_filter': (parcel_df['hh_p'] > 0),
        'hh_filter': (-hh['prev_home_lat'].isnull())
        }
        ]    

    # Find nearest school and workplace
    for i in range(len(filter_dict_list)):

        varname = filter_dict_list[i]['var_name']
        parcel_filter = filter_dict_list[i]['parcel_filter']
        hh_filter = filter_dict_list[i]['hh_filter']

        # Convert GPS Coordinates to State Plane
        gdf = gpd.GeoDataFrame(hh[hh_filter], geometry=gpd.points_from_xy(hh[hh_filter][varname+'_lng'], hh[hh_filter][varname+'_lat']))
        gdf.crs = {'init' :lat_lng_crs}
        gdf[varname+'_lng_gps'] = gdf[varname+'_lng']
        gdf[varname+'_lat_gps'] = gdf[varname+'_lat']
        gdf = gdf.to_crs({'init': 'epsg:2285'})    # convert to state plane WA 
        # Exclude any location outside the region
        # Spatial join between region TAZ file and person file
        gdf = gpd.sjoin(gdf, df_taz)
        xy_field = get_points_array(gdf.geometry)
        gdf[varname+'_lng_gps'] = gdf[varname+'_lng']
        gdf[varname+'_lat_gps'] = gdf[varname+'_lat']
        gdf[varname+'_lng_fips_4601'] = xy_field[:,0]
        gdf[varname+'_lat_fips_4601'] = xy_field[:,1]

        # Return: (_dist) the distance to the closest parcel that meets given critera,
        # (_ix) list of the indices of parcel IDs from (_df), which is the filtered set of candidate parcels
        _dist, _ix = locate_parcel(parcel_df[parcel_filter], df=gdf, xcoord_col=varname+'_lng_fips_4601', ycoord_col=varname+'_lat_fips_4601')

        # Assign values to person df, extracting from the filtered set of parcels (_df)
        gdf[varname+'_parcel'] = parcel_df[parcel_filter].iloc[_ix].parcelid.values
        gdf[varname+'_parcel_distance'] = _dist
        gdf[varname+'_taz'] = gdf['TAZ'].astype('int')

        # For households that are not reasonably near a parcel with households, 
        # add them to the nearset unfiltered parcel and flag
        # Typically occurs with households living on military bases
        hh_max_dist = 2000
        gdf_far = gdf[gdf[varname+'_parcel_distance'] > hh_max_dist]
        _dist, _ix = locate_parcel(parcel_df, df=gdf_far, xcoord_col=varname+'_lng_fips_4601', ycoord_col=varname+'_lat_fips_4601')
        gdf_far[varname+'_parcel'] = parcel_df.iloc[_ix].parcelid.values
        gdf_far[varname+'_parcel_distance'] = _dist
        gdf_far[varname+'_taz'] = gdf_far['TAZ'].astype('int')



        # Add this new distance to the original gdf
        gdf.loc[gdf_far.index,varname+'_parcel_original'] = gdf.loc[gdf_far.index,varname+'_parcel']
        gdf.loc[gdf_far.index,varname+'_parcel_distance_original'] = gdf.loc[gdf_far.index,varname+'_parcel_distance']
        gdf.loc[gdf_far.index,varname+'_parcel'] = gdf_far[varname+'_parcel']
        gdf.loc[gdf_far.index,varname+'_parcel_distance'] = gdf_far[varname+'_parcel_distance']
        gdf['distance_flag'] = 0
        gdf.loc[gdf_far.index,varname+'distance_flag'] = 1

        # Join the gdf dataframe to the person df
        hh_results = hh_results.merge(gdf[['hhid',varname+'_taz',varname+'_parcel',varname+'_parcel_distance',varname+'_parcel_distance_original',
                                           varname+'_lat_fips_4601',varname+'_parcel_original',
                                   varname+'_lng_fips_4601',varname+'_lat_gps']], on='hhid',how='left')

    
    return hh_results

def locate_trip_parcels(trip, parcel_df, df_taz):
    """ Attach parcel ID to trip origins and destinations. """

    opurp_field = 'o_purpose'
    dpurp_field = 'd_purpose'
    
    # Filter out people who have missing origin/destination purposes

    for purp_field in [opurp_field,dpurp_field]:
        trip = trip[-trip[purp_field].isnull()]
        trip = trip[trip[purp_field] >= 0]

    trip_results = trip.copy()

    for trip_end in ['origin', 'dest']:

        lng_field = trip_end+'_lng'
        lat_field = trip_end+'_lat'

        # filter out some odd results with lng > 0 and lat < 0
        trip = trip[trip[lat_field] > 0]
        trip = trip[trip[lng_field] < 0]

        gdf = gpd.GeoDataFrame(
            trip, geometry=gpd.points_from_xy(trip[lng_field], trip[lat_field]))
        gdf.crs = {'init' :lat_lng_crs}
        gdf = gdf.to_crs({'init': 'epsg:2285'})    # convert to state plane WA 
        # Exclude any trips that start or end outside of the region
        # Spatial join between region TAZ file and trip file
        gdf = gpd.sjoin(gdf, df_taz)
        xy_field = get_points_array(gdf.geometry)
        gdf[trip_end+'_lng_gps'] = gdf[trip_end+'_lng']
        gdf[trip_end+'_lat_gps'] = gdf[trip_end+'_lat']
        gdf[trip_end+'_lng_fips_4601'] = xy_field[:,0]
        gdf[trip_end+'_lat_fips_4601'] = xy_field[:,1]
        gdf[trip_end+'_taz'] = gdf['TAZ']
        trip_results = trip_results.merge(gdf[['recid',trip_end+'_lng_gps',trip_end+'_lat_gps',trip_end+'_lng_fips_4601',trip_end+'_lat_fips_4601',trip_end+'_taz']], on='recid')

    # Dictionary of filters to be applied
    # Filters are by trip purpose and define which parcels should be available for selection as nearest
    filter_dict_list = [
        # Home trips (purp == 1) should be nearest parcel with household population > 0
        {'parcel_filter': parcel_df['hh_p'] > 0,
            'o_trip_filter': trip_results[opurp_field]==1,
            'd_trip_filter': trip_results[dpurp_field]==1},

        # Work trips (purp.isin([10,11,14]), parcel must have jobs (emptot>0)
        {'parcel_filter': parcel_df['emptot_p'] > 0,
            'o_trip_filter': trip_results[opurp_field].isin([10,11,14]),
            'd_trip_filter': trip_results[dpurp_field].isin([10,11,14])},

        # School (purp==6); parcel must have students (either grade, high, or uni students)
        {'parcel_filter': ((parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0) | (parcel_df['stuuni_p'] > 0)),
            'o_trip_filter': trip_results[opurp_field]==6,
            'd_trip_filter': trip_results[dpurp_field]==6},

        # Escort (purp==9); parcel must have jobs or grade/high school students
        {'parcel_filter': ((parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0) | (parcel_df['emptot_p'] > 0)),
            'o_trip_filter': trip_results[opurp_field]==9,
            'd_trip_filter': trip_results[dpurp_field]==9},

        # Personal Business/other apporintments, errands (purp.isin([33,61]); parcel must have either retail or service jobs
        {'parcel_filter': ((parcel_df['empret_p'] > 0) | (parcel_df['empsvc_p'] > 0)),
            'o_trip_filter': trip_results[opurp_field].isin([33,61]),
            'd_trip_filter': trip_results[dpurp_field].isin([33,61])},

        # Shopping (purp.isin([30,32])); parcel must have retail jobs
        {'parcel_filter': parcel_df['empret_p'] > 0,
            'o_trip_filter': trip_results[opurp_field].isin([30,32]),
            'd_trip_filter': trip_results[dpurp_field].isin([30,32])},

        # Meal (purp==50); parcel must have food service jobs
        {'parcel_filter': parcel_df['empfoo_p'] > 0,
            'o_trip_filter': trip_results[opurp_field]==50,
            'd_trip_filter': trip_results[dpurp_field]==50},

        # Social (purp.isin([52,62]); parcel must have households or employment
        {'parcel_filter': (parcel_df['hh_p'] > 0),
            'o_trip_filter': trip_results[opurp_field].isin([52,62]),
            'd_trip_filter': trip_results[dpurp_field].isin([52,62])},

        # Recreational, exercise, volunteed/community event, family activity, other (purp.isin([53,51,54]); any parcel allowed
        ####
        {'parcel_filter': -parcel_df.isnull(),   # no parcel filter
            'o_trip_filter': trip_results[opurp_field].isin([53,51,54,56,97]),
            'd_trip_filter': trip_results[dpurp_field].isin([53,51,54,56,97])},

        # Medical (purp==34); parcel must have medical employment
        {'parcel_filter': parcel_df['empmed_p'] > 0,
            'o_trip_filter': trip_results[opurp_field]==34,
            'd_trip_filter': trip_results[dpurp_field]==34},

        # For change mode (purp==60, no parcel filter)
        {'parcel_filter': -parcel_df.isnull(),    # no parcel filter
            'o_trip_filter': trip_results[opurp_field]==60,
            'd_trip_filter': trip_results[dpurp_field]==60},
        ]

    final_df = trip_results.copy()
    # Loop through each trip end type (origin or destination) and each trip purpose
    for trip_end_type in ['origin','dest']:

        df_temp = pd.DataFrame()
        for i in range(len(filter_dict_list)):

            trip_filter = filter_dict_list[i][trip_end_type[0]+'_trip_filter']
            parcel_filter = filter_dict_list[i]['parcel_filter']

            _df = trip_results[trip_filter]

            _dist, _ix = locate_parcel(parcel_df[parcel_filter], df=_df, xcoord_col=trip_end_type+'_lng_fips_4601', ycoord_col=trip_end_type+'_lat_fips_4601')

            _df[trip_end_type[0]+'pcl'] = parcel_df[parcel_filter].iloc[_ix].parcelid.values
            _df[trip_end_type[0]+'pcl_distance'] = _dist
            _df[trip_end_type[0]+'taz'] = trip_results[trip_end_type+'_taz']

            df_temp = df_temp.append(_df)
        # Join df_temp to final field for each trip type
        final_df = final_df.merge(df_temp[['recid',trip_end_type[0]+'pcl',trip_end_type[0]+'pcl_distance',trip_end_type[0]+'taz']], on='recid')

    return final_df

def main():

    # Load parcel data
    parcel_df = pd.read_csv(parcel_file_dir, delim_whitespace=True)
    
    # Load TAZ shapefile
    df_taz = gpd.read_file(taz_dir)
    df_taz.crs = {'init' :' epsg:2285'}

    ##################################################
    # Process person records
    ##################################################

    # Load original person file with GPS data attached 
    person_original_dir = person_file_dir
    person_original = pd.read_csv(person_file_dir, encoding='latin1')  
    
    # Join original person records to daysim-formatted records to get xy coordinates
    person_daysim = pd.read_csv(person_daysim_dir)
    # drop the personid from person_daysim because it's calculated differently
    person_daysim.drop(['personid'], axis=1, inplace=True)
    _person = person_daysim.merge(person_original[['hhid','pernum','personid','school_loc_lat','school_loc_lng',
                                                  'work_lat','work_lng','prev_work_lat','prev_work_lng']], 
                                                   left_on=['hhno','pno'], right_on=['hhid','pernum'], how='left')

    # Add parcel location for current and previous school and workplace location
    person, person_daysim = locate_person_parcels(_person, parcel_df, df_taz)
    person_loc_fields = ['school_loc_parcel','school_loc_taz', 'work_parcel','work_taz','prev_work_parcel','prev_work_taz',
                         'school_loc_parcel_distance','work_parcel_distance','prev_work_parcel_distance']

    # Join the new fields back to the original person file and write out
    person_orig_update = person_original.merge(person[person_loc_fields+['personid']], on='personid', how='left')
    person_orig_update[person_loc_fields] = person_orig_update[person_loc_fields].fillna(-1).astype('int')

    # Write to file
    person_orig_update.to_csv(os.path.join(orig_format_output_dir,'2_person.csv'), index=False)

    # Export daysim versions
    person_daysim.to_csv(os.path.join(daysim_format_output_dir,'person17.csv'), index=False)

    ##################################################
    # Process household records
    ##################################################
    
    # Add the household geography columns to look these up as well
    hh_original = pd.read_csv(hh_file_dir, encoding='latin1')
    hh_daysim = pd.read_csv(hh_daysim_dir)

    hh_new = locate_hh_parcels(hh_original.copy(), parcel_df, df_taz)
    
    # Join with daysim version
    hh_daysim = hh_daysim.merge(hh_new[['hhid','final_home_parcel','final_home_taz']] ,left_on='hhno', right_on='hhid', how='left')
    hh_daysim.rename(columns={'final_home_parcel': 'hhparcel', 'final_home_taz': 'hhtaz'}, inplace=True)

    # add the original lat/lng fields back
    hh_new = hh_new.merge(hh_original[['hhid','final_home_lat','final_home_lng']], on='hhid')

    # write out updated versions
    hh_new.to_csv(os.path.join(orig_format_output_dir,'1_household.csv'), index=False)
    hh_daysim.to_csv(os.path.join(daysim_format_output_dir,'household17.csv'), index=False)

    ##################################################
    # Process trip records
    ##################################################
    
    trip_original = pd.read_csv(trip_file_dir, encoding='latin1')
    trip_daysim = pd.read_csv(trip_daysim_dir)

    #trip = trip_original.merge(trip_daysim, right_on='recid', left_on='tsvid')

    trip = locate_trip_parcels(trip_original.copy(), parcel_df, df_taz)

    # Export daysim records
    df = trip.merge(trip_daysim.drop(['otaz','dtaz','opcl','dpcl'], axis=1),left_on='recid', right_on='tsvid')
    df[trip_daysim.columns.drop(['personid'])].to_csv(os.path.join(daysim_format_output_dir,'trip17.csv'),index=False)

    # Export original survey records
    # Merge with originals to make sure we didn't exclude records
    trip_original_updated = trip_original.merge(trip[['recid','otaz','dtaz','opcl','dpcl','opcl_distance','dpcl_distance']],on='recid',how='left')
    trip_original_updated['otaz'].fillna(-1,inplace=True)
    trip_original_updated.to_csv(os.path.join(orig_format_output_dir,'5_trip.csv'), index=False)

    # temp output
    trip_opcl = trip_original_updated.merge(parcel_df,left_on='opcl',right_on='parcelid',how='left')
    trip_opcl.to_csv(os.path.join(orig_format_output_dir,'5_trip_opcl.csv'), index=False)
    trip_dpcl = trip_original_updated.merge(parcel_df,left_on='dpcl',right_on='parcelid',how='left')
    trip_dpcl.to_csv(os.path.join(orig_format_output_dir,'5_trip_dpcl.csv'), index=False)

if __name__ =="__main__":
    main()