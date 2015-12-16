from HHSurveyToPandas import *
from h5toDF import *
import winsound as ws
from time import sleep

play_end_sound = False

def end_sound():
    ws.Beep(932, 250)
    sleep(0.25)
    ws.Beep(698, 166)
    ws.Beep(659, 166)
    ws.Beep(698, 167)
    ws.Beep(784, 500)
    ws.Beep(698, 500)
    sleep(0.5)
    ws.Beep(880, 250)
    sleep(0.25)
    ws.Beep(932, 250)
    sleep(0.25)
    ws.Beep(233, 500)

def assign_ferry(df):
    for trip in df.index.tolist():
        if df.loc[trip, 'mode'] == 'Ferry':
            if df.loc[trip, 'tripID'] - 1 in df['tripID']:
                if df.loc[trip - 1, 'mode'] == 'Walk' or df.loc[trip - 1, 'mode'] == 'Bike':
                    df.loc[trip, 'mode'] = 'Transit'
                else:
                    df.loc[trip, 'mode'] = df.loc[trip - 1, 'mode']
            else:
                df.loc[trip, 'mode'] = 'Transit'
    print ('Ferry trips assigned a mode')
    return df

output_location = '[OUTPUT LOCATION]'

file = '[SURVEY H5 FILE]'
guide = '[GUIDE FILE]'
name = 'ancient mystical past'

mode_map = {'Drove alone': 'SOV',
            'Motorcycle/moped/scooter': 'SOV',
            'Drove/rode ONLY with other household members': 'HOV',
            'Drove/rode with people not in household (may also include household members)': 'HOV',
            'Taxi or other hired car service (e.g. Lyft, Uber)': 'HOV',
            'Vanpool': 'HOV',
            'Bicycle': 'Bike',
            'Bus (public transit)': 'Transit',
            'Ferry or water taxi': 'Ferry',
            'Paratransit': 'Transit',
            'Streetcar': 'Transit',
            'Train (rail and monorail)': 'Transit',
            'Private bus or shuttle': 'Other',
            'Walk, jog, or wheelchair': 'Walk',
            'School bus': 'School Bus',
            'School Bus': 'School Bus',
            'Other (e.g. skateboard, kayak, motor home, etc.)': 'Other',
            
            'SOV': 'SOV',
            'HOV2': 'HOV',
            'HOV3+': 'HOV',
            'Transit': 'Transit',
            'Walk': 'Walk',
            'Bike': 'Bike',
            'Other': 'Other'}
#'Airplane or helicopter': 'Other',

purpose_map = {'Go home': 'None/Home',
               'Go to workplace': 'Work',
               'Go grocery shopping': 'Shop',
               "Drop off/pick up someone (e.g. son at a friend's house, spouse at bus stop)": 'Escort',
               'Go to restaurant to eat/get take-out': 'Meal',
               'Go to other shopping (e.g. mall, pet store)': 'Shop',
               'Go exercise (e.g. gym, walk, jog, bike ride)': 'Recreational',
               'Conduct personal business (e.g. bank, post office)': 'Personal Business',
               'Other': 'Other',
               'Go to school/daycare (e.g. daycare, K-12, college)': 'School',
               'Attend social event (e.g. visit with friends, family, co-workers)': 'Social',
               'Go to other work-related place (e.g. meeting, delivery)': 'Work',
               'Go to medical appointment (e.g. doctor, dentist)': 'Medical',
               'Transfer to another mode of transportation (e.g. change from ferry to bus)': 'Other',
               'Attend recreational event (e.g. movies, sporting event)': 'Recreational',
               'Go to religious/community/volunteer activity': 'Personal Business',
               'None/Home': 'None/Home',
               'Work': 'Work',
               'Escort': 'Escort',
               'Shop': 'Shop',
               'Personal Business': 'Personal Business',
               'Recreational': 'Recreational',
               'Meal': 'Meal',
               'School': 'School',
               'Social': 'Social',
               'Medical': 'Medical',
               'Other': 'Other'}

data_2006 = convert(file, guide, name)

districtfile = '[TAZ_TAD_COUNTY.CSV]'
zone_district = pd.DataFrame.from_csv(districtfile)


years = ['2006', '2014', 'Change', '% Change']
modes = ['SOV', 'HOV', 'Bike', 'Transit', 'Walk', 'School Bus', 'Other', 'Ferry']
purposes = ['None/Home', 'Work', 'Escort', 'Shop', 'Personal Business', 'Recreational', 'Meal', 'School', 'Social', 'Medical', 'Other']

data_2006['Trip'] = data_2006['Trip'].query('travdist > 0')

transit_14 = HHPerTrip.query("mode in ['Bus (public transit)', 'Ferry or water taxi', 'Paratransit', 'Streetcar', 'Train (rail and monorail)', 'Private bus or shuttle']")
transit_06 = data_2006['Trip'].query('mode == "Transit" and travdist > 0')

numbers = pd.Panel(items = ['Weighted', 'Unweighted'], minor_axis = ['2006', '2014', 'Change', '% Change'], major_axis = ['Households', 'People', 'Trips', 'Trips per Household', 'Trips per Person', 'Transit Trips', 'Transit Trips per Person'])
numbers.loc['Weighted', 'Households', '2014'] = round(num_households)
numbers.loc['Weighted', 'Households', '2006'] = round(data_2006['Household']['hhexpfac'].sum())
numbers.loc['Unweighted', 'Households', '2014'] = round(num_households_unweighted)
numbers.loc['Unweighted', 'Households', '2006'] = round(data_2006['Household']['hhexpfac'].count())
numbers.loc['Weighted', 'People', '2014'] = round(num_people)
numbers.loc['Weighted', 'People', '2006'] = round(data_2006['Person']['psexpfac'].sum())
numbers.loc['Unweighted', 'People', '2014'] = round(num_people_unweighted)
numbers.loc['Unweighted', 'People', '2006'] = round(data_2006['Person']['psexpfac'].count())
numbers.loc['Weighted', 'Trips', '2014'] = round(num_trips)
numbers.loc['Weighted', 'Trips', '2006'] = round(data_2006['Trip']['trexpfac'].sum())
numbers.loc['Unweighted', 'Trips', '2014'] = round(num_trips_unweighted)
numbers.loc['Unweighted', 'Trips', '2006'] = round(data_2006['Trip']['trexpfac'].count())
numbers.loc['Weighted', 'Transit Trips', '2014'] = round(transit_14['expwt_final'].sum())
numbers.loc['Weighted', 'Transit Trips', '2006'] = round(transit_06['trexpfac'].sum())
numbers.loc['Unweighted', 'Transit Trips', '2014'] = round(transit_14['expwt_final'].count())
numbers.loc['Unweighted', 'Transit Trips', '2006'] = round(transit_06['trexpfac'].count())
numbers.loc['Weighted', 'Trips per Household', '2014'] = float(numbers.loc['Weighted', 'Trips', '2014']) / numbers.loc['Weighted', 'Households', '2014']
numbers.loc['Weighted', 'Trips per Household', '2006'] = float(numbers.loc['Weighted', 'Trips', '2006']) / numbers.loc['Weighted', 'Households', '2006']
numbers.loc['Unweighted', 'Trips per Household', '2014'] = float(numbers.loc['Unweighted', 'Trips', '2014']) / numbers.loc['Unweighted', 'Households', '2014']
numbers.loc['Unweighted', 'Trips per Household', '2006'] = float(numbers.loc['Unweighted', 'Trips', '2006']) / numbers.loc['Unweighted', 'Households', '2006']
numbers.loc['Weighted', 'Trips per Person', '2014'] = float(numbers.loc['Weighted', 'Trips', '2014']) / numbers.loc['Weighted', 'People', '2014']
numbers.loc['Weighted', 'Trips per Person', '2006'] = float(numbers.loc['Weighted', 'Trips', '2006']) / numbers.loc['Weighted', 'People', '2006']
numbers.loc['Unweighted', 'Trips per Person', '2014'] = float(numbers.loc['Unweighted', 'Trips', '2014']) / numbers.loc['Unweighted', 'People', '2014']
numbers.loc['Unweighted', 'Trips per Person', '2006'] = float(numbers.loc['Unweighted', 'Trips', '2006']) / numbers.loc['Unweighted', 'People', '2006']
numbers.loc['Weighted', 'Transit Trips per Person', '2014'] = float(numbers.loc['Weighted', 'Transit Trips', '2014']) / numbers.loc['Weighted', 'People', '2014']
numbers.loc['Weighted', 'Transit Trips per Person', '2006'] = float(numbers.loc['Weighted', 'Transit Trips', '2006']) / numbers.loc['Weighted', 'People', '2006']
numbers.loc['Unweighted', 'Transit Trips per Person', '2014'] = float(numbers.loc['Unweighted', 'Transit Trips', '2014']) / numbers.loc['Unweighted', 'People', '2014']
numbers.loc['Unweighted', 'Transit Trips per Person', '2006'] = float(numbers.loc['Unweighted', 'Transit Trips', '2006']) / numbers.loc['Unweighted', 'People', '2006']

for weighting in numbers.items:    
    numbers[weighting]['Change'] = numbers[weighting]['2014'] - numbers[weighting]['2006']
    numbers[weighting]['% Change'] = (numbers[weighting]['Change'] / numbers[weighting]['2006'] * 100).round(2)
    numbers[weighting]['2006'] = numbers[weighting]['2006'].round(2)
    numbers[weighting]['2014'] = numbers[weighting]['2014'].round(2)
    numbers[weighting]['Change'] = numbers[weighting]['Change'].round(2)

data_2006['Trip']['mode'] = data_2006['Trip']['mode'].map(mode_map)
HHPerTrip['mode'] = HHPerTrip['mode'].map(mode_map)
HHPerTrip = HHPerTrip.reset_index()
HHPerTrip = assign_ferry(HHPerTrip)
HHPerTrip = HHPerTrip.set_index('tripID')
HHPerTrip['d_purpose'] = HHPerTrip['d_purpose'].map(purpose_map)

mode_share_06_w = get_mode_share_06(data_2006['Trip']).apply(remove_percent)
mode_share_14_w = get_mode_share(HHPerTrip).apply(remove_percent)
mode_share_06_u = get_mode_share_06(data_2006['Trip'], weighted = False).apply(remove_percent)
mode_share_14_u = get_mode_share(HHPerTrip, weighted = False).apply(remove_percent)

mode_share = pd.Panel(items = ['Weighted', 'Unweighted'], minor_axis = ['2006', '2014', 'Change', '% Change'], major_axis = modes)
mode_share.loc['Weighted', 'SOV', '2006'] = mode_share_06_w['SOV']
mode_share.loc['Weighted', 'HOV', '2006'] = mode_share_06_w['HOV']
mode_share.loc['Weighted', 'Bike', '2006'] = mode_share_06_w['Bike']
mode_share.loc['Weighted', 'Transit', '2006'] = mode_share_06_w['Transit']
mode_share.loc['Weighted', 'Walk', '2006'] = mode_share_06_w['Walk']
mode_share.loc['Weighted', 'School Bus', '2006'] = mode_share_06_w['School Bus']
mode_share.loc['Weighted', 'Other', '2006'] = mode_share_06_w['Other']

mode_share.loc['Unweighted', 'SOV', '2006'] = mode_share_06_u['SOV']
mode_share.loc['Unweighted', 'HOV', '2006'] = mode_share_06_u['HOV']
mode_share.loc['Unweighted', 'Bike', '2006'] = mode_share_06_u['Bike']
mode_share.loc['Unweighted', 'Transit', '2006'] = mode_share_06_u['Transit']
mode_share.loc['Unweighted', 'Walk', '2006'] = mode_share_06_u['Walk']
mode_share.loc['Unweighted', 'School Bus', '2006'] = mode_share_06_u['School Bus']
mode_share.loc['Unweighted', 'Other', '2006'] = mode_share_06_u['Other']

mode_share.loc['Weighted', 'SOV', '2014'] = mode_share_14_w['SOV']
mode_share.loc['Weighted', 'HOV', '2014'] = mode_share_14_w['HOV']
mode_share.loc['Weighted', 'Bike', '2014'] = mode_share_14_w['Bike']
mode_share.loc['Weighted', 'Transit', '2014'] = mode_share_14_w['Transit']
mode_share.loc['Weighted', 'Walk', '2014'] = mode_share_14_w['Walk']
mode_share.loc['Weighted', 'School Bus', '2014'] = mode_share_14_w['School Bus']
mode_share.loc['Weighted', 'Other', '2014'] = mode_share_14_w['Other']

mode_share.loc['Unweighted', 'SOV', '2014'] = mode_share_14_u['SOV']
mode_share.loc['Unweighted', 'HOV', '2014'] = mode_share_14_u['HOV']
mode_share.loc['Unweighted', 'Bike', '2014'] = mode_share_14_u['Bike']
mode_share.loc['Unweighted', 'Transit', '2014'] = mode_share_14_u['Transit']
mode_share.loc['Unweighted', 'Walk', '2014'] = mode_share_14_u['Walk']
mode_share.loc['Unweighted', 'School Bus', '2014'] = mode_share_14_u['School Bus']
mode_share.loc['Unweighted', 'Other', '2014'] = mode_share_14_u['Other']



#mode_share.loc['Weighted', 'SOV', '2014'] = mode_share_14_w['Drove alone'] + mode_share_14_w['Motorcycle/moped/scooter']
#mode_share.loc['Weighted', 'HOV', '2014'] = mode_share_14_w['Drove/rode ONLY with other household members'] + mode_share_14_w['Drove/rode with people not in household (may also include household members)'] + mode_share_14_w['Taxi or other hired car service (e.g. Lyft, Uber)'] + mode_share_14_w['Vanpool']
#mode_share.loc['Weighted', 'Bike', '2014'] = mode_share_14_w['Bicycle']
#mode_share.loc['Weighted', 'Transit', '2014'] = mode_share_14_w['Bus (public transit)'] + mode_share_14_w['Ferry or water taxi'] + mode_share_14_w['Paratransit'] + mode_share_14_w['Streetcar'] + mode_share_14_w['Train (rail and monorail)'] + mode_share_14_w['Private bus or shuttle']
#mode_share.loc['Weighted', 'Walk', '2014'] = mode_share_14_w['Walk, jog, or wheelchair']
#mode_share.loc['Weighted', 'School Bus', '2014'] = mode_share_14_w['School bus']
#mode_share.loc['Weighted', 'Other', '2014'] = mode_share_14_w['Other (e.g. skateboard, kayak, motor home, etc.)'] + mode_share_14_w['Airplane or helicopter']

#mode_share.loc['Unweighted', 'SOV', '2014'] = mode_share_14_u['Drove alone'] + mode_share_14_u['Motorcycle/moped/scooter']
#mode_share.loc['Unweighted', 'HOV', '2014'] = mode_share_14_u['Drove/rode ONLY with other household members'] + mode_share_14_u['Drove/rode with people not in household (may also include household members)'] + mode_share_14_u['Taxi or other hired car service (e.g. Lyft, Uber)'] + mode_share_14_u['Vanpool']
#mode_share.loc['Unweighted', 'Bike', '2014'] = mode_share_14_u['Bicycle']
#mode_share.loc['Unweighted', 'Transit', '2014'] = mode_share_14_u['Bus (public transit)'] + mode_share_14_u['Ferry or water taxi'] + mode_share_14_u['Paratransit'] + mode_share_14_u['Streetcar'] + mode_share_14_u['Train (rail and monorail)'] + mode_share_14_u['Private bus or shuttle']
#mode_share.loc['Unweighted', 'Walk', '2014'] = mode_share_14_u['Walk, jog, or wheelchair']
#mode_share.loc['Unweighted', 'School Bus', '2014'] = mode_share_14_u['School bus']
#mode_share.loc['Unweighted', 'Other', '2014'] = mode_share_14_u['Other (e.g. skateboard, kayak, motor home, etc.)'] + mode_share_14_u['Airplane or helicopter']

for weighting in mode_share.items:
    mode_share[weighting]['Change'] = mode_share[weighting]['2014'] - mode_share[weighting]['2006']
    mode_share[weighting]['% Change'] = (mode_share[weighting]['Change'] / mode_share[weighting]['2006'] * 100).round(2)
    mode_share[weighting]['2006'] = mode_share[weighting]['2006'].round(2)
    mode_share[weighting]['2014'] = mode_share[weighting]['2014'].round(2)
    mode_share[weighting]['Change'] = mode_share[weighting]['Change'].round(2)


mode_share.to_excel(output_location + '/Mode_Share.xlsx')

HHPerTrip = HHPerTrip.query('gdist != "."')
HHPerTrip['gdist'] = HHPerTrip['gdist'].astype('float')


trip_lengths = {}
trip_lengths['Mode'] = pd.Panel4D(items = ['Distance', 'Time'], labels = ['Weighted', 'Unweighted'], minor_axis = years, major_axis = modes)

trip_lengths['Mode']['Weighted']['Distance']['2006'] = weighted_average(data_2006['Trip'], 'travdist', 'trexpfac', 'mode')
trip_lengths['Mode']['Weighted']['Time']['2006'] = weighted_average(data_2006['Trip'], 'travtime', 'trexpfac', 'mode')
trip_lengths['Mode']['Weighted']['Distance']['2014'] = weighted_average(HHPerTrip, 'gdist', 'expwt_final', 'mode')
trip_lengths['Mode']['Unweighted']['Distance']['2006'] = data_2006['Trip'].groupby('mode').mean()['travdist']
trip_lengths['Mode']['Unweighted']['Distance']['2014'] = HHPerTrip.groupby('mode').mean()['gdist']
    
trip_lengths['Mode']['Weighted']['Time']['2014'] = weighted_average(HHPerTrip, 'trip_dur_reported', 'expwt_final', 'mode')
trip_lengths['Mode']['Unweighted']['Time']['2006'] = data_2006['Trip'].groupby('mode').mean()['travtime']
trip_lengths['Mode']['Unweighted']['Time']['2014'] = HHPerTrip.groupby('mode').mean()['trip_dur_reported']
trip_lengths['Purpose'] = pd.Panel4D(items = ['Distance', 'Time'], labels = ['Weighted', 'Unweighted'], minor_axis = years, major_axis = purposes)
trip_lengths['Purpose']['Weighted']['Distance']['2006'] = weighted_average(data_2006['Trip'], 'travdist', 'trexpfac', 'dpurp')
trip_lengths['Purpose']['Weighted']['Distance']['2014'] = weighted_average(HHPerTrip, 'gdist', 'expwt_final', 'd_purpose')
trip_lengths['Purpose']['Unweighted']['Distance']['2006'] = data_2006['Trip'].groupby('dpurp').mean()['travdist']
trip_lengths['Purpose']['Unweighted']['Distance']['2014'] = HHPerTrip.groupby('d_purpose').mean()['gdist']
trip_lengths['Purpose']['Weighted']['Time']['2006'] = weighted_average(data_2006['Trip'], 'travtime', 'trexpfac', 'dpurp')
trip_lengths['Purpose']['Weighted']['Time']['2014'] = weighted_average(HHPerTrip, 'trip_dur_reported', 'expwt_final', 'd_purpose')
trip_lengths['Purpose']['Unweighted']['Time']['2006'] = data_2006['Trip'].groupby('dpurp').mean()['travtime']
trip_lengths['Purpose']['Unweighted']['Time']['2014'] = HHPerTrip.groupby('d_purpose').mean()['trip_dur_reported']

for grouping in trip_lengths:
    for weighting in ['Weighted', 'Unweighted']:
        for variable in ['Distance', 'Time']:
        
            trip_lengths[grouping][weighting][variable]['2006'] = trip_lengths[grouping][weighting][variable]['2006'].fillna(0)
            trip_lengths[grouping][weighting][variable]['2014'] = trip_lengths[grouping][weighting][variable]['2014'].fillna(0)
            trip_lengths[grouping][weighting][variable]['Change'] = trip_lengths[grouping][weighting][variable]['2014'] - trip_lengths[grouping][weighting][variable]['2006']
            trip_lengths[grouping][weighting][variable]['% Change'] = (trip_lengths[grouping][weighting][variable]['Change'] / trip_lengths[grouping][weighting][variable]['2006'] * 100).round(2)
            trip_lengths[grouping][weighting][variable]['2006'] = trip_lengths[grouping][weighting][variable]['2006'].round(2)
            trip_lengths[grouping][weighting][variable]['2014'] = trip_lengths[grouping][weighting][variable]['2014'].round(2)
            trip_lengths[grouping][weighting][variable]['Change'] = trip_lengths[grouping][weighting][variable]['Change'].round(2)                   
    trip_lengths[grouping]['Weighted'].to_excel('R:/JOE/Survey Summaries/Trip_Lengths_by_' + grouping + '.xlsx')

#dist_by_submode = weighted_average(HHPerTrip, 'gdist', 'expwt_final', 'mode')

rgc_map = {}
parcel_rgc = pd.DataFrame.from_csv('[PARCEL FILE]')
parcel_rgc = parcel_rgc.drop(0)
for parcel in parcel_rgc.index.tolist():
    rgc_map.update({parcel: parcel_rgc.loc[parcel, 'NAME']})
HHPer_2006 = pd.merge(data_2006['Household'], data_2006['Person'], on = 'hhno')
HHPerTrip_2006 = pd.merge(HHPer_2006, data_2006['Trip'], on = ['hhno', 'pno'])
HHPerTrip_2006 = HHPerTrip_2006.query('travdist > 0 and travdist < 200')
HHPerTrip_2006['rgc'] = HHPerTrip_2006['hhparcel'].map(rgc_map)
in_rgc_06 = HHPerTrip_2006[pd.isnull(HHPerTrip_2006['rgc']) == False]
out_rgc_06 = HHPerTrip_2006[pd.isnull(HHPerTrip_2006['rgc']) == True]

in_rgc_14 = HHPerTrip[pd.isnull(HHPerTrip['h_rgc_name']) == False]
out_rgc_14 = HHPerTrip[pd.isnull(HHPerTrip['h_rgc_name']) == True]
rgc_mode_share = pd.Panel4D(labels = ['Weighted', 'Unweighted'], items = ['In', 'Out', 'Difference', '% Difference'], minor_axis = years, major_axis = modes)
rgc_mode_share['Weighted']['In']['2014'] = (get_mode_share(in_rgc_14)).apply(remove_percent)
rgc_mode_share['Weighted']['Out']['2014'] = (get_mode_share(out_rgc_14)).apply(remove_percent)
rgc_mode_share['Unweighted']['In']['2014'] = (get_mode_share(in_rgc_14, weighted = False)).apply(remove_percent)
rgc_mode_share['Unweighted']['Out']['2014'] = (get_mode_share(out_rgc_14, weighted = False)).apply(remove_percent)
rgc_mode_share['Weighted']['In']['2006'] = (get_mode_share_06(in_rgc_06)).apply(remove_percent)
rgc_mode_share['Weighted']['Out']['2006'] = (get_mode_share_06(out_rgc_06)).apply(remove_percent)
rgc_mode_share['Unweighted']['In']['2006'] = (get_mode_share_06(in_rgc_06, weighted = False)).apply(remove_percent)
rgc_mode_share['Unweighted']['Out']['2006'] = (get_mode_share_06(out_rgc_06, weighted = False)).apply(remove_percent)
rgc_mode_share['Weighted']['Difference'] = rgc_mode_share['Weighted']['In'] - rgc_mode_share['Weighted']['Out']
rgc_mode_share['Weighted']['% Difference'] = rgc_mode_share['Weighted']['Difference'] / rgc_mode_share['Weighted']['Out'] * 100
rgc_mode_share['Unweighted']['Difference'] = rgc_mode_share['Unweighted']['In'] - rgc_mode_share['Unweighted']['Out']
rgc_mode_share['Unweighted']['% Difference'] = rgc_mode_share['Unweighted']['Difference'] / rgc_mode_share['Unweighted']['Out'] * 100
for weighting in ['Weighted', 'Unweighted']:
    for item in ['In', 'Out', 'Difference', '% Difference']:
        rgc_mode_share[weighting][item]['2006'] = rgc_mode_share[weighting][item]['2006'].fillna(0)
        rgc_mode_share[weighting][item]['2014'] = rgc_mode_share[weighting][item]['2014'].fillna(0)
        rgc_mode_share[weighting][item]['Change'] = rgc_mode_share[weighting][item]['2014'] - rgc_mode_share[weighting][item]['2006']
        rgc_mode_share[weighting][item]['% Change'] = (rgc_mode_share[weighting][item]['Change'] / rgc_mode_share[weighting][item]['2006'] * 100).round(2)
        rgc_mode_share[weighting][item]['2006'] = rgc_mode_share[weighting][item]['2006'].round(2)
        rgc_mode_share[weighting][item]['2014'] = rgc_mode_share[weighting][item]['2014'].round(2)
        rgc_mode_share[weighting][item]['Change'] = rgc_mode_share[weighting][item]['Change'].round(2)

rgc_mode_share['Weighted'].to_excel(output_location + '/Regional_Center_Mode_Share.xlsx')

HHPer_2006['rgc'] = HHPer_2006['hhparcel'].map(rgc_map)
per_in_rgc_14 = HHPer[pd.isnull(HHPer['h_rgc_name']) == False]['expwt_final'].sum()
per_out_rgc_14 = HHPer[pd.isnull(HHPer['h_rgc_name']) == True]['expwt_final'].sum()
per_in_rgc_06 = HHPer_2006[pd.isnull(HHPer_2006['rgc']) == False]['psexpfac'].sum()
per_out_rgc_06 = HHPer_2006[pd.isnull(HHPer_2006['rgc']) == True]['psexpfac'].sum()
percent_in_2006 = per_in_rgc_06 / (per_in_rgc_06 + per_out_rgc_06) * 100
percent_in_2014 = per_in_rgc_14 / (per_in_rgc_14 + per_out_rgc_14) * 100


#Comparing East Side/Seattle
district_map = {}
for taz in zone_district.index.tolist()[:3700]:
    #print taz
    district_map.update({taz: zone_district.loc[taz, 'New DistrictName']})
#HHPerTrip_2006['h_district'] = HHPerTrip_2006['hhtaz'].map(district_map)
#HHPerTrip_2006['w_district'] = HHPerTrip_2006['pwtaz'].map(district_map)
HHPerTrip_2006['o_district'] = HHPerTrip_2006['otaz'].map(district_map)
HHPerTrip_2006['d_district'] = HHPerTrip_2006['dtaz'].map(district_map)

omap = {}
dmap = {}
odf = pd.io.excel.read_excel('[ORIGINS FILE]')
ddf = pd.io.excel.read_excel('[DESTINATIONS FILE]')
odf['District'] = odf['TAZ'].map(district_map)
ddf['District'] = ddf['TAZ'].map(district_map)
for trip in odf.index.tolist():
    omap.update({odf.loc[trip, 'tripID']: odf.loc[trip, 'District']})
for trip in ddf.index.tolist():
    dmap.update({ddf.loc[trip, 'tripID']: ddf.loc[trip, 'District']})
HHPerTrip = HHPerTrip.reset_index()
HHPerTrip['o_district'] = HHPerTrip['tripID'].astype('float').map(omap)
HHPerTrip['d_district'] = HHPerTrip['tripID'].astype('float').map(dmap)

gb06 = HHPerTrip_2006[['o_district', 'd_district', 'trexpfac']].groupby(['o_district', 'd_district']).sum()
gb14 = HHPerTrip[['o_district', 'd_district', 'expwt_final']].groupby(['o_district', 'd_district']).sum()
gb06 = gb06.reset_index()
gb14 = gb14.reset_index()

dd06 = gb06.pivot(index = 'o_district', columns = 'd_district', values = 'trexpfac')
dd14 = gb14.pivot(index = 'o_district', columns = 'd_district', values = 'expwt_final')

from_east_side_06 = dd06.loc['East Side'] / dd06.loc['East Side'].sum() * 100
from_east_side_14 = dd14.loc['East Side'] / dd14.loc['East Side'].sum() * 100
from_east_side = pd.DataFrame.from_items([('2006', from_east_side_06), ('2014', from_east_side_14)])

transit_06 = HHPerTrip_2006.query('mode == "Transit"')
transit_14 = HHPerTrip.query('mode == "Transit"')

gb06_transit = transit_06[['o_district', 'd_district', 'trexpfac']].groupby(['o_district', 'd_district']).sum()
gb14_transit = transit_14[['o_district', 'd_district', 'expwt_final']].groupby(['o_district', 'd_district']).sum()
gb06_transit = gb06_transit.reset_index()
gb14_transit = gb14_transit.reset_index()

dd06_transit = gb06_transit.pivot(index = 'o_district', columns = 'd_district', values = 'trexpfac')
dd14_transit = gb14_transit.pivot(index = 'o_district', columns = 'd_district', values = 'expwt_final')

lengths_06 = weighted_average(transit_06, 'travdist', 'trexpfac', ['o_district', 'd_district'])
lengths_14 = weighted_average(transit_14, 'gdist', 'expwt_final', ['o_district', 'd_district'])

lengths_06 = pd.DataFrame.from_items([('2006', lengths_06)])
lengths_14 = pd.DataFrame.from_items([('2014', lengths_14)])
lengths_06 = lengths_06.reset_index()
lengths_14 = lengths_14.reset_index()

lengths_06 = lengths_06.pivot(index = 'o_district', columns = 'd_district', values = '2006')
lengths_14 = lengths_14.pivot(index = 'o_district', columns = 'd_district', values = '2014')

districts = lengths_06.index.tolist()

transit_lengths = pd.Panel(items = ['2006', '2014', 'Change', '% Change'], major_axis = districts, minor_axis = districts)
transit_lengths['2006'] = lengths_06
transit_lengths['2014'] = lengths_14
transit_lengths['Change'] = transit_lengths['2014'] - transit_lengths['2006']
transit_lengths['% Change'] = transit_lengths['Change'] / transit_lengths['2006'] * 100
transit_lengths.to_excel(output_location + '/transit_lengths_by_district.xlsx')

transit_trips = pd.Panel(items = ['2006', '2014', 'Change', '% Change'], major_axis = districts, minor_axis = districts)
transit_trips['2006'] = dd06_transit
transit_trips['2014'] = dd14_transit
transit_trips['Change'] = transit_trips['2014'] - transit_trips['2006']
transit_trips['% Change'] = transit_trips['Change'] / transit_trips['2006'] * 100
transit_trips.to_excel(output_location + '/transit_trips_by_district.xlsx')

ugb06_transit = transit_06[['o_district', 'd_district', 'trexpfac']].groupby(['o_district', 'd_district']).count()
ugb14_transit = transit_14[['o_district', 'd_district', 'expwt_final']].groupby(['o_district', 'd_district']).count()
ugb06_transit = ugb06_transit.reset_index()
ugb14_transit = ugb14_transit.reset_index()

udd06_transit = ugb06_transit.pivot(index = 'o_district', columns = 'd_district', values = 'trexpfac')
udd14_transit = ugb14_transit.pivot(index = 'o_district', columns = 'd_district', values = 'expwt_final')

transit_records = pd.Panel(items = ['2006', '2014', 'Change', '% Change'], major_axis = districts, minor_axis = districts)
transit_records['2006'] = udd06_transit
transit_records['2014'] = udd14_transit
transit_records['Change'] = transit_records['2014'] - transit_records['2006']
transit_records['% Change'] = transit_records['Change'] / transit_records['2006'] * 100
transit_records.to_excel(output_location + '/transit_records_by_district.xlsx')

#writer = pd.ExcelWriter('R:/JOE/Survey Summaries/HHPerTrip.xlsx', 'xlsxwriter')
#HHPerTrip_2006.to_excel(writer, '2006')
#HHPerTrip.to_excel(writer, '2014')
#writer.save()

print('Completed')

#for tmode in modes:
#    mode_06 = data_2006['Trip'].query('mode = @tmode')
