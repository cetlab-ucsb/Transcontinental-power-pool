library(rworldmap)
library(dplyr)
library(ggplot2)
library(scales)
library(rgeos)
library(rgdal)
library(openxlsx)
library(data.table)
library(ggpubr)

#Figure1

map_data=read.xlsx("cost_metric.xlsx",sheet="summary_100")%>%setDT()
map_data2=read.xlsx("cost_metric.xlsx",sheet="country_100")%>%setDT()
mapped_data <- joinCountryData2Map(map_data2, joinCode = "ISO3", 
                                   nameJoinColumn = "load_zone",
                                   projection = map_data)
new_world <- subset(mapped_data, continent != "Antarctica")

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



catmethod=c(-1,0.025,0.05,0.1,0.2,1)
color=c(
  rgb(214/255,47/255,39/255),
  rgb(235/255,110/255,75/255),
  rgb(247/255,164/255,116/255),
  rgb(1,227/255,166/255),
  rgb(1,1,191/255)
)
map_produce<-mapCountryData(new_world,
                            nameColumnToPlot = "gap",
                            catMethod=catmethod,
                            colourPalette = rev(color),
                            addLegend=FALSE,
                            missingCountryCol=rgb(0.5,0.5,0.5),
                            mapTitle = "",
                            lwd=0.3)
abline(v=0)
abline(v=c(-100,100),lty=2,col='grey')
abline(h=0)
abline(h=c(-50,50),lty=2,col='grey')

do.call(addMapLegend,c(map_produce,
                       legendIntervals = "page",
                       legendLabels="all",
                       legendWidth=0.5,
                       tcl=0,
                       legendMar=5))


map_data_10=read.xlsx("cost_metric.xlsx",sheet="summary_10")%>%setDT()
map_data_10_2=read.xlsx("cost_metric.xlsx",sheet="country_10")%>%setDT()
mapped_data <- joinCountryData2Map(map_data_10_2, joinCode = "ISO3", 
                                   nameJoinColumn = "load_zone",
                                   projection = map_data)
new_world_10 <- subset(mapped_data, continent != "Antarctica")

map_produce_10<-mapCountryData(new_world_10,
                            nameColumnToPlot = "gap",
                            catMethod=catmethod,
                            colourPalette = rev(color),
                            addLegend=FALSE,
                            missingCountryCol=rgb(0.5,0.5,0.5),
                            mapTitle = "",
                            lwd=0.3)

abline(v=0)
abline(v=c(-100,100),lty=2,col='grey')
abline(h=0)
abline(h=c(-50,50),lty=2,col='grey')

do.call(addMapLegend,c(map_produce_10,
                       legendIntervals = "page",
                       legendLabels="all",
                       legendWidth=0.5,
                       tcl=0,
                       legendMar=5))


#Figure 2

world<-readOGR("../../TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp")
world_df=fortify(world,region="ISO3")


# map_data1=read.xlsx("../supply curve/energy.xlsx",sheet="addcost_baseline")%>%setDT()
# map_data2=read.xlsx("../supply curve/energy.xlsx",sheet="addcost_scenario")%>%setDT()
# map_data=data.table(map_data1[,.(ISO3)],map_data1[,.(Grade_1)],map_data2[,.(Grade_1)])
# setnames(map_data,c("ISO3","base","scenario"))

#map <- left_join(map_data, world_df, by =c ("ISO3"="id"))

map <- left_join(map_data, world_df, by =c ("load_zone"="id"))
map_10 <- left_join(map_data_10, world_df, by =c ("load_zone"="id"))

p1=ggplot() +
  geom_polygon(data = map, aes(x=long, y = lat, group = group,fill=levelized_country),colour="grey",size=0.2)+
  scale_fill_gradientn(colours  = c("#FFFFCC","#FFFF00","#FF3333","#660033"),
                       limits=c(30,60),
                       breaks=c(30,40,50,60),
                       oob=squish
  )+
  guides(fill=guide_colorbar(barheight =0.8,barwidth = 20,title = "$/MWh",
                             title.hjust = 0,
                             ticks.colour = "black",
                             ticks.linewidth = 1.5))+
  theme(legend.text = element_text(size=12,colour = "black"),
        legend.title = element_text(size=12,colour = "black"),
        legend.position = "bottom",
        panel.background= element_blank(),
        panel.border = element_rect(colour = "black",fill=NA),
        panel.grid.major = element_line(colour = NA), 
        panel.grid.minor = element_line(colour = NA)
        )
  #theme_void()


p2=ggplot() +
  geom_polygon(data = map_10, aes(x=long, y = lat, group = group,fill=levelized_country),colour="grey",size=0.2)+
  scale_fill_gradientn(colours  = c("#FFFFCC","#FFFF00","#FF3333","#660033"),
                       limits=c(30,60),
                       breaks=c(30,40,50,60),
                       oob=squish
  )+
  #theme_void()+
  guides(fill=guide_colorbar(barheight =0.8,barwidth = 20,title = "$/MWh",
                             title.hjust = 0,
                             ticks.colour = "black",
                             ticks.linewidth = 1.5))+
  theme(legend.text = element_text(size=12,colour = "black"),
        legend.title = element_text(size=12,colour = "black"),
        legend.position = "bottom",
        panel.background= element_blank(),
        panel.border = element_rect(colour = "black",fill=NA),
        panel.grid.major = element_line(colour = NA), 
        panel.grid.minor = element_line(colour = NA)
  )

#p=ggarrange(p1,p2,nrow=1,ncol=2,common.legend = TRUE,legend="bottom",
#             labels = c("a","b"),font.label = 20)

ggsave("IEA_breakeven_100_3.eps",plot=p1,device="eps",width=200,height=100,units="mm")
ggsave("IEA_breakeven_10_3.eps",plot=p2,device="eps",width=200,height=100,units="mm")
