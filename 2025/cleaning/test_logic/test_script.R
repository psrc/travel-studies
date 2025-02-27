library(tidyverse)
library(psrcelmer)

# read in data
Household <- psrcelmer::get_table(db_name="hhts_cleaning", schema="HHSurvey", tbl_name="Household")
Person <- psrcelmer::get_table(db_name="hhts_cleaning", schema="HHSurvey", tbl_name="Person")
Day <- psrcelmer::get_table(db_name="hhts_cleaning", schema="HHSurvey", tbl_name="Day")
Trip <- psrcelmer::get_table(db_name="hhts_cleaning", schema="HHSurvey", tbl_name="Trip")
Vehicle <- psrcelmer::get_table(db_name="hhts_cleaning", schema="HHSurvey", tbl_name="Vehicle")

# person table summary
# count unique values for each variable
summary_Person <- data.frame()
for(var in names(Person)){
  df_summary <- Person %>%
    group_by(.data[[var]]) %>%
    summarise(count = n()) %>%
    ungroup() %>%
    mutate(variable = var) %>%
    rename(value_label=var)
  summary_Person <- rbind(summary_Person,df_summary)
}

# list of all variables need checking
# check_variable_Person <- summary_Person %>%
#   filter(is.na(value_label) | value_label==995)


# data processing
df_hh <- Household %>%
  select(hhid,diary_platform)
df_person <- Person %>%
  left_join(df_hh, by="hhid")

# list out all the variables that we want to check
all_vars <- c(
  # frequency variables
  "share_1","share_2","share_3","share_4","share_5","share_996",
  "walk_freq","bike_freq","transit_freq","tnc_freq","carshare_freq",
  # commute subsidy variables
  "commute_subsidy_1","commute_subsidy_2","commute_subsidy_3",
  "commute_subsidy_4","commute_subsidy_5","commute_subsidy_6",
  "commute_subsidy_7","commute_subsidy_996","commute_subsidy_998",
  "commute_subsidy_use_1","commute_subsidy_use_2","commute_subsidy_use_3",
  "commute_subsidy_use_4","commute_subsidy_use_5","commute_subsidy_use_6",
  "commute_subsidy_use_7","commute_subsidy_use_996",
  # other frequency variables
  "commute_freq","remote_class_freq","school_freq","telecommute_freq",
  # other variables
  "workplace","drive_for_work","school_mode_typical","work_mode",
  # school_loc
  "school_loc_lat","work_lat")


# target expressions are specified in logic.R
# each variable's target expression is named "f.var.{variable_name}"

test_var_logic <- function(table, var_name){
  
  logic <- eval(parse(text = paste0("f.var.",var_name)))
  
  df_variable <- table %>% 
    select(any_of(c("person_id", all.vars(logic), var_name))) %>%
    mutate(target = case_when(!!logic~paste0("f.var.",var_name),
                              TRUE~"not"))
  df_summary <- df_variable %>%
    group_by(target,.data[[var_name]]) %>%
    summarise(count = n()) %>%
    ungroup() %>%
    mutate(variable = var_name) %>%
    rename(value_label=var_name)
  
  return(df_summary)
  
}

# generate list of unique values for each variable (by target/not target)
test_logic <- data.frame()
for(var in all_vars){
  df_test <- test_var_logic(df_person,var)
  test_logic <- rbind(test_logic,df_test)
}
test<-test_var_logic(df_person,"commute_subsidy_use_996")

## look into variables with issues
# frequency variables
find_error <- df_person %>%
  filter(!(!!f.var.transit_freq)) %>%
  select(hhid,person_id,age_detailed,share_3,transit_freq)
find_error <- df_person %>%
  filter(share_3==995) %>%
  select(hhid,person_id,diary_platform,age_detailed,share_1,share_2,share_3,share_3,share_4,share_996,
         walk_freq,bike_freq,transit_freq,tnc_freq,carshare_freq)
find_error <- df_person %>%
  filter(transit_freq==998) %>%
  select(hhid,person_id,diary_platform,age_detailed,share_1,share_2,share_3,share_3,share_4,share_996,
         walk_freq,bike_freq,transit_freq,tnc_freq,carshare_freq)


# commute subsidy: if employment is not “not employed for pay”
find_error <- df_person %>%
  filter((!!f.var.commute_subsidy_1) & commute_subsidy_1==995) %>%
  select(hhid,person_id,age_detailed,employment,
           commute_subsidy_1,commute_subsidy_2,commute_subsidy_3,
           commute_subsidy_4,commute_subsidy_5,commute_subsidy_6,
           commute_subsidy_7,commute_subsidy_996,commute_subsidy_998)

find_error <- df_person %>%
  filter(!(!!f.var.commute_subsidy_use_3) & commute_subsidy_use_3!=995) %>%
  select(hhid,person_id,age_detailed,employment,
         commute_subsidy_3,commute_subsidy_use_3)

# commute_freq
find_error <- df_person %>%
  filter((!!f.var.commute_freq) & commute_freq==995) %>%
  select(hhid,person_id,employment,workplace,commute_freq)
# telecommute_freq
find_error <- df_person %>%
  filter((!!f.var.telecommute_freq) & telecommute_freq==995) %>%
  select(hhid,person_id,employment,commute_freq,telecommute_freq)
# drive_for_work
find_error <- df_person %>%
  filter(workplace %in% c(8,9)) %>%
  select(hhid,person_id,employment,workplace,drive_for_work)
# remote_class_freq
find_error <- df_person %>%
  filter(!(!!f.var.remote_class_freq) & remote_class_freq!=995) %>%
  select(hhid,person_id,age_detailed,student,schooltype,remote_class_freq)
# school_freq
find_error <- df_person %>%
  filter(!(!!f.var.school_freq) & school_freq!=995) %>%
  select(hhid,person_id,age_detailed,student,schooltype,school_freq)
# school_mode_typical
find_error <- df_person %>%
  filter((!!f.var.school_mode_typical) & school_mode_typical==995) %>%
  select(hhid,person_id,age_detailed,student,schooltype,school_mode_typical)
# work_mode
find_error <- df_person %>%
  # filter((!!f.var.work_mode) & work_mode==995) %>%
  filter(commute_freq==9) %>%
  select(hhid,person_id,employment,commute_freq,work_mode)

find_error <- df_person %>%
  filter(!(!!f.var.school_loc_lat) & school_loc_lat>0) %>%
  select(hhid,person_id,age_detailed,student,schooltype,school_loc_lat)
find_error <- df_person %>%
  filter(!(!!f.var.work_lat) & work_lat>0) %>%
  select(hhid,person_id,employment,office_available,work_lat)

