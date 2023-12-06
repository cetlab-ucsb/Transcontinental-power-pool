clear

wind_area=1/3; %km2/MW
lifetime=30;
r=0.07;
discount_factor=r*(r+1)^lifetime/((1+r)^lifetime-1);
%capital $/MW
capital_fixed_wind=2483000;
capital_float_wind=2820000;
 
%Fixed maintenance cost $/MW
%OM_fixed_wind=133000;%NREL
%OM_float_wind=111000;

cost_fixed_wind=capital_fixed_wind*discount_factor;%$/MWh, IEC class II

%depth>60m
cost_float_wind=capital_float_wind*discount_factor;


eez=shaperead('offshore wind\World_EEZ_v11_20191118\eez_v11.shp');
countrymap=shaperead('TM_WORLD_BORDERS-0.3\TM_WORLD_BORDERS-0.3.shp');

country_map={countrymap.ISO3};
country1=unique({eez.ISO_TER1});
country2=unique({eez.ISO_TER2});
country3=unique({eez.ISO_TER3});

country=unique([country1 country2 country3]);
country=country';
country(cellfun('isempty',country)==1)=[];

load wind
clear indicator_wind


load windspeed.mat
windspeed(windspeed<8)=0;
windspeed(windspeed>=8)=1;

wind=wind.*windspeed;

clear windspeed

%{
load small_fish.mat
value=fish(fish~=0);
threshold_fish=prctile(value,90);

wind(fish>threshold_fish)=0;

clear fish 

%%%%%%%%%%%%%%%%%%%%%%%%%%   ship   %%%%%%%%%%

load ship.mat
value=ship(ship~=0);
threshold_ship=prctile(value,90);
clear value
wind(ship>threshold_ship)=0;

clear ship
%%%%%%%%%%%%%%%%%%%%  demersal  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

load demersal.mat

value=demersal(demersal~=0);
threshold_demersal=prctile(value,90);
clear value

wind(demersal>threshold_demersal)=0;

clear demersal
%%%%%%%%%%%%%%%%%% pelagic %%%%%%%%%%%%%%%%%%%%
load pelagic.mat

value=pelagic(pelagic~=0);
threshold_pelagic=prctile(value,90);
clear value

wind(pelagic>threshold_pelagic)=0;

clear pelagic
%}

load X
load Y
load border.mat

%%%%%%%%%%%%%%%%land%%%%%%%%%%%%%%%%%%5
for i=1:length(country_map)
    lon2=countrymap(i).X;
    lat2=countrymap(i).Y;
    wind_temp=wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    row=size(wind_temp,1);
    col=size(wind_temp,2);      
    in=in_country{i};
    in_temp=reshape(in,[row,col]);
    wind_temp(in)=0;
    wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2))=wind_temp;
end


%%%%%%%%%%%%%%%%%%%%%%sea ice%%%%%%%%%%%%%%%%%%%%%%%%%%
[sea1,R_sea1]=geotiffread('offshore wind\northseaice.tif');
[sea2,R_sea2]=geotiffread('offshore wind\northseaice_202003.tif');

sea=max(sea1,sea2);
%sea(sea>1)=0;

%{
fid1= fopen('offshore wind\psn25lats_v3.dat');
lats=fread(fid1,'int');

fid2= fopen('offshore wind\psn25lons_v3.dat');
lons=fread(fid2,'int');

lat_ice=lats/100000;
lon_ice=lons/100000;

seaice1=geotiffread('offshore wind\N_198503_extent_v3.0.tif');
seaice2=geotiffread('offshore wind\N_198503_extent_v3.0.tif');


seaice=max(seaice1,seaice2);
seaice(seaice>1)=0;
seaice=rot90(seaice);
%}
yv=linspace(90,31.4383,149);
xv=linspace(-180,180,911);

[X_v,Y_v]=meshgrid(xv,yv);
%{
F_sea_ice=scatteredInterpolant(lon_ice,lat_ice,double(seaice(:)),'nearest');
sea_ice=F_sea_ice(X_v,Y_v);
%}
sea_ice2=interp2(X_v,Y_v,sea,X,Y,'nearest',0);
sea_ice2(sea_ice2>1)=0;
sea_ice3=1-sea_ice2;

wind=wind.*single(sea_ice3);
wind(Y>=80)=0;
clear sea*

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
depthinfo=ncinfo('offshore wind\GEBCO_2014\GEBCO_2014_2D.nc');
depth=ncread('offshore wind\GEBCO_2014\GEBCO_2014_2D.nc','elevation');
lat_depth=ncread('offshore wind\GEBCO_2014\GEBCO_2014_2D.nc','lat');
lon_depth=ncread('offshore wind\GEBCO_2014\GEBCO_2014_2D.nc','lon');
[X_depth,Y_depth]=meshgrid(single(lon_depth),flip(single(lat_depth)));

depth=single(rot90(depth));
depth=interp2(X_depth,Y_depth,depth,X,Y,'linear');
clear X_depth Y_depth

save sea_depth.mat depth
%}

load sea_depth.mat

wind(depth>0)=0;


protect1=shaperead('offshore wind\WDPA_WDOECM_marine_shp\WDPA_WDOECM_marine_shp0\WDPA_WDOECM_marine_shp-polygons.shp');
protect2=shaperead('offshore wind\WDPA_WDOECM_marine_shp\WDPA_WDOECM_marine_shp1\WDPA_WDOECM_marine_shp-polygons.shp');
protect3=shaperead('offshore wind\WDPA_WDOECM_marine_shp\WDPA_WDOECM_marine_shp2\WDPA_WDOECM_marine_shp-polygons.shp');
protect=[protect1
         protect2
         protect3];
  
%protect_in=cell(length(protect),1);
load protect_zone.mat
for i=1:length(protect)
    if protect(i).GIS_M_AREA<4
        continue
    end
    lat2=protect(i).Y;
    lon2=protect(i).X;        
    
    west=lon2(lon2<0);
    east=lon2(lon2>=0);
    if isempty(west)==0 & isempty(east)==0
     X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),...
         (X(1,:)>=min(west) & X(1,:)<=max(west))...
         |(X(1,:)>=min(east) & X(1,:)<=max(east)));
     Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),...
          (X(1,:)>=min(west) & X(1,:)<=max(west))...
          |(X(1,:)>=min(east) & X(1,:)<=max(east)));
      
     wind_1=wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),...
                 (X(1,:)>=min(west) & X(1,:)<=max(west))...
                 |(X(1,:)>=min(east) & X(1,:)<=max(east)));

    else
      X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
      Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
      wind_1=wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    end
    
    if sum(wind_1(:))==0
        continue
    end
    %{
    if sum(ismember(i,[6727,6759,7781,11365,11399 14918,15054,15626:15630]))==1
      in1=inpolygon(X1(:),Y1(:),protect(i).X',protect(i).Y');  
    else
  
      in1=inpoly2([X1(:),Y1(:)],[lon2',lat2']);
  
    end
    %}
    
    %protect_in{i}=in1;
    in1=protect_in{i};
    
    row=size(wind_1,1);
    col=size(wind_1,2);
    wind_1=wind_1(:);
    wind_1(in1)=0;
    wind_2=reshape(wind_1,[row,col]);
    if isempty(west)==0 & isempty(east)==0
      wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),...
           (X(1,:)>=min(west) & X(1,:)<=max(west))...
           |(X(1,:)>=min(east) & X(1,:)<=max(east)))=wind_2;  
    else
    wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2))=wind_2;
    end
    i
end
clear protect
%save protect_zone.mat protect_in

lat_country={eez.Y};
lon_country={eez.X};

%%%%%%% cost  %%%%%%%
%{
load eez.mat

storage=xlsread('storage_factor.xlsx',1);
storage_factor=single(zeros(14500,36000));

for i=1:length(lat_country)
    in=logical(eez_in{i});
    lon2=lon_country{i};
    lat2=lat_country{i};
    tmp=find(ismember(country_map,eez(i).ISO_SOV1));
    if isempty(tmp)==1
        tmp=23; %use the world average 
    end
    storage_factor_temp=0*storage_factor(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    storage_factor_temp(in)=storage(tmp); 
    temp2=storage_factor(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    storage_factor_temp(temp2>0)=0;
    storage_factor(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2))...
         =storage_factor_temp+storage_factor(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
end

clear X Y eez_in
%}
load tranmission_cost_offshore_1km.mat
load wind/class_fix.mat
line_cost_offshore_1km(wind==0)=0;
load wind/OM_fix.mat
level_wind_offshore=((cost_fixed_wind.*class_fix+OM_fixed_wind)+line_cost_offshore_1km)./(wind*8760);
clear wind/class_fix OM_fixed_wind

load wind/class_float.mat
load wind/OM_float.mat
level_wind_offshore(depth<-60)=((cost_float_wind.*class_float(depth<-60)+OM_float_wind(depth<-60))+line_cost_offshore_1km(depth<-60))./(wind(depth<-60)*8760);
clear class_float OM_float_wind
clear depth storage_factor

clear line_cost_offshore_1km

%%%%%%%% generation %%%%%
load X
load Y
A=cdtarea(Y,X,'km^2');
wind=wind.*(A/wind_area)*8760;
wind_capacity=A/wind_area;
clear A

%level_numeric=log(level_wind_offshore(level_wind_offshore~=Inf));
%s=skewness(level_numeric);

%max_level_wind=prctile(level_numeric,99);
%min_level_wind=prctile(level_numeric,1);

%indicator_level=(log(level_wind_offshore)-min_level_wind)/(max_level_wind-min_level_wind);
%indicator_level(indicator_level>1)=1;
%indicator_level(indicator_level<0)=0;
%indicator_level(indicator_level==Inf)=NaN;

%load index
%index(wind==0)=NaN;
index=level_wind_offshore;
index(index==Inf)=NaN;

clear indicator_level

cost_grid_offshore=cell(length(lat_country),1);
indicator_offshore=0*X;

load eez.mat
tic
for i=1:length(lat_country)
    in=logical(eez_in{i});
    if isempty(in)==1
        continue
    end
    lon2=lon_country{i};
    lat2=lat_country{i};
    X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));

    wind_temp=wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    wind_capacity_temp=wind_capacity(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));

    level_wind_temp=level_wind_offshore(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    
    index_temp=index(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    
    row=size(wind_temp,1);
    col=size(wind_temp,2);
    
    wind_temp=wind_temp(:);
    wind_capacity_temp=wind_capacity_temp(:);
    level_wind_temp=level_wind_temp(:);
    
    index_temp=index_temp(:);
    index_temp2=index_temp;
    
    wind_temp2=wind_temp;
    if sum(wind_temp)==0
        continue    
    end
 %{      
    if  i==15 | i==62
     in=inpolygon(X1(:),Y1(:),lon2',lat2');    
     i
     else 
     in=inpoly2([X1(:),Y1(:)],[lon2',lat2']);     
     i
    end   
  %}  

   
    wind_temp=wind_temp(in);
    wind_capacity_temp=wind_capacity_temp(in);
    level_wind_temp=level_wind_temp(in);
    index_temp=index_temp(in);
    i
    if sum(wind_temp)==0
       continue
    end
    
    X_temp=X1(:);
    Y_temp=Y1(:);
    X_temp=X_temp(in);
    Y_temp=Y_temp(in);
    
    temp=[wind_temp wind_capacity_temp level_wind_temp index_temp Y_temp X_temp];
    temp(wind_temp==0,:)=[];
    cost_grid_offshore{i}=temp; 
                 
    in_2=reshape(in,[row,col]);
   
    indicator_offshore(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2))...
        =in_2+indicator_offshore(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
end
toc

indicator_offshore(indicator_offshore==0)=NaN;
indicator_offshore(indicator_offshore>1)=1;
indicator_offshore=indicator_offshore.*index;

save offshore_cost.mat level_wind_offshore 

clear index level_wind_offshore wind wind_capacity


index_value=indicator_offshore(isnan(indicator_offshore)~=1);

very_high=prctile(index_value(:),10);
high_medium=prctile(index_value(:),25);
high_low=prctile(index_value(:),50);
low_medium=prctile(index_value(:),75);
low_very=prctile(index_value(:),90);
clear index_value

indicator_offshore_temp=indicator_offshore;
indicator_offshore(indicator_offshore_temp<=very_high)=6;
indicator_offshore(indicator_offshore_temp<=high_medium & indicator_offshore_temp>very_high)=5;
indicator_offshore(indicator_offshore_temp<=high_low & indicator_offshore_temp>high_medium)=4;
indicator_offshore(indicator_offshore_temp<=low_medium & indicator_offshore_temp>high_low)=3;
indicator_offshore(indicator_offshore_temp<=low_very & indicator_offshore_temp>low_medium)=2;
indicator_offshore(indicator_offshore_temp>low_very)=1;

save offshore_cost.mat indicator_offshore -append
clear indicator_offshore

for i=1:length(lat_country)
   if isempty(cost_grid_offshore{i})==1
       continue
   end
   indicator_abs=cost_grid_offshore{i}(:,4);
   indicator_abs_temp=indicator_abs;
   indicator_abs(indicator_abs_temp<=very_high)=6;
   indicator_abs(indicator_abs_temp<=high_medium & indicator_abs_temp>very_high)=5; 
   indicator_abs(indicator_abs_temp<=high_low & indicator_abs_temp>high_medium)=4;
   indicator_abs(indicator_abs_temp<=low_medium & indicator_abs_temp>high_low)=3;
   indicator_abs(indicator_abs_temp<=low_very & indicator_abs_temp>low_medium)=2;
   indicator_abs(indicator_abs_temp>low_very)=1;
   cost_grid_offshore{i}(:,4)=indicator_abs;
end


cost_grid_offshore_wind=cell(length(country_map),6);
offshore_country=zeros(length(country_map),6);


sov1_country={eez.ISO_SOV1};
sov2_country={eez.ISO_SOV2};
sov3_country={eez.ISO_SOV3};

ter1_country={eez.ISO_TER1};
ter2_country={eez.ISO_TER2};
ter3_country={eez.ISO_TER3};

ter1_country(cellfun('isempty',ter1_country)==1)=sov1_country(cellfun('isempty',ter1_country)==1);
ter2_country(cellfun('isempty',ter2_country)==1)=sov2_country(cellfun('isempty',ter2_country)==1);
ter3_country(cellfun('isempty',ter3_country)==1)=sov3_country(cellfun('isempty',ter3_country)==1);


for i=1:length(lat_country)

    ter1=ter1_country{i};
    ter2=ter2_country{i};
    ter3=ter3_country{i};
  
    
    index1=find(ismember(country_map,ter1));
    index2=find(ismember(country_map,ter2));
    index3=find(ismember(country_map,ter3));
   
    generation_temp=cost_grid_offshore{i};
  
    if isempty(generation_temp)==1
        i
        continue
    end
    
    if isempty(index1)==1
        i
        continue
    end
    
    indicator_offshore=generation_temp(:,4);
      
   
  for j=1:6
       generation_temp2=generation_temp;
       generation_temp2(indicator_offshore~=7-j,:)=[];
       
     if isempty(index2)==1
      cost_grid_offshore_wind{index1,j}=[cost_grid_offshore_wind{index1,j}
                                         generation_temp2(:,1:3)]; 
                                     
      offshore_country(index1,j)=offshore_country(index1,j)+sum(generation_temp2(:,1),'omitnan');   
     elseif isempty(index2)==0 & isempty(index3)==1
      rep=size(generation_temp2,1);
      weight_generation=repmat(mean(generation_temp2(:,1)),[round(rep/2),1]);
      weight_capacity=repmat(mean(generation_temp2(:,2)),[round(rep/2),1]);
      weight_cost=sum(generation_temp2(:,1).*generation_temp2(:,3))/sum(generation_temp2(:,1));
      weight_cost=repmat(weight_cost,[round(rep/2),1]);
      
      cost_grid_temp=[weight_generation weight_capacity weight_cost];
      cost_grid_offshore_wind{index1,j}=[cost_grid_offshore_wind{index1,j}
                                         cost_grid_temp];
                                   
      cost_grid_offshore_wind{index2,j}=[cost_grid_offshore_wind{index2,j}
                                        cost_grid_temp];  
                                   
      offshore_country(index1,j)=offshore_country(index1,j)+sum(generation_temp2(:,1),'omitnan')/2; 
      offshore_country(index2,j)=offshore_country(index2,j)+sum(generation_temp2(:,1),'omitnan')/2; 
     else
       i
      rep=size(generation_temp2,1);
      weight_generation=repmat(mean(generation_temp2(:,1)),[round(rep/3),1]);
      weight_capacity=repmat(mean(generation_temp2(:,2)),[round(rep/3),1]);
      weight_cost=sum(generation_temp2(:,1).*generation_temp2(:,3))/sum(generation_temp2(:,1));
      weight_cost=repmat(weight_cost,[round(rep/3),1]);
      cost_grid_temp=[weight_generation weight_capacity weight_cost];
      cost_grid_offshore_wind{index1,j}=[cost_grid_offshore_wind{index1,j}
                                         cost_grid_temp];
                                   
      cost_grid_offshore_wind{index2,j}=[cost_grid_offshore_wind{index2,j}
                                         cost_grid_temp];  
                                    
      cost_grid_offshore_wind{index3,j}=[cost_grid_offshore_wind{index2,j}
                                         cost_grid_temp];  
                                   
      offshore_country(index1,j)=offshore_country(index1,j)+sum(generation_temp2(:,1),'omitnan')/3; 
      offshore_country(index2,j)=offshore_country(index2,j)+sum(generation_temp2(:,1),'omitnan')/3;  
      offshore_country(index3,j)=offshore_country(index3,j)+sum(generation_temp2(:,1),'omitnan')/3;  

     end
  end
end

save cost_offshore.mat cost_grid_offshore_wind

output=table(country_map',offshore_country);

sum(offshore_country)/10^6%TWH
sum(offshore_country)/10^6*3600/10^6
sum(offshore_country(:,1))/10^6*3600/10^6
