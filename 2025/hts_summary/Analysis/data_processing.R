# this script contains standard data processing that can be shared across analyses
# RUNNING THIS SCRIPT: this script should be run from within topic project directories. Change working directory if running from a different location

source("../util.R")
library(glue)


log_info("Data processing script starting up...")

# ---- read hts data ----
# 2025 HTS codebook: https://github.com/psrc/travel-studies/tree/master/HTS_codebook/2025_codebook
# variables as topic_vars

topic_vars <- c("dest_purpose_cat","dest_purpose_cat_5","mode_class","mode_class_5",
                "hhincome_broad", "home_county", "vehicle_count",
                "age","race_category","disability_person",
                "employment","workplace","work_from_home","telecommute_freq","commute_freq",
                "fuel")

# survey years as topic_years
topic_years <- c(1719, 2021, 2023, 2025)
hts_data <- get_psrc_hts(survey_vars = topic_vars,  # specify HTS variables from quarto doc
                         survey_years = topic_years
                         )  # specify which survey years to include from quarto doc

log_info("HTS data loaded successfully. Now starting data manipulation...")

# ---- data manipulation ----


df_hts_analysis <- hts_data  # processed data is saved as df_hts_analysis



# [add data manipulation here]

## ---- household table ----

# get unique values in variable (make sure to use all survey years, values vary across years)
# unique(hts_data[["hh"]]$hhincome_broad)

df_hts_analysis[["hh"]] <- hts_data[["hh"]] %>%
  mutate(
    
    # income with only 2 groups (high and low)
    income_2group = factor(
      case_when(
        hhincome_broad %in% c("Under $25,000","$25,000-$49,999","$50,000-$74,999")~ "Under $75,000",
        hhincome_broad %in% c("$75,000-$99,999","$100,000 or more","$100,000-$199,999","$200,000 or more")~ "$75,000 or more",
        hhincome_broad == "Prefer not to answer"~ NA
                ),
      levels= c("Under $75,000","$75,000 or more")
      ),  # add new categorical variables as factors with specified levels
    
    income_3group = factor(
      case_when(
        
        hhincome_broad %in% c("Under $25,000","$25,000-$49,999")~'Under $50,000',
        hhincome_broad %in% c("$50,000-$74,999", "$75,000-$99,999")~"$50,000-$99,999",
        hhincome_broad %in% c("$100,000 or more","$100,000-$199,999", "$200,000 or more")~"$100,000 or more",
        TRUE~hhincome_broad
        
        ),
      levels = c('Under $50,000',"$50,000-$99,999","$100,000 or more","Prefer not to answer")
      ),
    
    hhincome_broad_100Kmore = factor(
      case_when(
        
        hhincome_broad %in% c("$100,000 or more","$100,000-$199,999", "$200,000 or more")~"$100,000 or more",
        TRUE~hhincome_broad
        
      ),
      levels = c("Under $25,000","$25,000-$49,999", "$50,000-$74,999",
                 "$75,000-$99,999","$100,000 or more", "Prefer not to answer")
    ),
  
    )
log_add_group_var("income_2group", "hh")
log_add_group_var("income_3group", "hh")
log_add_group_var("hhincome_broad_100Kmore", "hh")



## ---- person table ----

df_hts_analysis[["person"]] <- hts_data[["person"]] %>%
  mutate(
    
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
        
        TRUE~ "Fully In Person"
        
      ),
      levels = c("Fully At Home","Hybrid","Fully In Person")
    ),
  )

log_add_group_var("telecommute_status", "person")


## ---- day table ----

## ---- trip table ----



# ---- save output ----
# saveRDS(df_hts_analysis, "../Data/df_hts.rds")
