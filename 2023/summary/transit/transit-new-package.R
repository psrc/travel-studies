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


# mode_acc to transit
# Specify which variables to retrieve
vars <- c("mode_class", "mode_acc")

hts_data <- get_psrc_hts(survey_vars = vars)

hts_data <- hts_bin_transit_mode_acc(hts_data)

# create new variable
hts_data$trip <- mutate(
  hts_data$trip,
  access_cond=case_when(mode_acc %in% c("Rode a bike", "Drove and parked a car (e.g., a vehicle in my household)",
                                        "Got dropped off", "Other") ~ "Drove/Bike/Other",
                                mode_acc %in% c("Walked or jogged") ~ "Walk")) %>%
  mutate(access_cond = factor(access_cond, levels = c("Drove/Bike/Other", "Walk")))

df <- psrc_hts_stat(hts_data, "trip", c("mode_class", "access_cond"), incl_na=FALSE) %>%
  filter(mode_class == "Transit") 

df$survey_year<-as.character(df$survey_year)

transit_acc_chart <- static_column_chart(df, x='survey_year', y='prop', fill='access_cond',ylabel= 'Share',
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

# mode based on home rgc/not rgc
vars <- c("home_rgcname", "mode_class_5", "mode_class")

hts_data <- get_psrc_hts(survey_year=2023, survey_vars = vars)

hts_data <- hts_bin_mode(hts_data)

# create new variable
hts_data$hh <- mutate(
  hts_data$hh,
  rgchome=if_else((!is.na(home_rgcname) & home_rgcname!='Not RGC'),"Regional Growth Center", "Not Regional Growth Center"))

# walk trips
df <- psrc_hts_stat(hts_data, "trip", c("rgchome", "mode_class_5"), incl_na=FALSE) %>%
  filter(mode_class_5 == "Walk")

df$survey_year<-as.character(df$survey_year)

home_rgc_chart <- static_column_chart(df, x='rgchome', y='prop', fill='rgchome',ylabel= '% of Trips',
                                       xlabel='Home Location', 
                                       #moe='prop_moe'
                                      title='Walk Trips by Home in RGCs - Share (2023)'
) + theme(axis.text.x=element_text(size=14),
          axis.text.y=element_text(size=14),
          legend.text = element_text(size=14), 
          axis.title.y=element_text(size=20), 
          axis.title.x=element_text(size=20))

# bike/micromobility trips
df <- psrc_hts_stat(hts_data, "trip", c("rgchome", "mode_class_5"), incl_na=FALSE) %>%
  filter(mode_class_5 == "Bike/Micromobility")

df$survey_year<-as.character(df$survey_year)

home_rgc_bike_chart <- static_column_chart(df, x='rgchome', y='prop', fill='rgchome',ylabel= '% of Trips',
                                      xlabel='Home Location', 
                                      moe='prop_moe',
                                      title='Bike/Micromobility Trips by Home in RGCs - Share (2023)'
) + theme(axis.text.x=element_text(size=14),
          axis.text.y=element_text(size=14),
          legend.text = element_text(size=14), 
          axis.title.y=element_text(size=20), 
          axis.title.x=element_text(size=20))
