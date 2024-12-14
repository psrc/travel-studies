library(magrittr)
library(dplyr)
library(srvyr)
library(stringr)
library(psrc.travelsurvey)
library(travelSurveyTools)
library(data.table)
library(psrccensus)

#`%not_in%` <- Negate(`%in%`)

vars <- c("hh_race_category",  "hhsize","age", "gender", "vehicle_count",
          "hhincome_broad", "employment", "education", "home_county")

# PSRC HTS ------------------

hts_data <- get_psrc_hts(2023, survey_vars=vars)                                                   # Get HTS data
hts_data$hh %<>% mutate(region=1,                                                                  # Add variables; 1 for regionwide
                        veh_yn=factor(
                          case_when(vehicle_count=="0 (no vehicles)" ~"No vehicle",
                                    !is.na(vehicle_count) ~ "1+ vehicle"),
                          levels= c("No vehicle","1+ vehicle")))
hts_data %<>% hts_bin_worker() %>% hts_bin_income() %>% hts_bin_gender()

rs_hts <- list()                                                                                # Summaries in list
rs_hts$hh_count <- psrc_hts_stat(hts_data, "hh", group_vars="region")
rs_hts$hh_size <- psrc_hts_stat(hts_data, "hh", group_vars="hhsize")
rs_hts$hh_veh <- psrc_hts_stat(hts_data, "hh", group_vars="veh_yn")
rs_hts$hh_county <- psrc_hts_stat(hts_data, "hh", group_vars="home_county")
rs_hts$hh_size_county <- psrc_hts_stat(hts_data, "hh", group_vars=c("home_county","hhsize"))
rs_hts$hh_veh_county <- psrc_hts_stat(hts_data, "hh", group_vars=c("home_county","veh_yn"))

rs_hts$pop_count <- psrc_hts_stat(hts_data, "person", group_vars="region")
rs_hts$pop_county <- psrc_hts_stat(hts_data, "person", group_vars="home_county")
rs_hts$pop_worker <- psrc_hts_stat(hts_data, "person", group_vars="worker", incl_na=FALSE)
rs_hts$pop_edu <- psrc_hts_stat(hts_data, "person", group_vars="education")
rs_hts$pop_gender <- psrc_hts_stat(hts_data, "person", group_vars="gender_bin3")

# Census ACS ----------------

pums_hh_vars <- c("NP","BINCOME","HHT","VEH","NWRK","TYPEHUGQ")
pums_pp_vars <- c("SEX","ED_ATTAIN","ESR","TYPEHUGQ")

pums_hh_data <- get_psrc_pums(1, 2022, "h", pums_hh_vars) %>% filter(TYPEHUGQ=="Housing unit")
pums_pp_data <- get_psrc_pums(1, 2022, "p", pums_pp_vars) %>% filter(TYPEHUGQ=="Housing unit")

pums_pp_data %<>% mutate(worker=case_when(grepl("^(Civilian|Armed)", ESR) ~1L,
                                          !is.na(ESR)         ~0L))
pums_hh_data %<>% mutate(non_family=case_when(grepl("^Nonfamily", HHT) ~"Non-family",
                                              !is.na(HHT) ~"Family"),
                         hhsize=case_when(NP > 8 ~8, !is.na(NP) ~NP),
                         veh_yn=case_when(VEH=="No vehicles" ~"No vehicles",
                                          !is.na(VEH) ~"1+ vehicles"))
rs_pums <- list()
rs_pums$hh_count <- psrc_pums_count(pums_hh_data)
rs_pums$hh_size <- psrc_pums_count(pums_hh_data, group_vars="hhsize")
rs_pums$hh_veh <- psrc_pums_count(pums_hh_data,  group_vars="veh_yn")
rs_pums$hh_non_family <- psrc_pums_count(pums_hh_data,  group_vars=c("COUNTY","non_family"))
rs_pums$hh_county <- psrc_pums_count(pums_hh_data, group_vars="COUNTY") %>%
  filter(COUNTY!="Region")
rs_pums$hh_size_county <- psrc_pums_count(pums_hh_data, group_vars=c("COUNTY","hhsize")) %>%
  filter(COUNTY!="Region")
rs_pums$hh_veh_county <- psrc_pums_count(pums_hh_data,  group_vars=c("COUNTY","veh_yn")) %>%
  filter(COUNTY!="Region")
rs_pums$pop_count <- psrc_pums_count(pums_pp_data, "person")
rs_pums$pop_county <- psrc_pums_count(pums_pp_data, "person", group_vars="COUNTY") %>%
  filter(COUNTY!="Region")
rs_pums$pop_worker <- psrc_pums_count(pums_pp_data, "person", group_vars="worker", incl_na=FALSE)
rs_pums$pop_edu <- psrc_pums_count(pums_pp_data, "person", group_vars="ED_ATTAIN")
rs_pums$pop_gender <- psrc_pums_count(pums_pp_data, "person", group_vars="SEX")
