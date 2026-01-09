library(tidyverse)
library(psrcelmer)
library(config)

# lookup tool
library(qdapTools)
# summary table
library(tableone)
library(survey)


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


# get weighted summary table
get_vars_summary_w <- function(.data, summary_vars, order = TRUE){
  
  df <- .data %>%
    mutate(across(any_of(summary_vars), ~get_labels(., varname = cur_column(), order = order))) %>%
    filter(person_weight>0)
  nhanesSvy <- svydesign(ids = ~person_id, weights = ~person_weight, data = df)
  
  return(
    svyCreateTableOne(data = nhanesSvy,
                      vars = summary_vars
    )
  )
}

get_stat_output <- function(.data, variable_list, logic_des, weighted=FALSE){
  # get stat table for all variables with specific logic
  
  
  character_vars <- c("platform", "home_loc_flag", "work_loc_flag")
  
  if(logic_des!="NA"){
    incl_vars <- variable_list %>% filter(logic == logic_des, variable %in% codebook$variable, !variable %in% character_vars)
  } else{
    incl_vars <- variable_list %>% filter(is.na(logic), variable %in% codebook$variable, !variable %in% character_vars)
  }
  
  if(weighted){
    stat <- .data %>%
      select(any_of(c(incl_vars$variable, "person_weight", "person_id"))) %>%
      get_vars_summary_w(incl_vars$variable)
  }
  else{
    stat <- .data %>%
      select(any_of(incl_vars$variable)) %>%
      get_vars_summary(incl_vars$variable)
  }
  
  return(stat)
  
}


plot_single <- function(var, color_ramp = psrc_color){
  
  df <- safety_responses %>%
    select(all_of(c(var,"person_weight"))) %>%
    filter(!is.na(!!sym(var)) & !is.na(person_weight)) %>%
    mutate(across(!!sym(var), ~get_labels(., varname = cur_column()))) %>%
    arrange(!!sym(var))
  
  df_sum <- df %>%
    summarise(count=n(), .by=var) %>%
    mutate(percent = count/sum(count),
           summary="count")
  
  df_sum_weighted <- df %>%
    summarise(count=sum(person_weight), .by=var) %>%
    mutate(percent = count/sum(count),
           summary="weighted")
  
  df_final <- rbind(df_sum,df_sum_weighted)
  
  p <- ggplot2::ggplot(df_final, aes(x=!!sym(var), y=percent, fill=summary)) + 
    geom_bar(stat="identity", position = "dodge") + 
    geom_text(aes(label=scales::percent(percent,accuracy=2)),
              position = position_dodge(0.9)) + 
    scale_y_continuous(labels = scales::percent) +
    coord_flip() +
    theme_bw() +
    scale_fill_manual(values = psrcplot::psrc_colors$obgnpgy_10) +
    theme(axis.title = element_blank(),
          plot.title = element_blank()) +
    labs(title = var)
  
  plotly::ggplotly(p)
  
  
}


