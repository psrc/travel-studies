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
    select(-est_moe)
}

# plot_single_var <- function(df_plot, var_name, limits=NULL){
#   ggplot(df_plot, aes(x={{var_name}}, y=prop, fill=factor(survey_year))) +
#     geom_col(position = position_dodge(),width = 0.8) +
#     geom_text(aes(label=prop_label),
#               vjust = -0.5,
#               position = position_dodge(0.8)) +
#     scale_fill_manual(values = psrc_colors$pgnobgy_5)+
#     scale_y_continuous(labels = scales::percent, limits = limits) +
#     psrc_style() +
#     theme(panel.grid.major.y = element_blank(),
#           axis.title = element_blank())
# }
