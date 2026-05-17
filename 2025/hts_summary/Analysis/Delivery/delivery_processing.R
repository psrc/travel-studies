source("../util.R")
library(logger)
library(glue)


log_info("Data processing script starting up...")

# ---- read hts data ----
# 2025 HTS codebook: https://github.com/psrc/travel-studies/tree/master/HTS_codebook/2025_codebook

# specify variables and survey years needed

# variables as topic_vars
delivery_vars <- c("deliver_food", "deliver_grocery", "deliver_package", "deliver_work", "deliver_other",
                   "deliver_none", "deliver_elsewhere", "deliver_office")
topic_vars <- c(delivery_vars, "daynum","travel_dow","travel_date",
                "dest_purpose_cat","dest_purpose_cat_5","mode_class","mode_class_5",
                "hhincome_broad", "home_county", "numworkers",
                "hh_race_category","vehicle_count","hhsize","numadults",
                "home_rgcname","lifecycle_class","res_type",
                "displaced","res_dur",
                "prev_res_factors_forced","prev_res_factors_income_change",
                "prev_res_factors_housing_cost","prev_res_factors_community_change"
                )

# survey years as topic_years
topic_years <- c(2017, 2019, 2021, 2023, 2025)

# get data
hts_data <- get_psrc_hts(survey_vars = topic_vars,  # specify HTS variables from quarto doc
                         survey_years = topic_years
)

log_info("HTS data loaded successfully. Now starting data manipulation...")

# ---- data manipulation ----


df_hts_analysis <- hts_data  # processed data is saved as df_hts_analysis

df_hts_analysis$hh <- hts_data$hh %>%
  mutate(
    
    # income with only 2 groups (high and low)
    income_2group = factor(
      case_when(
        
        hhincome_broad %in% c("Under $25,000","$25,000-$49,999","$50,000-$74,999")~ "Under $75,000",
        hhincome_broad %in% c("$75,000-$99,999","$100,000 or more","$100,000-$199,999","$200,000 or more")~ "$75,000 or more",
        hhincome_broad == "Prefer not to answer"~ NA
        
      ),
      levels= c("Under $75,000","$75,000 or more")
    ),
    
    # income with 3 groups
    income_3group = factor(
      case_when(
        
        hhincome_broad %in% c("Under $25,000","$25,000-$49,999")~'Under $50,000',
        hhincome_broad %in% c("$50,000-$74,999", "$75,000-$99,999")~"$50,000-$99,999",
        hhincome_broad %in% c("$100,000 or more","$100,000-$199,999", "$200,000 or more")~"$100,000 or more",
        TRUE~hhincome_broad
        
      ),
      levels = c('Under $50,000',"$50,000-$99,999","$100,000 or more","Prefer not to answer")
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
                        "Dorm or institutional housing")~ "Other",
        res_type %in% c("Building with 4 or more apartments/condos",
                        "Building with 3 or fewer apartments/condos")~ "Apartments/Condos",
        res_type == "Single-family house (detached house)"~ "Single-family house",
        res_type == "Townhouse (attached house)"~ "Townhouse",
        TRUE~ res_type),
      levels = c("Single-family house","Townhouse",
                 "Apartments/Condos","Other")
    ),
  )

# create household day table ----

# calculate household-day weights
if(file.exists("hh_day_delivery_day_format.rds")){
  
  pretend_day_table <- readRDS("hh_day_delivery_day_format.rds")
  
  log_info("load household-day table from hh_day_delivery_day_format.rds")
  
} else{
  hh_day_weight<- df_hts_analysis$day %>%
    
    summarize(hh_day_weight=first(day_weight), 
              .by = c(survey_year, hh_id, daynum)) %>%
    
    mutate(hh_day_id = paste(hh_id, daynum, sep="0"))
  
  hh_day_delivery <- df_hts_analysis$day %>%
    
    group_by(survey_year, hh_id, daynum) %>%
    # any 18+ person in household has delivery -> yes
    summarise_at(vars(deliver_food, deliver_grocery, deliver_package, deliver_work, deliver_other,
                      deliver_none, deliver_elsewhere, deliver_office),
                 ~case_when(sum(.=="Yes", na.rm=TRUE)>0~"Yes",
                            sum(.=="No", na.rm=TRUE)>0~"No",
                            sum(.=="Selected", na.rm=TRUE)>0~"Yes",
                            sum(.=="Not Selected", na.rm=TRUE)>0~"No",
                            TRUE~NA)) %>%
    ungroup() %>%
    
    mutate(deliver_home_any= case_when( deliver_food=="Yes" | deliver_grocery=="Yes" | 
                                          deliver_package=="Yes" | deliver_work=="Yes" | deliver_other=="Yes"~ "Yes", 
                                        TRUE~"No")) %>%
    
    left_join(hh_day_weight, by=c('survey_year','hh_id', 'daynum'))
  
  # rename ID and weight column for package use
  pretend_day_table <- hh_day_delivery %>%
    rename(day_id = hh_day_id,
           day_weight = hh_day_weight)
  
  saveRDS(pretend_day_table, "hh_day_delivery_day_format.rds")
  log_info("household-day table generated from HHSurvey.v_days view")
}


  

# HTS data manupulation for analysis work ----

df_hts_data <- df_hts_analysis

# replace day with custom hh-day table

# work around package not registering variables in custom hh-day table
# TODO: check issue
test <- df_hts_analysis$day %>%
  select(any_of(names(pretend_day_table))) %>%
  mutate(type = "original",
         deliver_home_any = NA) %>% 
  add_row(pretend_day_table %>% select(any_of(names(.)))) %>%
  filter(is.na(type)) 

df_hts_data$day <- test

