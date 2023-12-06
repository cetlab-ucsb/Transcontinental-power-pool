library(rworldmap)
library(dplyr)
library(ggplot2)
library(R.matlab)
library(scales)
library(rgeos)
library(rgdal)
library(openxlsx)
library(data.table)
library(ggpubr)
library(RColorBrewer)

setwd(getwd())
world<-readOGR("../../TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp")
world_df=fortify(world,region="ISO3")

map_data=read.xlsx("cost_metric.xlsx",sheet="summary_100",rows = 1:247)%>%setDT()
map_data_10=read.xlsx("cost_metric.xlsx",sheet="summary_10",rows = 1:247)%>%setDT()

map_data2=read.xlsx("pool_scenario.xlsx")%>%setDT()
map <- left_join(map_data2, world_df, by =c ("load_zone"="id"))

#=================================
# region=unique(map$scenario)
# region=sort(region)    
# p=list()
# 
# for (i in region)
# {
#   map_tmp=map[scenario==i,]
#   if (i=="pool_Asia")
#   {
#           
#           long_tmp=map_tmp$long
#           long_tmp[long_tmp< (-100)]=long_tmp[long_tmp<(-100)]+360
#           map_tmp[,long:=long_tmp]
#   }
#   
#   if (i=="pool_NorthAmerica")
#   {
#     long_tmp=map_tmp$long
#     long_tmp[long_tmp>0]=long_tmp[long_tmp>0]-360
#     map_tmp[,long:=long_tmp]
#   }
#   if (i=="pool_SoutheastAsia")
#   {
#           long_tmp=map_tmp$long
#           long_tmp[long_tmp<0]=long_tmp[long_tmp<0]+360
#           map_tmp[,long:=long_tmp]
#   }
#   #fill=Renewable_production+Regional_Generation_scenario/10^6-pop_intensity_sum/10^6
#   #fill=Renewable_production+Regional_Generation/10^6-Electricity.consumption.in.2018_TWh
#   #fill=Renewable_production+Regional_Generation_IEA/10^6-IEA
#   
#   p[[i]]=ggplot() +
#         geom_polygon(data = map_tmp, aes(x=long, y = lat, group = group,fill=-net_mwh/10^6),colour="black")+
#         scale_fill_gradientn(colours  = c("#990000","#FF0000","#FFFFFF","#3399FF","#000099"),
#                                 limits=c(-200,200),
#                                 breaks=c(-200,-150,-100,-50,0,50,100,150,200),
#                                 oob=squish
#          )+
#         ggtitle(i)+
#         theme_void()+
#          guides(fill=guide_colorbar(barheight =1,barwidth = 50,title = "TWh",
#                                       title.hjust = 0,
#                                       ticks.colour = "black",
#                                       ticks.linewidth = 1.5,
#                                       title.postion="top")
#                 )+
#      theme(legend.text = element_text(size=20,colour = "black"),
#           legend.title = element_text(size=24,colour = "black"),
#            legend.position = "bottom",
#           plot.title = element_text(hjust = 0.5)
#           )
# }    
# 
# p1=ggarrange(plotlist=p,nrow=2,ncol=3,common.legend = TRUE,legend="bottom",
#              #labels = c("a","b","c","d","e","f","g","h"),
#              font.label = 20)

#==========================
#ggsave("Figure region_IEA.eps",plot=p1,device="eps",width=300,height=150,units="mm")


map_data[cost_change_rel==0,'cost_change_rel']=NA
map_data[cost_change_abs==0,'cost_change_abs']=NA

map_data[import==0,'import']=NA
map_data[export==0,'export']=NA

map_data[,'import']=map_data[,'import']/10^9
map_data[,'export']=map_data[,'export']/10^9

map_data[,'net_mwh']=-map_data[,'net_mwh']/10^6

map_data[import_average==0,'import_average']=NA
map_data[export_average==0,'export_average']=NA

mapped_data <- joinCountryData2Map(map_data, joinCode = "ISO3", 
                                   nameJoinColumn = "load_zone",
                                   projection = map_data)
new_world <- subset(mapped_data, continent != "Antarctica")

map_data_10[cost_change_rel==0,'cost_change_rel']=NA
map_data_10[cost_change_abs==0,'cost_change_abs']=NA

map_data_10[import==0,'import']=NA
map_data_10[export==0,'export']=NA

map_data_10[,'import']=map_data_10[,'import']/10^9
map_data_10[,'export']=map_data_10[,'export']/10^9

map_data_10[import_average==0,'import_average']=NA
map_data_10[export_average==0,'export_average']=NA

map_data_10[,'net_mwh']=-map_data_10[,'net_mwh']/10^6

mapped_data_10 <- joinCountryData2Map(map_data_10, joinCode = "ISO3", 
                                   nameJoinColumn = "load_zone",
                                   projection = map_data)
new_world_10 <- subset(mapped_data_10, continent != "Antarctica")


catmethod=c(-1000,-0.3,-0.2,-0.1,-0.05,0,0.05,0.1,0.2,0.3,1000)

catmethod=c(-10000,-20,-10,-5,-2.5,0,2.5,5,10,20,100000)

color=c(
  rgb(214/255,47/255,39/255),
  rgb(235/255,110/255,75/255),
  rgb(247/255,164/255,116/255),
  rgb(1,227/255,166/255),
  rgb(1,1,191/255),
  rgb(190/255,232/255,1),
  rgb(115/255,223/255,1),
  rgb(0,169/255,230/255),
  rgb(0,92/255,230/255),
  rgb(0,77/255,168/255)
)

map_cost_export<-mapCountryData(new_world,
                             nameColumnToPlot = "export_average",
                             catMethod=catmethod,
                             colourPalette = rev(color),
                             addLegend=FALSE,
                             missingCountryCol=rgb(1,1,1),
                             mapTitle = "")

map_cost_import<-mapCountryData(new_world,
                            nameColumnToPlot = "import_average",
                            catMethod=catmethod,
                            colourPalette = rev(color),
                            addLegend=FALSE,
                            missingCountryCol=rgb(1,1,1),
                            mapTitle = "")

abline(v=0)
abline(v=c(-100,100),lty=2,col='grey')
abline(h=0)
abline(h=c(-50,50),lty=2,col='grey')

map_cost_export<-mapCountryData(new_world_10,
                                nameColumnToPlot = "export_average",
                                catMethod=catmethod,
                                colourPalette = rev(color),
                                addLegend=FALSE,
                                missingCountryCol=rgb(1,1,1),
                                mapTitle = "")

map_cost_import<-mapCountryData(new_world_10,
                                nameColumnToPlot = "import_average",
                                catMethod=catmethod,
                                colourPalette = rev(color),
                                addLegend=FALSE,
                                missingCountryCol=rgb(1,1,1),
                                mapTitle = "")


do.call(addMapLegend,c(map_cost_import,
                       legendIntervals = "page",
                       legendLabels="all",
                       legendWidth=0.5,
                       tcl=0.1,
                       legendMar=5))




catmethod=c(-10000,-20,-10,-5,-2.5,0,2.5,5,10,20,100000)

color=c(
  rgb(168/255,0,0),
  rgb(235/255,56/255,56/255),
  rgb(1,127/255,127/255),
  rgb(1,190/255,190/255),
  rgb(250/255,225/255,225/255),
  rgb(190/255,232/255,1),
  rgb(115/255,223/255,1),
  rgb(0,169/255,230/255),
  rgb(0,132/255,168/255),
  rgb(0,76/255,115/255)
)

map_cost_export<-mapCountryData(new_world,
                                nameColumnToPlot = "export",
                                catMethod=catmethod,
                                colourPalette = rev(color),
                                addLegend=FALSE,
                                missingCountryCol=rgb(1,1,1),
                                mapTitle = "")

map_cost_import<-mapCountryData(new_world,
                                nameColumnToPlot = "import",
                                catMethod=catmethod,
                                colourPalette = rev(color),
                                addLegend=FALSE,
                                missingCountryCol=rgb(1,1,1),
                                mapTitle = "")


map_cost_export<-mapCountryData(new_world_10,
                                nameColumnToPlot = "export",
                                catMethod=catmethod,
                                colourPalette = rev(color),
                                addLegend=FALSE,
                                missingCountryCol=rgb(1,1,1),
                                mapTitle = "")

map_cost_import<-mapCountryData(new_world_10,
                                nameColumnToPlot = "import",
                                catMethod=catmethod,
                                colourPalette = rev(color),
                                addLegend=FALSE,
                                missingCountryCol=rgb(1,1,1),
                                mapTitle = "")

do.call(addMapLegend,c(map_cost_import,
                       legendIntervals = "page",
                       legendLabels="all",
                       legendWidth=0.5,
                       tcl=0.1,
                       legendMar=5))


#import and export
catmethod=c(-10000,-200,-100,-50,-25,0,25,50,100,200,100000)

map_trade<-mapCountryData(new_world,
                                nameColumnToPlot = "net_mwh",
                                catMethod=catmethod,
                                colourPalette = rev(color),
                                addLegend=FALSE,
                                missingCountryCol=rgb(1,1,1),
                                mapTitle = "")


map_trade<-mapCountryData(new_world_10,
                                nameColumnToPlot = "net_mwh",
                                catMethod=catmethod,
                                colourPalette = rev(color),
                                addLegend=FALSE,
                                missingCountryCol=rgb(1,1,1),
                                mapTitle = "")


do.call(addMapLegend,c(map_trade,
                       legendIntervals = "page",
                       legendLabels="all",
                       legendWidth=0.5,
                       tcl=0.1,
                       legendMar=5))

# map_cost_IEA<-mapCountryData(new_world,
#                          nameColumnToPlot = "cost_change_rel",
#                          catMethod=catmethod,
#                          colourPalette = rev(color),
#                          addLegend=FALSE,
#                          missingCountryCol=rgb(1,1,1),
#                          mapTitle = "")
# 
# map_cost_10<-mapCountryData(new_world_10,
#                              nameColumnToPlot = "cost_change_rel",
#                              catMethod=catmethod,
#                              colourPalette = rev(color),
#                              addLegend=FALSE,
#                              missingCountryCol=rgb(1,1,1),
#                              mapTitle = "")
# 
# 
# do.call(addMapLegend,c(map_cost_IEA,
#                        legendIntervals = "page",
#                        legendLabels="all",
#                        legendWidth=0.5,
#                        tcl=0.1,
#                        legendMar=5))
# 
# color2 <- rev(brewer.pal(8, "PuOr"))
# 
# catmethod=c(-150,-20,-10,-5,-1,0,1,5,10,20,150)
# map_cost_abs<-mapCountryData(new_world,
#                              nameColumnToPlot = "cost_change_abs",
#                              catMethod=catmethod,
#                              colourPalette = color2,
#                              addLegend=FALSE,
#                              missingCountryCol=rgb(1,1,1),
#                              mapTitle = "")
# 
# 
# 
# do.call(addMapLegend,c(map_cost_abs,
#                        legendIntervals = "page",
#                        legendLabels="all",
#                        legendWidth=0.5,
#                        tcl=0.1,
#                        legendMar=5))