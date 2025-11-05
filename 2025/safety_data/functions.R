library(tidyverse)
library(psrcelmer)
library(config)

# lookup tool
library(qdapTools)
# summary table
library(tableone)


config <- config::get()
codebook <- read_csv(config$codebook)
variable_list <- read_csv(config$variable_list)

scale_color <- c("1: Strongly disagree" = "#E3C9E3", 
                 "2: Disagree" = "#C388C2",
                 "3: Neither agree nor disagree" = "#AD5CAB",
                 "4: Agree" = "#91268F",
                 "5: Strongly agree" = "#630460",
                 "NA" = "#4C4C4C")
# psrcplot::psrc_colors$obgnpgy_10
psrc_color <- c("#F05A28", "#00A7A0", "#8CC63E", "#91268F", "#4C4C4C", 
                "#9f3913", "#00716c", "#588527", "#630460", "#4C4C4C",
                "#F05A28", "#00A7A0", "#8CC63E", "#91268F")

get_labels <- function(.column, varname, order=TRUE){
  
  var_lookup <- codebook[codebook$variable == varname,]
  var_lookup <- data.frame(var_lookup$value,var_lookup$label) %>%
    mutate(`var_lookup.label` = paste0(`var_lookup.value`,": ",`var_lookup.label`),
           `var_lookup.value` = as.numeric(`var_lookup.value`))
  
  s_unordered <- lookup(.column, var_lookup)
  s_ordered <- factor(s_unordered, levels=var_lookup[['var_lookup.label']])
  
  return( if(order){s_ordered} else{s_unordered} )
}


# get summary table
get_vars_summary <- function(.data, summary_vars, order = TRUE){
  
  df <- .data %>%
    mutate(across(any_of(summary_vars), ~get_labels(., varname = cur_column(), order = order)))
  
  return(
    CreateTableOne(data = df,
                   vars = summary_vars,
                   includeNA = TRUE
    )
  )
}

get_stat_output <- function(.data, variable_list, logic_des){
  # get stat table for all variables with specific logic
  
  
  character_vars <- c("platform", "home_loc_flag", "work_loc_flag")
  
  if(logic_des!="NA"){
    incl_vars <- variable_list %>% filter(logic == logic_des, variable %in% codebook$variable, !variable %in% character_vars)
  } else{
    incl_vars <- variable_list %>% filter(is.na(logic), variable %in% codebook$variable, !variable %in% character_vars)
  }
  
  stat <- .data %>%
    select(any_of(incl_vars$variable)) %>%
    get_vars_summary(incl_vars$variable)
  return(stat)
  
}


plot_single <- function(var, color_ramp = psrc_color){
  
  df <- safety_responses %>%
    select(all_of(var)) %>%
    filter(!is.na(!!sym(var))) %>%
    mutate(across(!!sym(var), ~get_labels(., varname = cur_column()))) %>%
    summarise(count=n(), .by=var) %>%
    mutate(percent = count/sum(count))
  
  p <- ggplot2::ggplot(df, aes(x=!!sym(var), y=percent, fill=!!sym(var))) + 
    geom_bar(stat="identity") + 
    scale_y_continuous(labels = scales::percent) +
    coord_flip() +
    theme_bw() +
    scale_fill_manual(values = color_ramp) +
    theme(axis.title = element_blank(),
          plot.title = element_blank(),
          legend.position = "none") +
    labs(title = var)
  
  
  plotly::ggplotly(p)
  
}
