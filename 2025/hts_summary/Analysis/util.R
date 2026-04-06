# this file contains common libraries and functions that are used across analyses

library(tidyverse)
library(logger)

library(psrc.travelsurvey)
library(psrccensus)
library(psrcplot)

log_add_group_var <- function(var_name, table){
  
  log_info(glue("{table} -new variable `{var_name}` added: ", 
                paste0(levels(df_hts_analysis[[table]][[var_name]]), collapse = " > ")))
  
}

get_percent_format <- function(.data){
  .data  %>%
    mutate(prop_pct = percent_format(prop), # prop for printed tables
           prop_moe_pct = percent_format(prop_moe,0.001), # prop_moe for printed tables
           prop_label = percent_format(prop,1)) # rounded for chart labels
}

plot_single_var <- function(df_plot, var_name, limits=NULL){
  ggplot(df_plot, aes(x={{var_name}}, y=prop, fill=factor(survey_year))) +
    geom_col(position = position_dodge(),width = 0.8) +
    geom_text(aes(label=prop_label),
              vjust = -0.5,
              position = position_dodge(0.8)) +
    scale_fill_manual(values = psrc_colors$pgnobgy_5)+
    scale_y_continuous(labels = scales::percent, limits = limits) +
    psrc_style() +
    theme(panel.grid.major.y = element_blank(),
          axis.title = element_blank())
}
