library(psrc.travelsurvey)
library(tidyverse)
library(stringr)
library(rlang)
library(chron)
library(scales)


trip_vars = c("travelers_total","mode_1","d_rgcname")
              
trip_data_17_19<- get_hhts("2017_2019", "t", vars=trip_vars) #%>% trip_group_data(per_data_17_19)
trip_data_21<-    get_hhts("2021", "t", vars=trip_vars)# %>%      trip_group_data(per_data_21)
drive <- c("Household vehicle 1",
           "Household vehicle 2",
           "Household vehicle 3",
           "Household vehicle 4",
           "Household vehicle 5",
           "Household vehicle 6",
           "Household vehicle 7",
           "Household vehicle 8",
           "Household vehicle 9",
           "Household vehicle 10",
           "Other vehicle in household",
           "Rental car",
           "Carshare service (e.g., Turo, Zipcar, Getaround, GIG)",
           "Carshare service (e.g., Turo, Zipcar, ReachNow)",
           "Other non-household vehicle",
           "Car from work",
           "Other motorcycle/moped/scooter",
           "Other motorcycle/moped",
           "Vanpool",
           "Friend/colleague's car")
recode_mode <- function(.data){
  .data %>%
    mutate(mode = case_when(mode_1 == "Walk (or jog/wheelchair)"~ "Walk",
                            mode_1 %in% c("Bicycle or e-bike (rSurvey only)",
                                          "Bicycle owned by my household (rMove only)",
                                          "Borrowed bicycle (e.g., from a friend) (rMove only)",
                                          "Bike-share bicycle (rMove only)",
                                          "Other rented bicycle (rMove only)",
                                          "Scooter or e-scooter (e.g., Lime, Bird, Razor)") ~ "Bicycle",
                            mode_1 %in% drive & travelers_total >= 2  ~ "HOV",
                            mode_1 %in% drive  ~ "SOV",
                            mode_1 %in% c("Bus (public transit)",
                                          "School bus",
                                          "Private bus or shuttle",
                                          "Paratransit",
                                          "Other bus (rMove only)",
                                          "Commuter rail (Sounder, Amtrak)",
                                          "Other rail",
                                          "Other rail (e.g., streetcar)",
                                          "Urban Rail (e.g., Link light rail, monorail)",
                                          "Urban Rail (e.g., Link light rail, monorail, streetcar)") ~ "Transit",
                            mode_1 %in% c("Taxi (e.g., Yellow Cab)",
                                          "Other hired service (Uber, Lyft, or other smartphone-app car service)") ~ "Ridehail/Taxi",
                            mode_1 %in% c("Airplane or helicopter",
                                          "Ferry or water taxi",
                                          "Other mode (e.g., skateboard, kayak, motorhome, etc.)") ~ "Other"))
  
  
}
data_rgc_mode_17_19 <- trip_data_17_19 %>% recode_mode() %>% filter(!is.na(mode))
data_rgc_mode_21 <- trip_data_21 %>% recode_mode() %>% filter(!is.na(mode))


rgc_light_rail <- c("SeaTac","Seattle Downtown","Seattle First Hill/Capitol Hill",
                    "Seattle University Community","Tacoma Downtown")
rgc_hct <- c("Auburn","Bellevue","Bothell Canyon Park","Burien",
             "Everett","Federal Way","Kent","Kirkland Totem Lake",
             "Redmond-Overlake","Redmond Downtown","Renton",
             "Seattle Northgate","Seattle South Lake Union","Seattle Uptown","Tukwila")

# match_names <- data_rgc_mode_17_19 %>%
#   mutate(RGCs = case_when(d_rgcname %in% rgc_light_rail ~ "RGC with light rail",
#                              d_rgcname %in% rgc_hct ~ "RGC with HCT",
#                              !is.na(d_rgcname) ~ "RGC with neither",
#                              is.na(d_rgcname) ~ "outside of RGCs"))
mode_share <- hhts_count(data_rgc_mode_17_19 %>%
                           mutate(RGCs = case_when(d_rgcname %in% rgc_light_rail ~ "RGC with light rail",
                                                      d_rgcname %in% rgc_hct ~ "RGC with HCT",
                                                      !is.na(d_rgcname) ~ "RGC with neither",
                                                      is.na(d_rgcname) ~ "outside of RGCs")),
                         group_vars = c('RGCs', 'mode'),
                         spec_wgt = "trip_adult_weight_2017_2019",
                         incl_na=FALSE) %>%
  add_row(
    hhts_count(data_rgc_mode_21 %>%
                 mutate(RGCs = case_when(d_rgcname %in% rgc_light_rail ~ "RGC with light rail",
                                            d_rgcname %in% rgc_hct ~ "RGC with HCT",
                                            !is.na(d_rgcname) ~ "RGC with neither",
                                            is.na(d_rgcname) ~ "outside of RGCs")),
               group_vars = c('RGCs', 'mode'),
               spec_wgt = "trip_adult_weight_2021",
               incl_na=FALSE)
  ) %>%
  mutate(survey = case_when(survey=="2017_2019"~"2017/2019",
                            survey=="2021"~"2021"))
test <- mode_share %>%
  filter(mode_fp != "Total") %>%
  group_by(survey,rgc_cat) %>%
  summarise(sum(share))

write.csv(mode_share,"C:/Users/JLin/Downloads/rgc_mode_share.csv",row.names = FALSE)
