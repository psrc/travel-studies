source("../util.R")
library(logger)
library(glue)


log_info("Data processing script starting up...")

# ---- read hts data ----
# 2025 HTS codebook: https://github.com/psrc/travel-studies/tree/master/HTS_codebook/2025_codebook

# specify variables and survey years needed

# variables as topic_vars
topic_vars <- c(# trip info
                "dest_purpose_cat","dest_purpose_cat_5","travelers_total","mode_class","mode_class_5",
                "distance_miles",
                
                # person
                "telecommute_freq","work_mode",
                "employment","work_from_home","workplace","work_county",
                "race_category","gender","industry",
                
                
                # household demographics
                "hhincome_broad", "hhincome_detailed", "numworkers",
                "hh_race_category","vehicle_count","hhsize","numadults",
                "home_county","home_rgcname","lifecycle_class","res_type",
                
                # landuse
                "home_hh_1","home_emptot_1","home_hh_2","home_emptot_2",
                "home_auto_jobs_access","home_transit_jobs_access","home_nodes4_1",
                
                # lon/lat
                "home_lat", "home_lng"
                
                )

# survey years as topic_years
topic_years <- c(2017, 2019, 2021, 2023, 2025)

# get data
hts_data <- get_psrc_hts(survey_vars = topic_vars,  # specify HTS variables from quarto doc
                         survey_years = topic_years
                         ) %>%
  hts_bin_industry_sector() %>%
  hts_bin_gender()

log_info("HTS data loaded successfully. Now starting data manipulation...")

# ---- data manipulation ----

df_hh <- hts_data$hh %>%
  mutate(
    
    # income with 3 groups
    income_50_100 = factor(
      case_when(
        
        hhincome_broad %in% c("Under $25,000","$25,000-$49,999")~'Under $50,000',
        hhincome_broad %in% c("$50,000-$74,999", "$75,000-$99,999")~"$50,000-$99,999",
        hhincome_broad %in% c("$100,000 or more","$100,000-$199,999", "$200,000 or more")~"$100,000 or more",
        TRUE~hhincome_broad
        
      ),
      levels = c('Under $50,000',"$50,000-$99,999","$100,000 or more","Prefer not to answer")
    ),
    
    # income with 4 groups (only 2023 and later)
    income_100_200 = factor(
      case_when(
        
        survey_year < 2023~ NA,
        hhincome_broad %in% c("Under $25,000","$25,000-$49,999","$50,000-$74,999", "$75,000-$99,999")~ "Under $100,000",
        TRUE~hhincome_broad
        
      ),
      levels = c("Under $100,000","$100,000-$199,999","$200,000 or more","Prefer not to answer")
    ),
    
    # income with $100,000 or more combined
    hhincome_broad_100Kmore = factor(
      case_when(
        
        hhincome_broad %in% c("$100,000 or more","$100,000-$199,999", "$200,000 or more")~"$100,000 or more",
        TRUE~hhincome_broad
        
      ),
      levels = c("Under $25,000","$25,000-$49,999", "$50,000-$74,999",
                 "$75,000-$99,999","$100,000 or more", "Prefer not to answer")
    ),
    
    # income with $100,000 or more combined
    hhincome_num = case_when(
        
        hhincome_detailed == "Under $10,000"~5000,
        hhincome_detailed == "$10,000-$24,999"~17500,
        hhincome_detailed == "$25,000-$34,999"~30000,
        hhincome_detailed == "$35,000-$49,999"~42500,
        hhincome_detailed == "$50,000-$74,999"~62500,
        hhincome_detailed == "$75,000-$99,999"~87500,
        hhincome_detailed == "$100,000-$149,999"~125000,
        hhincome_detailed == "$150,000-$199,999"~175000,
        hhincome_detailed == "$200,000-$249,999"~225000,
        hhincome_detailed == "$250,000 or more"~250000,
        hhincome_broad == "Under $25,000"~12500,
        hhincome_broad == "$25,000-$49,999"~37500,
        hhincome_broad == "$50,000-$74,999"~62500,
        hhincome_broad == "$75,000-$99,999"~87500,
        hhincome_broad == "$100,000-$199,999"~150000,
        hhincome_broad == "$100,000 or more"~100000,
        hhincome_broad == "$200,000 or more"~200000,
        hhincome_broad == "Prefer not to answer"~NA,
        TRUE~NA
        
    ),
    
    # number of workers combined
    numworkers_3cap = factor(
      case_when(
        
        numworkers %in% c("3 workers","4 workers","5 workers","6 workers")~"3+ workers",
        TRUE~numworkers
        
      ),
      levels = c("0 workers","1 worker","2 workers","3+ workers")
    ),
    
    numadults_num = as.numeric(numadults),
    
    # vehicle counts
    vehicle_num = 
      case_when(
        vehicle_count == "0 (no vehicles)" ~0,
        vehicle_count == "1 vehicle"~ 1,
        vehicle_count == "2 vehicles"~ 2,
        vehicle_count == "3 vehicles"~ 3,
        vehicle_count == "4 vehicles"~ 4,
        vehicle_count == "5 vehicles"~ 5,
        vehicle_count == "6 vehicles"~ 6,
        vehicle_count == "7 vehicles"~ 7,
        vehicle_count %in% c("8 vehicles","8 or more vehicles")~ 8,
        vehicle_count == "9 vehicles"~ 9,
        vehicle_count == "10 or more vehicles"~ 10
      ),
    
    # auto availabilty
    auto_availabilty = factor(
      case_when(
        vehicle_num == 0~ "no cars",
        numadults_num <= vehicle_num~ "enough cars",
        numadults_num > vehicle_num~ "fewer cars than adults",
        TRUE~ "other"),
      levels = c("no cars","fewer cars than adults","enough cars")
      ),
    
    # auto availabilty
    have_cars = factor(
      case_when(
        vehicle_num == 0~ "no cars",
        vehicle_num > 0~ "own cars",
        TRUE~ "other"),
      levels = c("no cars","own cars","other")
    ),
    
    home_county = factor(home_county, levels=c("King County","Kitsap County","Pierce County","Snohomish County")),
    
    home_rgc = factor(
      case_when(
        is.na(home_rgcname) | home_rgcname == "Not RGC"~ "Not RGC",
        !is.na(home_rgcname)~ "RGC",
        TRUE~ "other"),
      levels = c("RGC","Not RGC","other")
    ),
    
    res_type_group = factor(
      case_when(
        res_type %in% c("Mobile home/trailer","Other (including boat, RV, van, etc.)",
                        "Dorm or institutional housing")~ NA,
        res_type %in% c("Building with 4 or more apartments/condos",
                        "Building with 3 or fewer apartments/condos")~ "Apartments/Condos",
        res_type == "Single-family house (detached house)"~ "Single-family/Townhouse",
        res_type == "Townhouse (attached house)"~ "Single-family/Townhouse",
        TRUE~ res_type),
      levels = c("Single-family/Townhouse",
                 "Apartments/Condos","Other")
    ),
    
    lifecycle_2group = factor(
      case_when(
        lifecycle_class %in% c("Household with older adults", "Household includes children")~ "Household with children and/or elders",
        lifecycle_class %in% c("Household with adults 35-64", "Household with adults 18-34")~ "Household with adults 18-64",
        TRUE~ "other"),
      levels = c("Household with children and/or elders","Household with adults 18-64",
                 "other")
    ),
  )

df_person <- hts_data$person %>%
  mutate(
    
    employment_simple = case_when(
      employment %in% c("Employed full time (35+ hours/week, paid)",
                        "Employed part time (fewer than 35 hours/week, paid)",
                        "Self-employed",
                        "Self-employed (fewer than 35 hours/week, paid)"  )~"Employed full/part time or self-employed",
      TRUE~ NA
    ),
    
    workplace_simple = case_when(
      # only include full/part time or self-employed workers
      is.na(employment_simple)~ NA,
      workplace == "At home (telecommute or self-employed with home office)"~ "Work at home",
      workplace == "Telework some days and travel to a work location some days"~ "Some days at home",
      is.na(workplace)~NA,
      TRUE~ "Outside from home"
    ),
    
    telecommute_freq_1plus = case_when(
      # only include full/part time or self-employed workers
      is.na(employment_simple)~ NA,
      telecommute_freq %in% c("1 day a week","2 days a week","1-2 days",
                              "3 days a week","4 days a week","3-4 days",
                              "5 days a week","5+ days","6-7 days a week")~ "telecommute at least 1 day/week",
      work_from_home == "Yes, all of the time (100% of the time)" | 
        workplace == "At home (telecommute or self-employed with home office)" |
        workplace == "Telework some days and travel to a work location some days"~ "telecommute at least 1 day/week",
      # workplace with values other than at home and telework
      is.na(telecommute_freq) & !is.na(workplace)~ "less than 1 day/week",
      is.na(telecommute_freq)~ NA,
      TRUE~ "less than 1 day/week"
    ),
    
    # telecommute status assignment
    telecommute_status = factor(
      
      case_when(
        
        # Not Worker: assign NAs to non-workers
        !employment %in% c("Self-employed", 
                           "Self-employed (fewer than 35 hours/week, paid)", 
                           "Employed part time (fewer than 35 hours/week, paid)", 
                           "Employed full time (35+ hours/week, paid)") ~ NA,
        
        # Fully At Home (2025): new variable "work_from_home" added in 2025
        work_from_home == "Yes, all of the time (100% of the time)"~ "Fully At Home",
        # Fully At Home (pre-2025)
        workplace == "At home (telecommute or self-employed with home office)"~ "Fully At Home",
        
        # Hybrid: if workers teleworked 1+ days a week
        telecommute_freq %in% c("1 day a week","2 days a week","1-2 days",
                                "3 days a week","4 days a week","3-4 days",
                                "5 days a week","5+ days","6-7 days a week")~ "Hybrid",
        workplace == "Telework some days and travel to a work location some days"~ "Hybrid",
        
        TRUE~ "Fully In Person"
        
      ),
      levels = c("Fully At Home","Hybrid","Fully In Person")
    ),
    
    non_telecommute = factor(case_when(
      telecommute_status %in% c("Hybrid","Fully In Person")~"Not Fully At Home",
      telecommute_status == "Fully At Home"~"Fully At Home",
      TRUE~telecommute_status),
      levels = c("Fully At Home","Not Fully At Home")
      
      ),
    
    # fix industry groups
    industry_sector = ordered(
      case_when(
        industry %in% c("Government","Military")~"Government & Military",
        TRUE~ industry_sector
      ),
      levels = c("Professional & Business Services",
                 "Arts & Media",
                 "Government & Military",
                 "Healthcare & Education",
                 "Other",
                 "Retail & Personal Services",
                 "Construction & Manufacturing")
      ),
    
    work_mode_simple = ordered(
      case_when(
        # only include full/part time or self-employed workers
        is.na(employment_simple)~ NA,
        work_mode %in% c("Drive alone",
                         "Drive onto ferry",
                         "Household vehicle (or motorcycle)",
                         "Other vehicle (e.g., friend's car, rental, carshare, work car)",
                         "Carpool ONLY with other household members",
                         "Carpool with other people not in household (may also include household members)",
                         "Motorcycle/moped")~"Drive",
        work_mode %in% c("Bus, shuttle, or vanpool (public transit, private service, or shuttles for older adults and people with disabilities)",
                         "Rail (e.g., train, subway)",
                         "Ferry or water taxi",
                         "Bus (public transit)",
                         "Urban rail (Link light rail, monorail, streetcar)",
                         "Commuter rail (Sounder, Amtrak)",
                         "Urban rail (Link light rail, monorail)",
                         "Streetcar")~"Transit",
        work_mode %in% c("Walk (or jog/wheelchair)",
                         "Walk, jog, or wheelchair")~"Active Modes",#"Walk",
        work_mode %in% c("Bicycle or e-bicycle",
                         "Bicycle or e-bike",
                         "Scooter, moped, skateboard",
                         "Motorcycle/moped/scooter",
                         "Scooter or e-scooter (e.g., Lime, Bird, Razor)")~"Active Modes",#"Bike/Micromobility",
        work_mode %in% c("Other",
                         "Uber/Lyft, taxi, or car service",
                         "Private bus or shuttle",
                         "Other hired service (Uber, Lyft, or other smartphone-app car service)",
                         "Airplane or helicopter",
                         "Paratransit",
                         "Vanpool",
                         "Taxi (e.g., Yellow Cab)",
                         "Other (e.g. skateboard)")~"Other",
        TRUE~ "missing"
      ),
      levels = c("Drive",
                 "Transit",
                 "Active Modes",
                 "Walk",
                 "Bike/Micromobility",
                 "Other")
    ),
    
    work_county = factor(case_when(
      work_county %in% c("King County","Kitsap County","Pierce County","Snohomish County")~ work_county,
      !is.na(work_county)~ "Outside of Region",
      TRUE~NA
      ),
    levels = c("King County","Kitsap County","Pierce County","Snohomish County"))
  )




df_trip <- hts_data$trip %>%
  mutate(
    distance_bins = case_when(distance_miles<=2~ "0-2 miles",
                              distance_miles<=5~ "2-5 miles",
                              distance_miles<=15~ "5-15 miles",
                              distance_miles>15~ "more than 15 miles"),
    dest_purpose_rate = case_when(dest_purpose_cat %in% c("Social/Recreation", "Meal")~ "Social/Recreation/Meal",
                                  dest_purpose_cat %in% c("Personal Business/Errand/Appointment", 
                                                          "Shopping",
                                                          "Escort", 
                                                          "School", 
                                                          "School-related",
                                                          "Other")~ "Errands/Shopping/School/Other",
                                  dest_purpose_cat %in% c("Work", "Work-related")~ "Work",
                                  TRUE~ NA)
  )

# HTS data manupulation for analysis work ----

df_hts_data <- hts_data
df_hts_data$hh <- df_hh
df_hts_data$person <- df_person
df_hts_data$trip <- df_trip
