# -*- coding: utf-8 -*-
"""
Created on Wed Dec 29 14:39:54 2021

@author: haozheyang
"""

import os
os.chdir("H:/Renewable Equal/simulation")

from IPython import get_ipython
get_ipython().magic('reset -sf')

import numpy as np
from temporal_function import generate_period,generate_horizon_params,generate_horizon_timepoint, generate_structure

#create period
period_gap=10
start_year=np.arange(2050,2055,10)
discount=0.07

file='C:/Program Files/GRIDPATH/db/csvs_power_pool/temporal/4_global_3period/'
period_params=generate_period(start_year, period_gap,discount)
period_params.to_csv(file+'period_params.csv',index=False)

#horizon params
month=12
day_in_month=[31,28,31,30,31,30,31,31,30,31,30,31]
#day_in_month=[2,2,2,2,2,2,2,2,2,2,2,2]
subproblem='capacity_expansion'
linkage_option='circular'
horizon_params=generate_horizon_params(start_year, subproblem, month, day_in_month, linkage_option)
horizon_params.to_csv(file+'horizon_params.csv',index=False)

#create  horizon_timepoints
timepoint_option=8  
stage_option=1
horizon_timepoints=generate_horizon_timepoint(timepoint_option, horizon_params, stage_option, day_in_month)
horizon_timepoints.to_csv(file+'horizon_timepoints.csv',index=False)

#create structure.csv
peak=0
structure=generate_structure(timepoint_option,month,horizon_timepoints,horizon_params,period_params,stage_option,day_in_month,peak)
structure.to_csv(file+'structure.csv',index=False)

