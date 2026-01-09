import pandas as pd
import numpy as np
import config

#household = process_survey.load_data(household_file)
def load_data(file):
    return pd.io.excel.read_excel(io=file[0], sheetname=file[1])

def join_hh2per(person_df, household_df):
    ''' Join household fields to each person record. Input is pandas dataframe '''
    return pd.merge(person_df, household_df, 
                    left_on=config.p_hhid, right_on=config.h_hhid, 
                    suffixes=('', '_hh'))

def join_hhper2trip(trip_df, hh_per_df):
    ''' Join person and household fields to trip records '''
    return pd.merge(trip_df, hh_per_df, 
                    left_on=config.t_personid, right_on=config.p_personid, 
                    suffixes=('_trip', '_p_hh'))

class Person:
    def __init__(self, df, nan_replace=True):
        self.df = df
        self.gender = df[config.p_gender].mean()
        self.numjobs = df[config.p_jobs_count].mean()
        self.worker = df[config.p_worker].mean()
        self.num_trips = df[config.p_numtrips].mean()                # Number of trips made on travel day (derived)
        if nan_replace:
            # Replace blank cells with NaN
            df.replace(' ', np.nan, inplace=True)

    def pivot_table(self, rows, columns):
        return pd.pivot_table(self.db, values=config.p_exp_wt, 
                              rows=rows, columns=columns, aggfunc=np.sum)

    # Commute Factors
    def wbt_transitsafety(self, segmentation):
        ''' Would walk, bike or ride transit more if: 
        Safer ways to get to transit stops (e.g. more sidewalks, lighting, etc.) '''
        return pd.pivot_table(self.df, values=config.p_exp_wt, rows=segmentation, 
                                    columns='wbt_transitsafety', aggfunc=np.sum)

    def wbt_transitfreq(self, segmentation):
        ''' Would walk, bike or ride transit more if: 
        Increased frequency of transit (e.g. how often the bus arrives) '''
        return pd.pivot_table(self.df, values=config.p_exp_wt, rows=segmentation, 
                                    columns='wbt_transitfreq', aggfunc=np.sum)

    def wbt_reliability(self, segmentation):
        ''' Would walk, bike or ride transit more if: 
        Increased reliability of transit (e.g. the bus always arrives at exactly the scheduled time) '''
        return pd.pivot_table(self.df, values=config.p_exp_wt, rows=segmentation, 
                                    columns='wbt_reliability', aggfunc=np.sum)

    def wbt_bikesafety(self, segmentation):
        ''' Would walk, bike or ride transit more if: 
        Safer bicycle routes (e.g. protected bike lanes) '''
        return pd.pivot_table(self.df, values=config.p_exp_wt, rows=segmentation, 
                                    columns='wbt_reliability', aggfunc=np.sum)

    def wbt_walksafety(self, segmentation):
        ''' Would walk, bike or ride transit more if: 
        Safer walking routes (e.g. more sidewalks, protected crossings, etc.) '''
        return pd.pivot_table(self.df, values=config.p_exp_wt, rows=segmentation, 
                                    columns='wbt_walksafety', aggfunc=np.sum)

    def wbt_other(self, segmentation):
        ''' Would walk, bike or ride transit more if: Other '''
        return pd.pivot_table(self.df, values=config.p_exp_wt, rows=segmentation, 
                                    columns='wbt_other', aggfunc=np.sum)

    def wbt_none(self, segmentation):
        ''' Would walk, bike or ride transit more if: 
        None of these would get me to walk, bike, and/or take transit more '''
        return pd.pivot_table(self.df, values=config.p_exp_wt, rows=segmentation, 
                                    columns='wbt_none', aggfunc=np.sum)

    def wbt_na(self, segmentation):
        ''' Would walk, bike or ride transit more if: 
        Not applicable  I already regularly walk, bike, and/or take transit '''
        return pd.pivot_table(self.df, values=config.p_exp_wt, rows=segmentation, 
                                    columns='wbt_na', aggfunc=np.sum)



class Household:
    def __init__(self, df):
        self.hhsize = df[config.h_hhsize].mean()                     # Household size
        self.numadults = df[config.h_numadults].mean()               # Number of adults
        self.numchildren = df[config.h_numchildren].mean()           # Number of children
        self.numworkers = df[config.h_numworkers].mean()             # Number of workers
        self.hhnumtrips = df[config.h_numtrips].mean()               # Household number of trips on travel day (derived)
        self.vehicle_count = df[config.h_veh_count].mean()                  # Number of vehicles
        self.income = df.groupby(config.h_income_det_imp)[config.h_exp_wt].count() # Income classes

class Trip:
    def __init__(self, df):
        self.tripdur = df['trip_dur_reported']


def clip(file):
    ''' Send to clipboard for pasting into Excel '''
    file.to_clipboard()

def main():
    pass

if __name__ == '__main__':
    main()