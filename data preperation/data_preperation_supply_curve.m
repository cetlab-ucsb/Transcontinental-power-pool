clear
load cost_PV.mat
load cost_wind.mat
load cost_offshore.mat
load cost_hydro.mat
load cost_CSP.mat
load cost_rooftop.mat

countrymap=shaperead('TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp');
country={countrymap.ISO3};
clear countrymap
cost_grid=cell(length(country),6);

for i=1:length(country)  
         cost_grid_rooftop_temp=cost_grid_rooftop{i,1};
         if isempty(cost_grid_rooftop_temp)==1
             continue
         end
         cost_rooftop_tmp=cost_grid_rooftop_temp(:,3);
         cost_rooftop_tmp(cost_grid_rooftop_temp(:,1)==0)=inf;
         cost_grid_rooftop_temp(:,3)=cost_rooftop_tmp;
         clear cost_rooftop_tmp
    for j=1:3
        % cost_grid_solar_temp=cost_grid_solar{i,j};
        % cost_grid_wind_temp=cost_grid_wind{i,j};
        % cost_grid_hydro_temp=cost_grid_hydro{i,j};
        % cost_grid_CSP_temp=cost_grid_CSP{i,j}; 
         
         if j==1
           cost_temp=[cost_grid_solar{i,j}(:,3) cost_grid_wind{i,j}(:,3) cost_grid_hydro{i,j}(:,3) cost_grid_CSP{i,j}(:,3) cost_grid_rooftop_temp(:,3)];
           [cost_grid_temp,index_grid_temp]=min(cost_temp,[],2);
           index_grid_temp=single(index_grid_temp);
           clear cost_temp
           
           grid_temp=[cost_grid_solar{i,j}(:,1) cost_grid_wind{i,j}(:,1) cost_grid_hydro{i,j}(:,1) cost_grid_CSP{i,j}(:,1) cost_grid_rooftop_temp(:,1)];
           cap_temp=[cost_grid_solar{i,j}(:,2) cost_grid_wind{i,j}(:,2) cost_grid_hydro{i,j}(:,2) cost_grid_CSP{i,j}(:,2) cost_grid_rooftop_temp(:,2)];

           index_grid_temp2=[index_grid_temp==1,index_grid_temp==2,index_grid_temp==3,index_grid_temp==4,index_grid_temp==5];
           index_grid_temp2=single(index_grid_temp2);
         else
           cost_temp=[cost_grid_solar{i,j}(:,3) cost_grid_wind{i,j}(:,3) cost_grid_hydro{i,j}(:,3) cost_grid_CSP{i,j}(:,3)];
           [cost_grid_temp,index_grid_temp]=min(cost_temp,[],2);
           index_grid_temp=single(index_grid_temp);
           clear cost_temp
           
           grid_temp=[cost_grid_solar{i,j}(:,1) cost_grid_wind{i,j}(:,1) cost_grid_hydro{i,j}(:,1) cost_grid_CSP{i,j}(:,1)];    
           cap_temp=[cost_grid_solar{i,j}(:,2) cost_grid_wind{i,j}(:,2) cost_grid_hydro{i,j}(:,2) cost_grid_CSP{i,j}(:,2)];    
          
           index_grid_temp2=[index_grid_temp==1,index_grid_temp==2,index_grid_temp==3,index_grid_temp==4];
           index_grid_temp2=single(index_grid_temp2);
         end    
         clear cost_grid_rooftop_temp
        
         cost_grid_offshore_temp=cost_grid_offshore_wind{i,j};
                  
         if isempty(cost_grid_offshore_temp)==1
            cost_grid_offshore_temp=[0,0,NaN];
         end       
         
         grid_temp2=[sum(grid_temp.*index_grid_temp2,2,'omitnan');
                     cost_grid_offshore_temp(:,1)];
                 
         cap_temp2=[sum(cap_temp.*index_grid_temp2,2,'omitnan');
                     cost_grid_offshore_temp(:,2)];
                 
         clear grid_temp index_grid_temp2
         
         row_number=size(cost_grid_offshore_temp,1);
                  
         index_grid_temp_temp=[index_grid_temp
                              6*ones(row_number,1)];
                           
         index_grid_temp_temp=single(index_grid_temp_temp);
         clear index_grid_temp  
         
         cost_grid_temp_temp=[cost_grid_temp;   
                              cost_grid_offshore_temp(:,3)];
                               
         %grid_temp3=grid_temp.*index_grid_temp2;
   %{      
         if j==1
          country_rooftop2(i,j)=sum(grid_temp3(:,5),'omitnan');
         end
             
          country_solar2(i,j)=sum(grid_temp3(:,1),'omitnan');
          country_wind2(i,j)=sum(grid_temp3(:,2),'omitnan');
          country_hydro2(i,j)=sum(grid_temp3(:,3),'omitnan');
          country_CSP2(i,j)=sum(grid_temp3(:,4),'omitnan');
          country_offshore2(i,j)=sum(cost_grid_offshore_temp(:,1),'omitnan');
    %}      
         cost_grid_temp2=[grid_temp2 cap_temp2 cost_grid_temp_temp index_grid_temp_temp];
         cost_grid_temp2(isnan(cost_grid_temp_temp)==1 | grid_temp2==0,:)=[];

         cost_grid_temp3=sortrows(cost_grid_temp2,3);
         cost_grid{i,j}=cost_grid_temp3;
         
         clear cost_grid_temp3 cost_grid_temp2 grid_temp2 cost_grid_temp index_grid_temp
         
   %{     
         if j==1
             cost_grid_rooftop_temp=sortrows(cost_grid_rooftop_temp,2);
             cost_grid_rooftop_temp(cost_grid_rooftop_temp(:,1)==0,:)=[];
             cost_grid_rooftop2{i,j}=cost_grid_rooftop_temp;
         end
         
         cost_grid_solar_temp=sortrows(cost_grid_solar_temp,2);
         cost_grid_wind_temp=sortrows(cost_grid_wind_temp,2);
         cost_grid_hydro_temp=sortrows(cost_grid_hydro_temp,2);
         cost_grid_CSP_temp=sortrows(cost_grid_CSP_temp,2);
         
         cost_grid_solar_temp(isnan(cost_grid_solar_temp(:,1))==1,:)=[];
         cost_grid_wind_temp(isnan(cost_grid_wind_temp(:,1))==1,:)=[];
         cost_grid_hydro_temp(isnan(cost_grid_hydro_temp(:,1))==1,:)=[];
         cost_grid_CSP_temp(isnan(cost_grid_CSP_temp(:,1))==1,:)=[];
          
         cost_grid_solar2{i,j}=cost_grid_solar_temp;
         cost_grid_wind2{i,j}=cost_grid_wind_temp;         
         cost_grid_hydro2{i,j}=cost_grid_hydro_temp;
         cost_grid_CSP2{i,j}=cost_grid_CSP_temp;
     %}    
    end
end

save cost_grid.mat cost_grid -v7.3