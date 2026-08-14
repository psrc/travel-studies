# this file contains common libraries and functions that are used across analyses

library(tidyverse)
library(logger)

library(psrc.travelsurvey)
library(psrccensus)
library(psrcplot)
install_psrc_fonts()


get_table_format <- function(.data){
  .data  %>%
    mutate(prop = scales::percent(prop, accuracy = 0.1),
           prop_moe = scales::percent(prop_moe, accuracy = 0.01),
           est = scales::number(est, accuracy = 1, big.mark = ","),
           count = scales::number(count, accuracy = 1, big.mark = ",")) %>%
    select(-est_moe) %>%
    rename(`survey year` = survey_year,
           share = prop,
           share_moe = prop_moe,
           estimates = est,
           sample = count)
}



# switch to turn error bars on and off using yaml parameter: params$errorbar
errorbar_switch <- function(errorbar, on = FALSE){
  if(on){
    
    list( errorbar )
    
  } else{
    
    list()
    
  }
  
}
