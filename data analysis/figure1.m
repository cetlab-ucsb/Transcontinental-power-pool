data=readtable('cumulative data_100.xlsx','Range','H1:L212');
data(isnan(data.IEA)==1,:)=[];
data.Delta(data.Delta<0)=-1;
data=sortrows(data,{'IEA','Delta'},'descend');

demand=data.IEA/10^3;
supply=data.Renew/10^3;
production=data.production/10^3;

Y_tmp=0;
X_tmp=0;
figure(1)
for i=1:length(supply)
    X=[X_tmp,X_tmp+demand(i),X_tmp+demand(i),X_tmp];
    X_tmp=X_tmp+demand(i);
    Y=[Y_tmp,Y_tmp,Y_tmp+supply(i),Y_tmp+supply(i)];   
    Y_tmp=Y_tmp+production(i);             %generation
    %Y_tmp=Y_tmp+min(supply(i),demand(i)); %supply
    %{
    if supply(i)>=demand(i)
      Y_tmp=Y_tmp+demand(i);
    else
      Y_tmp=Y_tmp+supply(i);
    end
    %}
    fill(X,Y,[211,211,211]/255,'EdgeAlpha',0.1);
    hold on
    %plot([X_tmp-demand(i),X_tmp],[Y_tmp-min(supply(i),demand(i)),Y_tmp],'Color','r','LineWidth',1.5)
    plot([X_tmp-demand(i),X_tmp],[Y_tmp-production(i),Y_tmp],'Color','r','LineWidth',1.5)
    hold on
end

plot([0,55],[0,55],'Color','b','LineWidth',1.5)
xlim([0,42.7])
ylim([0,370])
%yticks([0,10,20,30,40,50,60,350,400])
yticks([0,10,20,30,40,50,100,150,200,250,300,370,400])
set(gcf,'Position', [10 10 250 225])
set(gca,'Fontsize',6,'FontName','Arial')
set(gca,'TickDir','out')
breakyaxis([50,365])

%%
data=readtable('cumulative data.xlsx','Range','H1:L212');
data(isnan(data.IEA)==1,:)=[];
data.Delta(data.Delta<0)=-1;
data=sortrows(data,{'IEA','Delta'},'descend');

demand=data.IEA/10^3;
supply=data.Renew/10^3;
production=data.production/10^3;

Y_tmp=0;
X_tmp=0;
figure(1)
for i=1:length(supply)
    X=[X_tmp,X_tmp+demand(i),X_tmp+demand(i),X_tmp];
    X_tmp=X_tmp+demand(i);
    Y=[Y_tmp,Y_tmp,Y_tmp+supply(i),Y_tmp+supply(i)];   
    Y_tmp=Y_tmp+production(i);
    %Y_tmp=Y_tmp+min(supply(i),demand(i));
    %{
    if supply(i)>=demand(i)
      Y_tmp=Y_tmp+demand(i);
    else
      Y_tmp=Y_tmp+supply(i);
    end
    %}
    fill(X,Y,[211,211,211]/255,'EdgeAlpha',0.1);
    
    hold on
    %plot([X_tmp-demand(i),X_tmp],[Y_tmp-min(supply(i),demand(i)),Y_tmp],'Color','r','LineWidth',1.5)
    plot([X_tmp-demand(i),X_tmp],[Y_tmp-production(i),Y_tmp],'Color','r','LineWidth',1.5)
    hold on
end

plot([0,55],[0.1,55],'Color','b','LineWidth',1.5)
xlim([0,42.7])
ylim([0,370])
%yticks([0,10,20,30,40,50,60,350,400])
yticks([0,10,20,30,40,50,100,150,200,250,300,370,400])
set(gcf,'Position', [10 10 250 225])
set(gca,'Fontsize',6,'FontName','Arial')
set(gca,'TickDir','out')
breakyaxis([50,365])

%%
data2=readtable('cumulative data_100.xlsx','Sheet',2);
data2(isnan(data2.IEA)==1,:)=[];
data2(data2.IEA==0,:)=[];
region=sortrows(data2,{'Region','IEA'},{'ascend','descend'}); 

region_select=string(unique(region.Region));

figure(2)
CData=[255, 204, 204
       255, 229, 204
       255, 255, 204
       204, 255 ,255
       204 204 255
       255 204 229]/256;

X_tmp=0;
tmp=0; 
tmp_Y=0;
for k=1:length(region_select)
  Y_tmp=tmp_Y;
  region_tmp=region(region.Region==region_select(k),:);
  demand_region=region_tmp.IEA/10^3;
  supply_region=region_tmp.Renew/10^3;
  production_region=region_tmp.production/10^3;
  X_t=[tmp,tmp+sum(demand_region),tmp+sum(demand_region),tmp];
  Y_t=[0,0,1000,1000];
  fill(X_t,Y_t,CData(k,:),'EdgeColor','none')
  hold on
  for i=1:length(region_tmp.Region)
    X=[X_tmp,X_tmp+demand_region(i),X_tmp+demand_region(i),X_tmp];
    X_tmp=X_tmp+demand_region(i);
    Y=[Y_tmp,Y_tmp,Y_tmp+supply_region(i),Y_tmp+supply_region(i)];
    Y_tmp=Y_tmp+supply_region(i);
    fill(X,Y,[211,211,211]/255);
    hold on
  end
% plot([tmp,tmp+sum(demand_region)],[tmp,tmp+sum(demand_region)],'Color','k','LineWidth',1)  
    tmp=tmp+sum(demand_region,'omitnan');
    tmp_Y=tmp_Y+sum(production_region,'omitnan');
    hold on
    xline(tmp,'LineStyle','--','LineWidth',1)
    hold on
end
plot([0,55],[0,55])

xlim([0,42.7])
ylim([0,1000])
yticks([0,100,200,300,400,500,600,700,800,900,1000])
set(gcf,'Position', [10 50 200 120])
set(gca,'Fontsize',7.5,'FontName','Arial')
set(gca,'TickDir','out')
%breakyaxis([400,980])

%%
data2=readtable('cumulative data.xlsx','Sheet',2);
data2(isnan(data2.IEA)==1,:)=[];
data2(data2.IEA==0,:)=[];
region=sortrows(data2,{'Region','IEA'},{'ascend','descend'}); 

region_select=string(unique(region.Region));

figure(2)
CData=[255, 204, 204
       255, 229, 204
       255, 255, 204
       204, 255 ,255
       204 204 255
       255 204 229]/256;

X_tmp=0;
tmp=0; 
tmp_Y=0;
for k=1:length(region_select)
  Y_tmp=tmp_Y;
  region_tmp=region(region.Region==region_select(k),:);
  demand_region=region_tmp.IEA/10^3;
  supply_region=region_tmp.Renew/10^3;
  production_region=region_tmp.production/10^3;
  X_t=[tmp,tmp+sum(demand_region),tmp+sum(demand_region),tmp];
  Y_t=[0,0,1000,1000];
  fill(X_t,Y_t,CData(k,:),'EdgeColor','none')
  hold on
  for i=1:length(region_tmp.Region)
    X=[X_tmp,X_tmp+demand_region(i),X_tmp+demand_region(i),X_tmp];
    X_tmp=X_tmp+demand_region(i);
    Y=[Y_tmp,Y_tmp,Y_tmp+supply_region(i),Y_tmp+supply_region(i)];
    Y_tmp=Y_tmp+supply_region(i);
    fill(X,Y,[211,211,211]/255);
    hold on
  end
% plot([tmp,tmp+sum(demand_region)],[tmp,tmp+sum(demand_region)],'Color','k','LineWidth',1)  
    tmp=tmp+sum(demand_region,'omitnan');
    tmp_Y=tmp_Y+sum(production_region,'omitnan');
    hold on
    xline(tmp,'LineStyle','--','LineWidth',1)
    hold on
end
plot([0,55],[0,55])

xlim([0,42.7])
ylim([0,1000])
%yticks([0,10,20,30,40,50,60,70,100,150,200,1000])
yticks([0,100,200,300,400,500,600,700,800,900,1000])
set(gcf,'Position', [10 10 1000 600])
set(gca,'Fontsize',16,'FontName','Arial')
set(gca,'TickDir','out')
%breakyaxis([80,990])
