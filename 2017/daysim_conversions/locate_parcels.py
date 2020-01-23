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

parcel_file_dir = r'R:\e2projects_two\SoundCast\Inputs\lodes\alpha_lodes\2014\landuse\parcels_urbansim.txt'
taz_dir = r'W:\geodata\forecast\taz2010.shp'

#person_file_dir = r'C:\Users\bnichols\travel-studies\2017\daysim_conversions\person17.csv'
person_file_dir = r'J:\Projects\Surveys\HHTravel\Survey2017\Data\Export\Version 2\Restricted\In-house\2017-internal-v2-R-2-person.xlsx'
trip_file_dir = r'C:\Users\bnichols\travel-studies\2017\daysim_conversions\trip17.csv'



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
    _dist, _ix = nearest_neighbor(_parcel_df[['xcoord_p','ycoord_p']],
                                 df[[xcoord_col,ycoord_col]])

    return _dist, _ix


def locate_person_parcels(person, df_taz):
    """ Locate parcel ID for school, workplace, home location from person records. """

    # Find parcels for person fields
    filter_dict_list = [{
        'var_name': 'work',
        'parcel_filter': parcel_df['emptot_p'] > 0,
        'person_filter': -person['work_lng'].isnull()
        },
        {
        # K12 student
        'var_name': 'school_loc',
        'parcel_filter': (parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0),
        'person_filter': person['pptyp'].isin([6,7]) & -person['school_loc_lat'].isnull()
        },
        {
        # College student
        'var_name': 'school_loc',
        'parcel_filter': (parcel_df['stuuni_p'] > 0),
        'person_filter': person['pptyp'] == 5 & -person['school_loc_lat'].isnull()
        },
        ]

    _person = person.copy() # Make local copy for extracting XY coordinates in consistent projection

    # Find nearest school and workplace
    for i in range(len(filter_dict_list)):

        varname = filter_dict_list[i]['var_name']
        person_filter = filter_dict_list[i]['person_filter']
        parcel_filter = filter_dict_list[i]['parcel_filter']

        # Convert GPS Coordinates to State Plane
        gdf = gpd.GeoDataFrame(person, geometry=gpd.points_from_xy(_person[varname+'_lng'], _person[varname+'_lat']))
        gdf.crs = {'init' :lat_lng_crs}
        gdf = gdf.to_crs({'init': 'epsg:2285'})    # convert to state plane WA 
        # Exclude any location outside the region
        # Spatial join between region TAZ file and person file
        gdf = gpd.sjoin(gdf, df_taz)
        xy_field = get_points_array(gdf.geometry)
        person_filter = person['personid'].isin(gdf.personid)
        person.loc[person_filter,varname+'_lng'] = xy_field[:,0]
        person.loc[person_filter,varname+'_lat'] = xy_field[:,1]

        parcel_filter = parcel_df['emptot_p'] > 0
        person_filter = -person[varname+'_lng'].isnull()

        _dist, _ix = locate_parcel(parcel_df, df=person, xcoord_col=varname+'_lng', ycoord_col=varname+'_lat', 
                                    parcel_filter=parcel_filter, df_filter=person_filter)

        # Assign values to person df
        person.loc[person_filter,varname+'_parcel'] = parcel_df.iloc[_ix].parcelid.values
        person.loc[person_filter,varname+'_parcel_distance'] = _dist

    # Rename variables for daysim
    person['pwpcl'] = person['work_parcel']
    person = pd.merge(person, parcel_df[['parcelid','taz_p']], left_on='pwpcl', right_on='parcelid',how='left').drop('parcelid',axis=1)
    person.rename(columns={'taz_p': 'pwtaz'}, inplace=True)
    person['pspcl'] = person['school_loc_parcel']
    person = pd.merge(person, parcel_df[['parcelid','taz_p']], left_on='pspcl', right_on='parcelid',how='left').drop('parcelid',axis=1)
    person.rename(columns={'taz_p': 'pstaz'}, inplace=True)
    for col in ['pspcl','pstaz','pwpcl','pwtaz']:
        person[col] = person[col].fillna(-1).astype('int')

    # Add additional variables for writing file
    daysim_cols = ['hhno', 'pno', 'pptyp', 'pagey', 'pgend', 'pwtyp', 'pwpcl', 'pwtaz', 'pwautime',
                    'pwaudist', 'pstyp', 'pspcl', 'pstaz', 'psautime', 'psaudist', 'puwmode', 'puwarrp', 
                    'puwdepp', 'ptpass', 'ppaidprk', 'pdiary', 'pproxy', 'psexpfac']

    # Add empty columns to fill in later with skims
    for col in daysim_cols:
        if col not in person.columns:
            person[col] = -1
        
    person = person[daysim_cols]

    return person


def locate_trip_parcels(trip):
    """ Attach parcel ID to trip origins and destinations. """

    
    # Filter out people who have missing origin/destination purposes
    # For now, just drop individual trips
    # FIX ME ^
    for purp_field in ['opurp','dpurp']:
        trip = trip[-trip[purp_field].isnull()]
        trip = trip[trip[purp_field] >= 0]

    for trip_end in ['origin', 'dest']:
        # Filter for records with valid entries and create gdf
        lng_field = trip_end+'_lng'
        lat_field = trip_end+'_lat'
        gdf = gpd.GeoDataFrame(
            trip, geometry=gpd.points_from_xy(trip[lng_field], trip[lat_field]))
        gdf.crs = {'init' :lat_lng_crs}
        gdf = gdf.to_crs({'init': 'epsg:2285'})    # convert to state plane WA 
        # Exclude any trips that start or end outside of the region
        # Spatial join between region TAZ file and trip file
        gdf = gpd.sjoin(gdf, df_taz)
        xy_field = get_points_array(gdf.geometry)

        trip = trip[trip['recid'].isin(gdf.recid)]
        trip[trip_end[0]+'_x_coord'] = xy_field[:,0]
        trip[trip_end[0]+'_y_coord'] = xy_field[:,1]

    # Create columns to store results
    trip['opcl'] = -1
    trip['dpcl'] = -1
    trip['opcl_distance'] = -1
    trip['dpcl_distance'] = -1

    # Dictionary of filters to be applied
    # Filters are by trip purpose and define which parcels should be available for selection as nearest
    filter_dict_list = [
        # Home trips (purp == 0) should be nearest parcel with household population > 0
        {'parcel_filter': parcel_df['hh_p'] > 0,
            'o_trip_filter': trip['opurp']==0,
            'd_trip_filter': trip['dpurp']==0},

        # Work trips (purp==1), parcel must have jobs (emptot>0)
        {'parcel_filter': parcel_df['emptot_p'] > 0,
            'o_trip_filter': trip['opurp']==1,
            'd_trip_filter': trip['dpurp']==1},

        # School (purp==2); parcel must have students (either grade, high, or uni students)
        {'parcel_filter': ((parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0) | (parcel_df['stuuni_p'] > 0)),
            'o_trip_filter': trip['opurp']==2,
            'd_trip_filter': trip['dpurp']==2},

        # Escort (purp==3); parcel must have jobs or grade/high school students
        {'parcel_filter': ((parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0) | (parcel_df['emptot_p'] > 0)),
            'o_trip_filter': trip['opurp']==3,
            'd_trip_filter': trip['dpurp']==3},

        # Personal Business(purp==4); parcel must have either retail or service jobs
        {'parcel_filter': ((parcel_df['empret_p'] > 0) | (parcel_df['empsvc_p'] > 0)),
            'o_trip_filter': trip['opurp']==4,
            'd_trip_filter': trip['dpurp']==4},

        # Shopping (purp==5); parcel must have retail jobs
        {'parcel_filter': parcel_df['empret_p'] > 0,
            'o_trip_filter': trip['opurp']==5,
            'd_trip_filter': trip['dpurp']==5},

        # Meal (purp==6); parcel must have food service jobs
        {'parcel_filter': parcel_df['empfoo_p'] > 0,
            'o_trip_filter': trip['opurp']==6,
            'd_trip_filter': trip['dpurp']==6},

        # Social (purp==7); parcel must have households
        {'parcel_filter': parcel_df['hh_p'] > 0,
            'o_trip_filter': trip['opurp']==7,
            'd_trip_filter': trip['dpurp']==7},

        ##### FIXME: really? Why so?
        # Recreational (purp==8); parcel must have households
        ####
        {'parcel_filter': parcel_df['hh_p'] > 0,
            'o_trip_filter': trip['opurp']==8,
            'd_trip_filter': trip['dpurp']==8},

        # Medical (purp==9); parcel must have medical employment
        {'parcel_filter': parcel_df['empmed_p'] > 0,
            'o_trip_filter': trip['opurp']==9,
            'd_trip_filter': trip['dpurp']==9},

        # For change mode (purp==10, no parcel filter)
        {'parcel_filter': None,
            'o_trip_filter': trip['opurp']==10,
            'd_trip_filter': trip['dpurp']==10},
        ]

    # Loop through each trip end type (origin or destination) and each trip purpose
    for trip_end_type in ['o','d']:
        for i in range(len(filter_dict_list)):

            trip_filter = filter_dict_list[i][trip_end_type+'_trip_filter']
            parcel_filter = filter_dict_list[i]['parcel_filter']

            _dist, _ix = locate_parcel(parcel_df, df=trip, xcoord_col=trip_end_type+'_x_coord', ycoord_col=trip_end_type+'_y_coord', 
                                        parcel_filter=parcel_filter, df_filter=trip_filter)

            # Assign values to trip df
            trip.loc[trip_filter,trip_end_type+'pcl'] = parcel_df.iloc[_ix].parcelid.values
            trip.loc[trip_filter,trip_end_type+'pcl_distance'] = _dist

    return trip

###########################################################
# Evaluate results with large distances
###########################################################

#if distance is over a threshold, try a second (looser) parcel filter
filter_dict_list_loose = [
    # Home trips (purp == 0) should be nearest parcel with household population > 0, or with k-12 students
    {'parcel_filter': ((parcel_df['hh_p'] > 0) | (parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0)),
        'o_trip_filter': trip['opurp']==0,
        'd_trip_filter': trip['dpurp']==0},

    # Work trips (purp==1), parcel must have jobs (emptot>0 or hh>0)
    {'parcel_filter': ((parcel_df['emptot_p'] > 0) | (parcel_df['hh_p'] > 0)),
        'o_trip_filter': trip['opurp']==1,
        'd_trip_filter': trip['dpurp']==1},

    # School (purp==2); parcel must have students (either grade, high, or uni students, or any employment)
    {'parcel_filter': ((parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0) | (parcel_df['stuuni_p'] > 0) | (parcel_df['emptot_p'] > 0)),
        'o_trip_filter': trip['opurp']==2,
        'd_trip_filter': trip['dpurp']==2},

    # Escort, personal business, social, and recreational
    {'parcel_filter': ((parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0) | (parcel_df['hh_p'] > 0) | (parcel_df['emptot_p'] > 0) | (parcel_df['stuuni_p'] > 0)),
        'o_trip_filter': trip['opurp'].isin([3,4,7,8]),
        'd_trip_filter': trip['dpurp'].isin([3,4,7,8])},

    # Shopping (purp==5); parcel must have any job
    {'parcel_filter': parcel_df['emptot_p'] > 0,
        'o_trip_filter': trip['opurp']==5,
        'd_trip_filter': trip['dpurp']==5},

    # Meal (purp==6); parcel must have any job
    {'parcel_filter': parcel_df['emptot_p'] > 0,
        'o_trip_filter': trip['opurp']==6,
        'd_trip_filter': trip['dpurp']==6},

    # Medical (purp==9); parcel must have medical employment
    {'parcel_filter': parcel_df['emptot_p'] > 0,
        'o_trip_filter': trip['opurp']==9,
        'd_trip_filter': trip['dpurp']==9},

    ]

##################################################
# Trips with initial distances > 1/8 mile
# For trips above this threshold, loosen threshold
# to find a closer parcel
##################################################

trip_0125 = trip.copy()
trip_0125 = trip_0125[trip_0125['opcl_distance'] > 660]

for trip_end_type in ['o','d']:
    for i in range(len(filter_dict_list_loose)):

        trip_filter = filter_dict_list_loose[i][trip_end_type+'_trip_filter']
        parcel_filter = filter_dict_list_loose[i]['parcel_filter']

        _dist, _ix = locate_parcel(parcel_df, df=trip_0125, xcoord_col=trip_end_type+'_x_coord', ycoord_col=trip_end_type+'_y_coord', 
                                    parcel_filter=parcel_filter, df_filter=trip_filter)

        # Assign values to trip df
        trip_0125.loc[trip_filter,trip_end_type+'pcl'] = parcel_df.iloc[_ix].parcelid.values
        trip_0125.loc[trip_filter,trip_end_type+'pcl_distance'] = _dist

# If the closer parcel found from trip_loose is within the 1/8 mile buffer, keep it, otherwise use the one from 1/4 buffer?
for trip_purp in ['o','d']:
    filter = trip.loc[trip_0125.index,trip_purp+'pcl_distance'] > trip_0125[trip_purp+'pcl_distance']
    indexvals = trip_0125[trip.loc[trip_0125.index,trip_purp+'pcl_distance'] > trip_0125[trip_purp+'pcl_distance']].index
    trip.loc[indexvals,trip_purp+'pcl_distance_new'] = trip_0125.loc[indexvals][trip_purp+'pcl_distance']
    trip.loc[indexvals,trip_purp+'pcl_new'] = trip_0125.loc[indexvals][trip_purp+'pcl']
    trip[trip_purp+'pcl_distance_new'].fillna(trip[trip_purp+'pcl_distance'],inplace=True)
    trip[trip_purp+'pcl_new'].fillna(trip[trip_purp+'pcl'],inplace=True)

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
    person = pd.read_excel(person_file_dir, skiprows=1)
    person_original_dir = person_file_dir
    person_daysim_dir = r'C:\Users\bnichols\travel-studies\2017\daysim_conversions\person17.csv'
    
    # Join original person records to daysim-formatted records to get xy coordinates
    person_original = pd.read_excel(person_file_dir, skiprows=1)
    person_daysim = pd.read_csv(person_daysim_dir)
    person = person_daysim.merge(person_original[['hhid','pernum','personid','school_loc_lat','school_loc_lng','work_lat','work_lng']], 
                        left_on=['hhno','pno'], right_on=['hhid','pernum'], how='left')
    person = locate_person_parcels(person, df_taz)

    ##################################################
    # Process trip records
    ##################################################
    trip_original_dir = r'R:\e2projects_two\SoundCastDocuments\2017Estimation\trip_from_db.csv'
    trip_daysim_dir = r'C:\Users\bnichols\travel-studies\2017\daysim_conversions\trip17.csv'
    trip_original = pd.read_csv(trip_original_dir)
    trip_daysim = pd.read_csv(trip_daysim_dir)

    trip = trip_daysim.merge(trip_original[['origin_lat','origin_lng','dest_lat','dest_lng','recid']], 
                             left_on='tsvid', right_on='recid')

    trip = locate_trip_parcels(trip)

    # Summarize and evaluate

if __name__ =="__main__":
    main()