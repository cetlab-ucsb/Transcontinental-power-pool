# -*- coding: utf-8 -*-
"""
Created on Sat Oct 15 12:45:16 2022

@author: haozheyang
"""


from IPython import get_ipython
get_ipython().magic('reset -sf')

import os
os.chdir("H:/Renewable Equal/simulation")

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
#unserved load BAU and fixed scenario
main_path='G:/My Drive/renewable/'

respath = main_path

output='no'

supergrid=pd.read_excel('country_ISO3.xlsx',sheet_name='pool')
period=pd.read_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/temporal/3_global_3period/period_params.csv')[['period','discount_factor']]

#%%
sc=['country_3_full']
load_balance=pd.DataFrame()

for i,scenario in enumerate(sc):
    load=pd.read_csv(respath+scenario+'/results/load_balance.csv')
    load['unserved_energy_mwh']=load.timepoint_weight*load.unserved_energy_mw
    load['load_mwh']=load.timepoint_weight*load.load_mw
    load_summary=load.groupby(['period','zone'])[['unserved_energy_mwh','load_mwh']].sum().reset_index()
    load_summary['scenario']=scenario
    load_balance=load_balance.append(load_summary)
load_balance_2050=load_balance.loc[load_balance.period==2050,:] 

if output=='yes':
    load_balance_2050.to_csv('result_analysis/load_balance_country_fixed.csv',index=False)
#%%curtailment
curtailment=pd.DataFrame()
for i,scenario in enumerate(sc):
    curtail=pd.read_csv(respath+scenario+'/results/dispatch_variable.csv').merge(period,how='left') 
    curtail['curtail_mwh']=curtail.timepoint_weight*curtail.total_curtailment_mw
    curtail_summary=curtail.groupby(['load_zone','period'])[['curtail_mwh']].sum().reset_index()
    curtail_summary['scenario']=scenario
    curtailment=curtailment.append(curtail_summary)
    
    curtail_tech_country=curtail.groupby(['load_zone'])[['curtail_mwh']].sum().reset_index()
#%%
generation=pd.DataFrame()
dispatch_tech=pd.DataFrame()
for i,scenario in enumerate(sc):
    dispatch=pd.read_csv(respath+scenario+'/results/dispatch_all.csv').merge(period,how='left') 
    dispatch['power_mwh']=dispatch.timepoint_weight*dispatch.power_mw
    dispatch['power_mwh_npv']=dispatch.timepoint_weight*dispatch.power_mw*dispatch['discount_factor']
    dispatch_summary=dispatch.groupby(['load_zone','period'])[['power_mwh','power_mwh_npv']].sum().reset_index()
    dispatch_summary['scenario']=scenario
    generation=generation.append(dispatch_summary)
    
    dispatch_tech_summary=dispatch.groupby(['load_zone','technology'])[['power_mwh','power_mwh_npv']].sum().reset_index()
    dispatch_tech=dispatch_tech.append(dispatch_tech_summary)

generation=generation.sort_values(by='load_zone') 
#%% average_cost
#period['discount_factor']=period['discount_factor']*1/(1+0.07)**10

capital_cost=pd.DataFrame()
for i,scenario in enumerate(sc):
    capital=pd.read_csv(respath+scenario+'/results/costs_capacity_all_projects.csv').merge(period,how='left') 
    capital['capacity_cost']=capital['capacity_cost']*capital['discount_factor']
    capital_summary=capital.groupby(['load_zone','period'])['capacity_cost'].sum().reset_index()
    capital_summary['scenario']=scenario
    capital_cost=capital_cost.append(capital_summary) 
    
    capital_tech_summary=capital.groupby(['load_zone','technology'])['capacity_cost'].sum().reset_index()
    
print(capital_cost['capacity_cost'].sum())    
#%%
operation_cost=pd.DataFrame()
for i,scenario in enumerate(sc):
    operation=pd.read_csv(respath+scenario+'/results/costs_operations.csv').merge(period,how='left')
    operation['operation_cost']=operation['timepoint_weight']*operation['variable_om_cost']*operation['discount_factor']
    operation_summary=operation.groupby(['load_zone','period'])['operation_cost'].sum().reset_index()
    operation_summary['scenario']=scenario
    operation_cost=operation_cost.append(operation_summary)
    
    operation_tech_summary=operation.groupby(['load_zone','technology'])['operation_cost'].sum().reset_index()
    
print(operation_cost['operation_cost'].sum())    

#%%
penalty=pd.read_excel('result_analysis/penalty.xlsx').melt(id_vars='load_zone',var_name='period',value_name='penalty_mwh')
load_balance['production']=load_balance['load_mwh']-load_balance['unserved_energy_mwh']
load_balance=load_balance.merge(period,how='left')
load_balance['load_mwh_npv']=load_balance['load_mwh']*load_balance['discount_factor']
load_balance=load_balance.merge(penalty,how='left',left_on=['zone','period'],right_on=['load_zone','period'])
#load_balance=load_balance.merge(period,how='left')

load_balance['penalty_cost']=load_balance['unserved_energy_mwh']*load_balance['penalty_mwh']
load_balance_all_period=load_balance.groupby(['zone'])[['production','penalty_cost','load_mwh','load_mwh_npv']].sum().reset_index()
#*load_balance['discount_factor']
#%%
cost_country=pd.merge(capital_cost,operation_cost)
cost_country=pd.merge(cost_country,curtailment,how='left')
cost_country=pd.merge(cost_country,supergrid,how='left',left_on=['load_zone'],right_on=['ISO3'])
cost_country=cost_country.merge(load_balance,left_on=['load_zone','period'],right_on=['load_zone','period'])
cost_country['total_cost']=cost_country.penalty_cost+cost_country.capacity_cost+cost_country.operation_cost
cost_country=cost_country.rename(columns={'total_cost':'country_cost'})

cost_group_country=cost_country.groupby(['pool'])[['country_cost','production','load_mwh','load_mwh_npv','curtail_mwh']].sum().reset_index()
cost_group_country['levelized']=cost_group_country.country_cost/cost_group_country.load_mwh_npv

cost_country_all_period=cost_country.groupby(['load_zone','pool'])[['production','load_mwh','load_mwh_npv','curtail_mwh','country_cost']].sum().reset_index()
cost_country_all_period['levelized_country']=cost_country_all_period.country_cost/cost_country_all_period.load_mwh_npv

if output=='yes':
    cost_country_all_period[['load_zone','pool','production','load_mwh','curtail_mwh','country_cost','levelized_country']].to_excel('result_analysis/country_scenario_8760.xlsx',index=False)
#%%
cost_tech_country=pd.merge(capital_tech_summary,operation_tech_summary)
cost_tech_country['total_cost']=cost_tech_country.capacity_cost+cost_tech_country.operation_cost
cost_tech_country=cost_tech_country[['load_zone','technology','total_cost']]

load_balance_all_period2=load_balance_all_period.copy()
load_balance_all_period2=load_balance_all_period2.rename(columns={'zone':'load_zone',
                                                                  'penalty_cost':'total_cost',
                                                                  })

load_balance_all_period2['technology']='penalty'

cost_tech_country=cost_tech_country.append(load_balance_all_period2[['load_zone','technology','total_cost']],ignore_index=True)
cost_tech_country=pd.merge(cost_tech_country,supergrid,how='left',left_on=['load_zone'],right_on=['ISO3'])

#cost_tech=cost_tech.sort_values(by=['load_zone','levelized'])
#cost_tech_generation=cost_tech.groupby(['pool'])[['power_mwh']].sum().reset_index().rename(columns={'power_mwh':'total_mwh'})
cost_tech_group_country=cost_tech_country.groupby(['pool','technology'])[['total_cost']].sum().reset_index()
cost_tech_group_country=cost_tech_group_country.merge(cost_group_country[['pool','load_mwh','load_mwh_npv']],how='left')
cost_tech_group_country['level']=cost_tech_group_country.total_cost/cost_tech_group_country.load_mwh_npv
cost_tech_group_table_country=cost_tech_group_country.pivot(index='pool',columns='technology',values='level')
if output=='yes':
    cost_tech_group_table_country.to_excel('result_analysis/country_cost_8760.xlsx')
#%%

sc1=['pool_Africa_3_fixed','pool_Asia_3_fixed','pool_Europe_3_fixed','pool_NorthAmerica_3_fixed','pool_SouthAmerica_3_fixed','pool_SoutheastAsia_3_fixed']
#outpath = main_path + 'results_scs/plots_stats/paper3_v1/'

# Core scenarios
#%%check load_balance

load_balance=pd.DataFrame()

for i,scenario in enumerate(sc1):
    load=pd.read_csv(respath+scenario+'/results/load_balance.csv')
    load['unserved_energy_mwh']=load.timepoint_weight*load.unserved_energy_mw
    load['load_mwh']=load.timepoint_weight*load.load_mw
    load_summary=load.groupby(['period','zone'])[['unserved_energy_mwh','load_mwh']].sum().reset_index()
    load_summary['scenario']=scenario
    load_balance=load_balance.append(load_summary)
    print(load_summary.unserved_energy_mwh.sum())
load_balance_2050=load_balance.loc[load_balance.period==2050,:]

if output=='yes':
    load_balance_2050.to_csv('result_analysis/load_balance_pool_fixed.csv',index=False)

#%%
generation=pd.DataFrame()
dispatch_tech=pd.DataFrame()
for i,scenario in enumerate(sc1):
    dispatch=pd.read_csv(respath+scenario+'/results/dispatch_all.csv').merge(period,how='left') 
    dispatch['power_mwh']=dispatch.timepoint_weight*dispatch.power_mw
    dispatch['power_mwh_npv']=dispatch.timepoint_weight*dispatch.power_mw*dispatch['discount_factor']
    dispatch_summary=dispatch.groupby(['load_zone','period'])[['power_mwh','power_mwh_npv']].sum().reset_index()
    dispatch_summary['scenario']=scenario
    generation=generation.append(dispatch_summary)
    
    dispatch_tech_summary=dispatch.groupby(['load_zone','technology'])[['power_mwh','power_mwh_npv']].sum().reset_index()
    dispatch_tech=dispatch_tech.append(dispatch_tech_summary)

generation=generation.sort_values(by='load_zone')
#%%curtailment
curtailment=pd.DataFrame()
for i,scenario in enumerate(sc1):
    curtail=pd.read_csv(respath+scenario+'/results/dispatch_variable.csv').merge(period,how='left') 
    curtail['curtail_mwh']=curtail.timepoint_weight*curtail.total_curtailment_mw
    curtail_summary=curtail.groupby(['load_zone','period'])[['curtail_mwh']].sum().reset_index()
    curtail_summary['scenario']=scenario
    curtailment=curtailment.append(curtail_summary)
    
    curtail_tech_country=curtail.groupby(['load_zone'])[['curtail_mwh']].sum().reset_index()
 
#%% average_cost
#period['discount_factor']=period['discount_factor']*1/(1+0.07)**10

capital_cost=pd.DataFrame()
capital_tech_cost=pd.DataFrame()
for i,scenario in enumerate(sc1):
    capital=pd.read_csv(respath+scenario+'/results/costs_capacity_all_projects.csv').merge(period,how='left') 
    capital['capacity_cost']=capital['capacity_cost']*capital['discount_factor']
    capital_summary=capital.groupby(['load_zone','period'])['capacity_cost'].sum().reset_index()
    capital_summary['scenario']=scenario
    
    capital_tech_summary=capital.groupby(['load_zone','technology'])['capacity_cost'].sum().reset_index()
    capital_tech_summary['scenario']=scenario
    
    capital_cost=capital_cost.append(capital_summary)
    capital_tech_cost=capital_tech_cost.append(capital_tech_summary)
    
print(capital_cost['capacity_cost'].sum())    
#%%
operation_cost=pd.DataFrame()   
operation_tech_cost=pd.DataFrame()
for i,scenario in enumerate(sc1):
    operation=pd.read_csv(respath+scenario+'/results/costs_operations.csv').merge(period,how='left')
    operation['operation_cost']=operation['timepoint_weight']*operation['variable_om_cost']*operation['discount_factor']
    operation_summary=operation.groupby(['load_zone','period'])['operation_cost'].sum().reset_index()
    operation_summary['scenario']=scenario
    operation_cost=operation_cost.append(operation_summary)  

    operation_tech_summary=operation.groupby(['load_zone','technology'])['operation_cost'].sum().reset_index()
    operation_tech_summary['scenario']=scenario
    operation_tech_cost=operation_tech_cost.append(operation_tech_summary)
    
print(operation_cost['operation_cost'].sum())    
    
#%%transmission cost
transmission_cost=pd.DataFrame()

#transmission_new_cost=pd.read_csv('result_analysis/1_transmission_new_cost_pool.csv').rename(columns={"transmission_line":"tx_line",
#                                                                                                      "vintage":'period'})
sc2=['pool_Africa_3','pool_Asia_3','pool_Europe_3','pool_NorthAmerica_3','pool_SouthAmerica_3','pool_SoutheastAsia_3']

for i,scenario in enumerate(sc2):
    
    transmission=pd.read_csv(respath+scenario+'/results/costs_transmission_capacity.csv').merge(period,how='left')
    transmission['transmission_cost']=transmission['capacity_cost']*transmission['discount_factor']
    transmission_summary=transmission.groupby('period')['transmission_cost'].sum().reset_index()
    scenario1=scenario+'_fixed'
    transmission_summary['scenario']=scenario1
    transmission_cost=transmission_cost.append(transmission_summary)
    '''
    transmission=pd.read_csv(respath+scenario+'/results/transmission_operations.csv')
    transmission['transmission_flow_abs']=transmission['transmission_flow_mw'].abs()
    transmission_max=transmission.groupby(['tx_line','period'])['transmission_flow_abs'].max().reset_index()
    transmission_max=transmission_max.merge(transmission_new_cost,how='left')
    
    transmission_2030=transmission_max.loc[transmission_max.period==2030,:].rename(columns={"transmission_flow_abs": "flow_2030"})
    transmission_2040=transmission_max.loc[transmission_max.period==2040,:].rename(columns={"transmission_flow_abs": "flow_2040"})
    transmission_2050=transmission_max.loc[transmission_max.period==2050,:].rename(columns={"transmission_flow_abs": "flow_2050"})
    
    transmission_period=pd.merge(transmission_2030,transmission_2040,how='outer',left_on=['tx_line'],right_on=['tx_line'])
    transmission_period=pd.merge(transmission_period,transmission_2050,how='outer',left_on=['tx_line'],right_on=['tx_line'])
    
    transmission_period['build_2030']=transmission_period.flow_2030
    transmission_period['build_2040']=transmission_period.flow_2040-transmission_period.flow_2030
    transmission_period['build_2050']=transmission_period.flow_2050-transmission_period[['flow_2030','flow_2040']].max(axis=1)
    transmission_period.loc[transmission_period.build_2040<0,'build_2040']=0
    transmission_period.loc[transmission_period.build_2050<0,'build_2050']=0
    
    transmission_period=transmission_period[['tx_line','build_2030','build_2040','build_2050','tx_annualized_real_cost_per_mw_yr']]
    transmission_cost_tmp=transmission_period['tx_annualized_real_cost_per_mw_yr']*(transmission_period.build_2030*period['discount_factor'][0]
                                                                                    +transmission_period.build_2040*period['discount_factor'][1]
                                                                                    +transmission_period.build_2050*period['discount_factor'][2])
    transmission_cost_tmp=transmission_cost_tmp.sum()   
    transmission_cost=transmission_cost.append(pd.DataFrame({
        'pool': [scenario],
        'transmission_cost': transmission_cost_tmp
        })
        )
    '''
    
#%%

#penalty=pd.read_excel('result_analysis/penalty.xlsx')
load_balance['production']=load_balance['load_mwh']-load_balance['unserved_energy_mwh']
load_balance=load_balance.merge(penalty,how='left',left_on=['zone','period'],right_on=['load_zone','period'])
#load_balance=load_balance.merge(period,how='left')
load_balance=load_balance.merge(period,how='left')
load_balance['load_mwh_npv']=load_balance['load_mwh']*load_balance['discount_factor']

load_balance['penalty_cost']=load_balance['unserved_energy_mwh']*load_balance['penalty_mwh']
#*load_balance['discount_factor']
load_balance_all_period=load_balance.groupby(['zone','scenario'])[['production','penalty_cost','load_mwh','load_mwh_npv']].sum().reset_index()
load_balance_all_period_region=load_balance.groupby(['scenario','period'])[['production','penalty_cost','load_mwh']].sum().reset_index()

#%%
cost=pd.merge(capital_cost,operation_cost)
cost=cost.merge(generation)
cost=pd.merge(cost,curtailment,how='left')
#cost=pd.merge(cost,supergrid,how='left',left_on=['load_zone'],right_on=['ISO3'])
cost=cost.merge(load_balance[['period','load_zone','production','load_mwh','load_mwh_npv','penalty_cost']])
cost['total_cost']=cost.penalty_cost+cost.capacity_cost+cost.operation_cost
cost['levelized']=cost.total_cost/cost.power_mwh_npv

cost_all_period=cost.groupby('load_zone')[['total_cost','power_mwh','power_mwh_npv','load_mwh','load_mwh_npv','curtail_mwh','production']].sum().reset_index()
cost_all_period['levelized']=cost_all_period.total_cost/cost_all_period.power_mwh_npv

cost_group=cost.groupby(['scenario'])[['total_cost','production','load_mwh','load_mwh_npv','curtail_mwh']].sum().reset_index()
transmission_region=transmission_cost.groupby(['scenario'])['transmission_cost'].sum().reset_index()
cost_group=cost_group.merge(transmission_region)

cost_group['levelized']=(cost_group.total_cost+cost_group.transmission_cost)/cost_group.load_mwh_npv
cost_group['levelized_notran']=(cost_group.total_cost)/cost_group.load_mwh_npv
#%%
cost_tech=pd.merge(capital_tech_cost,operation_tech_cost)
cost_tech=cost_tech.merge(dispatch_tech)
cost_tech['total_cost']=cost_tech.capacity_cost+cost_tech.operation_cost
cost_tech=cost_tech[['load_zone','scenario','technology','total_cost','power_mwh','power_mwh_npv']]

load_balance_all_period2=load_balance_all_period.copy()
load_balance_all_period2=load_balance_all_period2.rename(columns={'zone':'load_zone',
                                                                  'penalty_cost':'total_cost',
                                                                  })
load_balance_all_period2['power_mwh']=load_balance_all_period2.load_mwh-load_balance_all_period2.production
load_balance_all_period2['technology']='penalty'

cost_tech=cost_tech.append(load_balance_all_period2[['load_zone','scenario','technology','total_cost','power_mwh']],ignore_index=True)

cost_tech=pd.merge(cost_tech,supergrid,how='left',left_on=['load_zone'],right_on=['ISO3'])

#cost_tech=cost_tech.sort_values(by=['load_zone','levelized'])
#cost_tech_generation=cost_tech.groupby(['pool'])[['power_mwh']].sum().reset_index().rename(columns={'power_mwh':'total_mwh'})

cost_tech_group=cost_tech.groupby(['scenario','pool','technology'])[['total_cost','power_mwh']].sum().reset_index()

transmission_all_period=transmission_cost.groupby('scenario')['transmission_cost'].sum().reset_index().rename(columns={'transmission_cost':'total_cost'})                                                                                                                
                                                                                                                       
transmission_all_period['technology']='Transmission'
transmission_all_period['power_mwh']=0
transmission_all_period['pool']=['African super grid',
                                 'Asian super grid',
                                 'European super grid',
                                 'North American super grid',
                                 'South American super grid',
                                 'Southeast Asian super grid']
cost_tech_group=cost_tech_group.append(transmission_all_period,ignore_index=True)
cost_tech_group=cost_tech_group.merge(cost_group[['scenario','load_mwh','load_mwh_npv']],how='left',on='scenario')
cost_tech_group['level']=cost_tech_group.total_cost/cost_tech_group.load_mwh_npv
cost_tech_group_table=cost_tech_group.pivot(index='pool',columns='technology',values='level')

cost_tech_battery=cost_tech_country.loc[cost_tech_country.technology=='Battery_Storage',]
cost_tech_battery=cost_tech_battery.merge(cost_tech.loc[cost_tech.technology=='Battery_Storage',['total_cost','ISO3']],
                                          how='left',on=['ISO3'])

if output=='yes':
    cost_tech_group_table.to_excel('result_analysis/pool_cost_fixed.xlsx')
#%%
net_import=pd.DataFrame()
for i,scenario in enumerate(sc1):
    trade=pd.read_csv(respath+scenario+'/results/imports_exports.csv')
    trade['net_mwh']=trade['net_imports_mw']*trade['timepoint_weight']
    trade['export_mwh']=trade['exports_mw']*trade['timepoint_weight']
    trade['import_mwh']=trade['imports_mw']*trade['timepoint_weight']
    
    trade['export_mwh_p']=trade['export_mwh']
    trade.loc[trade.export_mwh_p<0,'export_mwh_p']=0
    trade['export_mwh_n']=trade['export_mwh']
    trade.loc[trade.export_mwh_n>0,'export_mwh_n']=0
    
    trade['import_mwh_p']=trade['import_mwh']
    trade.loc[trade.import_mwh_p<0,'import_mwh_p']=0
    trade['import_mwh_n']=trade['import_mwh']
    trade.loc[trade.import_mwh_n>0,'import_mwh_n']=0
    
    trade['total_export_mwh']=trade['export_mwh_p']-trade['import_mwh_n']
    trade['total_import_mwh']=-trade['export_mwh_n']+trade['import_mwh_p']
    
    trade_summary=trade.groupby(['load_zone','period'])[['net_mwh','total_export_mwh','total_import_mwh']].sum().reset_index()
    trade_summary['scenario']=scenario
    net_import=net_import.append(trade_summary)
    
net_import['net_export_mwh']=-net_import.net_mwh
net_import['net_import_mwh']=net_import.net_mwh

net_import.loc[net_import.net_import_mwh<0,'net_import_mwh']=0
net_import.loc[net_import.net_export_mwh<0,'net_export_mwh']=0

cost_trade=cost.merge(net_import)  
cost_trade=cost_trade.merge(cost_country[['load_zone','period','country_cost']])  
#cost_trade['export_cost']=cost_trade.total_cost-cost_trade.country_cost

#cost_trade.loc[cost_trade.net_mwh<0,'export_cost']=cost_trade.loc[cost_trade.net_mwh<0,'total_cost']*cost_trade.loc[cost_trade.net_mwh<0,'net_export_mwh']/cost_trade.loc[cost_trade.net_mwh<0,'power_mwh']

#cost_trade.loc[cost_trade.export_cost<0,'export_cost']=0
#cost_trade.loc[(cost_trade.net_mwh>0) & (cost_trade.export_cost<0),'export_cost']=0
#cost_trade.loc[cost_trade.net_mwh>0,'export_cost']=0

cost_trade_region=cost_trade.groupby(['scenario','period'])[['load_mwh','net_export_mwh','net_import_mwh']].sum().reset_index()
cost_trade_region=cost_trade_region.merge(transmission_cost)
cost_trade_region=cost_trade_region.rename(columns={'load_mwh':'total_load_mwh'})
#cost_trade_region['pool_cost']=(cost_trade_region['transmission_cost']+cost_trade_region['export_cost'])/cost_trade_region['net_import_mwh']
#cost_trade_region['pool_cost']=cost_trade_region['export_cost']/cost_trade_region['net_import_mwh']

#cost_trade=cost_trade.merge(cost_trade_region[['scenario','period','pool_cost','transmission_cost','total_load_mwh']])
cost_trade=cost_trade.merge(cost_trade_region[['scenario','period','transmission_cost','total_load_mwh']])

#cost_trade.loc[cost_trade.net_mwh<0,'pool_cost']=0
#cost_trade['new_cost']=cost_trade['pool_cost']*cost_trade['net_import_mwh']+cost_trade['transmission_cost']*cost_trade.load_mwh/cost_trade.total_load_mwh
cost_trade['new_cost']=cost_trade['transmission_cost']*cost_trade.load_mwh/cost_trade.total_load_mwh

#cost_trade_all_period=cost_trade.groupby(['load_zone'])[['load_mwh','load_mwh_npv','total_cost','new_cost','export_cost','net_mwh','total_import_mwh','total_export_mwh']].sum().reset_index()
cost_trade_all_period=cost_trade.groupby(['load_zone','scenario'])[['load_mwh_npv','power_mwh_npv','curtail_mwh','total_cost','new_cost','net_mwh','total_import_mwh','total_export_mwh']].sum().reset_index()
cost_trade_all_period['levelized']=(cost_trade_all_period.new_cost+cost_trade_all_period.total_cost)/cost_trade_all_period.power_mwh_npv
cost_trade_all_period=cost_trade_all_period.merge(cost_group[['scenario','levelized','levelized_notran']],how='left',on='scenario')
cost_trade_all_period=cost_trade_all_period.rename(columns={'levelized_x':'levelized','levelized_y':'average_levelized'})


print(sum(cost_trade_all_period.levelized*cost_trade_all_period.load_mwh_npv)-sum(cost_group.levelized*cost_group.load_mwh_npv))

if output=='yes':
    cost_trade_all_period.to_excel('result_analysis/pool_scenario_fixed.xlsx',index=False)
