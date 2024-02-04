# Transcontinental-power-pool

data preperation: codes that we use to generate the renewable resouce potential.


offshore_generation.m and renewable_potential.m: generate the renewable energy capacity, energy generation, levelized costs and development potential (1-6) by 0.01 degree grid.
eez_boudary.m: the boundary of offshore wind in each country
new_distance.m: distance between countries
supply_curve.m: generate capacity factor and maximum capacity potential for gridpath

data input for gridpath:
generate_temporal.py: generate temoral files for gridpath
cluster.py: generate data inputs for the non power pool scenario.
clulster_by_pool: generate data inputs for the power pool scenario.
generate_fixed_specified_capacity.py: generate fixed capacity to run 8760 hour scenario.
