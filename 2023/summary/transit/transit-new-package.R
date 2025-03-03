library(psrc.travelsurvey)
library(magrittr)
library(data.table)
library(dplyr)
library(stringr)
library(psrcplot)
library(tidyverse)

# transit trips
# Specify which variables to retrieve
vars <- c("mode_class_5", "mode_class")

hts_data <- get_psrc_hts(survey_vars = vars)

hts_data <- hts_bin_mode(hts_data)

df <- psrc_hts_stat(hts_data, "trip", c("mode_class_5"), incl_na=FALSE) %>%
  filter(mode_class_5 == "Transit")

df$survey_year<-as.character(df$survey_year)

mode_chart <- static_column_chart(df, x='mode_class_5', y='prop', fill='survey_year',ylabel= 'Share',
                                  #xlabel='Mode', 
                                  moe='prop_moe'
) + theme(axis.text.x=element_text(size=14),
        axis.text.y=element_text(size=14),
        legend.text = element_text(size=14), 
        axis.title.y=element_text(size=20), 
        axis.title.x=element_text(size=20))

# mode of all trips based on destination rgc/not rgc
# Specify which variables to retrieve
vars <- c("dest_rgcname", "mode_class_5", "mode_class")

# Retrieve the data
hts_data <- get_psrc_hts(survey_year=2023, survey_vars = vars) 

hts_data <- hts_bin_mode(hts_data)

# create new variable
hts_data$trip <- mutate(
  hts_data$trip,
  rgcdest=if_else((!is.na(dest_rgcname) & dest_rgcname!='Not RGC'),"Regional Growth Center", "Not Regional Growth Center"))

df <- psrc_hts_stat(hts_data, "trip", c("rgcdest", "mode_class_5"), incl_na=FALSE) 

df$survey_year<-as.character(df$survey_year)

dest_rgc_chart <- static_column_chart(df, x='mode_class_5', y='prop', fill='rgcdest',ylabel= 'Share',
                                  #xlabel='Mode', 
                                  moe='prop_moe'
) + theme(axis.text.x=element_text(size=14),
          axis.text.y=element_text(size=14),
          legend.text = element_text(size=14), 
          axis.title.y=element_text(size=20), 
          axis.title.x=element_text(size=20))

# mode - walk trips based on home rgc/not rgc
vars <- c("home_rgcname", "mode_class_5", "mode_class")

hts_data <- get_psrc_hts(survey_vars = vars)

hts_data <- hts_bin_mode(hts_data)

# create new variable
hts_data$trip <- mutate(
  hts_data$trip,
  rgchome=if_else((!is.na(home_rgcname) & home_rgcname!='Not RGC'),"Regional Growth Center", "Not Regional Growth Center"))

df <- psrc_hts_stat(hts_data, "trip", c("rgchome", "mode_class_5"), incl_na=FALSE) 

df$survey_year<-as.character(df$survey_year)

home_rgc_chart <- static_column_chart(df, x='mode_class_5', y='prop', fill='rgcdest',ylabel= 'Share',
                                       #xlabel='Mode', 
                                       #moe='prop_moe'
) + theme(axis.text.x=element_text(size=14),
          axis.text.y=element_text(size=14),
          legend.text = element_text(size=14), 
          axis.title.y=element_text(size=20), 
          axis.title.x=element_text(size=20))
