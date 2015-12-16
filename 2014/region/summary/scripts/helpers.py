# This code contains various helper functions used to process household survey data with pandas

import pandas as pd
import numpy as np
import time
import h5toDF
import imp
import scipy.stats as stats
import math

def round_add_percent(number): 
    ''' Rounds a floating point number and adds a percent sign '''
    if type(number) == str or type(number) == None:
        raise ValueError("Not float type, cannot process")
    outnumber = str(round(number, 2)) + '%'
    return outnumber

def remove_percent(input = str): 
    ''' Removes a percent sign at the end of a string to get a number '''
    if input[len(input) - 1] != '%':
        raise TypeError("No percent string present")
    try:
        output = float(input[:len(input) - 1])
        return output
    except ValueError:
        raise TypeError("Woah, " + input + "'s not going to work. I need a string where everything other than the last character could be a floating point number.")

#Functions based on formulas at http://www.nematrian.com/R.aspx?p=WeightedMomentsAndCumulants

def weighted_variance(df_in, col, weights):
    wa = weighted_average(df_in, col, weights)
    df_in['sp'] = df_in[weights] * (df_in[col] - wa) ** 2
    n_out = df_in['sp'].sum() / df_in[weights].sum()
    return n_out

def weighted_skew(df_in, col, weights):
    wa = weighted_average(df_in, col, weights)
    wv = weighted_variance(df_in, col, weights)
    df_in['sp'] = df_in[weights] * ((df_in[col] - wa) / (math.sqrt(wv))) ** 3
    n_out = df_in['sp'].sum() / df_in[weights].sum()
    return n_out

def weighted_kurtosis(df_in, col, weights, excess = True): #Gives the excess kurtosis
    wa = weighted_average(df_in, col, weights)
    wv = weighted_variance(df_in, col, weights)
    df_in['sp'] = df_in[weights] * ((df_in[col] - wa) / (math.sqrt(wv))) ** 4
    if excess:
        n_out = df_in['sp'].sum() / df_in[weights].sum() - 3
    else:
        n_out = df_in['sp'].sum() / df_in[weights].sum()
    return n_out

def recode_index(df,old_name,new_name): #Recodes index
   df[new_name]=df.index
   df=df.reset_index()
   del df[old_name]
   df=df.set_index(new_name)
   return df

def min_to_hour(input, base): #Converts minutes since a certain time of the day to hour of the day
    timemap = {}
    for i in range(0, 24):
        if i + base < 24:
            for j in range(0, 60):
                if i + base < 9:
                    timemap.update({i * 60 + j: '0' + str(i + base) + ' - 0' + str(i + base + 1)})
                elif i + base == 9:
                    timemap.update({i * 60 + j: '0' + str(i + base) + ' - ' + str(i + base + 1)})
                else:
                    timemap.update({i * 60 + j: str(i + base) + ' - ' + str(i + base + 1)})
        else:
            for j in range(0, 60):
                if i + base - 24 < 9:
                    timemap.update({i * 60 + j: '0' + str(i + base - 24) + ' - 0' + str(i + base - 23)})
                elif i + base - 24 == 9:
                    timemap.update({i * 60 + j: '0' + str(i + base - 24) + ' - ' + str(i + base - 23)})
                else:
                    timemap.update({i * 60 + j:str(i + base - 24) + ' - ' + str(i + base - 23)})
    output = input.map(timemap)
    return output

def all_same(items): #Checks if all of the items in a list or list-like object are the same
    return all(x == items[0] for x in items)

def to_percent(y, position): #Converts a number to a percent
    global found
    if found:
        # Ignore the passed in position. This has the effect of scaling the default
        # tick locations.
        s = str(100 * y)

        # The percent symbol needs escaping in latex
        if matplotlib.rcParams['text.usetex'] == True:
            return s + r'$\%$'
        else:
            return s + '%'
    else:
        print('No matplotlib')
        return 100 * y

def variable_guide(guide_file):
    ''' loads a categorical variable dictionary as a dataframe. '''
    guide = h5toDF.get_guide(guide_file)
    return h5toDF.guide_to_dict(guide)

def load_survey_sheet(file_loc, sheetname):
    ''' load excel worksheet into dataframe, specified by sheetname '''
    return pd.io.excel.read_excel(file_loc, sheetname=sheetname)