library(tidyverse)
library(psrcelmer)
library(leaflet)

data_path <- "R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629"

tours <- read_csv("R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/skims_attached/survey_tours.csv")
trips_skims <- read_csv("R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/skims_attached/survey_trips.csv")
pnr_tours <- tours %>%
  filter(!is.na(tPNRjunctID))

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


pnr_tours_manual <- pnr_tours %>% bind_rows(survey_trips)
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
pnr_assign <- read_csv("R:/e2projects_two/2023_base_year/park_and_ride/park-and-ride-assignment-2023.csv") %>%
  mutate(trip_id = as.character(trip_id))



# fix cleaned data for estimation bundle
p_cleaned <- "R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/cleaned"

trip <- read_csv(file.path(p_cleaned,"uncloned/override_trips.csv"))
survey_cleaned <- read_csv(file.path(p_cleaned,"survey_tours.csv"))
override_cleaned <- read_csv(file.path(p_cleaned,"override_tours.csv"))
override_uncloned_cleaned <- read_csv(file.path(p_cleaned,"uncloned/override_tours.csv"))

test1 <- override_uncloned_cleaned %>% filter(tPNRname!=-1)
test2 <- override_cleaned %>% filter(tPNRname!=-1) %>%
  mutate(in_uncloned = tour_id %in% override_uncloned_cleaned$tour_id, .before = "tour_id")
  


survey <- read_csv("R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/skims_attached/survey_trips.csv")

sample <- read_csv("T:/60day-TEMP/Joanne_temp/override_tours.csv") 
list_cols <- names(sample)

test <- survey_cleaned %>% select(all_of(names(override_cleaned)))
# missing from override `survey_tour_id`, `survey_parent_tour_id`, `composition`, `tdd`, and `atwork_subtour_frequency`

# get missing pnrs
ok_pnr <- survey_cleaned %>%
  filter(tPNRname!=-1)

missing_pnr <- survey %>%
  filter(!is.na(tPNRname)) %>%
  filter(!household_id %in% ok_pnr$household_id)

final <- survey_cleaned %>%
  bind_rows(missing_pnr)

# write.csv(final,"R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/cleaned/survey_tours.csv",
#           row.names = FALSE)

# 9/1/2026: assign school location for estimation bundle process

# get all pnr households
pnr_tour <- override_uncloned_cleaned[override_uncloned_cleaned$pnr_zone_id>0,]
hh <- read_csv(file.path(p_cleaned,"uncloned/override_households.csv"))
hh_all <- read_csv(file.path(p_cleaned,"override_households.csv"))

test <- hh %>% filter(household_id %in% pnr_tour$household_id)
test3 <- override_uncloned_cleaned %>% filter(household_id %in% pnr_tour$household_id)

test2 <- pnr_tour %>% filter(!tour_id %in% test3$tour_id)

person <- read_csv(file.path(p_cleaned,"uncloned/override_persons.csv")) %>%
  select(household_id,person_id,ptype,age,workplace_zone_id,school_zone_id) %>%
  filter(household_id %in% hh_pnr)
student_pnr_hh <- person %>% filter(ptype %in% c(3,6,7))

hh <- read_csv(file.path(p_cleaned,"survey_households.csv")) %>%
  select(household_id,home_zone_id)


# 9/15 missing maz
land_use <- read_table("R:/e2projects_two/SoundCast/Inputs/rtp_2026_2050/landuse/2023/23_on_23_v3/parcels_urbansim.txt")

test <- land_use %>% filter(parcelid==750359)
maz <- read_csv("R:/e2projects_two/activitysim/estimation/2017_2019_data/validation_data/auto_ownership/maz_bg_lookup.csv")


p_cleaned <- "R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629/cleaned"
uncloned_trips <- read_csv(file.path(p_cleaned,"uncloned/override_trips.csv"))
uncloned_tours <- read_csv(file.path(p_cleaned,"uncloned/override_tours.csv"))
uncloned_persons <- read_csv(file.path(p_cleaned,"uncloned/override_persons.csv"))

test <- trip %>% filter(origin == 46529 | destination == 46529)
tour_missing_maz <- tour %>% filter(origin == 46529 | destination == 46529)

geolocated_trip <- read_csv(file.path(data_path,"geolocated_trip.csv"))
survey_trips <- read_csv(file.path(data_path,"survey_trips.csv"))
skims_attached_trips <- read_csv(file.path(data_path,"skims_attached/survey_trips.csv"))
cleaned_trips <- read_csv(file.path(p_cleaned,"override_trips.csv"))

out_region_trips <- uncloned_trips %>% filter(d_in_region == "No" | o_in_region == "No")

out_persons <- uncloned_trips %>%
  filter(person_id %in% out_region_trips$person_id) %>%
  mutate(out_region = case_when(d_in_region == "No" | o_in_region == "No"~"Outside region",
                                                                     TRUE~"In region"),
                                              .after="trip_id") %>%
  select(person_id,trip_id,mode_class,opurp,purpose,opcl:dpcl_distance,o_in_region,d_in_region,out_region)
write.csv(out_persons,"T:/60day-TEMP/Joanne_temp/persons_with_outside_trips.csv",row.names = FALSE)


# tour_id
p_folder <- "R:/e2projects_two/2023_base_year/2023_survey/activitysim_format"
p_folder2 <- "R:/e2projects_two/2023_base_year/2023_survey/activitysim_format_20260629"
tour <- read_csv(file.path(p_folder,"survey_tours.csv"))
tour2 <- read_csv(file.path(p_folder2,"survey_tours.csv"))
[1] "#005753" "#00716c" "#00A7A0" "#40BDB8"
[5] "#73CFCB" "#BFE9E7"
