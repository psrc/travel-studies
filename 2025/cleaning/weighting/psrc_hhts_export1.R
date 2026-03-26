library(psrcelmer)
library(magrittr)
library(data.table)

folder_path <- "C:/Joanne_PSRC/data_science/travel-studies/2025/cleaning/weighting/hts_data_for_weighting"

day <- psrcelmer::get_table("hhts_cleaning", "HHSurvey", "Day")
day %<>% setDT() %>% setnames("hhid","hh_id")
readr::write_rds(day, file.path(folder_path,"day.rds"))

person <- psrcelmer::get_table("hhts_cleaning", "HHSurvey", "Person")
person %<>% setDT() %>% .[, c("school_geog", "work_geog", "school_geom", "work_geom"):=NULL] %>% 
  setnames(paste0("race_",c("afam","aiak","asian","hapi","white","other","noanswer")),
           paste0("race_",c(1:5,997,999))) %>% setnames("hhid","hh_id") %>%
  .[, person_id:=as.character(person_id)]
readr::write_rds(person, file.path(folder_path,"person.rds"))

hh <- psrcelmer::get_table("hhts_cleaning", "HHSurvey", "Household")
hh %<>% setDT() %>% .[, c("home_geog", "sample_geog", "home_geom"):=NULL] %>%
  .[, hhid:=as.character(hhid)] %>% .[, num_people:=(numadults + numchildren)] %>%
  setnames("hhid","hh_id") %>%
  setnames(c("hh_is_complete","hhincome_detailed","hhincome_broad","hhincome_followup"),
           c("is_complete","income_detailed","income_broad","income_followup"))
readr::write_rds(hh, file.path(folder_path,"hh.rds"))

id_cols <- c("hhid", "person_id","trip_id")
trip <- psrcelmer::get_table("hhts_cleaning", "HHSurvey", "Trip")
trip %<>% setDT() %>% .[, c("origin_geog", "dest_geog", "origin_geom", "dest_geom", "recid", "initial_tripid"):=NULL] %>%
  setnames("tripid","trip_id") %>%
  .[, (id_cols) := lapply(.SD, as.character), .SDcols = id_cols] %>% setnames("hhid","hh_id")
readr::write_rds(trip, file.path(folder_path,"trip.rds"))


example_path <- "J:/Projects/Surveys/HHTravel/Survey2025/Data/delivery_20251104_weighting_script/Weighting_Inputs_2025-11-04/PSRC_2025_client_inputs"
toc_hh <- readRDS(file.path(example_path, "toc_hh.rds"))

value_labels <- readRDS(file.path(example_path, "toc_value_labels.rds"))
