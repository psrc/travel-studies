library(psrcplot)
library(ggplot2)


rgc_mode<-read.csv('rgcs/rgc_mode_share.csv')

rgc_mode_17_19<-rgc_mode%>%filter(survey=='2017/2019')%>%filter(mode!='Total')

static_column_chart(rgc_mode_17_19, x='mode', y='share', fill='RGCs', moe='share_moe',
                     title='All Trip Mode Share by RGC Trip Destination Location', 
                    subtitle='2017/2019 Household Travel Survey')

rgc_mode_21<-rgc_mode%>%filter(survey=='2021')%>%filter(mode!='Total')

static_column_chart(rgc_mode_21, x='mode', y='share', fill='RGCs', moe='share_moe',
                    title='All Trip Mode Share by RGC Trip Destination Location',
                    ,subtitle='2021 Household Travel Survey')