clear
clc
%area of 1 MW solar PV
solar_area=7.9*0.00404686*0.85; %km2/MW
wind_area=1/3; %km2/MW
CSP_area=10*0.0040468;%no storage
rooftop_area=8.13/1118; %km2/MW  Technical guide from NREL
urban_roof=0.25;%Global cooling: increasing world-wide urban albedos to offset CO2
roof_suitable=0.33;% Deng et al. Quantifying solar and wind electricity potential

countrymap=shaperead('TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp');

lifetime=30;
r=0.07;
discount_factor=r*(r+1)^lifetime/((1+r)^lifetime-1);
discount_hydro=r*(r+1)^lifetime/((1+r)^100-1);
%capita cost $/MW, NREL, CAPEX
capital_solar=655000;
capital_CSP=2935000;%no storage
capital_wind=1243000;
capital_rooftop=1304000;
capital_hydro=6000000;

%Fixed maintenance cost $/MW
OM_solar=8000;%NREL
OM_CSP=55000;
OM_wind=38000;%NREL
OM_rooftop=10000;%NREL
OM_hydro=30000;

VAR_CSP=4;%NREL $/MWh

cost_solar=capital_solar*discount_factor+OM_solar;%$/MW
cost_CSP=capital_CSP*discount_factor+OM_CSP;%$/MW
cost_wind=capital_wind*discount_factor+OM_wind;%$/MW, IEC class II
cost_rooftop=capital_rooftop*discount_factor+OM_rooftop;%$/MW
cost_hydro=capital_hydro*discount_hydro+OM_hydro;%$/MW, IEC class II


load X
load Y


country={countrymap.ISO3};
lon_country={countrymap.X};
lat_country={countrymap.Y};
clear countrymap

%consider the storage
%{
load border.mat
storage=xlsread('storage_factor.xlsx',1);
storage_factor=single(zeros(14500,36000));
for i=1:length(country)
    lon2=lon_country{i};
    lat2=lat_country{i};
    storage_factor_temp=0*storage_factor(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    storage_factor_temp(in_country{i})=storage(i); 
    storage_factor(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2))...
        =storage_factor_temp+storage_factor(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
end
save storage_factor.mat storage_factor
%}
%{
[lat,lon]=cdtgrid(0.01);
Y=lat(lat(:,1)<=85 & lat(:,1)>=-60,:);
X=lon(lat(:,1)<=85 & lat(:,1)>=-60,:);
clear lat lon

X=single(X);
Y=single(Y);

save X.mat X
save Y.mat Y
%}
%{
%%rooftop
%rooftop solar
[artificial,R_artifical]=geotiffread('GlcShare_v10_01\glc_shv10_01.Tif');

%Original for urban
lat_art=linspace(R_artifical.YWorldLimits(2)-R_artifical.SampleSpacingInWorldY/2,R_artifical.YWorldLimits(1)+R_artifical.SampleSpacingInWorldY/2,R_artifical.RasterSize(1));
lon_art=linspace(R_artifical.XWorldLimits(1)+R_artifical.SampleSpacingInWorldX/2,R_artifical.XWorldLimits(2)-R_artifical.SampleSpacingInWorldX/2,R_artifical.RasterSize(2));

[X_art,Y_art]=meshgrid(lon_art,lat_art);

X_art=single(X_art);
Y_art=single(Y_art);
%interp for PV
artificial=single(artificial);
artificial=interp2(X_art,Y_art,artificial,X,Y,'linear',0);
artificial=sparse(double(artificial));
in_urban=artificial>0;
save rooftop.mat artificial -append
clear X_art Y_art lat_art lon_art artificial

[indicator_solar,R_solar]=geotiffread('lulc-development-potential-indices-pv-geographic-geotiff\lulc-development-potential-indices_pv_dpi_classes_geographic.tif');
[indicator_wind,R_wind]=geotiffread('lulc-development-potential-indices-wind-geographic-geotiff\lulc-development-potential-indices_wind_dpi_classes_geographic.tif');
[indicator_hydro,R_hydro]=geotiffread('lulc-development-potential-indices-hydro-geographic-geotiff\lulc-development-potential-indices_hydro_dpi_classes_geographic.tif');

[solar,R1]=geotiffread('World_PVOUT_GISdata_LTAy_DailySum_GlobalSolarAtlas_GEOTIFF/PVOUT.tif');
[wind,R2]=geotiffread('capacity.tif');

sum(sum(solar,'omitnan'))

solar(isnan(solar)==1)=0;
wind(wind<0)=0;

%%develoment potential
check1=sum(sum(indicator_solar))
% resize indicator of solar PV
[indicator_solar,R_solar2]=georesize(single(indicator_solar),R_solar,0.5,'bilinear');
check2=sum(sum(indicator_solar))

[indicator_wind,R_wind2]=georesize(single(indicator_wind),R_wind,0.5,'bilinear');

[indicator_hydro,R_hydro2]=georesize(single(indicator_hydro),R_hydro,0.5,'bilinear');

lat_indicator=linspace(R_solar2.LatitudeLimits(2)-R_solar2.CellExtentInLatitude/2,R_solar2.LatitudeLimits(1)+R_solar2.CellExtentInLatitude/2,R_solar2.RasterSize(1));
lon_indicator=linspace(R_solar2.LongitudeLimits(1)+R_solar2.CellExtentInLongitude/2,R_solar2.LongitudeLimits(2)-R_solar2.CellExtentInLongitude/2,R_solar2.RasterSize(2));

[X_indicator,Y_indicator]=meshgrid(lon_indicator,lat_indicator);


X_indicator=single(X_indicator);
Y_indicator=single(Y_indicator);

%Development potential for solar PV
indicator_solar=interp2(X_indicator,Y_indicator,indicator_solar,X,Y,'linear',0);
indicator_solar=sparse(double(round(indicator_solar)));
indicator_solar(in_urban)=0;

indicator_wind=interp2(X_indicator,Y_indicator,indicator_wind,X,Y,'linear',0);
indicator_wind=sparse(double(round(indicator_wind)));
indicator_wind(in_urban)=0;

indicator_hydro=interp2(X_indicator,Y_indicator,indicator_hydro,X,Y,'linear',0);
indicator_hydro=sparse(double(round(indicator_hydro)));
indicator_hydro(in_urban)=0;

save hydro.mat indicator_hydro -append;

clear X_indicator Y_indicator 
clear lat_indicator lon_indicator
image(indicator_solar)
%%

%Original grid for solar PV
[Y1,X1]=cdtgrid(R1.CellExtentInLatitude);
X1=X1(Y1(:,1)<=R1.LatitudeLimits(2) & Y1(:,1)>=R1.LatitudeLimits(1),:);
Y1=Y1(Y1(:,1)<=R1.LatitudeLimits(2) & Y1(:,1)>=R1.LatitudeLimits(1),:);

X1=single(X1);
Y1=single(Y1);
%interp for PV
solar=interp2(X1,Y1,solar,X,Y,'linear',0);
solar=sparse(double(solar));
sum(sum(solar,'omitnan'))
save solar.mat solar -append
save solar.mat indicator_solar -append
clear solar indicator_solar
clear X1 Y1


%Original grid for onshore wind
lat2=linspace(R2.LatitudeLimits(2)-R2.CellExtentInLatitude/2,R2.LatitudeLimits(1)+R2.CellExtentInLatitude/2,R2.RasterSize(1));
lon2=linspace(R2.LongitudeLimits(1)+R2.CellExtentInLongitude/2,R2.LongitudeLimits(2)-R2.CellExtentInLongitude/2,R2.RasterSize(2));
[X2,Y2]=meshgrid(lon2,lat2);
X2=single(X2);
Y2=single(Y2);
wind=interp2(X2,Y2,wind,X,Y,'linear',0);
wind=single(full(wind));
save wind.mat wind -append
save wind indicator_wind -append
clear wind indicator_wind
clear X2 Y2 lat2 lon2


%hydro
load Hydropower.mat
hydropower=hydropower(hydropower(:,3)<=85 & hydropower(:,3)>=-60,:);

x_hydro=hydropower(:,2);
x_hydro(x_hydro>180)=x_hydro(x_hydro>180)-360;
hydropower(:,2)=x_hydro;

y_hydro=hydropower(:,3);

hydro=hydropower(:,1);
sum(sum(hydro))
xx_hydro=ceil((x_hydro+180)/0.01);
yy_hydro=ceil((85-y_hydro)/0.01);
hydroele=zeros(14500,36000);

for i=1:length(hydro)
     xx=xx_hydro(i);
     yy=yy_hydro(i);
     hydroele(yy,xx)=hydroele(yy,xx)+hydro(i);
 end

hydroele=sparse(hydroele);
sum(sum(hydroele))
save hydro.mat hydroele -append
clear hydroele indicator_hydro
%}


load solar

load tranmission_cost_1km.mat
line_solar=line_cost_1km;
line_solar(solar==0)=0;

level_solar=(cost_solar+line_solar)./(single(full(solar))*8760);%$/MWh
clear line_solar



A=cdtarea(Y,X,'km^2');
solar=solar.*(A/solar_area)*8760;
solar_capacity=A/solar_area;
clear A 


country_solar=zeros(length(country),6);
country_CSP=zeros(length(country),6);
country_wind=zeros(length(country),6);
country_rooftop=zeros(length(country),6);
country_hydro=zeros(length(country),6);

cost_grid_solar=cell(length(country),6);
cost_grid_CSP=cell(length(country),6);
cost_grid_wind=cell(length(country),6);
cost_grid_rooftop=cell(length(country),1);
cost_grid_hydro=cell(length(country),6);

grid_solar=cell(length(country),6);
grid_CSP=cell(length(country),6);
grid_wind=cell(length(country),6);
grid_rooftop=cell(length(country),1);
grid_hydro=cell(length(country),6);

%in_country=cell(length(country),1);
load border.mat
tic
for i=1:length(country)    
    lon2=lon_country{i};
    lat2=lat_country{i};
    X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    %%{
    solar_temp=solar(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    solar_temp=solar_temp(:);
     
     if isempty(solar_temp)==1
         continue
     end
     in=in_country{i};
     
    indicator_solar_temp=indicator_solar(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    indicator_solar_temp=indicator_solar_temp(:);
    level_solar_temp=level_solar(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    level_solar_temp=level_solar_temp(:);
    solar_capacity_temp=solar_capacity(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    solar_capacity_temp=solar_capacity_temp(:);
    
    solar_temp=single(full(solar_temp(in))); 
    solar_capacity_temp=single(full(solar_capacity_temp(in))); 
    solar_develop=single(full(indicator_solar_temp(in)));
    level_solar_temp=level_solar_temp(in);

     for j=1:3
        %%%%%%%%
         country_solar(i,j)=sum(solar_temp(solar_develop==7-j),'omitnan');
   
         solar_temp2=solar_temp;
         solar_temp2(solar_develop~=7-j)=NaN;
         
         solar_capacity_temp2=solar_capacity_temp;
         solar_capacity_temp2(solar_develop~=7-j)=NaN;
         
         level_solar_temp2=level_solar_temp;
         level_solar_temp2(solar_develop~=7-j)=NaN;
        
         cost_grid_solar_temp=[solar_temp2,solar_capacity_temp2,level_solar_temp2];
         
         cost_grid_solar{i,j}=cost_grid_solar_temp;
     end
      clear solar_temp solar_temp2 level_solar_temp level_solar_temp2 solar_capacity_temp solar_capacity_temp2 indicator_solar_temp
end

save cost_PV.mat cost_grid_solar -v7.3
clear cost_grid_solar
clear solar indicator_solar level_solar solar_capacity

load wind%wind is single
line_wind=line_cost_1km;
line_wind(wind==0)=0;
load wind/class_onshore.mat

level_wind=(((cost_wind-OM_wind).*class+OM_wind)+line_wind)./(wind*8760);
clear line_wind class 

A=cdtarea(Y,X,'km^2');
wind=wind.*(A/wind_area)*8760;
wind_capacity=A/wind_area;

clear A 
for i=1:length(country)
    lon2=lon_country{i};
    lat2=lat_country{i};
    X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
     
    wind_temp=wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    wind_temp=wind_temp(:);
    
    indicator_wind_temp=indicator_wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    indicator_wind_temp=indicator_wind_temp(:);
    
    wind_capacity_temp=wind_capacity(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    wind_capacity_temp=wind_capacity_temp(:);
    
     if isempty(wind_temp)==1
         continue
     end
     
    in=in_country{i};
    
    level_wind_temp=level_wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    level_wind_temp=level_wind_temp(:);
    
    wind_temp=wind_temp(in);
    wind_capacity_temp=wind_capacity_temp(in);
    wind_develop=single(full(indicator_wind_temp(in))); 
    level_wind_temp=level_wind_temp(in);
    
   for j=1:3
     %%%%%%%%%%%%%    
         country_wind(i,j)=sum(wind_temp(wind_develop==7-j),'omitnan');
         wind_temp2=wind_temp;
         wind_temp2(wind_develop~=7-j)=NaN;
         
         wind_capacity_temp2=wind_capacity_temp;
         wind_capacity_temp2(wind_develop~=7-j)=NaN;
         
         level_wind_temp2=level_wind_temp;
         level_wind_temp2(wind_develop~=7-j)=NaN;
         
         cost_grid_wind_temp=[wind_temp2,wind_capacity_temp2,level_wind_temp2];
         cost_grid_wind{i,j}=cost_grid_wind_temp;
   end
   clear wind_temp wind_temp2 wind_capacity_temp wind_capacity_temp2 level_wind_temp level_wind_temp2 indicator_wind_temp

    %}
  %{   
     if  i==145 
    % in1=inpolygon(X1,Y1,lon2,lat2);
     in=inpolygon(X1(:),Y1(:),lon2',lat2');    
     i
    else 
    in=inpoly2([X1(:),Y1(:)],[lon2',lat2']);     
    i
    end    
    in_country{i}=in;
    %}
   
    i
end
toc

save cost_wind cost_grid_wind -v7.3
clear cost_grid_wind

clear wind indicator_wind level_wind wind_capacity

load CSP
line_CSP=line_cost_1km;
line_CSP(CSP==0)=0;
level_CSP=(cost_CSP+line_CSP)./(CSP*8760)+VAR_CSP;
clear line_CSP

A=cdtarea(Y,X,'km^2');
CSP=CSP.*(A/CSP_area)*8760;
CSP_capacity=A/CSP_area;
clear A 

for i=1:length(country)    
    lon2=lon_country{i};
    lat2=lat_country{i};
    X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
   
    CSP_temp=CSP(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    CSP_temp=CSP_temp(:);
    
    CSP_capacity_temp=CSP_capacity(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    CSP_capacity_temp=CSP_capacity_temp(:);
    
    indicator_CSP_temp=indicator_CSP(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    indicator_CSP_temp=indicator_CSP_temp(:);
    
      if isempty(CSP_temp)==1
         continue
      end
     
    in=in_country{i};
     
    level_CSP_temp=level_CSP(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    level_CSP_temp=level_CSP_temp(:);
    
    CSP_temp=CSP_temp(in);
    CSP_capacity_temp=CSP_capacity_temp(in);
    CSP_develop=single(full(indicator_CSP_temp(in))); 
    level_CSP_temp=level_CSP_temp(in);
    
   for j=1:3
     %%%%%%%%%%%%%    
         country_CSP(i,j)=sum(CSP_temp(CSP_develop==7-j),'omitnan');
         CSP_temp2=CSP_temp;
         CSP_temp2(CSP_develop~=7-j)=NaN;
         
         CSP_capacity_temp2=CSP_capacity_temp;
         CSP_capacity_temp2(CSP_develop~=7-j)=NaN;
         
         level_CSP_temp2=level_CSP_temp;
         level_CSP_temp2(CSP_develop~=7-j)=NaN;
         
         cost_grid_CSP_temp=[CSP_temp2,CSP_capacity_temp2,level_CSP_temp2];
         cost_grid_CSP{i,j}=cost_grid_CSP_temp;
   end
   clear CSP_temp CSP_temp2 CSP_capacity_temp CSP_capacity_temp2 level_CSP_temp level_CSP_temp2 indicator_CSP_temp

end
clear CSP indicator_CSP level_CSP CSP_capacity

save cost_CSP.mat cost_grid_CSP -v7.3
clear cost_grid_CSP

load hydro
line_hydro=line_cost_1km;
line_hydro(hydroele==0)=0;
level_hydro=(cost_hydro+line_hydro)/8760/0.5;
level_hydro(hydroele==0)=0;
clear line_hydro
hydro=hydroele/1000; %MWh
clear hydroele 

clear line_cost_1km

for i=1:length(country)
    
   lon2=lon_country{i};
   lat2=lat_country{i};
   X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
   Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
 
   hydro_temp=hydro(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
   hydro_temp=hydro_temp(:);
 
    if isempty(hydro_temp)==1
         continue
    end
    in=in_country{i};
     
   indicator_hydro_temp=indicator_hydro(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
   indicator_hydro_temp=indicator_hydro_temp(:);     
     
    level_hydro_temp=level_hydro(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    level_hydro_temp=level_hydro_temp(:);
    
    hydro_temp=single(full(hydro_temp(in)));
    hydro_develop=single(full(indicator_hydro_temp(in)));
    level_hydro_temp=level_hydro_temp(in);
  
    for j=1:3
     %%%%%%%%%%
         country_hydro(i,j)=sum(hydro_temp(hydro_develop==7-j),'omitnan');
         hydro_temp2=hydro_temp;
         hydro_temp2(hydro_develop~=7-j)=NaN;
         
         level_hydro_temp2=level_hydro_temp;
         level_hydro_temp2(hydro_develop~=7-j)=NaN;
         
         cost_grid_hydro_temp=[hydro_temp2,2*hydro_temp2/8760,level_hydro_temp2];
         cost_grid_hydro{i,j}=cost_grid_hydro_temp;
    end
    i
   clear hydro_temp hydro_temp2 level_hydro_temp level_hydro_temp2 indicator_hydro_temp
 end
clear hydro indicator_hydro level_hydro

save cost_hydro.mat cost_grid_hydro -v7.3
clear cost_grid_hydro

A=cdtarea(Y,X,'km^2');

load rooftop
load solar solar
level_rooftop=single(cost_rooftop)./(single(full(solar))*8760);%$/MWh
rooftop=roof_suitable*urban_roof*(solar.*artificial).*(A/rooftop_area)*8760/100;
rooftop_capacity=A/rooftop_area*roof_suitable*urban_roof.*artificial/100;
clear solar indicator_solar A 


for i=1:length(country)
    lon2=lon_country{i};
    lat2=lat_country{i};
    X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));

   rooftop_temp=rooftop(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
   rooftop_temp=rooftop_temp(:);
   
   rooftop_capacity_temp=rooftop_capacity(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
   rooftop_capacity_temp=rooftop_capacity_temp(:); 

   if isempty(rooftop_temp)==1
         continue
   end
    
   in=in_country{i};
   level_rooftop_temp=level_rooftop(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
  
   level_rooftop_temp=level_rooftop_temp(:);
   

   rooftop_temp=single(full(rooftop_temp(in))); 
   rooftop_capacity_temp=single(full(rooftop_capacity_temp(in))); 
   level_rooftop_temp=level_rooftop_temp(in);
   
   country_rooftop(i)=sum(rooftop_temp,'omitnan');
         
   cost_grid_rooftop_temp=[rooftop_temp,rooftop_capacity_temp,level_rooftop_temp];
   cost_grid_rooftop{i}=cost_grid_rooftop_temp;
   i
   clear rooftop_temp level_rooftop_temp

end
clear rooftop level_rooftop rooftop_capacity
clear X Y
save cost_rooftop.mat cost_grid_rooftop

