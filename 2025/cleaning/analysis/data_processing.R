source("functions.R")

# read data
Trip <- get_query("SELECT * FROM delivered_20251021.ex_trip_unlinked", db_name = config$db_raw)
Trip_linked <- get_query("SELECT * FROM delivered_20251021.ex_trip_linked", db_name = config$db_raw)

Household <- get_query("SELECT * FROM delivered_20251021.ex_hh", db_name = config$db_raw)
Person <- get_query("SELECT * FROM delivered_20251021.ex_person", db_name = config$db_raw)
Day <- get_query("SELECT * FROM delivered_20251021.ex_day", db_name = config$db_raw)
Vehicle <- get_query("SELECT * FROM delivered_20251021.ex_vehicle", db_name = config$db_raw)
Location <- get_query("SELECT * FROM delivered_20251021.ex_location", db_name = config$db_raw)

# data processing
df_trip <- Trip %>%
  get_county("o_bg","o_county") %>%
  get_county("d_bg","d_county")

df_person <- Person %>%
  get_county("work_bg","work_county")

# 10/20/2025: fix mode_acc/mode_egr value labels
# mode_fix <- c("1" =	8, "2" =	1, "8" =	2, "9" =	18, "10" =	17, "11" =	5, "12" =	12, "97" =	97, "995" =	995)
# df_trip <- df_trip %>%
#   mutate(mode_acc_fix = recode(mode_acc, !!!mode_fix, .default = 9999),
#          mode_egr_fix = recode(mode_egr, !!!mode_fix, .default = 9999))
# df_person <- df_person %>%
#   mutate(school_freq_fix = school_freq)
# end fix




# analysis data
tables <- list("trip_unlinked"=df_trip,
               "trip_linked"=Trip_linked,
               "hh"=Household,
               "person"=df_person,
               "day"=Day,
               "vehicle"=Vehicle,
               "location"=Location)
saveRDS(tables, "analysis_table.RDS")

Trip_dest <- get_psrc_geographies(df_trip,"tripid","dest_lng","dest_lat","dest_")
Trip_origin <- get_psrc_geographies(df_trip %>% filter(!is.na(origin_lat)),"tripid","origin_lng","origin_lat","origin_")
Household_home <- get_psrc_geographies(Household %>% filter(!is.na(reported_lat)),"hhid","reported_lng","reported_lat","home_")
Person_work <- get_psrc_geographies(df_person %>% filter(!is.na(work_lat)),"person_id","work_lng","work_lat","work_")
Person_school <- get_psrc_geographies(df_person %>% filter(!is.na(school_loc_lng)),"person_id","school_loc_lng","school_loc_lat","school_")



df_trip_loc <- df_trip %>%
  select(tripid) %>%
  left_join(Trip_dest, by = "tripid") %>%
  left_join(Trip_origin, by = "tripid")
df_person_loc <- df_person %>%
  select(person_id) %>%
  left_join(Person_work, by = "person_id") %>%
  left_join(Person_school, by = "person_id")
df_hh_loc <- Household_home

saveRDS(list(df_trip_loc,df_person_loc,df_hh_loc), "df_loc.RDS")


# processing locations ----

# read data
c_Trip <- get_query("SELECT * FROM HHSurvey.Trip", db_name = config$db_clean)
c_Household <- get_query("SELECT *, home_geog.Long as lng, home_geog.Lat as lat FROM HHSurvey.Household", db_name = config$db_clean)
c_Person <- get_query("SELECT * FROM HHSurvey.Person", db_name = config$db_clean)
c_Day <- get_query("SELECT * FROM HHSurvey.Day", db_name = config$db_clean)
c_Vehicle <- get_query("SELECT * FROM HHSurvey.Vehicle", db_name = config$db_clean)
# 
# Trip_dest <- get_psrc_geographies(c_Trip,"recid","dest_lng","dest_lat","dest_")
# Trip_origin <- get_psrc_geographies(c_Trip %>% filter(!is.na(origin_lat)),"recid","origin_lng","origin_lat","origin_")
# Household_home <- get_psrc_geographies(c_Household %>% filter(!is.na(lng)),"hhid","lng","lat","home_")
# Person_work <- get_psrc_geographies(c_Person %>% filter(!is.na(work_lat)),"person_id","work_lng","work_lat","work_")
# Person_school <- get_psrc_geographies(c_Person %>% filter(!is.na(school_loc_lng)),"person_id","school_loc_lng","school_loc_lat","school_")
# 
# 
# 
# df_trip_loc <- c_Trip %>%
#   select(recid) %>%
#   left_join(Trip_dest, by = "recid") %>%
#   left_join(Trip_origin, by = "recid")
# df_person_loc <- c_Person %>%
#   select(person_id) %>%
#   left_join(Person_work, by = "person_id") %>%
#   left_join(Person_school, by = "person_id")
# df_hh_loc <- Household_home
# 
# 
# saveRDS(list(df_trip_loc,df_person_loc,df_hh_loc), "df_loc.RDS")
