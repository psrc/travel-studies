# This script assigns parcel IDs to survey fields, including current/past work and home location,
# school location, and trip origin and destination. 
# Locations are assigned by finding nearest parcel that meets criteria (e.g., work location must have workers at parcel) 
# In some cases (school location), if parcels are over a threshold distance from original xy values, 
# multiple filter tiers can be applied (e.g., first find parcel with students; for parcels with high distances, 
# use a looser criteria like a parcel with service jobs, followed by parcels with household population.)

# Requires Python 3 for geopandas

import os, sys
import pandas as pd
import geopandas as gpd
import sqlalchemy
from scipy.spatial import cKDTree
import pyodbc
from shapely import wkt
from pysal.lib.weights.distance import get_points_array    # May cause a warning due to some compatiability issues with pandana
from shapely.geometry import LineString
from pyproj import Proj, transform
import pyproj
import numpy as np
from operator import itemgetter

# Set current working directory to script location
working_dir = r'C:\Workspace\travel-studies\2021\daysim_conversion'
os.chdir(working_dir)

# Set input paths


# Geographic files
# We use the latest land use file for workers and student placement, to find nearest parcel with jobs/school
parcel_file_dir = r'R:\e2projects_two\SoundCast\Inputs\dev\landuse\2018\v3_RTP\parcels_urbansim.txt'
# Hana produces another file that reports residential units and buildings per parcel
# to ensure that households are placed on parcels that actually have housing
parcel_res_units_file = r'R:\e2projects_two\2022_base_year\2021_survey\parcels_for_hh_survey.csv'

# Original format output
orig_format_output_dir = r'R:\e2projects_two\2022_base_year\2021_survey\geocoded'
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

    parcel_df['total_students'] = parcel_df[['stugrd_p','stuhgh_p','stuuni_p']].sum(axis=1)

    # For records 

    # Find parcels for person fields
    filter_dict_list = [{
        'var_name': 'work',
        'parcel_filter': parcel_df['emptot_p'] > 0,
        'person_filter': (-person['work_lng'].isnull()) & 
                         (person['workplace'].isin(['Usually the same location (outside home)',
                                                    'Telework some days and travel to a work location some days']))    # workplace is at a consistent location
        },
        #{
        ## Previous work location
        #'var_name': 'prev_work',
        #'parcel_filter': parcel_df['emptot_p'] > 0,
        #'person_filter': -person['prev_work_lng'].isnull()
        #},
        {
        # Student
        'var_name': 'school_loc',
        'parcel_filter': (parcel_df['total_students'] > 0),
        'person_filter': (-person['school_loc_lat'].isnull()) & 
                         (-(person['final_home_lat'] == person['school_loc_lat'])) &   # Exclude home-school students
                         (-(person['final_home_lng'] == person['school_loc_lng']))
        },
        ]

    # Find nearest school and workplace
    for i in range(len(filter_dict_list)):
        print(i)
        varname = filter_dict_list[i]['var_name']
        person_filter = filter_dict_list[i]['person_filter']
        parcel_filter = filter_dict_list[i]['parcel_filter']

        # Convert GPS Coordinates to State Plane
        gdf = gpd.GeoDataFrame(person[person_filter], geometry=gpd.points_from_xy(person[person_filter][varname+'_lng'], person[person_filter][varname+'_lat']))
        gdf.crs = lat_lng_crs
        gdf[varname+'_lng_gps'] = gdf[varname+'_lng']
        gdf[varname+'_lat_gps'] = gdf[varname+'_lat']
        gdf = gdf.to_crs('epsg:2285')    # convert to state plane WA 
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
        gdf[varname+'_taz'] = gdf['taz']
        
        gdf_cols = ['person_id',varname+'_taz',varname+'_parcel',varname+'_parcel_distance',
                                           varname+'_lat_fips_4601',
                                   varname+'_lng_fips_4601',varname+'_lat_gps']

        # Refine School Location in 2 tiers
        # Tier 2: for locations that are over 1 mile (5280 feet) from lat/lng, 
        # place them in parcel with >0 education or service employees (could be daycare or specialized school, etc. without students listed)

        #if varname == 'school_loc':
        #    hh_max_dist = 5280
        #    gdf_far = gdf[gdf[varname+'_parcel_distance'] > hh_max_dist]
        #    _dist, _ix = locate_parcel(parcel_df[parcel_df['total_students'] > 0], 
        #                               df=gdf_far, xcoord_col=varname+'_lng_fips_4601', ycoord_col=varname+'_lat_fips_4601')
        #    gdf_far[varname+'_parcel'] = parcel_df.iloc[_ix].parcelid.values
        #    gdf_far[varname+'_parcel_distance'] = _dist
        #    gdf_far[varname+'_taz'] = gdf_far['TAZ'].astype('int')

        #    # Add this new distance to the original gdf
        #    gdf.loc[gdf_far.index,varname+'_parcel_original'] = gdf.loc[gdf_far.index,varname+'_parcel']
        #    gdf.loc[gdf_far.index,varname+'_parcel_distance_original'] = gdf.loc[gdf_far.index,varname+'_parcel_distance']
        #    gdf.loc[gdf_far.index,varname+'_parcel'] = gdf_far[varname+'_parcel']
        #    gdf.loc[gdf_far.index,varname+'_parcel_distance'] = gdf_far[varname+'_parcel_distance']
        #    gdf['distance_flag'] = 0
        #    gdf.loc[gdf_far.index,varname+'distance_flag'] = 1

        #    gdf_cols += [varname+'_parcel_distance_original',varname+'_parcel_original']

        # Join the gdf dataframe to the person df
        person_results = person_results.merge(gdf[gdf_cols], how='left', on='person_id')

    # Export 2 different versions, one for Daysim, one an updated version of the original dataset
    #person_daysim = person_results.copy()

    # Rename variables for daysim
    #person_daysim['pwpcl'] = person_daysim['work_parcel']
    #person_daysim['pwtaz'] = person_daysim['work_taz']
    #person_daysim['pspcl'] = person_daysim['school_loc_parcel']
    #person_daysim['pstaz'] = person_daysim['school_loc_taz']
    #person_daysim['hhno'] = person_daysim['household_id']
    #person_daysim['pno'] = person_daysim['person_id']

    #for col in ['pspcl','pstaz','pwpcl','pwtaz']:
    #    person_daysim[col] = person_daysim[col].fillna(-1).astype('int')

    ## Add additional variables for writing file
    #daysim_cols = ['hhno','pno', 'pptyp', 'pagey', 'pgend', 'pwtyp', 'pwpcl', 'pwtaz', 'pwautime',
    #                'pwaudist', 'pstyp', 'pspcl', 'pstaz', 'psautime', 'psaudist', 'puwmode', 'puwarrp', 
    #                'puwdepp', 'ptpass', 'ppaidprk', 'pdiary', 'pproxy', 'psexpfac']

    ## Add empty columns to fill in later with skims
    #for col in daysim_cols:
    #    if col not in person_daysim.columns:
    #        person[col] = -1
        
    #person_daysim = person_daysim[daysim_cols]

    #return person_results, person_daysim
    return person_results

def locate_hh_parcels(hh, parcel_df, df_taz):

    hh_results = hh.copy()

    filter_dict_list = [{
    
         # Current Home Location
        'var_name': 'final_home',
        'parcel_filter': (parcel_df['residential_units'] > 0),
        'hh_filter': (-hh['final_home_lat'].isnull())
        },
        {
        # Previous Home Location
        'var_name': 'prev_home',
        'parcel_filter': (parcel_df['residential_units'] > 0),
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
        gdf.crs = lat_lng_crs
        gdf[varname+'_lng_gps'] = gdf[varname+'_lng']
        gdf[varname+'_lat_gps'] = gdf[varname+'_lat']
        gdf = gdf.to_crs('epsg:2285')    # convert to state plane WA 
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
        gdf[varname+'_taz'] = gdf['taz'].astype('int')

        # For households that are not reasonably near a parcel with households, 
        # add them to the nearset unfiltered parcel and flag
        # Typically occurs with households living on military bases
        hh_max_dist = 2000
        gdf_far = gdf[gdf[varname+'_parcel_distance'] > hh_max_dist]
        _dist, _ix = locate_parcel(parcel_df, df=gdf_far, xcoord_col=varname+'_lng_fips_4601', ycoord_col=varname+'_lat_fips_4601')
        gdf_far[varname+'_parcel'] = parcel_df.iloc[_ix].parcelid.values
        gdf_far[varname+'_parcel_distance'] = _dist
        gdf_far[varname+'_taz'] = gdf_far['taz'].astype('int')

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

    opurp_field = 'origin_purpose'
    dpurp_field = 'dest_purpose'
    
    # Filter out people who have missing origin/destination purposes

    for purp_field in [opurp_field,dpurp_field]:
        trip = trip[-trip[purp_field].isnull()]
        #trip = trip[trip[purp_field] >= 0]

    trip_results = trip.copy()

    for trip_end in ['origin', 'dest']:

        lng_field = trip_end+'_lng'
        lat_field = trip_end+'_lat'

        # filter out some odd results with lng > 0 and lat < 0
        trip = trip[trip[lat_field] > 0]
        trip = trip[trip[lng_field] < 0]

        gdf = gpd.GeoDataFrame(
            trip, geometry=gpd.points_from_xy(trip[lng_field], trip[lat_field]))
        gdf.crs = lat_lng_crs
        gdf = gdf.to_crs('epsg:2285')    # convert to state plane WA 
        # Exclude any trips that start or end outside of the region
        # Spatial join between region TAZ file and trip file
        gdf = gpd.sjoin(gdf, df_taz)
        xy_field = get_points_array(gdf.geometry)
        gdf[trip_end+'_lng_gps'] = gdf[trip_end+'_lng']
        gdf[trip_end+'_lat_gps'] = gdf[trip_end+'_lat']
        gdf[trip_end+'_lng_fips_4601'] = xy_field[:,0]
        gdf[trip_end+'_lat_fips_4601'] = xy_field[:,1]
        gdf[trip_end+'_taz'] = gdf['taz']
        trip_results = trip_results.merge(gdf[['trip_id',trip_end+'_lng_gps',trip_end+'_lat_gps',trip_end+'_lng_fips_4601',trip_end+'_lat_fips_4601',trip_end+'_taz']], on='trip_id')

    # Dictionary of filters to be applied
    rec_other_purp_list = ['Went to exercise (e.g., gym, walk, jog, bike ride)','Attended recreational event (e.g., movies, sporting event)',
                           'Went to religious/community/volunteer activity',"Went to a family activity (e.g., child's softball game)"]

    # Filters are by trip purpose and define which parcels should be available for selection as nearest
    filter_dict_list = [
        # Home trips (purp == 'Went home') should be nearest parcel with household population > 0
        {'parcel_filter': parcel_df['hh_p'] > 0,
            'o_trip_filter': trip_results[opurp_field]=='Went home',
            'd_trip_filter': trip_results[dpurp_field]=='Went home'},

        # Work trips, parcel must have jobs (emptot>0)
        {'parcel_filter': -parcel_df.isnull(),
            'o_trip_filter': trip_results[opurp_field]=='Went to primary workplace',
            'd_trip_filter': trip_results[dpurp_field]=='Went to primary workplace'},

        # Work related-trips, no parcel restrictions
        {'parcel_filter': parcel_df['emptot_p'] > 0,
            'o_trip_filter': trip_results[opurp_field]=='Went to work-related place (e.g., meeting, second job, delivery)',
            'd_trip_filter': trip_results[dpurp_field]=='Went to work-related place (e.g., meeting, second job, delivery)'},

        # School; parcel must have students (either grade, high, or uni students)
        {'parcel_filter': ((parcel_df['stugrd_p'] > 0) | (parcel_df['stuhgh_p'] > 0) | (parcel_df['stuuni_p'] > 0)),
            'o_trip_filter': trip_results[opurp_field]=='Went to school/daycare (e.g., daycare, K-12, college)',
            'd_trip_filter': trip_results[dpurp_field]=='Went to school/daycare (e.g., daycare, K-12, college)'},

        # Escort; parcel must have jobs or grade/high school students
        {'parcel_filter': -parcel_df.isnull(),
            'o_trip_filter': trip_results[opurp_field]=="Dropped off/picked up someone (e.g., son at a friend's house, spouse at bus stop)",
            'd_trip_filter': trip_results[dpurp_field]=="Dropped off/picked up someone (e.g., son at a friend's house, spouse at bus stop)"},

        # Personal Business/other apporintments, errands (purp.isin([33,61]); parcel must have either retail or service jobs
        {'parcel_filter': -parcel_df.isnull(),
            'o_trip_filter': trip_results[opurp_field].isin(['Conducted personal business (e.g., bank, post office)','Other purpose']),
            'd_trip_filter': trip_results[dpurp_field].isin(['Conducted personal business (e.g., bank, post office)','Other purpose'])},

        # Shopping (purp.isin([30,32])); parcel must have retail jobs
        {'parcel_filter': -parcel_df.isnull(),
            'o_trip_filter': trip_results[opurp_field].isin(['Went grocery shopping','Went to other shopping (e.g., mall, pet store)']),
            'd_trip_filter': trip_results[dpurp_field].isin(['Went grocery shopping','Went to other shopping (e.g., mall, pet store)'])},

        # Meal (purp==50); parcel must have food service jobs
        {'parcel_filter': -parcel_df.isnull(),
            'o_trip_filter': trip_results[opurp_field]=='Went to restaurant to eat/get take-out',
            'd_trip_filter': trip_results[dpurp_field]=='Went to restaurant to eat/get take-out'},

        # Social (purp.isin([52,62]); parcel must have households or employment
        {'parcel_filter': -parcel_df.isnull(),
            'o_trip_filter': trip_results[opurp_field].isin(['Attended social event (e.g., visit with friends, family, co-workers)']),
            'd_trip_filter': trip_results[dpurp_field].isin(['Attended social event (e.g., visit with friends, family, co-workers)'])},

         #Recreational, exercise, volunteed/community event, family activity, other (purp.isin([53,51,54]); any parcel allowed
        ###
        {'parcel_filter': -parcel_df.isnull(),   # no parcel filter
            'o_trip_filter': trip_results[opurp_field].isin(rec_other_purp_list),
            'd_trip_filter': trip_results[dpurp_field].isin(rec_other_purp_list)},

         #Medical (purp==34); parcel must have medical employment
        {'parcel_filter': parcel_df['empmed_p'] > 0,
            'o_trip_filter': trip_results[opurp_field]=='Went to medical appointment (e.g., doctor, dentist)',
            'd_trip_filter': trip_results[dpurp_field]=='Went to medical appointment (e.g., doctor, dentist)'},

        # For change mode (purp==60, no parcel filter)
        {'parcel_filter': -parcel_df.isnull(),    # no parcel filter
            'o_trip_filter': trip_results[opurp_field]=='Transferred to another mode of transportation (e.g., change from ferry to bus)',
            'd_trip_filter': trip_results[dpurp_field]=='Transferred to another mode of transportation (e.g., change from ferry to bus)'},
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
        final_df = final_df.merge(df_temp[['trip_id',trip_end_type[0]+'pcl',trip_end_type[0]+'pcl_distance',trip_end_type[0]+'taz']], on='trip_id')

    return final_df

def read_from_sde(connection_string, feature_class_name, version,
                  crs='epsg:2285', is_table = False):
    """
    Returns the specified feature class as a geodataframe from ElmerGeo.
    
    Parameters
    ----------
    connection_string : SQL connection string that is read by geopandas 
                        read_sql function
    
    feature_class_name: the name of the featureclass in PSRC's ElmerGeo 
                        Geodatabase
    
    cs: cordinate system
    """


    engine = sqlalchemy.create_engine(connection_string)
    con=engine.connect()
    #con.execute("sde.set_current_version {0}".format(version))
    if is_table:
        gdf=pd.read_sql('select * from %s' % 
                   (feature_class_name), con=con)
        con.close()

    else:
        df=pd.read_sql('select *, Shape.STAsText() as geometry from %s' % 
                   (feature_class_name), con=con)
        con.close()

        df['geometry'] = df['geometry'].apply(wkt.loads)
        gdf=gpd.GeoDataFrame(df, geometry='geometry')
        gdf.crs = crs
        cols = [col for col in gdf.columns if col not in 
                ['Shape', 'GDB_GEOMATTR_DATA', 'SDE_STATE_ID']]
        gdf = gdf[cols]
    
    return gdf

def main():

    # Load parcel data
    parcel_df = pd.read_csv(parcel_file_dir, delim_whitespace=True)

    # Join parcel residential unit information (produced by Hana from urbansim) for household placement
    parcel_res_df = pd.read_csv(parcel_res_units_file, usecols=['parcel_id','residential_units','number_of_buildings'])
    parcel_df = parcel_df.merge(parcel_res_df, left_on='parcelid', right_on='parcel_id', how='left')
    
    # Load TAZ shapefile
    connection_string = 'mssql+pyodbc://AWS-PROD-SQL\Sockeye/ElmerGeo?driver=SQL Server?Trusted_Connection=yes'
    crs = 'EPSG:2285'
    version = "'DBO.Default'"
    df_taz = read_from_sde(connection_string, 'TAZ2010', version, crs=crs, is_table=False)

    # Load the survey files in original format from Elmer
    conn_string = "DRIVER={ODBC Driver 17 for SQL Server}; SERVER=AWS-PROD-SQL\Sockeye; DATABASE=Elmer; trusted_connection=yes; NeedODBCTypesOnly=1"
    sql_conn = pyodbc.connect(conn_string)

    hh_original = pd.read_sql(sql='select * from HHSurvey.v_households WHERE survey_year=2021', con=sql_conn)
    person_original = pd.read_sql(sql='select * from HHSurvey.v_persons WHERE survey_year=2021', con=sql_conn)
    trip_original = pd.read_sql(sql='select * from HHSurvey.v_trips WHERE survey_year=2021', con=sql_conn)
    
    # add xy data
    trip_xy = pd.read_csv(r'J:\Projects\Surveys\HHTravel\Survey2021\Data\Location Data for Requests\trips_2017_2019_2021_locations.csv')
    trip_original = trip_original.merge(trip_xy, on='trip_id', how='left')

    # Note that previous work lat/lng is missing from 2021 location data as of now.
    #person_xy = pd.read_csv(r'J:\Projects\Surveys\HHTravel\Survey2021\Data\Location Data for Requests\persons_2017_2019_2021_locations.csv')
    ##person_xy.drop('household_id', axis=1, inplace=True)
    #person_xy = person_xy[['prev_work_lat','prev_work_lng','person_id']]
    #person_original = person_original.merge(person_xy, on='person_id', how='left')


    ##################################################
    # Process household records
    ##################################################
    
    hh_new = locate_hh_parcels(hh_original.copy(), parcel_df, df_taz)

    # add the original lat/lng fields back
    # hh_new = hh_new.merge(hh_original[['hhid','final_home_lat','final_home_lng']], on='hhid')

    # Write to file
    hh_new.to_csv(os.path.join(orig_format_output_dir,'1_household.csv'), index=False)

    ###################################################
    ## Process person records
    ###################################################


    # Merge with household records to get school/work lat and long, to filter people who home school and work at home
    person = pd.merge(person_original, hh_new[['household_id','final_home_lat','final_home_lng', 'final_home_parcel','final_home_taz']], on='household_id')

    # Add parcel location for current and previous school and workplace location
    person = locate_person_parcels(person, parcel_df, df_taz)

    # For people that work from home, assign work parcel as household parcel
    # Join this person file back to original person file to get workplace
    person.loc[person['workplace'] == 'At home (telecommute or self-employed with home office)', 'work_parcel'] = person['final_home_parcel']
    person.loc[person['workplace'] == 'At home (telecommute or self-employed with home office)', 'work_taz'] = person['final_home_taz']

    # Write to file
    person.to_csv(os.path.join(orig_format_output_dir,'2_person.csv'), index=False)
    
    ##################################################
    # Process trip records
    ##################################################

    trip = locate_trip_parcels(trip_original.copy(), parcel_df, df_taz)

    # Export original survey records
    # Merge with originals to make sure we didn't exclude records
    #trip_original_updated = trip_original.merge(trip[['trip_id','otaz','dtaz','opcl','dpcl','opcl_distance','dpcl_distance']],on='trip_id',how='left')
    #trip_original_updated['otaz'].fillna(-1,inplace=True)

    # Write to file
    trip.to_csv(os.path.join(orig_format_output_dir,'5_trip.csv'), index=False)

if __name__ =="__main__":
    main()
