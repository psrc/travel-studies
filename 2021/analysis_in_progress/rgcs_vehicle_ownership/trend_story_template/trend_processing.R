library(psrc.travelsurvey)
library(psrccensus)
library(psrcplot)
library(psrctrends)
library(tidycensus)

library(tidyverse)
library(stringr)
library(rlang)
library(chron)
library(scales)
library(gridExtra)

install_psrc_fonts()
# setwd("C:/Joanne_PSRC/data_science/travel-studies/2021/analysis_in_progress/rgcs_vehicle_ownership")

Sys.setenv(CENSUS_API_KEY = '3fc20d0d6664692c0becc323b82c752408d843d9')
Sys.getenv("CENSUS_API_KEY")

# list of all urban and metro RGCs
rgcs_tracts_list <- read_csv("rgc_tracts.csv") %>% select(-1) %>%
  inner_join(read_csv("urban_metro.csv") %>% select(3,13), 
             by = "name") %>%
  rename(urban_metro = category)
urban_metro <- read_csv("urban_metro.csv") %>% select(3,13)

# functions
source("rgcs_functions.R")

# import HHTS data ####
hh_vars=c("survey_year",
          "hhid", "sample_county", "final_home_rgcnum", "final_home_is_rgc",
          "hhsize", "vehicle_count", "hhincome_broad", "hhincome_detailed", 
          "numadults", "numchildren", "numworkers", "lifecycle",
          "res_dur", "res_type", "res_months",
          "broadband", "offpark", "offpark_cost", "streetpark")

person_vars=c("person_id",  "household_id", "gender", 
              "age", "age_category", "race_category", "race_eth_broad",
              "education", "workplace", "industry", "employment",
              "worker", # for calculating number of workers in the household
              
              "license",
              "commute_freq", # How often commuted to workplace last week
              "commute_mode", # Method of commuting to work location/office last week
              "telecommute_freq",
              
              "mode_freq_1", # Times ridden transit in past 30 days
              "mode_freq_2", # Times ridden a bike in past 30 days
              "mode_freq_3", # Times gone for a walk in past 30 days
              "mode_freq_4", # Times used carshare in past 30 days
              "mode_freq_5", # Times used rideshare in past 30 days
              "benefits_3" # Employer commuter benefits: Free/partially subsidized passes/fares
              )

trip_vars = c("hhid",'person_id',
              "driver","mode_1","mode_simple",
              'dest_purpose_cat', 'origin_purpose_cat',
              "google_duration", 
              'trip_path_distance',
              "depart_time_hhmm", "arrival_time_hhmm", 
              "depart_time_mam", "arrival_time_mam",
              "dayofweek", "travelers_total")


hh_data_17_19<- get_hhts("2017_2019", "h", vars=hh_vars) %>% hh_group_data()
hh_data_17<-    get_hhts("2017", "h", vars=hh_vars) %>%      hh_group_data()
hh_data_19<-    get_hhts("2019", "h", vars=hh_vars) %>%      hh_group_data()
hh_data_21<-    get_hhts("2021", "h", vars=hh_vars) %>%      hh_group_data()


per_data_17_19<- get_hhts("2017_2019", "p", vars=person_vars) %>% per_group_data(hh_data_17_19)
per_data_17<-    get_hhts("2017", "p", vars=person_vars) %>%      per_group_data(hh_data_17)
per_data_19<-    get_hhts("2019", "p", vars=person_vars) %>%      per_group_data(hh_data_19)
per_data_21<-    get_hhts("2021", "p", vars=person_vars) %>%      per_group_data(hh_data_21)

trip_data_17_19<- get_hhts("2017_2019", "t", vars=trip_vars) %>% trip_group_data(per_data_17_19)
trip_data_17<-    get_hhts("2017", "t", vars=trip_vars) %>%      trip_group_data(per_data_17)
trip_data_19<-    get_hhts("2019", "t", vars=trip_vars) %>%      trip_group_data(per_data_19)
trip_data_21<-    get_hhts("2021", "t", vars=trip_vars) %>%      trip_group_data(per_data_21)


# RGC analysis ####

## demographics ####
## 2020 ACS 1-year data

### 1. vehicle ownership ####
acs_rgc <- get_acs_recs(geography = 'tract',
                         table.names = 'B08201',
                         years = 2021,
                         acs.type = 'acs1') 
veh_own <- acs_rgc %>%
  filter(label %in% c(#"Estimate!!Total:",
                      "Estimate!!Total:!!No vehicle available",
                      "Estimate!!Total:!!1 vehicle available",
                      "Estimate!!Total:!!2 vehicles available",
                      "Estimate!!Total:!!3 vehicles available",
                      "Estimate!!Total:!!4 or more vehicles available")) %>%
  mutate(RGC = case_when(GEOID %in% rgcs_tracts_list$geoid~"RGC",
                         !GEOID %in% rgcs_tracts_list$geoid~"Not RGC"),
         urban_metro = case_when(GEOID %in% rgcs_tracts_list[rgcs_tracts_list$urban_metro=="Metro",]$geoid~"Metro",
                                 GEOID %in% rgcs_tracts_list[rgcs_tracts_list$urban_metro=="Urban",]$geoid~"Urban",
                                 !GEOID %in% rgcs_tracts_list$geoid~"Not RGC"),
         label2 = case_when(label %in% c("Estimate!!Total:!!1 vehicle available",
                                         "Estimate!!Total:!!2 vehicles available",
                                         "Estimate!!Total:!!3 vehicles available",
                                         "Estimate!!Total:!!4 or more vehicles available")~"1 or more vehicle(s)",
                            label=="Estimate!!Total:!!No vehicle available"~"No vehicle")) %>%
  group_by(label2,urban_metro) %>%
  summarise(estimate = sum(estimate),
            moe = moe_sum(moe, estimate = estimate)) %>%
  group_by(urban_metro) %>%
  mutate(share = estimate/sum(estimate),
         share_moe = moe_ratio(estimate, sum(estimate), moe, moe_sum(moe, estimate = estimate))) %>%
  ungroup() %>%
  filter(label2 == "1 or more vehicle(s)")
veh_own$urban_metro <- factor(veh_own$urban_metro, levels=c("Metro","Urban","Not RGC")) 



# TT <- "Vehicle ownership (2021 ACS 1-year data)"
p_veh_own <- ggplot(veh_own, aes(x=label2, y=share, fill=urban_metro)) +
  geom_col(position = "dodge")+  
  moe_bars +
  scale_y_continuous(labels=percent) +
  scale_fill_discrete_psrc ("gnbopgy_5")+
  # ggtitle(TT)+
  psrc_style2(axis_text_size = 2)
# test <- veh_own %>%
#   mutate(year = "2021") %>%
#   add_row(veh_own2020 %>%
#             mutate(year = "2020"))


### 2. household size ####
hh_size <- acs_rgc %>%
  filter(label %in% c(#"Estimate!!Total:",
    "Estimate!!Total:!!1-person household:",
    "Estimate!!Total:!!2-person household:",
    "Estimate!!Total:!!3-person household:",
    "Estimate!!Total:!!4-or-more-person household:")) %>%
  mutate(RGC = case_when(GEOID %in% rgcs_tracts_list$geoid~"RGC",
                         !GEOID %in% rgcs_tracts_list$geoid~"Not RGC"),
         urban_metro = case_when(GEOID %in% rgcs_tracts_list[rgcs_tracts_list$urban_metro=="Metro",]$geoid~"Metro",
                                 GEOID %in% rgcs_tracts_list[rgcs_tracts_list$urban_metro=="Urban",]$geoid~"Urban",
                                 !GEOID %in% rgcs_tracts_list$geoid~"Not RGC"),
         label2 = case_when(label == "Estimate!!Total:!!1-person household:" ~ "Single-person",
                            TRUE~"2-or-more-person"))%>%
  group_by(label2,urban_metro) %>%
  summarise(estimate = sum(estimate),
            moe = moe_sum(moe, estimate = estimate)) %>%
  group_by(urban_metro) %>%
  mutate(share = estimate/sum(estimate),
         share_moe = moe_ratio(estimate, sum(estimate), moe, moe_sum(moe, estimate = estimate))) %>%
  ungroup() %>%
  filter(label2 =="Single-person")
hh_size$urban_metro <- factor(hh_size$urban_metro, levels=c("Metro","Urban","Not RGC")) 
hh_size$label2 <- factor(hh_size$label2, levels=c("Single-person","2-or-more-person")) 


# TT <- "Household size (2020 ACS 1-year data)"
p_hh_size <- ggplot(hh_size, aes(x=label2, y=share, fill=urban_metro)) +
  geom_col(position = "dodge")+  
  moe_bars +
  scale_y_continuous(labels=percent) +
  scale_fill_discrete_psrc ("gnbopgy_5")+
  # ggtitle(TT)+
  psrc_style2(axis_text_size = 2)