library(echarts4r)
library(psrcplot)
library(psrc.travelsurvey)
library(psrccensus)
library(psrcelmer)
library(tidyverse)

install_psrc_fonts()

Sys.setenv(CENSUS_API_KEY = '3fc20d0d6664692c0becc323b82c752408d843d9')
Sys.getenv("CENSUS_API_KEY")

# hhts_codebook <- get_table(schema = 'HHSurvey', tbl_name = 'variables_codebook')

# vmt data for analysis and modeling
working_vars <- c("person_id","household_id","sample_segment","survey",
                  "sample_county","final_home_rgcnum","urban_metro",
                  "gender","age_category","race_eth_broad","have_child",
                  "employment","license","hhincome_broad","vehicle_count",
                  "transit_pass","work_parking","commute_mode_simple",
                  "freq_transit","telecommute_freq",
                  "hh_weight_2017_2019","hh_weight_2017_2019_adult")


# new calculation with weighted trips
vmt_trip <- trip_data_17_19 %>% 
  filter(mode_simple=='Drive') %>%
  mutate(trip_path_distance=replace_na(trip_path_distance,0),
         travelers_total=case_when(travelers_total>10~1, 
                                   travelers_total<1~1,
                                   is.na(travelers_total)~1,
                                   TRUE~travelers_total),
         trip_adult_weight_2017_2019=replace_na(trip_adult_weight_2017_2019,0),
         vmt= trip_path_distance/travelers_total, 
         vmt_trip_weighted=((trip_path_distance*trip_adult_weight_2017_2019)/travelers_total))




# final person data for data description 
per_data_17_19_final <- per_data_17_19 %>% 
  select(all_of(working_vars)) %>%
  mutate(
    vehicle_count_num = as.numeric(substr(vehicle_count,1,1)),
    # q_group = factor(ntile(vmt_day, 10)), # 10 guantile groups
    # no_vmt_grp = case_when(vmt_day==0~"zero vmt", # people with no vmt
    #                        TRUE~"vmt"),
    freq_transit_simple = factor(recode(freq_transit,
                                        "1 day/week" = "1-4 days/week",
                                        "2-4 days/week" = "1-4 days/week",
                                        "5 days/week" = "5+ days/week",
                                        "6-7 days/week" = "5+ days/week"),
                                 c("5+ days/week",
                                   "1-4 days/week",
                                   "1-3 times in the past 30 days",
                                   "I do this, but not in the past 30 days",
                                   "I never do this")),
    freq_telecommute_simple = recode(telecommute_freq,
                                 "Never" = "Never",
                                 "1 day a week" = "1-2 days",
                                 "2 days a week" = "1-2 days",
                                 "3 days a week" = "3-4 days",
                                 "4 days a week" = "3-4 days",
                                 "5 days a week" = "5+ days",
                                 "6-7 days a week" = "5+ days",
                                 "Not applicable" = as.character(NA)))


vmt_final <- vmt_trip %>%
  # for filtering
  left_join(per_data_17_19_final, by = c("survey","sample_segment","household_id","person_id"))
  
  
# old vmt per person/day code: not working, use aggregated calculation instead
# person-day vmt: group by person ID and day number 
# vmt_per <- vmt_trip %>%
#   group_by(person_id, daynum) %>%
#   summarise(vmt_day=sum(vmt), 
#             vmt_trip_weighted_day=sum(vmt_trip_weighted)) %>%
#   ungroup() %>%
#   mutate(vmt_day=replace_na(vmt_day,0),
#          vmt_trip_weighted_day=replace_na(vmt_trip_weighted_day,0),
#          log_vmt_day=log(1+vmt_day),
#          log_vmt_trip_weighted_day=log(1+vmt_trip_weighted_day)) %>%
#   filter(vmt_day<300) # !! this filtering step will make the total vmt lower
# 
# 
# # merge with day weights using day table to avoid filtering out no trip days
# vmt_per_day_weights <- day_data_17_19 %>%
#   left_join(vmt_per, by = c("person_id", "daynum")) %>%
#   # remove days that are not complete or valid
#   filter(day_weight_2017_2019>0) %>%
#   # fill in days with 0 vmt
#   mutate(vmt_day=replace_na(vmt_day,0),
#          vmt_trip_weighted_day=replace_na(vmt_trip_weighted_day,0),
#          log_vmt_day=replace_na(log_vmt_day,0),
#          log_vmt_trip_weighted_day=replace_na(log_vmt_trip_weighted_day,0))
# refer to "J:\Projects\Surveys\HHTravel\Survey2019\Documents\Introduction_to_Household_Travel_Surveys.pdf" at the top of page16
# > Data users should always calculate the number of weighted travel days using the day table 
# > rather than the trip table given that persons with zero-trip travel days do not have any 
# > records in the trip tables for those days.

# Question: do we need to divide the day weights by 2 in 2017_2019 data?




# TODO: update household data
# vmt_hh <- trip_data_17_19 %>%
#   filter(mode_simple=="Drive", person_id!=19100243801) %>%
#   mutate(vmt= trip_path_distance/travelers_total) %>%
#   group_by(household_id) %>%
#   summarise(total_vmt=sum(vmt, na.rm = TRUE),
#             num_day = length(unique(daynum)),
#             n_trip_drive = sum(mode_simple=="Drive")) %>%
#   ungroup() %>%
#   mutate(vmt_day = total_vmt/num_day) %>%
#   full_join(hh_data_17_19, by = "household_id") %>%
#   mutate(vmt_day=replace_na(vmt_day,0),
#          vehicle_count_num = as.numeric(substr(vehicle_count,1,1)),
#          q_group = factor(ntile(vmt_day, 10)), # 10 guantile groups
#          no_vmt_grp = case_when(vmt_day==0~"zero vmt", # people with no vmt
#                                 TRUE~"vmt"))
# 
# # data to test correlation
# cor_test <- vmt_per %>%
#   select(vmt_day,person_id,
#          hhincome_broad,telecommute_freq,freq_transit,transit_pass,work_parking,vehicle_count_num,
#          license,have_child,
#          hh_weight_2017_2019) %>%
#   filter(!is.na(vmt_day)) %>%
#   mutate(
#     # ordinal
#     hhincome_ord = as.numeric(case_when(
#       hhincome_broad %in% c("Under $25,000","$25,000-$49,999","$50,000-$74,999",
#                             "$75,000-$99,999","$100,000 or more")~hhincome_broad,
#       TRUE~NA)),
#     telecommute_freq_ord = as.numeric(factor(telecommute_freq, 
#                                              levels=c("Never","Less than monthly","A few times per month",
#                                                       "1 day a week","2 days a week","3 days a week","4 days a week",
#                                                       "5 days a week","6-7 days a week"))),
#     freq_transit_ord = as.numeric(freq_transit),
#     
#     # binary
#     transit_pass_binary = case_when( transit_pass == "Not offered"~0,
#                                      transit_pass == "Offered"~1,
#                                      TRUE~NA),
#     work_parking_binary = case_when( work_parking == "paid parking"~0,
#                                      work_parking == "free/reimbursed parking"~1,
#                                      TRUE~NA),
#     have_child = as.numeric(have_child)-1)
