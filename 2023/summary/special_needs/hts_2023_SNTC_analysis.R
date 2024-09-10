library(magrittr)
library(dplyr)
library(psrc.travelsurvey)
library(travelSurveyTools)
library(data.table)
library(psrcplot)
library(ggplot2)
library(extrafont)
library(patchwork)

sn_vars <- c("age", "vehicle_count", "hhincome_broad", "disability_person")                    # Special needs dimensions  #, "hh_race_category"
travel_dims <- c("num_trips", "dest_purpose", "duration_minutes", "mode_characterization")     # Travel behavior variables
demog_dims <- c("home_county","hh_race_category")

add_hts_cv <- function(table){
  if(any(grepl("est", colnames(table)))){
    table %<>% mutate(cv=abs(est_moe/1.645)/est)
  }else if(any(grepl("mean", colnames(table)))){
    table %<>% mutate(cv=abs(mean_moe/1.645)/mean)
  }
  return(table)
}

battery <- function(sn_var){                                                                   # Statistical summaries for each SN dimension
  hts_data2 <- copy(hts_data)
  if(sn_var=="disability_person"){
    hts_data2 %<>% lapply(FUN=function(x) dplyr::filter(x, survey_year==2023))                 # -- disability is new to the survey
  }
  sn_stat <- purrr::partial(psrc_hts_stat, hts_data=hts_data2, ... = , incl_na=FALSE) %>%      # exclude NA from share denominator
    add_hts_cv()
  rs <- list()
  rs$tripcount      <- sn_stat("person", c("adult", sn_var), "num_trips")
  rs$purpose_share   <- sn_stat("trip",  c("adult", sn_var, "dest_purpose_bin4"))
  rs$mode_share      <- sn_stat("trip",  c("adult", sn_var, "mode_basic"))
  rs$minutes         <- sn_stat("trip",  c("adult", sn_var), "duration_minutes")
  rs$groc_mode_share <- sn_stat("trip", c("adult", "purpose_grocery", sn_var, "mode_basic"))
  rs$groc_minutes    <- sn_stat("trip",  c("adult", "purpose_grocery", sn_var), "duration_minutes")
  rs$work_mode_share <- sn_stat("trip", c("adult", "purpose_work", sn_var, "mode_basic"))
  rs$work_minutes    <- sn_stat("trip",  c("adult", "purpose_work", sn_var), "duration_minutes")

  hts_data2 %<>% lapply(FUN=function(x) dplyr::filter(x, survey_year==2023))
  rs$med_tripcount   <- sn_stat("person", c("adult", "purpose_medical", sn_var), "num_trips")
  rs$med_mode_share  <- sn_stat("trip",  c("adult", "purpose_medical", sn_var, "mode_basic"))
  rs$med_distance    <- sn_stat("trip",  c("adult", "purpose_medical", sn_var), "distance_miles")
  rs$med_minutes     <- sn_stat("trip",  c("adult", "purpose_medical", sn_var, "duration_minutes"))

  rs %<>% lapply(add_hts_cv) %>%
    lapply(FUN=function(x) dplyr::select(x, !matches("^adult$|^purpose_")))                    # Drop filter columns
  return(rs)
}

hts_data <- get_psrc_hts(survey_vars=c(sn_vars, travel_dims, demog_dims))                      # Retrieve the data

hts_data %<>% hts_bin_age() %>% hts_bin_income %>% hts_bin_dest_purpose()
hts_data$hh %<>% mutate(
  veh_yn=case_when(vehicle_count=="0 (no vehicles)" ~"No vehicle",
                   !is.na(vehicle_count) ~ "1+ vehicle"))
hts_data$person %<>% mutate(
  adult=case_when(substr(age_bin3, 1L, 2L) %in% c("18","65") ~"Adult", TRUE ~ NA))             # Restricting stats to adult trips
hts_data$trip %<>% mutate(
  dest_purpose_bin4 = case_when(dest_purpose_bin4=="Home" ~NA, TRUE ~dest_purpose_bin4),       # Using purposes besides return home
  mode_basic = case_when(
    mode_characterization=="Airplane"                          ~NA,
    stringr::str_detect(mode_characterization, "HOV")          ~"HOV2+",
    mode_characterization=="Drive SOV"                         ~"Drive alone",
    stringr::str_detect(mode_characterization, "^(Walk|Bike)") ~"Walk/Bike/Micromobility",
    TRUE ~mode_characterization),
  purpose_medical = case_when(stringr::str_detect(dest_purpose,"[mM]edical") ~ "Medical",
                              !is.na(dest_purpose) ~ NA),
  purpose_grocery = case_when(stringr::str_detect(dest_purpose,"[gG]rocery") ~ "Grocery",
                             !is.na(dest_purpose) ~ NA),
  purpose_work =    case_when(dest_purpose_bin4=="Work" ~ "Work",
                              !is.na(dest_purpose_bin4) ~ NA),
  purpose_social =  case_when(stringr::str_detect(dest_purpose,"([sS]ocial|[vV]olunteer)") ~ "Social/Volunteer",
                              !is.na(dest_purpose) ~ NA),
  travelers_basic = case_when(stringr::str_detect(travelers_total,"^1 ") ~ "1 traveler",
                              travelers_total=="Missing data" ~NA,
                              !is.na(travelers_total) ~"2+ travelers"))

sn_vars %<>% case_match("age" ~ "age_bin3",
                        "hhincome_broad" ~ "hhincome_bin5",
                        "vehicle_count" ~ "veh_yn", .default=sn_vars)                          # Sub desired sn vars for source vars
rs_master <- sapply(sn_vars, battery, simplify=FALSE, USE.NAMES=TRUE)                          # Run the analysis batches for all trips

psrcplot::install_psrc_fonts()

# Tripcount plots

p_dis_count <- psrcplot::static_bar_chart(                                                     # Shows notable difference
  mutate(rs_master$disability_person$tripcount, survey_year=as.character(survey_year)),
  x="mean", y="disability_person", fill="survey_year")

p_age_count <- psrcplot::static_line_chart(                                                    # Notable small but significant difference in 2023;
  rs_master$age_bin3$tripcount,                                                                # -- larger in 2019; triprates fluctuate quite a bit.
  x="survey_year", y="mean", fill="age_bin3") + expand_limits(y = 0)

p_veh_count <- psrcplot::static_line_chart(                                                    # Notable, as expected
  rs_master$veh_yn$tripcount,
  x="survey_year", y="mean", fill="veh_yn") + expand_limits(y = 0)

p_inc_count <- psrcplot::static_line_chart(                                                    # No clear pattern over time
  rs_master$hhincome_bin5$tripcount,
  x="survey_year", y="mean", fill="hhincome_bin5") + expand_limits(y = 0)

# Purpose share plots

p_dis_purpose <- psrcplot::static_bar_chart(                                                   # Less work; more errands
  rs_master$disability_person$purpose_share,
  x="prop", y="disability_person", fill="dest_purpose_bin4",
  pos="stack", est="percent")

p_age_purpose <- psrcplot::static_bar_chart(                                                   # Less work; more errands
  filter(rs_master$age_bin3$purpose_share, survey_year==2023),
  x="prop", y="age_bin3", fill="dest_purpose_bin4",
  pos="stack", est="percent")

p_veh_purpose <- psrcplot::static_bar_chart(                                                   # Only minor differences
  filter(rs_master$veh_yn$purpose_share, survey_year==2023),                                   # -- (slightly more social, less errands)
  x="prop", y="veh_yn", fill="dest_purpose_bin4",
  pos="stack", est="percent")

p_inc_purpose <- psrcplot::static_bar_chart(                                                   # Less work, more errands at lowest income ranges
  filter(rs_master$hhincome_bin5$purpose_share, survey_year==2023),
  x="prop", y="hhincome_bin5", fill="dest_purpose_bin4",
  pos="stack", est="percent")

# Mode share plots

p_dis_mode <- psrcplot::static_bar_chart(                                                      # More HOV & transit; less SOV
  rs_master$disability_person$mode_share,
  x="prop", y="disability_person", fill="mode_basic",
  pos="stack", est="percent")

p_age_mode <- psrcplot::static_bar_chart(                                                      # Only minor differences
  filter(rs_master$age_bin3$mode_share, survey_year==2023),
  x="prop", y="age_bin3", fill="mode_basic",
  pos="stack", est="percent")

p_veh_mode <- psrcplot::static_bar_chart(                                                      # Clear impact of mode availability; shares reversed.
  filter(rs_master$veh_yn$mode_share, survey_year==2023),
  x="prop", y="veh_yn", fill="mode_basic",
  pos="stack", est="percent")

p_inc_mode <- psrcplot::static_bar_chart(                                                      # Carownership costs likely result in more transit and walk for lowest incomes
  filter(rs_master$hhincome_bin5$mode_share, survey_year==2023),
  x="prop", y="hhincome_bin5", fill="mode_basic",
  pos="stack", est="percent")

# Duration plots

p_dis_minutes <- psrcplot::static_bar_chart(                                                   # No statistically significant difference
  mutate(rs_master$disability_person$minutes,
         survey_year=as.character(survey_year)),
  x="mean", y="disability_person", fill="survey_year")

p_age_minutes <- psrcplot::static_bar_chart(                                                   # Minor but statistically significant
  mutate(filter(rs_master$age_bin3$minutes, survey_year==2023),
         survey_year=as.character(survey_year)),
  x="mean", y="age_bin3", fill="survey_year")

p_veh_minutes <- psrcplot::static_bar_chart(
  mutate(filter(rs_master$veh_yn$minutes, survey_year==2023),                                  # Substantial differences
         survey_year=as.character(survey_year)),
  x="mean", y="veh_yn", fill="survey_year")

p_inc_minutes <- psrcplot::static_bar_chart(                                                   # Substantial differences; longer for low & high ends
  mutate(filter(rs_master$hhincome_bin5$minutes, survey_year==2023),
         survey_year=as.character(survey_year)),
  x="mean", y="hhincome_bin5", fill="survey_year")

