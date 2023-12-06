# -*- coding: utf-8 -*-
"""
Created on Sat Aug  6 16:26:52 2022

@author: haozheyang
"""

from IPython import get_ipython
get_ipython().magic('reset -sf')

import os
os.chdir("//babylon/phd/haozheyang/SAPP")

import pandas as pd
import glob

def generate_specified_capacity(cluster):
    project_specified_capacity=pd.DataFrame({
        'project':cluster.project,
        'period': cluster.period,
        'specified_capacity_mw': cluster.capacity_mw,
        'hyb_gen_specified_capacity_mw':"",
        'hyb_stor_specified_capacity_mw':"",
        'specified_capacity_mwh': cluster.capacity_mwh
        })
    
    project_specified_capacity=project_specified_capacity.fillna("")            
    return project_specified_capacity

def generate_specified_transmission_capacity(cluster):
    project_specified_transmission_capacity=pd.DataFrame({
        'transmission_line':cluster.tx_line,
        'period': cluster.period,
        'min_mw': cluster.transmission_min_capacity_mw,	
        'max_mw': cluster.transmission_max_capacity_mw
        })
    
    project_specified_transmission_capacity=project_specified_transmission_capacity.fillna("")            
    return project_specified_transmission_capacity
#%%
for file_id, file in enumerate(
        sorted(glob.glob('C:/Program Files/GRIDPATH/db/csvs_power_pool/project/project_portfolios/'+'*.csv'),key=lambda x:int(x.split('\\')[-1].split('_')[0]))
        ):
    portfolio=pd.read_csv(file)
    file2=file.split('_')[-1]
    portfolio.loc[portfolio.capacity_type.isin(['gen_new_bin','gen_new_lin']),'capacity_type']='gen_spec'
    portfolio.loc[portfolio.capacity_type=='stor_new_lin','capacity_type']='stor_spec'
    portfolio.to_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/project/project_portfolios/'+str(file_id+22)+'_fixed_capacity_'+file2,index=False)
#%%
for file_id, file in enumerate(
        sorted(glob.glob('C:/Program Files/GRIDPATH/db/csvs_power_pool/transmission/transmission_portfolios/'+'*.csv'),key=lambda x:int(x.split('\\')[-1].split('_')[0]))
        ):
    if file_id<20:
        transmission_portfolio=pd.read_csv(file)
        file2=file.split('_')[-1]
        transmission_portfolio['capacity_type']='tx_spec'
        transmission_portfolio.to_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/transmission/transmission_portfolios/'+str(file_id+21)+'_fixed_capacity_'+file2,index=False)
    else:
        continue
#%%
path='G:/My Drive/renewable/'
#scenario=['country','pool_Africa','pool_Asia','pool_Europe','pool_NorthAmerica','pool_SouthAmerica','pool_SoutheastAsia',
#          'country_NZE','pool_Africa_NZE','pool_Asia_NZE','pool_Europe_NZE','pool_NorthAmerica_NZE','pool_SouthAmerica_NZE','pool_SoutheastAsia_NZE',
#          'country_25','pool_Africa_25','pool_Asia_25','pool_Europe_25','pool_NorthAmerica_25','pool_SouthAmerica_25','pool_SoutheastAsia_25',
#          'country_prm_10','pool_Africa_prm_10','pool_Asia_prm_10','pool_Europe_prm_10','pool_NorthAmerica_prm_10','pool_SouthAmerica_prm_10','pool_SoutheastAsia_prm_10']

scenario=['country','pool_Africa','pool_Asia','pool_Europe','pool_NorthAmerica','pool_SouthAmerica','pool_SoutheastAsia',
          'country_25','pool_Africa_25','pool_Asia_25','pool_Europe_25','pool_NorthAmerica_25','pool_SouthAmerica_25','pool_SoutheastAsia_25',
           'country_100','pool_Africa_100','pool_Asia_100','pool_Europe_100','pool_NorthAmerica_100','pool_SouthAmerica_100','pool_SoutheastAsia_100',
          'country_NZE','pool_Africa_NZE','pool_Asia_NZE','pool_Europe_NZE','pool_NorthAmerica_NZE','pool_SouthAmerica_NZE','pool_SoutheastAsia_NZE',
          'country_25_NZE','pool_Africa_25_NZE','pool_Asia_25_NZE','pool_Europe_25_NZE','pool_NorthAmerica_25_NZE','pool_SouthAmerica_25_NZE','pool_SoutheastAsia_25_NZE',
          'country_100_NZE','pool_Africa_100_NZE','pool_Asia_100_NZE','pool_Europe_100_NZE','pool_NorthAmerica_100_NZE','pool_SouthAmerica_100_NZE','pool_SoutheastAsia_100_NZE',]


scenario=['country_3','pool_Africa_3','pool_Asia_3','pool_Europe_3','pool_NorthAmerica_3','pool_SouthAmerica_3','pool_SoutheastAsia_3',
           'country_3_100','pool_Africa_3_100','pool_Asia_3_100','pool_Europe_3_100','pool_NorthAmerica_3_100','pool_SouthAmerica_3_100','pool_SoutheastAsia_3_100']

for i_id,i in enumerate(scenario):
    cluster=pd.read_csv(path+i+'/results/capacity_all.csv')
    #cluster_id=int(i.split('_')[0].split('\\')[1])
    #cluster_des='_'.join(i.split('_')[1:])
    cluster_des=i
    #cluster_des='env_hbau'
    project_specified_capacity=generate_specified_capacity(cluster)
    project_specified_capacity=project_specified_capacity.sort_values(by=['project','period'])
    project_specified_capacity.to_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/project/project_specified_capacity/'+str(i_id+46)+'_project_existing_capacity_'+cluster_des+'.csv',index=False)
#%%
'''
scenario=['pool_Africa','pool_Asia','pool_Europe','pool_NorthAmerica','pool_SouthAmerica','pool_SoutheastAsia',
          'pool_Africa_NZE','pool_Asia_NZE','pool_Europe_NZE','pool_NorthAmerica_NZE','pool_SouthAmerica_NZE','pool_SoutheastAsia_NZE',
          'pool_Africa_25','pool_Asia_25','pool_Europe_25','pool_NorthAmerica_25','pool_SouthAmerica_25','pool_SoutheastAsia_25',
          'pool_Africa_prm_10','pool_Asia_prm_10','pool_Europe_prm_10','pool_NorthAmerica_prm_10','pool_SouthAmerica_prm_10','pool_SoutheastAsia_prm_10']

scenario=['pool_Africa','pool_Asia','pool_Europe','pool_NorthAmerica','pool_SouthAmerica','pool_SoutheastAsia',
          'pool_Africa_25','pool_Asia_25','pool_Europe_25','pool_NorthAmerica_25','pool_SouthAmerica_25','pool_SoutheastAsia_25',
          'pool_Africa_100','pool_Asia_100','pool_Europe_100','pool_NorthAmerica_100','pool_SouthAmerica_100','pool_SoutheastAsia_100',
          'pool_Africa_NZE','pool_Asia_NZE','pool_Europe_NZE','pool_NorthAmerica_NZE','pool_SouthAmerica_NZE','pool_SoutheastAsia_NZE',
          'pool_Africa_25_NZE','pool_Asia_25_NZE','pool_Europe_25_NZE','pool_NorthAmerica_25_NZE','pool_SouthAmerica_25_NZE','pool_SoutheastAsia_25_NZE',
          'pool_Africa_100_NZE','pool_Asia_100_NZE','pool_Europe_100_NZE','pool_NorthAmerica_100_NZE','pool_SouthAmerica_100_NZE','pool_SoutheastAsia_100_NZE']
'''
scenario=['pool_Africa_3','pool_Asia_3','pool_Europe_3','pool_NorthAmerica_3','pool_SouthAmerica_3','pool_SoutheastAsia_3',
           'pool_Africa_3_100','pool_Asia_3_100','pool_Europe_3_100','pool_NorthAmerica_3_100','pool_SouthAmerica_3_100','pool_SoutheastAsia_3_100']

for transmission_id,i in enumerate(scenario):
    transmission=pd.read_csv(path+i+'/results/transmission_capacity.csv')
    #transmission_id=int(i.split('_')[0].split('\\')[1])
    transmission_des='_'.join(i.split('_')[1:])
    project_specified_transmission_capacity=generate_specified_transmission_capacity(transmission)
    project_specified_transmission_capacity=project_specified_transmission_capacity.sort_values(by=['transmission_line','period'])
    project_specified_transmission_capacity.to_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/transmission/transmission_specified_capacity/'+str(transmission_id+38)+'_transmission_capacity_'+transmission_des+'.csv',index=False)
#%%

project_new_cost=pd.read_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/project/project_new_cost/'+str(3)+'_moderate'+'.csv')
project_new_cost_2_specified=project_new_cost[['project','vintage','annualized_real_cost_per_mw_yr','annualized_real_cost_per_mwh_yr']]
project_new_cost_2_specified=project_new_cost_2_specified.rename(columns={
        'vintage':'period',
        'annualized_real_cost_per_mw_yr':'fixed_cost_per_mw_year',
        'annualized_real_cost_per_mwh_yr': 'fixed_cost_per_mwh_year'
        })
project_specified_cost=pd.read_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/project/project_specified_fixed_cost/3_moderate'+'.csv')
project_specified_cost=project_specified_cost.append(project_new_cost_2_specified)
project_specified_cost.to_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/project/project_specified_fixed_cost/'+str(4)+'_project_fixed_cost_'+'new_cost_'+str(100)+'.csv',index=False)
