library(tidyverse)
library(stringr)


# specifications for ggplots ####
# error bars for ggplot
moe_bars <- geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                          width=0.2, position = position_dodge(0.9))


# functions for data processing ####
# group fields
hh_group_data <- function(.data){
  .data <- .data %>%
    mutate(
      survey = ifelse(survey=="2017_2019", "2017/2019",survey),
      vehicle_count = substring(vehicle_count,1,1),
      vehicle_count = case_when(vehicle_count==0 ~ "No vehicle", 
                                vehicle_count==1 ~ "1",
                                # vehicle_count==2 ~ "2",
                                vehicle_count %in% c(2,3,4,5,6,7,8)~ "2 or more"),
      vehicle_binary = case_when(vehicle_count=="No vehicle" ~ "No vehicle", 
                                vehicle_count %in% c("1","2 or more")~ "1 or more"),
      hhsize = substring(hhsize,1,1),
      hhsize = case_when(hhsize %in% c(4,5,6,7,8,9)~ "4 or more",
                         TRUE ~ hhsize),
      have_child = case_when((lifecycle %in% c("Household includes children age 5-17", "Household includes children under 5")) | 
                               numchildren>0 ~ "Includes children",
                             TRUE~ "No children"),
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
      hhincome_broad = case_when(hhincome_broad %in% c("$100,000-$199,000",
                                                       "$200,000 or more","$100,000 or more")~"$100,000 or more",
                                 TRUE ~ hhincome_broad),
      hhincome_binary = case_when(hhincome_broad %in% c("Under $25,000","$25,000-$49,999") ~ "Under $50,000",
                                  hhincome_broad %in% c("$50,000-$74,999","$75,000-$99,999","$100,000-$199,000",
                                                        "$200,000 or more","$100,000 or more") ~ "$50,000 and over",
                                  hhincome_broad == "Prefer not to answer" ~ "Prefer not to answer"),
      hhincome_three  = case_when(hhincome_broad %in% c("Under $25,000") ~ "Under $25,000",
                                  hhincome_broad %in% c("$25,000-$49,999","$50,000-$74,999",
                                                        "$75,000-$99,999")~ "$25,000 - $99,999",
                                  hhincome_broad %in% c("$100,000-$199,000",
                                                        "$200,000 or more","$100,000 or more") ~ "$100,000 and over",
                                  TRUE ~ hhincome_broad)
    )%>%
    left_join(urban_metro, by = c("final_home_rgcnum"="name")) %>%
    mutate(urban_metro = case_when(!is.na(category)~category,
                                   TRUE~"Not RGC"),
           .after = "final_home_rgcnum") %>%
    select(-category)
  
  .data$vehicle_count <- factor(.data$vehicle_count, levels=c("No vehicle","1","2 or more"))
  .data$vehicle_binary <- factor(.data$vehicle_binary, levels=c("No vehicle","1 or more"))
  .data$hhsize <- factor(.data$hhsize, levels=c("1","2","3","4 or more"))
  .data$have_child <- factor(.data$have_child, levels=c("No children","Includes children"))
  .data$res_type <- factor(.data$res_type, levels=c("Single-family house","Townhouse","Apartment/Condo","Others"))
  .data$res_dur <- factor(.data$res_dur, levels=c("Less than a year","Between 1 and 2 years","More than 2 years"))
  .data$final_home_is_rgc <- factor(.data$final_home_is_rgc, levels=c("RGC","Not RGC"))
  .data$hhincome_broad <- factor(.data$hhincome_broad, levels=c("Under $25,000","$25,000-$49,999",
                                                                "$50,000-$74,999","$75,000-$99,999",
                                                                "$100,000 or more","Prefer not to answer"))
  .data$hhincome_three <- factor(.data$hhincome_three, levels=c("Under $25,000","$25,000 - $99,999","$100,000 and over","Prefer not to answer"))
  .data$hhincome_binary <- factor(.data$hhincome_binary, levels=c("Under $50,000","$50,000 and over","Prefer not to answer"))
  .data$survey <- factor(.data$survey, levels=c("2017/2019","2021")) 
  .data$urban_metro <- factor(.data$urban_metro, levels=c("Metro","Urban","Not RGC")) 
  
  return(.data)
}


per_group_data <- function(.data){

  .data <- .data %>%
    rename(transit_freq = mode_freq_1,
           bike_freq = mode_freq_2,
           walk_freq = mode_freq_3,
           carshare_freq = mode_freq_4,
           rideshare_freq = mode_freq_5,
           transit_pass = benefits_3) %>%
    mutate(
      survey = ifelse(survey=="2017_2019", "2017/2019",survey),
      vehicle_count = substring(vehicle_count,1,1),
      vehicle_count = case_when(vehicle_count==0 ~ "No vehicle", 
                                vehicle_count==1 ~ "1",
                                # vehicle_count==2 ~ "2",
                                vehicle_count %in% c(2,3,4,5,6,7,8)~ "2 or more"),
      vehicle_binary = case_when(vehicle_count=="No vehicle" ~ "No vehicle", 
                                 vehicle_count %in% c("1","2 or more")~ "1 or more"),
      hhincome_broad = case_when(hhincome_broad %in% c("$100,000-$199,000",
                                                       "$200,000 or more","$100,000 or more")~"$100,000 or more",
                                 TRUE ~ hhincome_broad),
      hhincome_binary = case_when(hhincome_broad %in% c("Under $25,000","$25,000-$49,999") ~ "Under $50,000",
                                  hhincome_broad %in% c("$50,000-$74,999","$75,000-$99,999","$100,000-$199,000",
                                                        "$200,000 or more","$100,000 or more") ~ "$50,000 and over",
                                  hhincome_broad == "Prefer not to answer" ~ "Prefer not to answer"),
      race_eth_broad = case_when(race_eth_broad=="Asian only, non-Hispanic/Latinx"~"Asian only",
                                 race_eth_broad=="Black or African American only, non-Hispanic/Latinx"~"Black or African American only",
                                 race_eth_broad=="White only, non-Hispanic/Latinx"~ "White only",
                                 race_eth_broad=="Other race, including multi-race non-Hispanic"~ "Other race, including multi-race",
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
      commute_mode2 = case_when(commute_mode %in%  c("Bus (public transit)",
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
                               TRUE ~ "Other modes")
      )
  
  .data$vehicle_count <- factor(.data$vehicle_count, levels=c("No vehicle","1","2 or more"))
  .data$vehicle_binary <- factor(.data$vehicle_binary, levels=c("No vehicle","1 or more"))
  .data$final_home_is_rgc <- factor(.data$final_home_is_rgc, levels=c("RGC","Not RGC"))
  .data$hhincome_broad <- factor(.data$hhincome_broad, levels=c("Under $25,000","$25,000-$49,999",
                                                                "$50,000-$74,999","$75,000-$99,999",
                                                                "$100,000 or more","Prefer not to answer"))
  .data$hhincome_binary <- factor(.data$hhincome_binary, levels=c("Under $50,000","$50,000 and over","Prefer not to answer"))
  .data$survey <- factor(.data$survey, levels=c("2017/2019","2021"))
  
  .data$age <- factor(.data$age, levels=c("Under 5 years old","5-11 years","12-15 years","16-17 years","18-24 years",
                                          "25-34 years","35-44 years","45-54 years","55-64 years","65-74 years","75-84 years",
                                          "85 or years older"))
  .data$race_eth_broad <- factor(.data$race_eth_broad, 
                                 levels=c("Asian only",
                                          "Black or African American only",
                                          "Hispanic or Latinx",
                                          "White only",
                                          "Other race, including multi-race",
                                          "Child -- no race specified"))
  .data$workplace <- factor(.data$workplace, 
                            levels=c("Usually the same location (outside home)",
                                     "Telework some days and travel to a work location some days",
                                     "At home (telecommute or self-employed with home office)",   
                                     "Drives for a living (e.g., bus driver, salesperson)",
                                     "Workplace regularly varies (different offices or jobsites)",                 
                                     NA ))
  .data$education2 <- factor(.data$education2, 
                            levels=c("High school or less",
                                     "Technical or Associates",
                                     "Bachelor's or higher", 
                                     NA))
  .data$education <- factor(.data$education, 
                             levels=c("Less than high school",
                                      "High school graduate",
                                      "Vocational/technical training",
                                      "Associates degree",
                                      "Some college",
                                      "Bachelor degree","Graduate/post-graduate degree", 
                                      NA))
  .data$employment <- factor(.data$employment, 
                             levels=c("Employed full time (35+ hours/week, paid)",
                                      "Employed part time (fewer than 35 hours/week, paid)",
                                      "Self-employed",
                                      "Unpaid volunteer or intern",
                                      "Homemaker",
                                      "Not currently employed",
                                      "Employed but not currently working (e.g., on leave, furloughed 100%)",
                                      "Retired",
                                      NA))
  .data$transit_pass <- factor(.data$transit_pass, levels= c("Offered, and I use",
                                                             "Offered, but I don't use",
                                                             "Not offered",
                                                             "I don't know",
                                                             NA))
  .data$commute_mode2 <- factor(.data$commute_mode2, level = c("Drive alone","HOV modes","Public transit",
                                                               "Walk","Bike or micro-mobility","Other modes","NA"))
  # .data$commute_mode2 <- factor(.data$commute_mode2, levels= c("Bike","Drive alone","HOV modes","Other modes", "Public transit","Walk"))
  
  .freq <- c("I never do this",
             "1 day/week",
             "2-4 days/week",
             "5 days/week",
             "6-7 days/week",
             "1-3 times in the past 30 days",
             "I do this, but not in the past 30 days",
             NA )
  
  .data$transit_freq <- factor(.data$transit_freq, levels= .freq)
  .data$bike_freq <- factor(.data$bike_freq, levels= .freq)
  .data$walk_freq <- factor(.data$walk_freq, levels= .freq)
  .data$carshare_freq <- factor(.data$carshare_freq, levels= .freq)
  .data$rideshare_freq <- factor(.data$rideshare_freq, levels= .freq)
  
  
  return(.data)
}

trip_group_data <- function(.data){
  
  .data <- .data %>%
    mutate(survey = ifelse(survey=="2017_2019", "2017/2019",survey),
           vehicle_count = substring(vehicle_count,1,1),
           vehicle_count = case_when(vehicle_count==0 ~ "No vehicle", 
                                     vehicle_count==1 ~ "1",
                                     # vehicle_count==2 ~ "2",
                                     vehicle_count %in% c(2,3,4,5,6,7,8)~ "2 or more"),
           vehicle_binary = case_when(vehicle_count=="No vehicle" ~ "No vehicle", 
                                      vehicle_count %in% c("1","2 or more")~ "1 or more"),
           hhincome_broad = case_when(hhincome_broad %in% c("$100,000-$199,000",
                                                            "$200,000 or more","$100,000 or more")~"$100,000 or more",
                                      TRUE ~ hhincome_broad),
           hhincome_binary = case_when(hhincome_broad %in% c("Under $25,000","$25,000-$49,999") ~ "Under $50,000",
                                       hhincome_broad %in% c("$50,000-$74,999","$75,000-$99,999","$100,000-$199,000",
                                                             "$200,000 or more","$100,000 or more") ~ "$50,000 and over",
                                       hhincome_broad == "Prefer not to answer" ~ "Prefer not to answer"),
           race_eth_broad = case_when(race_eth_broad=="Asian only, non-Hispanic/Latinx"~"Asian only",
                                      race_eth_broad=="Black or African American only, non-Hispanic/Latinx"~"Black or African American only",
                                      race_eth_broad=="White only, non-Hispanic/Latinx"~ "White only",
                                      race_eth_broad=="Other race, including multi-race non-Hispanic"~ "Other race, including multi-race",
                                      TRUE~race_eth_broad),
           age = case_when(age == '75-84 years' ~ '75 years or older',
                           age == '85 or years older' ~ '75 years or older',
                           TRUE ~ age),
           simple_purpose = ifelse(dest_purpose_cat == 'Home',
             origin_purpose_cat,dest_purpose_cat),
           simple_purpose = case_when(
             simple_purpose %in% c('Work','School', 'Work-related') ~ 'Work/School',
             simple_purpose == 'Shop' ~ 'Shop',
             simple_purpose %in% c('Escort','Errand/Other','Change mode','Home')~ 'Errands',
             is.na(simple_purpose) ~ 'Errands',
             simple_purpose %in% c('Social/Recreation','Meal') ~ 'Social/Recreation/Meal',
             TRUE ~ simple_purpose),
           travel_time_google = case_when(google_duration_sec<=600~"Under 10 mins",
                                          google_duration_sec<=1200~"Under 20 mins",
                                          google_duration_sec<=1800~"Under 30 mins"),
           travel_time = arrival_time_mam-depart_time_mam,
           mode_simple2 = case_when(mode_simple %in% c("Bike","Walk")~"Walk/Bike",
                                    TRUE~mode_simple)
           
    )
  
  .data$vehicle_binary <- factor(.data$vehicle_binary, levels=c("No vehicle","1 or more"))
  .data$final_home_is_rgc <- factor(.data$final_home_is_rgc, levels=c("RGC","Not RGC"))
  .data$hhincome_broad <- factor(.data$hhincome_broad, levels=c("Under $25,000","$25,000-$49,999",
                                                                "$50,000-$74,999","$75,000-$99,999",
                                                                "$100,000 or more","Prefer not to answer"))
  .data$hhincome_binary <- factor(.data$hhincome_binary, levels=c("Under $50,000","$50,000 and over","Prefer not to answer"))
  .data$survey <- factor(.data$survey, levels=c("2017/2019","2021"))
  
  .data$age <- factor(.data$age, levels=c("Under 5 years old","5-11 years","12-15 years","16-17 years","18-24 years",
                                          "25-34 years","35-44 years","45-54 years","55-64 years","65-74 years","75-84 years",
                                          "85 or years older"))
  .data$race_eth_broad <- factor(.data$race_eth_broad, 
                                 levels=c("Asian only",
                                          "Black or African American only",
                                          "Hispanic or Latinx",
                                          "White only",
                                          "Other race, including multi-race",
                                          "Child -- no race specified"))
  .data$simple_purpose <- factor(.data$simple_purpose, 
                                 levels=c('Work/School',
                                          'Shop',
                                          'Errands',
                                          'Social/Recreation/Meal'))
  .data$mode_simple <- factor(.data$mode_simple, 
                              levels=c("Drive","Transit", "Bike","Walk","Other"))
  .data$mode_simple2 <- factor(.data$mode_simple2, 
                              levels=c("Drive","Transit", "Walk/Bike","Other"))
  
  return(.data)
}

# for wrapping the labels in x-axis
wrap_axis <- function(.data, fields, w=11){
  
  .data %>%
    mutate(cat = str_wrap({{fields}}, width=w))
  
}


# change legend
psrc_style2 <- function(text_size=0, loc="bottom") {
  font <- "Poppins"
  
  ggplot2::theme(
    
    #Text format:
    #This sets the font, size, type and color of text for the chart's title
    plot.title = ggplot2::element_text(family=font,
                                       face="bold",
                                       size=14+text_size),
    plot.title.position = "plot",
    
    #This sets the font, size, type and color of text for the chart's subtitle, as well as setting a margin between the title and the subtitle
    plot.subtitle = ggplot2::element_text(family=font,
                                          size=12+text_size,
                                          margin=ggplot2::margin(9,0,9,0)),
    
    #This leaves the caption text element empty, because it is set elsewhere in the finalise plot function
    plot.caption =  ggplot2::element_text(family=font,
                                          size=10+text_size,
                                          face="italic",
                                          color="#4C4C4C",
                                          hjust=0),
    plot.caption.position = "plot",
    
    #Legend format
    #This sets the position and alignment of the legend, removes a title and background for it and sets the requirements for any text within the legend.
    legend.position = loc,
    legend.background = ggplot2::element_blank(),
    legend.title = ggplot2::element_blank(),
    legend.key = ggplot2::element_blank(),
    legend.text = ggplot2::element_text(family=font,
                                        size=12+text_size,
                                        color="#4C4C4C"),
    
    #Axis format
    #This sets the text font, size and colour for the axis test, as well as setting the margins and removes lines and ticks. In some cases, axis lines and axis ticks are things we would want to have in the chart - the cookbook shows examples of how to do so.
    axis.title = ggplot2::element_blank(),
    axis.text = ggplot2::element_text(size=10+text_size,
                                      color="#2f3030"),
    axis.text.x = ggplot2::element_text(margin=ggplot2::margin(5, b = 10)),
    axis.ticks = ggplot2::element_blank(),
    axis.line = ggplot2::element_blank(),
    
    #Grid lines
    #This removes all minor gridlines and adds major y gridlines. In many cases you will want to change this to remove y gridlines and add x gridlines.
    panel.grid.minor = ggplot2::element_blank(),
    panel.grid.major.y = ggplot2::element_line(color="#cbcbcb"),
    panel.grid.major.x = ggplot2::element_blank(),
    
    #Blank background
    #This sets the panel background as blank, removing the standard grey ggplot background color from the plot
    panel.background = ggplot2::element_blank(),
    
    #Strip background sets the panel background for facet-wrapped plots to PSRC Gray and sets the title size of the facet-wrap title
    strip.background = ggplot2::element_rect(fill="#BCBEC0"),
    strip.text = ggplot2::element_text(size  = 12+text_size,  hjust = 0)
  )
}

