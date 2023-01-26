library(psrc.travelsurvey)
library(psrccensus)
library(psrcplot)
library(psrctrends)
library(tidycensus)
library(psrcelmer)

library(tidyverse)
library(stringr)
library(rlang)
library(chron)
library(scales)
library(gridExtra)
library(sf)

install_psrc_fonts()

Sys.setenv(CENSUS_API_KEY = '3fc20d0d6664692c0becc323b82c752408d843d9')
Sys.getenv("CENSUS_API_KEY")

# list of all urban and metro RGCs
rgcs_tracts_list <- read_csv("rgc_tracts.csv") %>% select(-1) %>%
  inner_join(read_csv("urban_metro.csv") %>% select(3,13), 
             by = "name") %>%
  rename(urban_metro = category)
urban_metro <- read_csv("urban_metro.csv") %>% select(3,13)

# functions
source("C:/Joanne_PSRC/data_science/travel-studies/2021/analysis_in_progress/rgcs_vehicle_ownership/rgcs_functions.R")

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

## travel behavior ####
### 1. mode share ####
mode_rgc <- hhts_count(trip_data_21 %>%
                         filter(race_eth_broad != "Child -- no race specified"),
                       group_vars = c('final_home_is_rgc', 'mode_simple2'),
                       spec_wgt = 'trip_adult_weight_2021') %>% 
  add_row(
    hhts_count(trip_data_19 %>%
                 filter(race_eth_broad != "Child -- no race specified"),
               group_vars = c('final_home_is_rgc', 'mode_simple2'),
               spec_wgt = 'trip_weight_2019')
  ) %>% 
  add_row(
    hhts_count(trip_data_17 %>%
                 filter(race_eth_broad != "Child -- no race specified"),
               group_vars = c('final_home_is_rgc', 'mode_simple2'),
               spec_wgt = 'trip_weight_2017')
  ) %>% 
  filter(final_home_is_rgc != 'Total',
         !is.na(mode_simple2),
         mode_simple2 != 'Total',
         survey=="2021") %>%
  mutate(survey = factor(survey, levels = c("2017","2019","2021"))) %>%
  ggplot(aes(x=fct_rev(final_home_is_rgc), y=share, fill=mode_simple2)) +
    geom_bar(position=position_stack(reverse = TRUE), stat="identity") +
    scale_y_continuous(labels = label_percent()) +
    psrc_style2()+
    scale_fill_manual(values = psrc_colors$pognbgy_5) +
    coord_flip()

mode_metro <- hhts_count(trip_data_21 %>%
                           filter(race_eth_broad != "Child -- no race specified"),
                         group_vars = c('urban_metro', 'mode_simple2'),
                         spec_wgt = 'trip_adult_weight_2021') %>% 
  add_row(
    hhts_count(trip_data_19 %>%
                 filter(race_eth_broad != "Child -- no race specified"),
               group_vars = c('urban_metro', 'mode_simple2'),
               spec_wgt = 'trip_weight_2019')
  ) %>% 
  add_row(
    hhts_count(trip_data_17 %>%
                 filter(race_eth_broad != "Child -- no race specified"),
               group_vars = c('urban_metro', 'mode_simple2'),
               spec_wgt = 'trip_weight_2017')
  ) %>% 
  filter(urban_metro != 'Total',
         !is.na(mode_simple2),
         mode_simple2 != 'Total') %>%
  mutate(survey = factor(survey, levels = c("2017","2019","2021"))) 

# mode_metro$survey <- factor(mode_metro$survey, levels = c("2017","2019","2021"))
# mode_rgc$survey <- factor(mode_rgc$survey, levels = c("2017","2019","2021"))

### 2. change in mode share ####
mode_change_rgc <- hhts_count(trip_data_17_19 %>%
                          filter(race_eth_broad != "Child -- no race specified"),
                        group_vars = c('final_home_is_rgc', 'mode_simple2'),
                        spec_wgt = 'trip_weight_2017_2019') %>%  
  add_row(hhts_count(trip_data_21 %>%
                       filter(race_eth_broad != "Child -- no race specified"),
                     group_vars = c('final_home_is_rgc', 'mode_simple2'),
                     spec_wgt = 'trip_adult_weight_2021')) %>% 
  filter(final_home_is_rgc != 'Total',
         !is.na(mode_simple2),
         mode_simple2 != 'Total') 

mode_change_rgc <- mode_change_rgc %>%
  left_join(mode_change_rgc[mode_change_rgc$survey=="2017_2019",c(2,3,6,7)] %>% 
              rename(share_base = share,
                     share_moe_base = share_moe),
            by = c("final_home_is_rgc", "mode_simple2")) %>%
  filter(survey!="2017_2019",
         mode_simple2!="Other") %>%
  mutate(
    share_change = (share-share_base) / share_base,
    share_moe_change = moe_ratio(share, share_base, share_moe, share_moe_base)
  ) %>%
  ggplot(aes(x=mode_simple2, y=share_change, fill=final_home_is_rgc)) +
    geom_col(position = "dodge")+
    geom_errorbar(aes(ymin=share_change-share_moe_change, ymax=share_change+share_moe_change),
                  width=0.2, position = position_dodge(0.9)) +
    scale_y_continuous(labels=percent,breaks=seq(-0.8,0.8,0.2)) +
    scale_fill_discrete_psrc ("pognbgy_10")+
    # ggtitle("Change in mode share in RGCs \n(2021 compared to 2017/2019 HHTS)")+
    psrc_style2()

mode_change_metro <- hhts_count(trip_data_17_19 %>%
                            filter(race_eth_broad != "Child -- no race specified"),
                          group_vars = c('urban_metro', 'mode_simple2'),
                          spec_wgt = 'trip_weight_2017_2019') %>%  
  add_row(hhts_count(trip_data_21 %>%
                       filter(race_eth_broad != "Child -- no race specified"),
                     group_vars = c('urban_metro', 'mode_simple2'),
                     spec_wgt = 'trip_adult_weight_2021')) %>% 
  filter(urban_metro != 'Total',
         !is.na(mode_simple2),
         mode_simple2 != 'Total')

mode_change_metro <- mode_change_metro %>%
  left_join(mode_change_metro[mode_change_metro$survey=="2017_2019",c(2,3,6,7)] %>% 
              rename(share_base = share,
                     share_moe_base = share_moe),
            by = c("urban_metro", "mode_simple2")) %>%
  filter(survey!="2017_2019",
         mode_simple2!="Other",
         !(mode_simple2=="Transit" & urban_metro=="Urban")) %>%
  mutate(
    share_change = (share-share_base) / share_base,
    share_moe_change = moe_ratio(share, share_base, share_moe, share_moe_base)
  ) 

### 3. trip travel time and distance ####
time_dist_rgc <- hhts_mean(trip_data_21, stat_var = 'trip_path_distance',
                  group_vars=c('final_home_is_rgc'),
                  spec_wgt='trip_adult_weight_2021') %>%
  filter(final_home_is_rgc!='Total') %>%
  mutate(label = "Trip distance (miles)") %>%
  rename(mean = trip_path_distance_mean,
         mean_moe = trip_path_distance_mean_moe) %>%
  add_row(hhts_mean(trip_data_21, stat_var = 'google_duration',
                    group_vars=c('final_home_is_rgc'),
                    spec_wgt='trip_adult_weight_2021') %>%
            filter(final_home_is_rgc!='Total') %>%
            mutate(label = "Travel time (minutes)") %>%
            rename(mean = google_duration_mean,
                   mean_moe = google_duration_mean_moe)) %>%
  ggplot(aes(x=final_home_is_rgc, y=mean, fill=final_home_is_rgc)) +
    geom_col(position = "dodge")+  
    geom_errorbar(aes(ymin=mean-mean_moe, 
                      ymax=mean+mean_moe),
                  width=0.2, position = position_dodge(0.9))+
    scale_fill_discrete_psrc ("pognbgy_10")+
    facet_wrap(~label, scales = "free_y") +
    psrc_style2(text_size = 2) + 
    theme(plot.title = element_blank())

time_dist_metro <- hhts_mean(trip_data_21, stat_var = 'trip_path_distance',
                  group_vars=c('urban_metro'),
                  spec_wgt='trip_adult_weight_2021') %>%
  filter(urban_metro!='Total') %>%
  mutate(label = "Trip distance (miles)") %>%
  rename(mean = trip_path_distance_mean,
         mean_moe = trip_path_distance_mean_moe) %>%
  add_row(hhts_mean(trip_data_21, stat_var = 'google_duration',
                    group_vars=c('urban_metro'),
                    spec_wgt='trip_adult_weight_2021') %>%
            filter(urban_metro!='Total') %>%
            mutate(label = "Travel time (minutes)") %>%
            rename(mean = google_duration_mean,
                   mean_moe = google_duration_mean_moe))

### 4. walking and transit frequencies ####
freq <- per_data_21 %>%
  mutate(walk_label = case_when(walk_freq %in% c("1 day/week",
                                                 "2-4 days/week",
                                                 "5 days/week",
                                                 "6-7 days/week")~"at least 1 day/week",
                                TRUE~ "less than 1 day/week"),
         transit_label = case_when(transit_freq %in% c("1 day/week",
                                                       "2-4 days/week",
                                                       "5 days/week",
                                                       "6-7 days/week")~"at least 1 day/week",
                                   TRUE~ "less than 1 day/week"))

freq_transit <- hhts_count(freq, 
                   group_vars=c("urban_metro", "transit_label"),
                   spec_wgt = "person_adult_weight_2021") %>%
  filter(transit_label!="Total")  %>%
  ggplot(aes(x=transit_label, y=share, fill=urban_metro)) +
  geom_col(position = "dodge")+  
  moe_bars+
  scale_y_continuous(labels=percent) +
  scale_fill_discrete_psrc ("gnbopgy_5")+
  psrc_style2() + 
  theme(plot.title = element_blank())

freq_walk  <- hhts_count(freq, 
                    group_vars=c("urban_metro", "walk_label"),
                    spec_wgt = "person_adult_weight_2021") %>%
  filter(walk_label!="Total") %>%
  ggplot(aes(x=walk_label, y=share, fill=urban_metro)) +
    geom_col(position = "dodge")+  
    moe_bars+
    scale_y_continuous(labels=percent) +
    scale_fill_discrete_psrc ("gnbopgy_5")+
    psrc_style2() + 
  theme(plot.title = element_blank())


## demographics ####
add_RGCs <- function(.data){
  .data <- .data %>%
    mutate(RGC = case_when(GEOID %in% rgcs_tracts_list$geoid~"RGC",
                           !GEOID %in% rgcs_tracts_list$geoid~"Not RGC"),
           urban_metro = case_when(GEOID %in% rgcs_tracts_list[rgcs_tracts_list$urban_metro=="Metro", ]$geoid~"Metro",
                                   GEOID %in% rgcs_tracts_list[rgcs_tracts_list$urban_metro=="Urban", ]$geoid~"Urban",
                                   !GEOID %in% rgcs_tracts_list$geoid~"Not RGC"))
  
  .data$RGC <- factor(.data$RGC, levels=c("RGC","Not RGC"))
  .data$urban_metro <- factor(.data$urban_metro, levels=c("Metro","Urban","Not RGC"))
  
  return(.data)
}
## 2021 ACS 1-year data

### 1. age ####
plot_age <- get_acs_recs(geography = 'tract',
                    table.names = 'B01001',
                    years = 2021,
                    acs.type = 'acs5') %>%
  add_RGCs() %>%
  filter(!label %in% c("Estimate!!Total:","Estimate!!Total:!!Male:","Estimate!!Total:!!Female:" )) %>%
  mutate(label2 = str_remove_all(label,"Estimate!!Total:"),
         label2 = str_remove_all(label2,"!!Male:"),
         label2 = str_remove_all(label2,"!!Female:"),
         label2 = str_remove_all(label2,"!!"),
         label3 = case_when(label2 %in% c("10 to 14 years","15 to 17 years",
                                          "5 to 9 years","Under 5 years")~ "< 18 years",
                            label2 %in% c("18 and 19 years",  
                                          "20 years",         
                                          "21 years",         
                                          "22 to 24 years",   
                                          "25 to 29 years",   
                                          "30 to 34 years")~ "18-34 years",
                            label2 %in% c("35 to 39 years",
                                          "40 to 44 years",
                                          "45 to 49 years",
                                          "50 to 54 years",
                                          "55 to 59 years",
                                          "60 and 61 years",
                                          "62 to 64 years")~ "35-64 years",
                            label2 %in% c("65 and 66 years",
                                          "67 to 69 years",
                                          "70 to 74 years",
                                          "75 to 79 years",
                                          "80 to 84 years",
                                          "85 years and over")~ "65+ years",
                            TRUE ~ label2)) %>%
  group_by(label3, RGC) %>%
  summarise(estimate = sum(estimate),
            moe = moe_sum(moe, estimate = estimate) )%>%
  group_by(RGC) %>%
  mutate(share = estimate/sum(estimate),
         share_moe = moe_ratio(estimate, sum(estimate), moe, moe_sum(moe, estimate = estimate))) %>%
  ungroup() %>% 
  ggplot(aes(x=label3, y=share, fill=RGC)) +
    geom_col(position = "dodge")+  
    moe_bars +
    scale_y_continuous(labels=percent,limits = c(0, 0.41)) +
    scale_fill_discrete_psrc ("gnbopgy_5")+
    psrc_style2() + 
    theme(plot.title = element_blank())


### 2. vehicle ownership ####
plot_veh_own <- get_acs_recs(geography = 'tract',
                        table.names = 'B08201',
                        years = 2021,
                        acs.type = 'acs1')  %>%
  add_RGCs() %>%
  filter(label %in% c(#"Estimate!!Total:",
                      "Estimate!!Total:!!No vehicle available",
                      "Estimate!!Total:!!1 vehicle available",
                      "Estimate!!Total:!!2 vehicles available",
                      "Estimate!!Total:!!3 vehicles available",
                      "Estimate!!Total:!!4 or more vehicles available")) %>%
  mutate(label2 = case_when(label %in% c("Estimate!!Total:!!1 vehicle available",
                                         "Estimate!!Total:!!2 vehicles available",
                                         "Estimate!!Total:!!3 vehicles available",
                                         "Estimate!!Total:!!4 or more vehicles available")~"1 or more vehicle(s)",
                            label=="Estimate!!Total:!!No vehicle available"~"No vehicle")) %>%
  group_by(label2,RGC) %>%
  summarise(estimate = sum(estimate),
            moe = moe_sum(moe, estimate = estimate)) %>%
  group_by(RGC) %>%
  mutate(share = estimate/sum(estimate),
         share_moe = moe_ratio(estimate, sum(estimate), moe, moe_sum(moe, estimate = estimate))) %>%
  ungroup() %>%
  filter(label2 == "1 or more vehicle(s)") %>%
  ggplot(aes(x=label2, y=share, fill=RGC)) +
    geom_col(position = "dodge")+  
    moe_bars +
    scale_y_continuous(labels=percent) +
    scale_fill_discrete_psrc ("gnbopgy_5")+
    psrc_style2(m.r=3,m.l=3) + 
    theme(plot.title = element_blank())

### 2. household size ####
plot_hhsize <- get_acs_recs(geography = 'tract',
                            table.names = 'B08201',
                            years = 2021,
                            acs.type = 'acs1') %>%
  filter(label %in% c(#"Estimate!!Total:",
    "Estimate!!Total:!!1-person household:",
    "Estimate!!Total:!!2-person household:",
    "Estimate!!Total:!!3-person household:",
    "Estimate!!Total:!!4-or-more-person household:")) %>%
  add_RGCs() %>%
  mutate(label2 = case_when(label == "Estimate!!Total:!!1-person household:" ~ "Single-person",
                            TRUE~"2-or-more-person"))%>%
  group_by(label2,RGC) %>%
  summarise(estimate = sum(estimate),
            moe = moe_sum(moe, estimate = estimate)) %>%
  group_by(RGC) %>%
  mutate(share = estimate/sum(estimate),
         share_moe = moe_ratio(estimate, sum(estimate), moe, moe_sum(moe, estimate = estimate))) %>%
  ungroup() %>%
  filter(label2 =="Single-person")%>%
  ggplot(aes(x=label2, y=share, fill=RGC)) +
    geom_col(position = "dodge")+  
    moe_bars +
    scale_y_continuous(labels=percent) +
    scale_fill_discrete_psrc ("gnbopgy_5")+
    psrc_style2() + 
    # psrc_style2(m.r=3,m.l=3) + 
    theme(plot.title = element_blank())

#income
plot_income <- get_acs_recs(geography = 'tract',
                         table.names = 'B19001',
                         years = 2021,
                         acs.type = 'acs1') %>%
  add_RGCs() %>%
  filter(label != "Estimate!!Total:") %>%
  mutate(label2 = case_when(label %in% c("Estimate!!Total:!!Less than $10,000",
                                         "Estimate!!Total:!!$10,000 to $14,999",
                                         "Estimate!!Total:!!$15,000 to $19,999",
                                         "Estimate!!Total:!!$20,000 to $24,999",
                                         "Estimate!!Total:!!$25,000 to $29,999",
                                         "Estimate!!Total:!!$30,000 to $34,999",
                                         "Estimate!!Total:!!$35,000 to $39,999",
                                         "Estimate!!Total:!!$40,000 to $44,999",
                                         "Estimate!!Total:!!$45,000 to $49,999") ~ "Under $50,000",
                            TRUE~"$50,000 and over"),
         label2 = factor(label2, levels=c("Under $50,000","$50,000 and over"))) %>%
  group_by(label2,RGC) %>%
  summarise(estimate = sum(estimate),
            moe = moe_sum(moe, estimate = estimate)) %>%
  group_by(RGC) %>%
  mutate(share = estimate/sum(estimate),
         share_moe = moe_ratio(estimate, sum(estimate), moe, moe_sum(moe, estimate = estimate))) %>%
  ungroup() %>%
  ggplot(aes(x=label2, y=share, fill=RGC)) +
    geom_col(position = "dodge")+
    moe_bars +
    scale_y_continuous(labels=percent) +
    scale_fill_discrete_psrc ("gnbopgy_5")+
    # psrc_style2() + 
    psrc_style2(m.r=3,m.l=3) +
    theme(plot.title = element_blank())

#-- ACS 2021 with block groups ----
sf_use_s2(FALSE)

rgc_blkgrp20 <- st_join(st_read_elmergeo('BLOCKGRP2020'),st_read_elmergeo('URBAN_CENTERS')) %>%
  mutate(name = ifelse(is.na(name),"Not RGC", name),
         category = ifelse(is.na(category),"Not RGC", category),
         RGC = ifelse(category=="Not RGC", "Not RGC", "RGC")) %>%
  select(geoid20,county_name,namelsad20,name,category,RGC)

# B01001
plot_age21 <- get_acs_recs(geography = 'block group',
                               table.names = 'B01001',
                               years = 2021,
                               acs.type = 'acs1')%>%
  mutate(age = case_when(grepl("Under 5 years|5 to 9 years|10 to 14 years|15 to 17 years",label) ~ "< 18 years",
                         grepl("18 and 19 years|20|21|22|25|30 to 34 years",label) ~ "18-34 years",
                         grepl("35 to 39 years|40 to 44 years|45 to 49 years|50 to 54 years|55 to 59 years|60 and 61 years|62 to 64 years",label) ~ "35-64 years",
                         grepl("65|67|70|75|80|85",label) ~ "65+ years",
                         label == "Estimate!!Total:"~ "total population"),
         .after="variable") %>%
  filter(!is.na(age)) %>%
  left_join(rgc_blkgrp20,by = c("GEOID" = "geoid20")) %>%
  group_by(RGC, age) %>%
  summarize(sum_est = sum(estimate), 
            sum_moe = moe_sum(moe, estimate)) %>%
  mutate(total_est = sum_est[age=="total population"],
         total_moe = sum_moe[age=="total population"]) %>%
  ungroup() %>%
  filter(age!="total population") %>%
  mutate(RGC = factor(RGC, levels=c("RGC", "Not RGC")),
         share = sum_est/total_est, 
         share_moe = moe_ratio(sum_est, total_est, sum_moe, total_moe)) %>% 
  ggplot(aes(x=age, y=share, fill=RGC)) +
    geom_col(position = "dodge")+  
    moe_bars +
    scale_y_continuous(labels=percent#,limits = c(0, 0.41)
                       ) +
    scale_fill_discrete_psrc ("gnbopgy_5")+
    psrc_style2() + 
    theme(plot.title = element_blank())

plot_hhsize21 <- get_acs_recs(geography = 'block group',
                         table.names = 'B11016',
                         years = 2021,
                         acs.type = 'acs1') %>%
  left_join(rgc_blkgrp20,by = c("GEOID" = "geoid20")) %>%
  mutate(hh_size = case_when(label == "Estimate!!Total:"~ "total population",
                             grepl("1-person household",label)~ "Single-person",
                             grepl("2-person household",label)~ "2-person",
                             grepl("3-person|4-person|5-person|6-person|7-or-more",label)~ "3(+)-person"),
         hh_size = factor(hh_size, levels = c("total population","Single-person","2-person","3(+)-person")),
         .after="variable") %>%
  filter(!is.na(hh_size)) %>%
  group_by(RGC, hh_size) %>%
  summarize(sum_est = sum(estimate), 
            sum_moe = moe_sum(moe, estimate)) %>%
  mutate(total_est = sum_est[hh_size=="total population"],
         total_moe = sum_moe[hh_size=="total population"])%>%
  ungroup() %>%
  filter(hh_size!="total population") %>%
  mutate(RGC = factor(RGC, levels=c("RGC", "Not RGC")),
         share = sum_est/total_est, 
         share_moe = moe_ratio(sum_est, total_est, sum_moe, total_moe)) %>%
  ggplot(aes(x=hh_size, y=share, fill=RGC)) +
    geom_col(position = "dodge")+  
    moe_bars +
    scale_y_continuous(labels=percent) +
    scale_fill_discrete_psrc ("gnbopgy_5")+
    psrc_style2(m.r=3,m.l=3) +
    theme(plot.title = element_blank())
    # ggtitle("(b) household size")

plot_veh21_rgc <- get_acs_recs(geography = 'block group',
                                  table.names = 'B25044',
                                  years = 2021,
                                  acs.type = 'acs1')%>%
  mutate(vehicle = case_when(
    grepl("No vehicle",label) ~ "No vehicle",
    grepl("1 vehicle|2 vehicles|3 vehicles|4 vehicles|5 or more vehicles",label) ~ "1+ vehicle(s)",
    label == "Estimate!!Total:" ~ "total population")) %>%
  filter(!is.na(vehicle)) %>%
  left_join(rgc_blkgrp20,by = c("GEOID" = "geoid20")) %>%
  group_by(RGC, vehicle) %>%
  summarize(sum_est = sum(estimate), 
            sum_moe = moe_sum(moe, estimate)) %>%
  mutate(total_est = sum_est[vehicle=="total population"],
         total_moe = sum_moe[vehicle=="total population"]) %>%
  ungroup() %>%
  filter(vehicle=="1+ vehicle(s)") %>%
  mutate(RGC = factor(RGC, levels=c("RGC", "Not RGC")),
         share = sum_est/total_est, 
         share_moe = moe_ratio(sum_est, total_est, sum_moe, total_moe))  %>%
  ggplot(aes(x=vehicle, y=share, fill=RGC)) +
  geom_col(position = "dodge")+  
  moe_bars +
  scale_y_continuous(labels=percent) +
  scale_fill_discrete_psrc ("gnbopgy_5")+
  psrc_style2(m.t=0.5,m.r=5,m.l=5) + 
  theme(plot.title = element_blank())
  # ggtitle("(d) vehicle ownership")

##-- metro and urban RGCs ----


plot_age21_mu <- get_acs_recs(geography = 'block group',
                           table.names = 'B01001',
                           years = 2021,
                           acs.type = 'acs1')%>%
  mutate(age = case_when(grepl("Under 5 years|5 to 9 years|10 to 14 years|15 to 17 years",label) ~ "< 18 years",
                         grepl("18 and 19 years|20|21|22|25|30 to 34 years",label) ~ "18-34 years",
                         grepl("35 to 39 years|40 to 44 years|45 to 49 years|50 to 54 years|55 to 59 years|60 and 61 years|62 to 64 years",label) ~ "35-64 years",
                         grepl("65|67|70|75|80|85",label) ~ "65+ years",
                         label == "Estimate!!Total:"~ "total population"),
         .after="variable") %>%
  filter(!is.na(age)) %>%
  left_join(rgc_blkgrp20,by = c("GEOID" = "geoid20")) %>%
  group_by(category, age) %>%
  summarize(sum_est = sum(estimate), 
            sum_moe = moe_sum(moe, estimate)) %>%
  mutate(total_est = sum_est[age=="total population"],
         total_moe = sum_moe[age=="total population"]) %>%
  ungroup() %>%
  filter(age!="total population") %>%
  mutate(category = factor(category, levels=c("Metro", "Urban", "Not RGC")),
         share = sum_est/total_est, 
         share_moe = moe_ratio(sum_est, total_est, sum_moe, total_moe)) %>% 
  ggplot(aes(x=age, y=share, fill=category)) +
  geom_col(position = "dodge")+  
  moe_bars +
  scale_y_continuous(labels=percent#,limits = c(0, 0.41)
  ) +
  scale_fill_discrete_psrc ("gnbopgy_5")+
  psrc_style2() + 
  theme(plot.title = element_blank())

plot_income_mu <- get_acs_recs(geography = 'tract',
                            table.names = 'B19001',
                            years = 2021,
                            acs.type = 'acs1') %>%
  add_RGCs() %>%
  filter(label != "Estimate!!Total:") %>%
  mutate(label2 = case_when(label %in% c("Estimate!!Total:!!Less than $10,000",
                                         "Estimate!!Total:!!$10,000 to $14,999",
                                         "Estimate!!Total:!!$15,000 to $19,999",
                                         "Estimate!!Total:!!$20,000 to $24,999",
                                         "Estimate!!Total:!!$25,000 to $29,999",
                                         "Estimate!!Total:!!$30,000 to $34,999",
                                         "Estimate!!Total:!!$35,000 to $39,999",
                                         "Estimate!!Total:!!$40,000 to $44,999",
                                         "Estimate!!Total:!!$45,000 to $49,999") ~ "Under $50,000",
                            TRUE~"$50,000 and over"),
         label2 = factor(label2, levels=c("Under $50,000","$50,000 and over"))) %>%
  group_by(label2,urban_metro) %>%
  summarise(estimate = sum(estimate),
            moe = moe_sum(moe, estimate = estimate)) %>%
  group_by(urban_metro) %>%
  mutate(share = estimate/sum(estimate),
         share_moe = moe_ratio(estimate, sum(estimate), moe, moe_sum(moe, estimate = estimate))) %>%
  ungroup() %>%
  ggplot(aes(x=label2, y=share, fill=urban_metro)) +
  geom_col(position = "dodge")+
  moe_bars +
  scale_y_continuous(labels=percent) +
  scale_fill_discrete_psrc ("gnbopgy_5")+
  # psrc_style2() + 
  psrc_style2(m.r=3,m.l=3) +
  theme(plot.title = element_blank())

plot_hhsize21_mu <- get_acs_recs(geography = 'block group',
                              table.names = 'B11016',
                              years = 2021,
                              acs.type = 'acs1') %>%
  left_join(rgc_blkgrp20,by = c("GEOID" = "geoid20")) %>%
  mutate(hh_size = case_when(label == "Estimate!!Total:"~ "total population",
                             grepl("1-person household",label)~ "Single-person",
                             grepl("2-person household",label)~ "2-person",
                             grepl("3-person|4-person|5-person|6-person|7-or-more",label)~ "3(+)-person"),
         hh_size = factor(hh_size, levels = c("total population","Single-person","2-person","3(+)-person")),
         .after="variable") %>%
  filter(!is.na(hh_size)) %>%
  group_by(category, hh_size) %>%
  summarize(sum_est = sum(estimate), 
            sum_moe = moe_sum(moe, estimate)) %>%
  mutate(total_est = sum_est[hh_size=="total population"],
         total_moe = sum_moe[hh_size=="total population"])%>%
  ungroup() %>%
  filter(hh_size!="total population") %>%
  mutate(category = factor(category, levels=c("Metro", "Urban", "Not RGC")),
         share = sum_est/total_est, 
         share_moe = moe_ratio(sum_est, total_est, sum_moe, total_moe)) %>%
  ggplot(aes(x=hh_size, y=share, fill=category)) +
  geom_col(position = "dodge")+  
  moe_bars +
  scale_y_continuous(labels=percent) +
  scale_fill_discrete_psrc ("gnbopgy_5")+
  psrc_style2(m.r=2,m.l=2) +
  theme(plot.title = element_blank())

plot_veh21_rgc_mu <- get_acs_recs(geography = 'block group',
                      table.names = 'B25044',
                      years = 2021,
                      acs.type = 'acs1')%>%
  mutate(vehicle = case_when(
    grepl("No vehicle",label) ~ "No vehicle",
    grepl("1 vehicle|2 vehicles|3 vehicles|4 vehicles|5 or more vehicles",label) ~ "1+ vehicle(s)",
    label == "Estimate!!Total:" ~ "total population")) %>%
  filter(!is.na(vehicle)) %>%
  left_join(rgc_blkgrp20,by = c("GEOID" = "geoid20")) %>%
  group_by(category, vehicle) %>%
  summarize(sum_est = sum(estimate), 
            sum_moe = moe_sum(moe, estimate)) %>%
  mutate(total_est = sum_est[vehicle=="total population"],
         total_moe = sum_moe[vehicle=="total population"]) %>%
  ungroup() %>%
  filter(vehicle=="1+ vehicle(s)") %>%
  mutate(category = factor(category, levels=c("Metro", "Urban", "Not RGC")),
         share = sum_est/total_est, 
         share_moe = moe_ratio(sum_est, total_est, sum_moe, total_moe))  %>%
  ggplot(aes(x=vehicle, y=share, fill=category)) +
    geom_col(position = "dodge")+  
    moe_bars +
    scale_y_continuous(labels=percent) +
    scale_fill_discrete_psrc ("gnbopgy_5")+
    psrc_style2(m.t=0.5,m.r=4,m.l=4) + 
    theme(plot.title = element_blank())


get_legend<-function(myggplot){
  tmp <- ggplot_gtable(ggplot_build(myggplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  legend <- tmp$grobs[[leg]]
  return(legend)
}

demo_legend <- get_legend(plot_veh21_rgc)
