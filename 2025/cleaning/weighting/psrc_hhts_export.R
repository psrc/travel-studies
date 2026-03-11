library(psrcelmer)
library(magrittr)
library(data.table)
library(tidyverse)

folder_path <- "C:/Joanne_PSRC/data_science/travel-studies/2025/cleaning/weighting/hts_data_for_weighting"

day_change_vec <- c(
  "hhid" = "hh_id",
  "daynum" = "day_num",
  "pernum" = "person_num",
  "loc_end" = "begin_day",
  "loc_start" = "end_day"
)

person_change_vec <- c(
  "hhid"                = "hh_id",
  "pernum"              = "person_num",
  "numdayscomplete"     = "num_days_complete",
  "person_is_complete"  = "is_complete",
  "proxy"               = "is_proxy",
  "race_afam"           = "race_1",
  "race_aiak"           = "race_2",
  "race_asian"          = "race_3",
  "race_hapi"           = "race_4",
  "race_white"          = "race_5",
  "race_other"          = "race_997",
  "race_noanswer"       = "race_999",
  "school_bg"           = "school_bg_2020",
  "work_bg"             = "work_bg_2020",
  "work_puma10"         = "work_puma_2012",
  "workplace"           = "job_type",
  "disability_person"   = "disability",
  "schooltype"          = "school_type",
  "school_mode_typical" = "school_mode",
  "school_puma10"       = "school_puma_2012"
)

hh_change_vec <- c(
  "hhid"                  = "hh_id",
  "hh_is_complete"        = "is_complete",
  "hhincome_detailed"     = "income_detailed",
  "hhincome_broad"        = "income_broad",
  "hhincome_followup"     = "income_followup",
  "hhsize"                = "num_people",
  "numdayscomplete"       = "num_days_complete",
  "rent_own"              = "residence_rent_own",
  "numworkers"            = "num_workers",
  "numadults"             = "num_adults",
  "numchildren"           = "num_kids",
  "traveldate_end"        = "first_travel_date",
  "traveldate_start"      = "last_travel_date",
  "prev_home_notwa_zip"   = "prev_home_not_wa_zip",
  "vehicle_count"         = "num_vehicles",
  "hhgroup"               =  "participation_group",
  "res_dur"               = "residence_duration",
  "res_type"              = "residence_type",
  "sample_lat"            = "sample_home_lat",
  "sample_lng"            = "sample_home_lon",
  "prev_home_notwa_state" = "prev_home_not_wa_state"
)

trip_change_vec <- c(
  "hhid"               = "hh_id",
  "tripid"             = "trip_id",
  "traveldate"         = "travel_date",
  "hh_day_iscomplete"  = "hh_day_complete",
  "day_iscomplete"     = "day_is_complete",
  "svy_complete"       = "trip_survey_complete",
  "origin_lat"         = "o_lat",
  "origin_lng"         = "o_lon",
  "dest_lat"           = "d_lat",
  "dest_lng"           = "d_lon",
  "travelers_total"    = "num_travelers",
  "travelers_hh"       = "num_hh_travelers",
  "travelers_nonhh"    = "num_non_hh_travelers"
)

full_change_vec <- c(day_change_vec, person_change_vec, hh_change_vec, trip_change_vec)
full_change_vec <- full_change_vec[!duplicated(names(full_change_vec))]

day <- psrcelmer::get_table("hhts_cleaning", "HHSurvey", "Day")
chg_day_datatype_cols <- c("num_complete_trip_surveys","num_trips")
day %<>% setDT() %>% setnames(names(day_change_vec), day_change_vec) %>%
  .[, (chg_day_datatype_cols) := lapply(.SD, as.numeric), .SDcols = chg_day_datatype_cols] 
readr::write_rds(day, file.path(folder_path,"day.rds"))

person <- psrcelmer::get_table("hhts_cleaning", "HHSurvey", "Person")
person %<>% setDT() %>% .[, c("school_geog", "work_geog", "school_geom", "work_geom"):=NULL] %>% 
  setnames(names(person_change_vec), person_change_vec) %>%
  .[, person_id:=as.character(person_id)] %>% .[, c("can_drive","num_trips"):= lapply(.SD, as.numeric), .SDcols = c("can_drive","num_trips")]
readr::write_rds(person, file.path(folder_path,"person.rds"))

hh <- psrcelmer::get_table("hhts_cleaning", "HHSurvey", "Household")
hh %<>% setDT() %>% .[, c("home_geog", "sample_geog", "home_geom"):=NULL] %>%
  .[, hhid:=as.character(hhid)] %>% .[, sample_home_bg:=as.numeric(sample_home_bg)] %>%
  setnames(names(hh_change_vec), hh_change_vec)
readr::write_rds(hh, file.path(folder_path,"hh.rds"))

id_cols <- c("hh_id","person_id","trip_id")
trip <- psrcelmer::get_table("hhts_cleaning", "HHSurvey", "Trip")
trip %<>% setDT() %>% .[, c("origin_geog", "dest_geog", "origin_geom", "dest_geom", "recid", "initial_tripid"):=NULL] %>%
  setnames(names(trip_change_vec), trip_change_vec) %>%
  .[, (id_cols) := lapply(.SD, as.character), .SDcols = id_cols]
readr::write_rds(trip, file.path(folder_path,"trip.rds"))


# keep only used variables
used_vars <- read_csv("C:/Joanne_PSRC/data_science/travel-studies/2025/cleaning/weighting/used_variables_renamed.csv")

df_day <- day %>% select(used_vars[used_vars$table=="day",]$column)
df_person <- person %>% select(used_vars[used_vars$table=="person",]$column)
df_hh <- hh %>% select(used_vars[used_vars$table=="hh",]$column)
df_trip <- trip %>% select(used_vars[used_vars$table=="trip",]$column)

# explore codebook differences
psrc_value_labels <- read_csv("C:/Joanne_PSRC/data_science/travel-studies/2025/2025_codebook/rsg_value_labels.csv")
rsg_value_labels <- readRDS("J:/Projects/Surveys/HHTravel/Survey2025/Data/delivery_20251104_weighting_script/Weighting_Inputs_2025-11-04/PSRC_2025_client_inputs/toc_value_labels.rds")

# new codebook with matching variable names and psrc value labels
share_path <- "T:/60day-TEMP/MichaelJ/hts_psrc_weighting_client"

edit_value_labels <- psrc_value_labels %>%
  rename(psrc_variable = variable) %>%
  mutate(variable = case_when(
    # our dest_purpose_cat values are different from RSG's values
    psrc_variable == "dest_purpose_cat" ~ "d_purpose_category",
    psrc_variable == "origin_purpose_cat" ~ "o_purpose_category",
    TRUE~full_change_vec[psrc_variable]
  ),
  variable = ifelse(is.na(variable), psrc_variable, variable)
  ) %>%
  select(variable, value, label)
saveRDS(edit_value_labels, file.path(share_path, "value_labels_psrc.rds"))

# comparison between codebooks
diff_value_labels <- psrc_value_labels %>%
  rename(psrc_variable = variable,
         psrc_value = value,
         psrc_label = label) %>%
  mutate(rsg_variable = case_when(
           # our dest_purpose_cat values are different from RSG's values
           psrc_variable == "dest_purpose_cat" ~ "d_purpose_category",
           psrc_variable == "origin_purpose_cat" ~ "o_purpose_category",
           TRUE~full_change_vec[psrc_variable]
         ),
         rsg_variable = ifelse(is.na(rsg_variable), psrc_variable, rsg_variable)
         ) %>%
  full_join(rsg_value_labels %>%
              rename(rsg_label = label), 
            by = c("rsg_variable" = "variable",
                   "psrc_value"="value")) %>%
  mutate(diff = ifelse(rsg_label != psrc_label, 1, 0))

saveRDS(diff_value_labels, file.path(share_path, "value_labels_comparison_table.rds"))
