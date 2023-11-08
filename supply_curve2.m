
%%
%==========================================================================
%==========================================================================
clear
load cost_grid.mat

countrymap=shaperead('TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp');
country={countrymap.ISO3};

ele_gen=readtable('global map\electrcity.xlsx','Sheet',1,'Range','A1:E247','TreatAsEmpty',{'.','NA','N/A'});

clear countrymap


region=readtable('global map\Fossil fuel resource.xlsx','Sheet','compare re and fo ele_price_TWh',...
       'TreatAsEmpty',{'.','NA','N/A'},...
        'Range','A1:BA247');
demand=region.ElectricityConsumptionIn2018_TWh-region.Renewable_production; %TWh
demand_scenario=region.pop_intensity_sum/10^6-region.Renewable_production;
demand_IEA=(region.IEA-region.Renewable_production)*1.15;
%%
select=["CHN","USA","IND","RUS","JPN","DEU","IRN","KOR","SAU"];
color=[255,0,0      %PV
       0,128,255    %onshore
       153,255,255   %hydro
       255,128,0      %CSP
       255,204,153      %rooftop
       0,0,255];  %offshore

%%
%renewable potential
land_grade=6;
capacity_potential=zeros(length(country),6); %MW
generation_potential=zeros(length(country),6); %MWh
cost_potential=zeros(length(country),6); 

for i=1:length(country)
    temp=[];
        for k=1:land_grade
         temp=[temp
               cost_grid{i,k}];
        end
       if isempty(temp)==1
           continue
       end
       type=temp(:,4);
       for j=1:6 
             capacity_potential(i,j)=sum(temp(type==j,2));
             generation_potential(i,j)=sum(temp(type==j,1)); %TWh
             cost_potential(i,j)=sum(temp(type==j,1).*temp(type==j,3))/sum(temp(type==j,2));
       end
end
capacity_factor_potential=generation_potential./(capacity_potential*8760);

capacity_factor_potential(isnan(capacity_factor_potential)==1)=0;

capacity_potential(isnan(capacity_potential)==1)=0;
cost_potential(isnan(cost_potential)==1)=0;

output=[array2table(country') array2table(capacity_potential)];
output.Properties.VariableNames={'ISO3','PV','Wind','Hydro','CSP','Rooftop','Offshore'};
output(isnan(demand_IEA)==1 | demand_IEA==0,:)=[];


output2=[array2table(country') array2table(capacity_factor_potential)];
output2.Properties.VariableNames={'ISO3','PV','Wind','Hydro','CSP','Rooftop','Offshore'};
output2(isnan(demand_IEA)==1 | demand_IEA==0,:)=[];


output3=[array2table(country') array2table(generation_potential)];
output3.Properties.VariableNames={'ISO3','PV','Wind','Hydro','CSP','Rooftop','Offshore'};
output3(isnan(demand_IEA)==1 | demand_IEA==0,:)=[];


writetable(output,'simulation/input_potential_capacity_100.csv');
writetable(output2,'simulation/input_potential_capacity_factor_100.csv');
writetable(output3,'simulation/input_potential_generation_100.csv');
%%
%%%%%%%%%%%%%%Region
land_grade=1;
capacity_type=zeros(length(country),6); %MW
generation_type=zeros(length(country),6); %MWh
cost_type=zeros(length(country),6);%$/MWh
generation=zeros(length(country),1);
for i=1:length(country)
       temp=cost_grid{i,land_grade}; 
       if isempty(temp)==1
           continue
       end
       
       generation(i)=sum(temp(:,1))/10^6;
       cumgeneration_temp=cumsum(temp(:,1))/10^6;
       id=1:size(temp,1);
       index=cumgeneration_temp>=demand_IEA(i);
       if sum(index)==0
        index_min=size(temp,1);
       else
        index_min=min(id(index));
       end
       temp2=temp(1:index_min,:);
       %{
       temp2=temp(cumgeneration_temp<=demand_IEA(i),:);
       if isempty(temp2)==1
           continue
       end
       %}
       type=temp2(:,4);
       for j=1:6 
             capacity_type(i,j)=sum(temp2(type==j,2));
             generation_type(i,j)=sum(temp2(type==j,1)); %TWh
             cost_type(i,j)=sum(temp2(type==j,1).*temp2(type==j,3))/sum(temp2(type==j,2));
       end
end
check=sum(generation_type,2)/10^6-demand_IEA;
sum(check,'omitnan')

capacity_factor=generation_type./(capacity_type*8760);
%capacity_factor(:,3)=generation_type(:,3)./capacity_type(:,3);
capacity_factor(isnan(capacity_factor)==1)=0;

capacity_type(isnan(capacity_type)==1)=0;
cost_type(isnan(cost_type)==1)=0;

output=[array2table(country') array2table(capacity_type)];
output.Properties.VariableNames={'ISO3','PV','Wind','Hydro','CSP','Rooftop','Offshore'};
output(isnan(demand_IEA)==1,:)=[];

output2=[array2table(country') array2table(capacity_factor)];
output2.Properties.VariableNames={'ISO3','PV','Wind','Hydro','CSP','Rooftop','Offshore'};
output2(isnan(demand_IEA)==1,:)=[];

output3=[array2table(country') array2table(cost_type)];
output3.Properties.VariableNames={'ISO3','PV','Wind','Hydro','CSP','Rooftop','Offshore'};
output3(isnan(demand_IEA)==1,:)=[];


writetable(output,'simulation/input_data_capacity.csv');
writetable(output2,'simulation/input_data_capacity_factor.csv');

%%
%region, data preperation
region=region.Region3;
region2=zeros(246,1);
region_s=unique(region);
region_s(cellfun(@(x)(strcmp(x,'0')),region_s))=[];


for i=1:length(region_s)
   region_order=ismember(region,region_s(i));
   region2(region_order,1)=i;
end

curve=[];
for i=1:246
    for j=1  %%%%%%%%%%%%%%%%%%%choose the land grade here==================
      temp=cost_grid{i,j};
      if isempty(temp)==1
      temp2=[0,0,1,0,i,region2(i)];
      else
      temp2=[temp,ones(size(temp,1),1)*i,ones(size(temp,1),1)*region2(i)];
      end
      curve=[curve
             temp2];
    end
    i
end

%%
cost_country=curve(:,3);


%cost_country=round(cost_country,1);%======================choose the digits==========================

cost_region_table=table(curve(:,1),curve(:,2),cost_country,curve(:,4),curve(:,5),curve(:,6),...
                  'VariableNames',{'Generation','Capacity','Cost','Type','Country','Region'});
              
cost_region_table.sumcost=cost_region_table.Cost.*cost_region_table.Generation;


clear cost_country
clear cost_grid
clear curve


cost_region=[table(country'),table(region2),table(demand_IEA)];
cost_region(isnan(demand_IEA)==1,:)=[];
cost_region.Properties.VariableNames{'region2'}='region';  

capacity_region_type=zeros(length(region_s),6); %MW
generation_region_type=zeros(length(region_s),6); %MWh
cost_region_type=zeros(length(region_s),6);%$/MWh
%%
region_country={};

for i=1:length(region_s)
    region_temp=sortrows(cost_region_table(cost_region_table.Region==i,:),3);
    region_type_temp=region_temp.Type;
    demand_IEA_tmp=cost_region.demand_IEA(cost_region.region==i);
    demand_total=sum(demand_IEA_tmp);
    
    cumgeneration_temp=cumsum(region_temp{:,1})/10^6;
    
    id=1:size(region_temp,1);
    index=cumgeneration_temp>=demand_total;
    if isempty(index)==1
        index_min=size(region_temp,1);
    else
        index_min=min(id(index));
    end
    temp2=region_temp(1:index_min,:);
    %{
    temp2=region_temp(cumgeneration_temp<=demand_total,:);
       if isempty(temp2)==1
           continue
       end
    %}
    temp=grpstats(temp2,{'Country','Type'},@(x)sum(x,'omitnan'));
    
    region_country=vertcat(region_country,temp);
    
    type=temp2{:,4};
    
    for j=1:6 
           capacity_region_type(i,j)=sum(temp2{type==j,2});
           generation_region_type(i,j)=sum(temp2{type==j,1}); %TWh
           cost_region_type(i,j)=sum(temp2{type==j,1}.*temp2{type==j,3})/sum(temp2{type==j,1});
    end
end

region_country.avg_cost=region_country.Fun1_sumcost./region_country.Fun1_Capacity;

region_country(region_country.Type==0,:)=[];
country_id=1:246;
country_id_keep=country_id(isnan(demand_IEA)==0);
country_keep=country(isnan(demand_IEA)==0);

region_country.ISO3={country{region_country.Country}}';

region_country2=region_country(ismember(region_country.Country,country_id_keep),:);
region_country2.capacity_factor=region_country2.Fun1_Generation./region_country2.Fun1_Capacity/8760;

region_country_capacity=unstack(region_country2(:,[1,10,2,5]),'Fun1_Capacity','Type','NewDataVariableNames',{'PV','Wind','Hydro','Rooftop','Offshore'});
%csp=table(zeros(height(region_country_capacity),1),'VariableNames',{'CSP'});
%region_country_capacity=[region_country_capacity(:,1:4),csp,region_country_capacity(:,5:end)];
region_country_capacity=sortrows(region_country_capacity,1);
idx = ismissing(region_country_capacity{:,3:end});
region_country_capacity{:,3:end}(idx)=0;
writetable(region_country_capacity,'simulation/input_region_data_capacity.csv');

region_country_cap_factor=unstack(region_country2(:,[1,10,2,11]),'capacity_factor','Type','NewDataVariableNames',{'PV','Wind','Hydro','Rooftop','Offshore'});
%region_country_cap_factor=[region_country_cap_factor(:,1:4),csp,region_country_cap_factor(:,5:end)];
region_country_cap_factor=sortrows(region_country_cap_factor,1);
idx = ismissing(region_country_cap_factor{:,3:end});
region_country_cap_factor{:,3:end}(idx)=0;
writetable(region_country_cap_factor,'simulation/input_region_data_capacity_factor.csv');

region_country_cost=unstack(region_country2(:,[1,10,2,9]),'avg_cost','Type','NewDataVariableNames',{'PV','Wind','Hydro','Rooftop','Offshore'});
%region_country_cost=[region_country_cost(:,1:4),csp,region_country_cost(:,5:end)];
region_country_cost=sortrows(region_country_cost,1);
idx = ismissing(region_country_cost{:,3:end});
region_country_cost{:,3:end}(idx)=0;
writetable(region_country_cost,'simulation/input_region_data_cost.csv');

generation_power_pool=zeros(246,1);
check2=grpstats(region_country2,{'Country'},'sum','DataVars',{'Fun1_Generation'});
generation_power_pool(check2{:,1},1)=check2.sum_Fun1_Generation;
sum(check2.sum_Fun1_Generation)/10^6-sum(demand_IEA,'omitnan')
