
# group fields
hh_group_data <- function(.data){
  .data <- .data %>%
    mutate(
      vehicle_count = substring(vehicle_count,1,1),
      vehicle_count = case_when(vehicle_count==0 ~ "No vehicle", 
                                vehicle_count==1 ~ "1",
                                # vehicle_count==2 ~ "2",
                                vehicle_count %in% c(2,3,4,5,6,7,8)~ "2 or more"),
      vehicle_binary = case_when(vehicle_count=="No vehicle" ~ "No vehicle", 
                                vehicle_count %in% c("1","2 or more")~ "1 or more"),
      hhsize = substring(hhsize,1,1),
      hhsize = case_when(hhsize %in% c(5,6,7,8,9)~ "5 or more",
                         TRUE ~ hhsize),
      res_type = case_when(res_type == "Single-family house (detached house)"~ "Single-family house",
                           res_type == "Townhouse (attached house)"~ "Townhouse",
                           res_type %in% c("Building with 4 or more apartments/condos",
                                           "Building with 3 or fewer apartments/condos")~ "Apartment/Condo",
                           res_type %in% c("Other (including boat, RV, van, etc.)","Mobile home/trailer",
                                           "Dorm or institutional housing")~ "Others"),
      res_dur = case_when(res_dur %in% c("Between 2 and 3 years", "Between 3 and 5 years", 
                                         "Between 5 and 10 years","Between 10 and 20 years",
                                         "More than 20 years")~ "More than 2 years",
                          TRUE ~ res_dur),
      hhincome_binary = case_when(hhincome_broad %in% c("Under $25,000","$25,000-$49,999") ~ "Under $50,000",
                                  hhincome_broad %in% c("$50,000-$74,999","$75,000-$99,999","$100,000-$199,000",
                                                        "$200,000 or more","$100,000 or more") ~ "$50,000 and over",
                                  hhincome_broad == "Prefer not to answer" ~ "Prefer not to answer")
      
    )
  
  .data$vehicle_count <- factor(.data$vehicle_count, levels=c("No vehicle","1","2 or more"))
  .data$vehicle_binary <- factor(.data$vehicle_binary, levels=c("No vehicle","1 or more"))
  .data$hhsize <- factor(.data$hhsize, levels=c("1","2","3","4","5 or more"))
  .data$res_type <- factor(.data$res_type, levels=c("Single-family house","Townhouse","Apartment/Condo","Others"))
  .data$res_dur <- factor(.data$res_dur, levels=c("Less than a year","Between 1 and 2 years","More than 2 years"))
  .data$final_home_is_rgc <- factor(.data$final_home_is_rgc, levels=c("RGC","Not RGC"))
  .data$hhincome_binary <- factor(.data$hhincome_binary, levels=c("Under $50,000","$50,000 and over","Prefer not to answer"))
  .data$survey <- factor(.data$survey, levels=c("2017_2019","2021"))
  return(.data)
}

plot_chart_w <- function(.data, vars) {
  .data %>% 
    group_by(final_home_is_rgc,survey) %>% 
    mutate(num_hh = sum(hh_weight)) %>% 
    group_by(final_home_is_rgc, survey, num_hh, {{vars}}) %>% 
    summarise(counts = sum(hh_weight)) %>%
    ungroup() %>%
    mutate(per = counts*100/num_hh)
}
