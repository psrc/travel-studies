library(magrittr)
library(dplyr)
library(srvyr)
library(stringr)
library(psrc.travelsurvey)
library(travelSurveyTools)
library(data.table)
library(psrccensus)

#`%not_in%` <- Negate(`%in%`)

vars <- c("hh_race_category", "hhsize", "vehicle_count", "hhincome_broad", "home_county",
           "employment", "education", "age", "gender", "race_category", "rent_own")

safegsub <- function(rgx, x){
  ans <- ifelse(grepl(rgx, x),
                gsub(rgx, "\\1", x),
                "")
  return(ans)
}

# PSRC HTS ------------------

hts_data <- get_psrc_hts(2023, survey_vars=vars)                                                   # Get HTS data
hts_data$hh %<>% mutate(region=1,                                                                  # Add variables; 1 for regionwide
                        veh_yn=factor(
                          case_when(vehicle_count=="0 (no vehicles)" ~"No vehicle",
                                    !is.na(vehicle_count) ~ "1+ vehicle"),
                          levels= c("No vehicle","1+ vehicle")),
                        race_bin3=case_when(grepl("^(AANHPI|White)", hh_race_category) ~hh_race_category,
                                            hh_race_category=="Missing/No response" ~NA,
                                            !is.na(hh_race_category) ~"Other POC"),
                        hhsize_bin3=case_when(safegsub("^(\\d+) (person|people)", hhsize) >2 ~"3+ people",
                                              !is.na(hhsize) ~hhsize),
                        own_rent=case_when(grepl("^Provided", rent_own) ~"Rent",
                                           grepl("^(Other|Prefer)", rent_own) ~NA_character_,
                                           !is.na(rent_own) ~rent_own))

hts_data$person %<>% mutate(prace_bin3=case_when(grepl("^(AANHPI|White)", race_category) ~race_category,
                                                race_category %in% c("Missing/No response", "Child") ~NA,
                                                !is.na(race_category) ~"Other POC"))

hts_data %<>% hts_bin_worker() %>% hts_bin_income() %>% hts_bin_gender() %>% hts_bin_age()

rs_hts <- list()                                                                                # Summaries in list
rs_hts$hh_count <- psrc_hts_stat(hts_data, "hh", group_vars="region")
rs_hts$hh_size <- psrc_hts_stat(hts_data, "hh", group_vars="hhsize_bin3")
rs_hts$hh_veh <- psrc_hts_stat(hts_data, "hh", group_vars="veh_yn")
rs_hts$hh_county <- psrc_hts_stat(hts_data, "hh", group_vars="home_county")
rs_hts$hh_size_county <- psrc_hts_stat(hts_data, "hh", group_vars=c("home_county","hhsize"))
rs_hts$hh_veh_county <- psrc_hts_stat(hts_data, "hh", group_vars=c("home_county","veh_yn"))
rs_hts$hh_race <- psrc_hts_stat(hts_data, "hh", group_vars=c("race_bin3"), incl_na=FALSE)
rs_hts$hh_income <- psrc_hts_stat(hts_data, "hh", group_vars=c("hhincome_bin5"), incl_na=FALSE)
rs_hts$hh_tenure <- psrc_hts_stat(hts_data, "hh", group_vars=c("own_rent", "hhsize_bin3"), incl_na=FALSE)
rs_hts$hh_tenure_county <- psrc_hts_stat(hts_data, "hh", group_vars=c("home_county","own_rent", "hhsize_bin3"), incl_na=FALSE)
rs_hts$hh_veh <- psrc_hts_stat(hts_data, "hh", group_vars=c("veh_yn","hhsize_bin3"))

rs_hts$pop_count <- psrc_hts_stat(hts_data, "person", group_vars="region")
rs_hts$pop_county <- psrc_hts_stat(hts_data, "person", group_vars="home_county")
rs_hts$pop_worker <- psrc_hts_stat(hts_data, "person", group_vars="worker", incl_na=FALSE)
rs_hts$pop_edu <- psrc_hts_stat(hts_data, "person", group_vars="education")
rs_hts$pop_gender <- psrc_hts_stat(hts_data, "person", group_vars="gender_bin3")
rs_hts$pop_race <- psrc_hts_stat(hts_data, "person", group_vars="prace_bin3", incl_na=FALSE)
rs_hts$pop_age <- psrc_hts_stat(hts_data, "person", group_vars="age_bin5", incl_na=FALSE)

# Census ACS ----------------

pums_hh_vars <- c("NP","BINCOME","HHT","HHT2","VEH","NWRK","TYPEHUGQ","PRACE","OWN_RENT")
pums_pp_vars <- c("SEX","ED_ATTAIN","ESR","TYPEHUGQ","PRACE", "BIN_AGE","OWN_RENT")

pums_hh_data <- get_psrc_pums(1, 2022, "h", pums_hh_vars) %>% filter(TYPEHUGQ=="Housing unit")
pums_pp_data <- get_psrc_pums(1, 2022, "p", pums_pp_vars) %>% filter(TYPEHUGQ=="Housing unit")

pums_pp_data %<>% mutate(
   worker=case_when(grepl("^(Civilian|Armed)", ESR) ~1L,
                    !is.na(ESR)         ~0L),
   race_bin3=case_when(grepl(" (5|12|15|16) ", BIN_AGE) ~NA_character_,
                       grepl("^(Asian|White)", PRACE) ~ PRACE,
                       !is.na(PRACE)                 ~ "Other POC"),
   age_bin5=case_when(grepl(" (5|12|15|16) ", BIN_AGE) ~"Under 18 Years",
                      grepl(" 18 ", BIN_AGE)           ~"18-24 Years",
                      grepl(" (25|35) ", BIN_AGE)      ~"25-44 Years",
                      grepl(" (45|55) ", BIN_AGE)      ~"45-64 Years",
                      grepl("(65|75|85)", BIN_AGE)     ~"65 years or older",
                      !is.na(BIN_AGE)                  ~BIN_AGE))
pums_hh_data %<>% mutate(
   non_family=case_when(grepl("^Nonfamily", HHT) ~"Non-family",
                        !is.na(HHT) ~"Family"),
   non_rel=case_when(grepl("^(Married|Cohabiting)", HHT2) ~"Relationship",
                     grepl("householder", HHT2)
                        ~str_replace(HHT2, "(Male|Female) householder, no spouse/partner present,", ""),
                     !is.na(HHT2) ~HHT2),
   adj_households=case_when(grepl("^Nonfamily", HHT) ~NP,
                            !is.na(HHT) ~1),
   adj_hhsize=case_when(grepl("^Nonfamily", HHT) ~"1",
                        NP > 2 ~"3+",
                        !is.na(NP) ~as.character(NP)),
   hhsize_bin3=case_when(NP > 2 ~"3+",
                         !is.na(NP) ~as.character(NP)),
   veh_yn=case_when(VEH=="No vehicles" ~"No vehicles",
                    !is.na(VEH) ~"1+ vehicles"),
   race_bin3=case_when(grepl("^(Asian|White)", PRACE) ~ PRACE,
                       !is.na(PRACE)                 ~ "Other POC"))
rs_pums <- list()
rs_pums$hh_count <- psrc_pums_count(pums_hh_data)
rs_pums$hh_size <- psrc_pums_count(pums_hh_data, group_vars="hhsize_bin3")
rs_pums$hh_veh <- psrc_pums_count(pums_hh_data,  group_vars="veh_yn")
rs_pums$hh_non_family <- psrc_pums_count(pums_hh_data,  group_vars="non_family")
rs_pums$hh_race_bin3 <- psrc_pums_count(pums_hh_data,  group_vars="race_bin3")
rs_pums$hh_income <- psrc_pums_count(pums_hh_data,  group_vars="BINCOME")
rs_pums$hh_tenure <- psrc_pums_count(pums_hh_data,  group_vars=c("OWN_RENT","hhsize_bin3"))
rs_pums$hh_tenure_county <- psrc_pums_count(pums_hh_data,  group_vars=c("COUNTY","OWN_RENT","hhsize_bin3"))
rs_pums$hh_nonrel <- psrc_pums_count(pums_hh_data,  group_vars=c("non_rel"))
rs_pums$hh_veh_hhsize <- psrc_pums_count(pums_hh_data,  group_vars=c("veh_yn","hhsize_bin3"))

rs_pums$adj_hh_count <- psrc_pums_sum(pums_hh_data, stat_var="adj_households")
rs_pums$adj_hh_county <- psrc_pums_sum(pums_hh_data, stat_var="adj_households", group_vars="COUNTY")
rs_pums$adj_hh_size <- psrc_pums_sum(pums_hh_data, stat_var="adj_households", group_vars="adj_hhsize")
rs_pums$adj_hh_veh <- psrc_pums_sum(pums_hh_data, stat_var="adj_households",  group_vars="veh_yn")
rs_pums$adj_race_bin3 <- psrc_pums_sum(pums_hh_data, stat_var="adj_households",  group_vars="race_bin3")

rs_pums$hh_county <- psrc_pums_count(pums_hh_data, group_vars="COUNTY") %>%
  filter(COUNTY!="Region")
rs_pums$hh_size_county <- psrc_pums_count(pums_hh_data, group_vars=c("COUNTY","hhsize")) %>%
  filter(COUNTY!="Region")
rs_pums$hh_veh_county <- psrc_pums_count(pums_hh_data,  group_vars=c("COUNTY","veh_yn")) %>%
  filter(COUNTY!="Region")
rs_pums$pop_count <- psrc_pums_count(pums_pp_data, "person")
rs_pums$pop_county <- psrc_pums_count(pums_pp_data, "person", group_vars="COUNTY") %>%
  filter(COUNTY!="Region")
rs_pums$hh_tenure_county <- psrc_pums_count(pums_hh_data,  group_vars=c("COUNTY","OWN_RENT","hhsize_bin3")) %>%
  filter(COUNTY!="Region")
rs_pums$hh_nonrel_county <- psrc_pums_count(pums_hh_data,  group_vars=c("COUNTY","non_rel")) %>%
   filter(COUNTY!="Region")

rs_pums$pop_worker <- psrc_pums_count(pums_pp_data, "person", group_vars="worker", incl_na=FALSE)
rs_pums$pop_edu <- psrc_pums_count(pums_pp_data, "person", group_vars="ED_ATTAIN")
rs_pums$pop_gender <- psrc_pums_count(pums_pp_data, "person", group_vars="SEX")
rs_pums$pop_race <- psrc_pums_count(pums_pp_data, "person", group_vars="race_bin3")
rs_pums$pop_age <- psrc_pums_count(pums_pp_data, "person", group_vars="age_bin5")



