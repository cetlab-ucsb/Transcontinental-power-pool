# -*- coding: utf-8 -*-
"""
Created on Sun Jan  2 18:50:35 2022

@author: haozheyang
"""
#cluster

from IPython import get_ipython
get_ipython().magic('reset -sf')

import os
os.chdir("H:/Renewable Equal/simulation")

import pandas as pd
import numpy as np
import glob
#%%
#make the project file
new_project=pd.read_csv('input_potential_capacity_100.csv').set_index('ISO3').stack().reset_index(name='MW').rename(columns={'level_1':'technology'})
existing_project=pd.read_excel('existing_capacity.xlsx',sheet_name='existing').set_index('ISO3').stack().reset_index(name='GW').rename(columns={'level_1':'technology'})
project_capacity_factor=pd.read_csv('input_potential_capacity_factor_100.csv').set_index('ISO3').stack().reset_index(name='capacity_factor').rename(columns={'level_1':'technology'})

existing_project=existing_project.merge(project_capacity_factor,how='left').fillna('')
new_project=new_project.merge(project_capacity_factor)

country=pd.read_excel('country_ISO3.xlsx',sheet_name='country')
supergrid=pd.read_excel('country_ISO3.xlsx',sheet_name='pool')
#create a cluster file for all projects
cluster=pd.DataFrame()
#add existing project
for i_id,i in enumerate(existing_project['ISO3']):
    if existing_project.technology[i_id]=='Hydro_Pumped':
        capacity_group='group_storage'
    elif existing_project.technology[i_id]=='PV':
        capacity_group='group_solar'
    elif existing_project.technology[i_id]=='Wind':
        capacity_group='group_wind'
    else:
        capacity_group='group_hydro'
            
        
    if existing_project.GW[i_id]>0:
        cluster=cluster.append(
            pd.DataFrame({
            'project':['_'.join([i,existing_project.technology[i_id],'existing'])],
            'technology':[existing_project.technology[i_id]],
            'load_zone': i,
            'capacity_group':capacity_group,
            'gen_dbid':'existing',
            'capacity':[existing_project.GW[i_id]*1000],
            'capacity_factor':existing_project.capacity_factor[i_id]
            })
            )
    else:
        continue
#add new projects    
for i_id,i in enumerate(new_project['ISO3']):
    if new_project.technology[i_id] in ['PV','Rooftop','CSP']:
        capacity_group='group_solar'
    elif new_project.technology[i_id] in ['Wind','Offshore']:
        capacity_group='group_wind'
    else:
        capacity_group='group_hydro'
        
    if new_project.MW[i_id]>0:
        cluster=cluster.append(
            pd.DataFrame({
            'project':['_'.join([i,new_project.technology[i_id],'new'])],
            'technology':new_project.technology[i_id],
            'load_zone': i,
            'capacity_group':capacity_group,
            'gen_dbid':'new',
            'capacity':new_project.MW[i_id],
            'capacity_factor':new_project.capacity_factor[i_id]
            })
            )
    else:
        continue    
    
#add battery
for i_id,i in enumerate(np.unique(new_project['ISO3'])):
        cluster=cluster.append(
            pd.DataFrame({
            'project':['_'.join([i,'Battery','new'])],
            'technology':'Battery_Storage',
            'load_zone': i,
            'capacity_group':'group_storage',
            'gen_dbid':'new',
            'capacity':'',
            'capacity_factor':''
            })
            )
   
cluster=cluster.reset_index().drop('index',axis=1)
cluster=cluster.merge(country,how='left')
#cluster=cluster.merge(supergrid,how='left')
#%%
period=np.arange(2030,2055,10)
horizon=pd.read_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/temporal/3_global_3period/horizon_params.csv')

timepoints=pd.read_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/temporal/3_global_3period/structure.csv')['timepoint']

share_path='C:/Program Files/GRIDPATH/db/csvs_power_pool/'

pool=['African super grid',
      'Asian super grid',
      'European super grid',
      'North American super grid',
      'South American super grid',
      'Southeast Asian super grid']

#%%
#project_portofolio
from project_function import generate_project_portofolio
portfolio_scenario=29
portfolio_description='portofolio'
path_portfolio=share_path+'project/project_portfolios/'+str(portfolio_scenario)+'_'+portfolio_description+'.csv'

project_portofolio=generate_project_portofolio(cluster)
project_portofolio.to_csv(path_portfolio,index=False)

#%%project_availability
from project_function import generate_availability_type
availability_type_scenario=3
availability_description='base'
exogenous_availability_scenario_id=''
path_availability_type=share_path+'project/project_availability/project_availability_types/'+str(availability_type_scenario)+'_'+availability_description+'.csv'

project_availability_type=generate_availability_type(cluster,exogenous_availability_scenario_id)
project_availability_type.to_csv(path_availability_type,index=False)


#%%project_capacity_group
from project_function import generate_project_cap_group
cap_group_scenario=3
cap_group_description='base_cap_groups'
path_capacity_group=share_path+'project/project_capacity_groups/projects/'+str(cap_group_scenario)+'_'+cap_group_description+'.csv'

project_capacity_groups=generate_project_cap_group(cluster)
project_capacity_groups.to_csv(path_capacity_group,index=False)
#%%project_hydro_operational_chars
from project_function import generate_hydro_operation_chars,generate_hydro_operation_chars_full
hydro_oper_scenario_id=1
hydro_month=pd.read_excel('country_ISO3.xlsx',sheet_name='hydro')
project_hydro_operational_chars=generate_hydro_operation_chars(cluster,hydro_month,hydro_oper_scenario_id,horizon,share_path)

hydro_oper_scenario_id_full=2
horizon_full=pd.read_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/temporal/1_global_3period/horizon_params.csv')
project_hydro_operational_chars=generate_hydro_operation_chars_full(cluster,hydro_month,hydro_oper_scenario_id_full,horizon_full,share_path)
 
#%%project_load_zone
from project_function import generate_load_zone
load_zone_scenario=3
load_zone_description='global'

load_zone_path=share_path+'project/project_load_zones/'+str(load_zone_scenario)+'_'+load_zone_description+'.csv'
project_load_zone=generate_load_zone(cluster)
project_load_zone.to_csv(load_zone_path,index=False)

#%%project_fixed_cost
from project_function import generate_fixed_cost
fixed_cost_set=pd.DataFrame(
    {
       'fixed_cost_description': ['moderate'],
       'fixed_cost_scenario': [5]
       }
    )
for i in range(1):
    fixed_cost_scenario=fixed_cost_set.loc[i,'fixed_cost_scenario']
    fixed_cost_description=fixed_cost_set.loc[i,'fixed_cost_description']
    path_fixed_cost=share_path+'project/project_specified_fixed_cost/'+str(fixed_cost_scenario)+'_'+fixed_cost_description+'.csv'

    fixed_cost=pd.read_excel('fixed_cost_new.xlsx',sheet_name=fixed_cost_description)


    project_fixed_cost=generate_fixed_cost(cluster,fixed_cost)
    project_fixed_cost.to_csv(path_fixed_cost,index=False)

#%%project_new_cost
from project_function import generate_new_cost

new_cost_set=pd.DataFrame(
    {
       'new_cost_description': ['moderate'],
       'new_cost_scenario': [5]
       }
    )
for i in range(1):
    new_cost_scenario=new_cost_set.loc[i,'new_cost_scenario']
    new_cost_description=new_cost_set.loc[i,'new_cost_description']

    path_new_cost=share_path+'project/project_new_cost/'+str(new_cost_scenario)+'_'+new_cost_description+'.csv'

    discount=0.07

    capital_cost=pd.read_excel('annualized_cost.xlsx',sheet_name=new_cost_description)
    

    lifetime=pd.read_excel('annualized_cost.xlsx',sheet_name='lifetime')
    lifetime_np=lifetime.iloc[:,1:].to_numpy()
    crf=discount*(1+discount)**lifetime_np/((1+discount)**lifetime_np-1)
    capital_cost.iloc[:,1:]=crf*capital_cost.iloc[:,1:]
    project_new_cost=generate_new_cost(cluster, capital_cost,lifetime,fixed_cost)
    project_new_cost.to_csv(path_new_cost,index=False)

#%%project_new_potential
from project_function import generate_new_potential
new_potential_scenario=5
new_potential_description='project_nocap'
path_new_potential=share_path+'project/project_new_potential/'+str(new_potential_scenario)+'_'+new_potential_description+'.csv'

stop_build=['group_coal']
stop_build=[]
project_new_potential=generate_new_potential(cluster, period, stop_build)
project_new_potential.to_csv(path_new_potential,index=False)
#%%
#project_operation_chars
from project_function import generate_operate_chars
operation_chars_scenario=3
operation_description='full_8760'
path_operation=share_path+'project/project_operational_chars/'+str(operation_chars_scenario)+'_'+operation_description+'.csv'

project_operation_chars=generate_operate_chars(cluster,operation_chars_scenario,operation_description)
project_operation_chars.to_csv(path_operation,na_rep='',index=False)

#%%project_specified_capacity
from project_function import generate_specified_capacity
specified_capacity_scenario=5
specified_capacity_description='project'
path_specified_capacity=share_path+'project/project_specified_capacity/'+str(specified_capacity_scenario)+'_'+specified_capacity_description+'.csv'

project_specified_capacity=generate_specified_capacity(cluster,period)
project_specified_capacity.to_csv(path_specified_capacity,index=False)

#%%project_variable
from project_function import generate_variable_generator_profile_peak,generate_variable_generator_profile_full
variable_scenario_id=1
description='generator_profile_1'
#major_country_list=glob.glob('Dantong2021-Geophysical_constraints/Input_data/42_major_countries/*'+'.csv')
#major_country=[major_country_list[i].split('_')[-1].split('.')[0] for i in range(len(major_country_list))]

#region=glob.glob('Dantong2021-Geophysical_constraints/Input_data/Regions/*'+'.csv')

file_var=generate_variable_generator_profile_peak(cluster, variable_scenario_id, description, timepoints, share_path)

variable_scenario_full_id=2
description='generator_profile_full'
timepoints_full=pd.read_csv('C:/Program Files/GRIDPATH/db/csvs_power_pool/temporal/1_global_3period/structure.csv')['timepoint']
file_var=generate_variable_generator_profile_full(cluster, variable_scenario_full_id, description, timepoints_full, share_path)

#%%
'''
from project_function import generate_carbon_cap_load_zone
carbon_cap_load_zone=generate_carbon_cap_load_zone(cluster)
carbon_cap_load_zone.to_csv('policy/carbon_cap/project_carbon_cap_zones/1_project_carbon_cap_zones_china.csv',index=False)
'''
#%%
from project_function import generate_system_load_peak, generate_system_load_full
demand_scenario=['IEA_SDG','IEA_NZE']
prm=1.15
generate_system_load_peak(demand_scenario,timepoints,share_path)

generate_system_load_full(demand_scenario,timepoints_full,share_path)

from reliability_function import generate_system_prm_req
generate_system_prm_req(demand_scenario,share_path,prm)

#100PWh
system_load_base=pd.read_csv(share_path+'system_load/system_load/4_IEA_NZE.csv')
system_load_100=system_load_base.copy()
system_load_100.load_mw=system_load_base.load_mw*100*10**9/system_load_base.loc[system_load_base.timepoint>2050000000,'load_mw'].sum()
system_load_100.to_csv(share_path+'system_load/system_load/5_IEA_100.csv',index=False)
#%% prm
from reliability_function import generate_geography_prm_zones
geography_prm_zones=generate_geography_prm_zones(cluster)
geography_prm_zones.to_csv(share_path+'reliability/prm/geography_prm_zones/2_geography_prm_zones.csv',index=False)

from reliability_function import generate_project_prm_zones
project_prm_zones=generate_project_prm_zones(cluster)
project_prm_zones.to_csv(share_path+'reliability/prm/project_prm_zones/2_project_prm_zones.csv',index=False)


from reliability_function import generate_prm_project_elcc
#project_elcc_chars
prm_project_elcc=generate_prm_project_elcc(cluster)
prm_project_elcc.to_csv(share_path+'reliability/prm/project_elcc_chars/2_project_elcc.csv',index=False)

#system prm requirement


#%%operating reserve
'''
from reliability_function import generate_system_reserve_req
generate_system_reserve_req(scenario)

from reliability_function import generate_reserve_load_zone
gen_type=pd.read_csv('project/project_operational_chars/2_full.csv')[['project','operational_type']]
generate_reserve_load_zone(cluster,gen_type)
'''
#%%transmission


from transmission_function import generate_transmission_portfolio
transmission_portfolio=generate_transmission_portfolio(pool)
transmission_portfolio.to_csv(share_path+'transmission/transmission_portfolios/1_transmission_porfolio_pool.csv',index=False)

from transmission_function import generate_transmission_load_zone  
transmission_load_zone=generate_transmission_load_zone(transmission_portfolio)
transmission_load_zone.to_csv(share_path+'transmission/transmission_load_zones/1_transmission_load_zones.csv',index=False)

from transmission_function import generate_transmission_new_cost  
#HVDC
cost_MW_per_km=1044
cost_OM_per_km=3
converter_capex=180000
converter_OM=1800
life_time=50
power_loss_km=0.016
power_loss_converter=0.014

#HVAC
cost_ac_MW_per_km=458
cost_ac_OM_per_km=3
#converter_capex=180000
#converter_OM=1800
power_ac_loss_km=0.095


discount=0.07

crf_t=discount*(1+discount)**life_time/((1+discount)**life_time-1)
capital_km=cost_MW_per_km*crf_t+cost_OM_per_km
capital=converter_capex*crf_t+converter_OM

capital_ac_km=cost_ac_MW_per_km*crf_t+cost_ac_OM_per_km

transmission_new_cost, transmission_operation=generate_transmission_new_cost(transmission_portfolio,period,capital_km,capital_ac_km,capital,life_time,power_loss_km,power_loss_converter,power_ac_loss_km)

transmission_new_cost.to_csv(share_path+'transmission/transmission_new_cost/1_transmission_new_cost_pool.csv',index=False)
transmission_operation.to_csv(share_path+'transmission/transmission_operational_chars/1_transmission_operational_pool.csv',index=False)

from transmission_function import generate_transmission_specified_capacity
transmission_specified_capacity=generate_transmission_specified_capacity(transmission_portfolio,period)
transmission_specified_capacity.to_csv(share_path+'transmission/transmission_specified_capacity/1_transmission_existing_pool.csv',index=False)

from transmission_function import generate_European_transmission
transmission_Europe=pd.read_csv(share_path+'transmission/transmission_portfolios/5_European super grid.csv')
existing_grid=pd.read_excel('existing transmission.xlsx',usecols=[0,1,2,3,4])

existing_grid['source_continent']=existing_grid.From.str.split('-').str[0]
existing_grid['target_continent']=existing_grid.To.str.split('-').str[0]
existing_grid['source']=existing_grid.From.str.split('-').str[1]
existing_grid['target']=existing_grid.To.str.split('-').str[1]
existing_EU_grid=existing_grid.loc[(existing_grid.source_continent.isin(['EU'])) & (existing_grid.target_continent.isin(['EU'])),]

existing_EU_grid['transmission_line']='European_super_grid'+'_'+existing_EU_grid.source+'_'+existing_EU_grid.target+'_existing'
existing_EU_grid['flow']=existing_EU_grid[['Max Flow (MW)','Min Flow (MW)']].max(axis=1)
existing_EU_grid=existing_EU_grid.loc[existing_EU_grid.flow!=0,]


existing_EU_grid=existing_EU_grid[['transmission_line','flow']]

generate_European_transmission(transmission_Europe,existing_EU_grid,share_path,power_loss_km,power_loss_converter,power_ac_loss_km)
    
    
