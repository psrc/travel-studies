
# list of all urban and metro RGCs
rgcs_tracts_list <- read_csv("rgc_tracts.csv") %>% select(-1) %>%
  inner_join(read_csv("urban_metro.csv") %>% select(3,13), 
             by = "name") %>%
  rename(urban_metro = category)
urban_metro <- read_csv("urban_metro.csv")

#--- household variables ----
hh_group_data <- function(.data){
  df <- .data %>%
    mutate(
      vehicle_count_simple = case_when(vehicle_count=="0 (no vehicles)" ~ "0", 
                                       vehicle_count=="1 vehicle" ~ "1",
                                       grepl("[2345678]",vehicle_count)~ "2+"),
      vehicle_count_simple4 = case_when(vehicle_count=="0 (no vehicles)" ~ "0", 
                                       vehicle_count=="1 vehicle" ~ "1",
                                       grepl("[2]",vehicle_count) ~ "2", 
                                       grepl("[3]",vehicle_count) ~ "3",
                                       grepl("[45678]",vehicle_count)~ "4+"),
      vehicle_binary = case_when(vehicle_count_simple=="No vehicle" ~ "0", 
                                 vehicle_count_simple %in% c("1","2+")~ "1+"),
      hhsize_simple = case_when(grepl("[456789]",hhsize)~ "4+",
                                TRUE ~ as.character(hhsize)),
      have_child = case_when(lifecycle %in% c("Household includes children age 5-17", 
                                              "Household includes children under 5") ~ "Includes children",
                             TRUE~ "No children"),
      res_type = case_when(res_type == "Single-family house (detached house)"~ "Single-family house",
                           res_type == "Townhouse (attached house)"~ "Townhouse",
                           res_type %in% c("Building with 4 or more apartments/condos",
                                           "Building with 3 or fewer apartments/condos")~ "Apartment/Condo",
                           res_type %in% c("Other (including boat, RV, van, etc.)","Mobile home/trailer",
                                           "Dorm or institutional housing")~ "Others"),
      hhincome_broad = case_when(hhincome_broad %in% c("$100,000-$199,000",
                                                       "$200,000 or more","$100,000 or more")~"$100,000 or more",
                                 TRUE ~ hhincome_broad),
      offpark_simple = case_when(offpark=="0 (no spaces available)"~"0",
                                 offpark>=vehicle_count~"enough spaces",
                                 offpark<vehicle_count~"not enough spaces")
    ) %>%
    left_join(urban_metro %>% select(name,category), by = c("final_home_rgcnum"="name")) %>%
    mutate(urban_metro = case_when(!is.na(category)~category,
                                   TRUE~"Not RGC"),
           .after = "final_home_rgcnum")
  df$have_child <- factor(df$have_child, levels=c("No children","Includes children"))
  df$res_type <- factor(df$res_type, levels=c("Single-family house","Townhouse","Apartment/Condo","Others"))
  df$final_home_is_rgc <- factor(df$final_home_is_rgc, levels=c("RGC","Not RGC"))
  df$hhincome_broad <- factor(df$hhincome_broad, levels=c("Under $25,000","$25,000-$49,999",
                                                          "$50,000-$74,999","$75,000-$99,999",
                                                          "$100,000 or more","Prefer not to answer"))
  df$urban_metro <- factor(df$urban_metro, levels=c("Metro","Urban","Not RGC"))
  
  return(df)
}

per_group_data <- function(.data,hh_data){
  
  df <- .data %>%
    rename(freq_transit = mode_freq_1,
           freq_bike = mode_freq_2,
           freq_walk = mode_freq_3,
           freq_carshare = mode_freq_4,
           freq_rideshare = mode_freq_5) %>%
    mutate(
      race_simple = case_when(race_eth_broad=="Asian only, non-Hispanic/Latinx"~"Asian only",
                              race_eth_broad=="Black or African American only, non-Hispanic/Latinx"~"Black or African American only",
                              race_eth_broad=="White only, non-Hispanic/Latinx"~ "White only",
                              race_eth_broad=="Other race, including multi-race non-Hispanic"~ "Other race",
                              TRUE~race_eth_broad),
      age = case_when(age == '75-84 years' ~ '75 years or older',
                      age == '85 or years older' ~ '75 years or older',
                      TRUE ~ age),
      education2 = case_when(education=="Less than high school"|
                               education=="High school graduate"~"High school or less",
                             education=="Vocational/technical training" |
                               education=="Some college" |
                               education=="Associates degree"~"Technical or Associates",
                             education=="Bachelor degree" |
                               education=="Graduate/post-graduate degree"~"Bachelor's or higher"),
      commute_mode_simple = case_when(commute_mode %in%  c("Bus (public transit)",
                                                           "Commuter rail (Sounder, Amtrak)",
                                                           "Ferry or water taxi",
                                                           "Paratransit",
                                                           "Streetcar",
                                                           "Urban rail (Link light rail, monorail)",
                                                           "Urban rail (Link light rail, monorail, streetcar)") ~ "Public transit",
                                      commute_mode %in% c("Bicycle or e-bike",
                                                          "Scooter or e-scooter (e.g., Lime, Bird, Razor)")~ "Bike or micro-mobility",
                                      commute_mode=="Walk, jog, or wheelchair" ~ "Walk",
                                      commute_mode=="Drive alone" ~ "Drive alone",
                                      commute_mode %in% c("Carpool ONLY with other household members",
                                                          "Carpool with other people not in household (may also include household members)",
                                                          "Vanpool",
                                                          "Private bus or shuttle") ~ "HOV modes",
                                      is.na(commute_mode) ~ "NA",
                                      TRUE ~ "Other modes"),
      transit_pass = case_when(benefits_3 %in% c("Offered, and I use","Offered, but I don't use")~"Offered",
                               TRUE ~ benefits_3),
      work_parking = case_when(workpass %in% c("No, parking is usually/always free",
                                               "Yes, employer pays/reimburses for all or part of daily parking costs",
                                               "Yes, employer pays/reimburses for all or part of parking pass")~"free/reimbursed parking",
                               workpass %in% c("Yes, personally pay for parking pass at work",  "Yes, personally pay daily with cash/tickets")~ "paid parking",
                               TRUE ~ NA)
    ) %>%
    # add household data
    left_join(hh_data, by = c("survey","household_id","hh_weight_2017_2019","sample_segment"))
  
  df$race_simple <- factor(df$race_eth_broad, 
                           levels=c("Asian only",
                                    "Black or African American only",
                                    "Hispanic or Latinx",
                                    "White only",
                                    "Other race",
                                    "Child -- no race specified"))
  df$workplace <- factor(df$workplace, 
                         levels=c("Usually the same location (outside home)",
                                  "Telework some days and travel to a work location some days",
                                  "At home (telecommute or self-employed with home office)",   
                                  "Drives for a living (e.g., bus driver, salesperson)",
                                  "Workplace regularly varies (different offices or jobsites)",                 
                                  NA ))
  df$education2 <- factor(df$education2, 
                          levels=c("High school or less",
                                   "Technical or Associates",
                                   "Bachelor's or higher", 
                                   NA))
  df$education <- factor(df$education, 
                         levels=c("Less than high school",
                                  "High school graduate",
                                  "Vocational/technical training",
                                  "Associates degree",
                                  "Some college",
                                  "Bachelor degree","Graduate/post-graduate degree", 
                                  NA))
  df$employment <- factor(df$employment, 
                          levels=c("Employed full time (35+ hours/week, paid)",
                                   "Employed part time (fewer than 35 hours/week, paid)",
                                   "Self-employed",
                                   "Unpaid volunteer or intern",
                                   "Homemaker",
                                   "Not currently employed",
                                   "Employed but not currently working (e.g., on leave, furloughed 100%)",
                                   "Retired",
                                   NA))
  df$transit_pass <- factor(df$transit_pass, levels= c("Offered",
                                                       "Not offered",
                                                       "I don't know",
                                                       NA))
  df$commute_mode_simple <- factor(df$commute_mode_simple, level = c("Drive alone","HOV modes","Public transit",
                                                                     "Walk","Bike or micro-mobility","Other modes","NA"))
  
  .freq <- c("I never do this",
             "1 day/week",
             "2-4 days/week",
             "5 days/week",
             "6-7 days/week",
             "1-3 times in the past 30 days",
             "I do this, but not in the past 30 days",
             NA )
  
  df$freq_transit <- factor(df$freq_transit, levels= .freq)
  df$freq_bike <- factor(df$freq_bike, levels= .freq)
  df$freq_walk <- factor(df$freq_walk, levels= .freq)
  df$freq_carshare <- factor(df$freq_carshare, levels= .freq)
  df$freq_rideshare <- factor(df$freq_rideshare, levels= .freq)
  
  return(df)
}

trip_group_data <- function(.data){
  df <- .data %>%
    mutate(travelers_total=ifelse(travelers_total>10 | travelers_total<=0 | is.na(travelers_total), 1, travelers_total))
  
  return(df)
}

