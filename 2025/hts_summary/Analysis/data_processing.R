# this script contains standard data processing that can be shared across analyses
# RUNNING THIS SCRIPT: this script should be run from within topic project directories. Change working directory if running from a different location

source("../util.R")
library(logger)
library(glue)


log_info("Data processing script starting up...")

# ---- read hts data ----
# 2025 HTS codebook: https://github.com/psrc/travel-studies/tree/master/2025/2025_codebook


# topic_vars <- c("dest_county","dest_purpose","dest_purpose_cat","dest_purpose_cat_5","mode_class","mode_class_5",
#           "age","license","gender",
#           "hhincome_broad","home_county")
# topic_years <- c(2017, 2019, 2021, 2023)

hts_data <- get_psrc_hts(survey_vars = topic_vars,  # specify HTS variables from quarto doc
                         survey_years = topic_years)  # specify which survey years to include from quarto doc

log_info("HTS data loaded successfully. Now starting data manipulation...")

# ---- data manipulation ----


df_hts_analysis <- hts_data  # processed data is saved as df_hts_analysis



# [add data manipulation here]

## ---- household table ----

if("hhincome_broad" %in% names(hts_data[["hh"]])){
  
  # get unique values in variable (make sure to use all survey years, values vary across years)
  # unique(hts_data[["hh"]]$hhincome_broad)
  
  under_75 <- c("Under $25,000","$25,000-$49,999","$50,000-$74,999")
  higher_75 <- c("$75,000-$99,999","$100,000 or more","$100,000-$199,999","$200,000 or more")
  
  df_hts_analysis[["hh"]] <- hts_data[["hh"]] %>%
    mutate(
      
      # income with only 2 groups (high and low)
      income_2group = factor(
        case_when(hhincome_broad %in% under_75~ "Under $75,000",
                  hhincome_broad %in% higher_75~ "$75,000 or more",
                  hhincome_broad == "Prefer not to answer"~ NA
                  ),
        levels= c("Under $75,000","$75,000 or more")
        )  # add new categorical variables as factors with specified levels
    
      )
  
  log_info(paste0("-hh -new variable added `income_2group`: ", 
                  paste0(levels(df_hts_analysis[['hh']]$income_2group), collapse = " > ")))
  
}


## ---- person table ----

## ---- day table ----

## ---- trip table ----



# ---- save output ----
saveRDS(df_hts_analysis, "../Data/df_hts.rds")
