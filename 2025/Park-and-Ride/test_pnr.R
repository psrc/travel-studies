library(tidyverse)
library(psrcelmer)
library(leaflet)

tours <- read_csv("R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/skims_attached/survey_tours.csv")
trip_pnr_example <- read_csv("C:/Users/jlin/OneDrive - PSRC/Desktop/pnr_validate_tours.csv")
survey_trips <- read_csv("C:/Users/jlin/OneDrive - PSRC/Desktop/survey_trips.csv") %>%
  select(trip_id,person_id,hhno,pno,day,trexpfac,otaz,dtaz,omaz,dmaz,opcl,dpcl,dpurp) %>%
  filter(trip_id %in% trip_pnr_example$trip_id) %>%
  rename(totaz = otaz,
         tdtaz = dtaz,
         tomaz = omaz,
         tdmaz = dmaz,
         topcl = opcl,
         tdpcl = dpcl) %>%
  
  filter(!is.na(tdpcl)) %>%
  left_join(trip_pnr_example %>% 
              select(trip_id,tlvorig:mandatory_status,PNRjunctID,PNRname) %>%
              rename(tPNRjunctID = PNRjunctID,
                     tPNRname = PNRname), by = "trip_id") %>%
  mutate(tPNRjunctID = case_when(tPNRjunctID == 3897~ 3821,
                                 TRUE~tPNRjunctID),
         tPNRname = case_when(tPNRname == "Calvary Christian Assemby P&R"~ "Green Lake P&R",
                              TRUE~tPNRname))


tour_pnr <- read_csv("C:/Users/jlin/OneDrive - PSRC/Desktop/pnr_tours.csv") %>%
  bind_rows(survey_trips)
write.csv(tour_pnr,"C:/Users/jlin/OneDrive - PSRC/Desktop/tour_pnr_test.csv")

# got full list of pnr tours as final_tour_pnr
skims_home_lot <- read_csv("R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/skims_attached/initial/pnr_home_lot_skim_output.csv") %>%
  rename(time_home_to_pnr_lot = t,     
         driving_cost_home_to_pnr_lot = d,
         distance_home_to_pnr_lot = c) %>%
  select(-c("skimid","tod_orig","tod_pulled"))
skims_lot_dest <- read_csv("R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/skims_attached/initial/pnr_lot_dest_skim_output.csv") %>%
  rename(time_dest_to_pnr_lot = t,     
         driving_cost_dest_to_pnr_lot = d,
         distance_dest_to_pnr_lot = c) %>%
  select(-c("skimid","tod_orig","tod_pulled"))

final_tour_pnr <- read_csv("T:/60day-TEMP/Joanne_temp/tour_pnr_test.csv") %>%
  select(-1) %>%
  left_join(skims_home_lot, by = c("tour" = "id")) %>%
  left_join(skims_lot_dest, by = c("tour" = "id"))

# write.csv(final_tour_pnr,"T:/60day-TEMP/Joanne_temp/tour_pnr_full.csv")

tour_pnr_full <- read_csv("T:/60day-TEMP/Joanne_temp/tour_pnr_full.csv")
lookup <- read_csv("//modelstation2/c$/workspace/sc_asim_2023_08_03_26_data/land_use.csv") %>%
  select(MAZ,TAZ) %>%
  rename(pnr_zone_id = MAZ)
block2010 <- st_read_elmergeo('block2010') %>%
  filter(county_name=="King")

leaflet() %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addPolygons(data = block2010,
              popup = paste(
                "<b>TAZ ID:</b>",
                block2010$taz_id,
                "<br><b>MAZ ID:</b>",
                block2010$maz_id
              ))


test <- tour_pnr_full %>%
  left_join(lookup, by = c("tPNRjunctID"="TAZ")) %>%
  mutate(pnr_zone_id = case_when(tPNRjunctID == 3897~ 16232,
                                 tPNRjunctID == 3926~ 13618,
                                 TRUE~pnr_zone_id))
write.csv(test,"T:/60day-TEMP/Joanne_temp/tour_pnr_full.csv")


# get data
elmer_trips <- psrcelmer::get_query("select trip_id,depart_date,origin_lat,origin_lng,dest_lng,dest_lat,dest_purpose_cat,trip_weight from HHSurvey.v_trips where survey_year = 2023") %>%
  mutate(trip_id = as.character(trip_id))


pnr_assign <- read_csv("R:/e2projects_two/2023_base_year/park_and_ride/park-and-ride-assignment-2023.csv") %>%
  mutate(trip_id = as.character(trip_id)) %>% 
  left_join(elmer_trips, by="trip_id")
