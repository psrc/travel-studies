library(psrc.travelsurvey)
library(tidyverse)
library(ggiraph)

# global variables
survey_a <- list(survey = '2017_2019', label = '2017/2019')
survey_b <- list(survey = '2021', label = '2021')
survey_c <- list(survey = '2017', label = '2017')
survey_d <- list(survey = '2019', label = '2019')

gridline.color <- '#ededed'
background.color <- 'white'

gender_tcf_get_hhts <- function(survey, level, vars) {
  if(survey == '2021') {
    wrkr <- get_hhts(survey = survey,
                     level = level,
                     vars = vars) %>%
      filter(age_category != 'Under 18 years') %>%
      filter(worker != 'No jobs') %>%
      filter(!(workplace %in% c(str_subset(workplace, "^At\\shome.*"), str_subset(workplace, "^Drives.*")))) %>%
      drop_na(any_of(c('workplace', 'telecommute_freq'))) %>%
      mutate(tc_freq_group_simple = case_when(telecommute_freq %in% str_subset(unique(.data$telecommute_freq), '.*days$')~ 'Telecommuted at least once per week',
                                              !is.na(telecommute_freq) ~ telecommute_freq))
    if('gender' %in% colnames(wrkr)) {
      wrkr <- wrkr %>% 
        mutate(gender_group = case_when(gender %in% c('Not listed here / prefer not to answer', 'Non-Binary') ~ 'Prefer not to answer / Another',
                                        !is.na(gender) ~ gender))
    }
    
  } else {
    wrkr <- get_hhts(survey = survey,
                     level = level,
                     vars = vars) %>%
      filter(age_category != 'Under 18 years') %>%
      filter(worker != 'No jobs') %>%
      filter(!(workplace %in% c(str_subset(workplace, "^At\\shome.*"), str_subset(workplace, "^Drives.*")))) %>%
      mutate(tc_freq_group = case_when(telecommute_freq %in% c('1 day a week', '2 days a week') ~ '1-2 days',
                                       telecommute_freq %in% c('3 days a week', '4 days a week') ~ '3-4 days',
                                       telecommute_freq %in% c('5 days a week', '6-7 days a week') ~ '5+ days',
                                       telecommute_freq %in% c('Never', 'Not applicable') ~ 'Never / None',
                                       !is.na(telecommute_freq) ~ telecommute_freq)) %>%
      mutate(tc_freq_group_simple = case_when(tc_freq_group %in% str_subset(unique(.data$tc_freq_group), '.*days$')~ 'Telecommuted at least once per week',
                                              !is.na(tc_freq_group) ~ tc_freq_group)) %>%
      filter(!(telecommute_freq %in% str_subset(unique(telecommute_freq), '.*month(ly)*$')))
    
    if('gender' %in% colnames(wrkr)) {
      wrkr <- wrkr %>% 
        mutate(gender_group = case_when(gender %in% c('Prefer not to answer', 'Another') ~ 'Prefer not to answer / Another',
                                        !is.na(gender) ~ gender))
    }
    
  }
  return(wrkr)
}

my_theme <- function(hjust = .5, vjust = 1.2, angle = 45) {
  theme(axis.text.x = element_text(hjust = hjust,
                                   vjust = vjust,
                                   angle = angle,
                                   size = 6),
        axis.ticks.x = element_blank(),
        axis.ticks.y = element_blank(),
        legend.position = 'bottom',
        legend.title = element_blank(),
        panel.background = element_rect(fill = background.color),
        panel.grid.major.y = element_line(color = gridline.color),
        panel.grid.minor.y = element_line(color = gridline.color),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.x = element_blank(),
        plot.caption = element_text(size=5)
  )
}

gender_tcf <- function(table, plot.source.year, plot.caption = plot.caption, plot.title = plot.title, palette, hjust = .5, vjust = 1.2, angle = 45, facet = FALSE) {
  
  plot.source <- paste0('Source: ', plot.source.year,' ', 'Household Travel Survey')
  plot.caption <- paste0(plot.source, plot.caption)
  
  g <- ggplot(table,
              aes(x = tc_freq_group,
                  y = share,
                  fill = period,
                  tooltip = paste0(tc_freq_group, ' ', period, ': ', round(share*100, 0), '%'))) +
    geom_col_interactive(position = position_dodge(width=.9)) +
    geom_linerange(aes(ymin = lower,
                       ymax = upper),
                   position = position_dodge(width=.9)) +
    scale_fill_brewer(palette = palette) +
    scale_y_continuous(labels = scales::label_percent()) +
    scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 20)) +
    labs(x = NULL,
         y = NULL,
         title = plot.title,
         subtitle = plot.subtitle,
         caption = plot.caption) +
    my_theme(hjust = hjust, vjust = vjust, angle = angle)
  
  if(facet == TRUE) {
    g <- g +
      facet_wrap(vars(gender_group), labeller = labeller(gender_group = plot.facet.labels)) 
  }
  
  girafe(ggobj = g)
}

