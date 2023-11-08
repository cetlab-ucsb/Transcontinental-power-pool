load wind.mat wind

eez=shaperead('offshore wind\World_EEZ_v11_20191118\eez_v11.shp');
countrymap=shaperead('TM_WORLD_BORDERS-0.3\TM_WORLD_BORDERS-0.3.shp');

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


lat_country={eez.Y};
lon_country={eez.X};



eez_in=cell(length(lat_country),1);

tic
for i=1:length(lat_country)
    lon2=lon_country{i};
    lat2=lat_country{i};
    X1=X(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    Y1=Y(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    
    wind_temp=wind(Y(:,1)>=min(lat2) & Y(:,1)<=max(lat2),X(1,:)>=min(lon2) & X(1,:)<=max(lon2));
    
    row=size(wind_temp,1);
    col=size(wind_temp,2);
    
    wind_temp=wind_temp(:);
    in_temp=wind_temp*0;
    
    X1=X1(:);
    Y1=Y1(:);
    X2=X1(wind_temp~=0);
    Y2=Y1(wind_temp~=0);
    
    if isempty(wind_temp2)==1
        continue    
    end
 %{      
    if  i==15 | i==62
     in=inpolygon(X1(:),Y1(:),lon2',lat2');    
     i
     else
 %}
    in=inpoly2([X1(:),Y1(:)],[lon2',lat2']);        
    i    
    in_temp(wind_temp~=0)=in;               
    in_temp2=reshape(in_temp2,[row,col]);
    eez_in{i}=in_temp2;
end
toc
