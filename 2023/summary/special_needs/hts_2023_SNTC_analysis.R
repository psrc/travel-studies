library(magrittr)
library(dplyr)
library(stringr)
library(psrc.travelsurvey)
library(travelSurveyTools)
library(data.table)
library(psrcplot)
library(ggplot2)
library(extrafont)

sn_vars <- c("age", "vehicle_count", "hhincome_broad", "disability_person","hh_race_category") # Special needs dimensions  #, "hh_race_category"
travel_dims <- c("trip_n", "dest_purpose", "duration_minutes", "mode_characterization")     # Travel behavior variables
demog_dims <- c("employment","mobility_aides")

# Helper functions ------------------------------

`%not_in%` <- Negate(`%in%`)

rm_pnta <- function(table){
  filtered <- dplyr::filter(table, if_any(any_of(sn_vars))!="Prefer not to answer")
  return(filtered)
}

p_save <- function(plot){
  ggplot2::ggsave(
    filename=paste0("./2023/summary/special_needs/", deparse(substitute(plot)),".png"),
    plot=plot, device="png", units="px", width=700, height=350)
}

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
  sn_stat <- purrr::partial(psrc_hts_stat, hts_data=hts_data2, analysis_unit="trip",
                            ... = , incl_na=FALSE) %>% add_hts_cv()                            # exclude NA from share denominator
  rs <- list()
  rs$popcount     <- psrc_hts_stat(hts_data2, "person", c("adult", sn_var), incl_na=FALSE)
  rs$worker_count <- psrc_hts_stat(hts_data2, "person", c("adult", "worker", sn_var), incl_na=FALSE)
  rs$emprate      <- psrc_hts_stat(hts_data2, "person", c("adult", sn_var, "worker"), incl_na=FALSE)
  rs$tripcount       <- sn_stat(c("adult", sn_var))
  rs$purpose_share   <- sn_stat(c("adult", sn_var, "dest_purpose_bin4"))
  rs$mode_share      <- sn_stat(c("adult", sn_var, "mode_basic"))
  rs$minutes         <- sn_stat(c("adult", sn_var), "duration_minutes")
  if(sn_var!="hh_race_category"){
    hts_data2 %<>% lapply(FUN=function(x) dplyr::filter(x, survey_year==2023))
    rs$work_tripcount  <- sn_stat(c("adult", "purpose_work", sn_var))
    rs$groc_tripcount  <- sn_stat(c("adult", "purpose_grocery", sn_var))
    rs$med_tripcount   <- sn_stat(c("adult", "purpose_medical", sn_var))
  }
  rs %<>% lapply(add_hts_cv) %>%
    lapply(FUN=function(x) dplyr::select(x, !matches("^adult$|^purpose_")))                    # Drop filter columns
  if(sn_var %in% c("hhincome_bin5","disability_person")){
    rs %<>% lapply(rm_pnta)
  }else if(sn_var=="hh_race_category"){
    rs %<>% lapply(dplyr::filter, hh_race_category!="Other")
  }
  return(rs)
}

# Get data ----------------------------------------

hts_data <- get_psrc_hts(survey_vars=c(sn_vars, travel_dims, demog_dims))

# Add grouping variables --------------------------

hts_data %<>% hts_bin_age() %>% hts_bin_income %>% hts_bin_dest_purpose() %>% hts_bin_worker() # Add standard recodes
hts_data$hh %<>% mutate(
  veh_yn=factor(
    case_when(vehicle_count=="0 (no vehicles)" ~"No vehicle",
              !is.na(vehicle_count) ~ "1+ vehicle"),
    levels= c("No vehicle","1+ vehicle")),
  hhincome_bin3=factor(
    case_when(str_detect(as.character(hhincome_bin5),"\\$25") ~ "Less than $50,000",
              str_detect(as.character(hhincome_bin5),"\\$7") ~ "$50,000-$99,999",
              !is.na(hhincome_bin5) ~ hhincome_bin5),
    levels= c("Less than $50,000","$50,000-$99,999","$100,000 or more")),
  hh_race_category=factor(
    case_when(hh_race_category=="Asian" ~"Asian American, Native Hawaiian or Pacific Islander",
              hh_race_category=="African American" ~"Black or African American",
              hh_race_category=="Non-Hispanic White" ~"White",
              !is.na(hh_race_category) ~as.character(hh_race_category)),
    levels= c("Black or African American", "Asian American, Native Hawaiian or Pacific Islander",
              "Hispanic", "White", "Other")))
hts_data$person %<>% mutate(
  adult=case_when(substr(age_bin3, 1L, 2L) %in% c("18","65") ~"Adult", TRUE ~ NA),             # Restricting stats to adult trips
  age_bin3=forcats::fct_rev(age_bin3),
  disability_person=factor(disability_person, levels=c("Yes","No","Prefer not to answer")))
hts_data$trip %<>% mutate(
  dest_purpose_bin4 = case_when(dest_purpose_bin4=="Home" ~NA, TRUE ~dest_purpose_bin4),       # Using purposes besides return home
  mode_basic = case_when(
    mode_characterization=="Airplane"                          ~NA,
    str_detect(mode_characterization, "HOV")          ~"HOV2+",
    mode_characterization=="Drive SOV"                         ~"Drive alone",
    str_detect(mode_characterization, "^(Walk|Bike)") ~"Walk/Bike/Micromobility",
    TRUE ~mode_characterization),
  purpose_medical = case_when(str_detect(dest_purpose,"[mM]edical") ~ "Medical",
                              !is.na(dest_purpose) ~ NA),
  purpose_grocery = case_when(str_detect(dest_purpose,"[gG]rocery") ~ "Grocery",
                             !is.na(dest_purpose) ~ NA),
  purpose_work =    case_when(dest_purpose_bin4=="Work" ~ "Work",
                              !is.na(dest_purpose_bin4) ~ NA),
  purpose_social =  case_when(str_detect(dest_purpose,"([sS]ocial|[vV]olunteer)") ~ "Social/Volunteer",
                              !is.na(dest_purpose) ~ NA)
  ) %>%
  mutate(mode_bin3=case_when(mode_basic %in% c("Drive alone","HOV2+") ~"Drive", TRUE ~mode_basic))

sn_vars %<>% case_match("age" ~ "age_bin3",
                        "hhincome_broad" ~ "hhincome_bin5",
                        "vehicle_count" ~ "veh_yn", .default=sn_vars)                          # Sub desired sn vars for source vars

# Summarize -------------------------------------
rs_master <- sapply(sn_vars, battery, simplify=FALSE, USE.NAMES=TRUE)                          # Run the analysis batches for all trips

rs_ref <- list()
rs_ref$tripcount     <- sn_stat(c("adult"))
rs_ref$purpose_share <- sn_stat(c("adult", "dest_purpose_bin4"))
rs_ref$mode_share    <- sn_stat(c("adult", "mode_basic"))
rs_ref$minutes       <- sn_stat(c("adult"), "duration_minutes")
rs_ref$emprate <- psrc_hts_stat(hts_data2, "person", c("adult", "worker"), incl_na=FALSE)
rs_ref$veh_age <- psrc_hts_stat(hts_data2, "person", c("adult","veh_yn", "age_bin5"), incl_na=FALSE)
rs_ref$inc_age <- psrc_hts_stat(hts_data2, "person", c("adult", "hhincome_bin5","age_bin5"), incl_na=FALSE)

rs_race <- list()
rs_race$work_tripcount  <- sn_stat(c("adult", "purpose_work", "hh_race_category"))
rs_race$emprate <- psrc_hts_stat(hts_data2, "person", c("adult", "hh_race_category", "worker"), incl_na=FALSE)
rs_race$popcount <- psrc_hts_stat(hts_data2, "person", c("adult", "hh_race_category"), incl_na=FALSE)
rs_race %<>% lapply(add_hts_cv)

inc_veh_mode_share <- list()
inc_veh_mode_share$Yes <- sn_stat(c("adult", "veh_yn", "hhincome_bin5","mode_basic")) %>% add_hts_cv()
inc_veh_mode_share$No <- copy(inc_veh_mode_share$Yes) %>% filter(veh_yn=="No vehicle")
inc_veh_mode_share$Yes %<>% filter(veh_yn=="1+ vehicle")

sn_stat2 <- purrr::partial(psrc_hts_stat, hts_data=hts_data, analysis_unit="person",
                          ... = , incl_na=FALSE) %>% add_hts_cv()

dis_veh <- sn_stat2(c("adult", "disability_person", "veh_yn"))
dis_inc <- sn_stat2(c("adult", "disability_person", "hhincome_bin5"))
dis_veh <- sn_stat2(c("adult", "disability_person"))
#dis_mob <- sn_stat2(c("adult", "mobility_aides"))
dis_age <- sn_stat2(c("adult", "disability_person", "age_bin3"))
veh_inc <- sn_stat2(c("adult", "veh_yn", "hhincome_bin3"))

# Visualize -------------------------------------

# Mode share plots

mode_plots <- list()

mode_plots$p_dis_mode <- psrcplot::static_bar_chart(                                           # More HOV & transit; less SOV
  rs_master$disability_person$mode_share,,
  x="prop", y="disability_person", fill="mode_basic",
  pos="stack", est="percent")

mode_plots$p_race_mode <- psrcplot::static_bar_chart(                                          # More HOV & transit; less SOV
  filter(rs_master$hh_race_category$mode_share, survey_year==2023),
  x="prop", y="hh_race_category", fill="mode_basic",
  pos="stack", est="percent") +
  scale_x_discrete(labels = function(x) str_wrap(x, width = 30))

mode_plots$p_age_mode <- psrcplot::static_bar_chart(                                           # Only minor differences
  filter(rs_master$age_bin3$mode_share, survey_year==2023),
  x="prop", y="age_bin3", fill="mode_basic",
  pos="stack", est="percent")

mode_plots$p_veh_mode <- psrcplot::static_bar_chart(                                           # Clear impact of mode availability; shares reversed.
  filter(rs_master$veh_yn$mode_share, survey_year==2023),
  x="prop", y="veh_yn", fill="mode_basic",
  pos="stack", est="percent")

mode_plots$p_inc_mode <- psrcplot::static_bar_chart(                                           # Car ownership costs likely result in more transit and walk for lowest incomes
  filter(rs_master$hhincome_bin5$mode_share,
         survey_year==2023),
  x="prop", y="hhincome_bin5", fill="mode_basic",
  pos="stack", est="percent")

mode_plots$p_incveh_mode <- psrcplot::static_bar_chart(                                        # Car ownership costs likely result in more transit and walk for lowest incomes
  filter(inc_veh_mode_share$Yes, survey_year==2023),
  x="prop", y="hhincome_bin5", fill="mode_basic",
  pos="stack", est="percent")

mode_plots$p_inc_noveh_mode <- psrcplot::static_bar_chart(                                     # Car ownership costs likely result in more transit and walk for lowest incomes
  filter(inc_veh_mode_share$No, survey_year==2023),
  x="prop", y="hhincome_bin5", fill="mode_basic",
  pos="stack", est="percent")

# Census comparisons ------------------
library(psrccensus)
library(magrittr)

acs2022_5 <- get_psrc_pums(span=1, dyear=2022, level="p",vars=c("DIS","ESR","PRACE","AGEP"))

acs2022_5 %<>% mutate(
  employment_status=case_when(grepl("^(Civilian|Armed) ", as.character(ESR)) ~"Employed",
                              !is.na(ESR)~"Unemployed"),
  adult=case_when(AGEP>17 ~ "Adult", TRUE ~NA_character_))
rs_race_emp <- psrc_pums_count(acs2022_5,                                                      # hh_race_category results are low for Black & Hispanic employment rate
                               group_vars =c("adult","PRACE","employment_status"),             # -- issue with sample size (only 169 Black respondents)
                               incl_na=FALSE)
rs_dis <- psrc_pums_count(acs2022_5,                                                           # ACS disability reports higher regional share than HTS
                          group_vars =c("adult","DIS"),                                        # -- Wider definition and no "prefer not to answer" option
                          incl_na=FALSE)


