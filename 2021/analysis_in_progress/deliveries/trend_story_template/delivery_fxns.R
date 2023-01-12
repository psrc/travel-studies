# r start

library(tidyverse)
library(stringr)

# Visualization functions
# function combining the delivery and household functions into one and ordering income by levels

smp_delivery_combo <- function(data, year) {
  ## rewriting labels of responses to be more concise
  temp_table <- data %>%
    mutate(delivery_food_all= case_when((pernum==1 & is.na(delivery_food_freq) & is.na(deliver_food)) ~ 'No HH Response',
                                        # pernum == 1 removes households where multiple members answered the question
                                        (pernum>1) ~ 'Not Person One, not the responder',
                                        delivery_food_freq == "0 (none)"  ~ 'No Delivery',
                                        deliver_food=='No' ~ 'No Delivery',
                                        TRUE ~ 'Delivery Received'))%>%
    mutate(delivery_pkgs_all= case_when((pernum==1 & is.na(delivery_pkgs_freq) & is.na(deliver_package)) ~ 'No HH Response',
                                        (pernum>1) ~ 'Not Person One, not the responder',
                                        deliver_package=='No' ~ 'No Delivery',
                                        delivery_pkgs_freq == "0 (none)"  ~ 'No Delivery',
                                        TRUE ~ 'Delivery Received'))%>%
    mutate(delivery_grocery_all=case_when((pernum==1 & is.na(delivery_grocery_freq) & is.na(deliver_grocery)) ~ 'No HH Response',
                                          (pernum>1) ~ 'Not Person One, not the responder',
                                          delivery_grocery_freq == "0 (none)"  ~ 'No Delivery',
                                          deliver_grocery=='No' ~ 'No Delivery',
                                          TRUE ~ 'Delivery Received'))%>%
    mutate(delivery_work_all= case_when((pernum==1 & is.na(delivery_work_freq) & is.na(deliver_work)) ~ 'No HH Response',
                                        (pernum>1) ~ 'Not Person One, not the responder',
                                        deliver_work =='No' ~ 'No Delivery',
                                        delivery_work_freq == "0 (none)"  ~ 'No Delivery',
                                        TRUE ~ 'Delivery Received'))%>%
    mutate(hhincome_broad = factor(case_when(as.character(hhincome_broad) %in% c("$100,000-$199,000","$200,000 or more") ~ 
                                               "$100,000 or more", !is.na(hhincome_broad) ~ as.character(hhincome_broad)),
                                   levels=c("Under $25,000", 
                                            "$25,000-$49,999", 
                                            "$50,000-$74,999", 
                                            "$75,000-$99,999", 
                                            "$100,000 or more", 
                                            "Prefer not to answer")))%>%
    mutate(lifecycle= case_when(lifecycle == "Household size > 1, Householder age 65+" | 
                                  lifecycle == "Household size = 1, Householder age 65+"  
                                ~ '65 years or older', 
                                lifecycle == "Household size > 1, Householder age 35 - 64" |
                                  lifecycle == "Household size = 1, Householder age 35 - 64"  
                                ~ '35-64',
                                lifecycle == "Household size > 1, Householder under age 35" | 
                                  lifecycle == "Household size = 1, Householder under age 35" 
                                ~ 'Under 35 years, no kids',
                                lifecycle == "Household includes children age 5-17" | 
                                  lifecycle == "Household includes children under 5" ~ 'Household has kids')) %>%
    mutate(hhsize= case_when(hhsize == "1 person" ~ '1 person', 
                             hhsize == "2 people"  ~ '2 people', 
                             hhsize == "3 people" ~ '3 people',
                             hhsize == "4 people" | 
                               hhsize == "5 people" | 
                               hhsize == "6 people" | 
                               hhsize == "7 people" |
                               hhsize == "8 people" | 
                               hhsize == "12 people" ~ "4+ people"))
  temp_table
}


# data visualization function for crosstabs
# plot by year and by category

share_plot_by_year <- function(dt1, dt2, dt3, grp_var, grp_var2, legend_name){
  
  fill_group <- all_food_freq_17_21[[grp_var]]
  x_axis_grp <- all_food_freq_17_21[[grp_var2]]
  
  ggplot(all_food_freq_17_21, aes(x=x_axis_grp,
                                  y=share,
                                  fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~period)+
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Share",
         fill = legend_name) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                  size=.5, width=.2,
                  position=position_dodge(0.9))
  
}

share_plot_by_year2 <- function(dt1, dt2, dt3, grp_var, grp_var2, legend_name){
  
  fill_group <- all_food_freq_17_21[[grp_var]]
  x_axis_grp <- all_food_freq_17_21[[grp_var2]]
  
  ggplot(all_food_freq_17_21, aes(x=x_axis_grp,
                                  y=share,
                                  fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~delivery_food_all)+
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Share",
         fill = legend_name) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                  size=.5, width=.2,
                  position=position_dodge(0.9))
  
}

share_plot_by_cat <- function(dt1, dt2, dt3, grp_var, grp_var2, legend_name){
  
  fill_group <- all_food_freq_17_21[[grp_var]]
  # facet_group <- all_commute_17_21[[grp_var2]]
  
  ggplot(all_food_freq_17_21, aes(x=period,
                                  y=share,
                                  fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~all_food_freq_17_21[[grp_var2]])+
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Share",
         fill = legend_name) +
    scale_y_continuous(labels = scales::percent_format(accuracy = 1)) +
    geom_errorbar(aes(ymin=share-share_moe, ymax=share+share_moe),
                  size=.5, width=.2,
                  position=position_dodge(0.9))
}

count_plot_by_cat <- function(dt1, dt2, dt3, grp_var, grp_var2, legend_name){
  
  fill_group <- all_food_freq_17_21[[grp_var]]
  # facet_group <- all_commute_17_21[[grp_var2]]
  
  ggplot(all_food_freq_17_21, aes(x=period,
                                  y=count,
                                  fill=fill_group)) +
    geom_bar(stat="identity",
             position="dodge2") +
    facet_wrap(~all_food_freq_17_21[[grp_var2]])+
    theme(axis.text.x=element_text(angle=45, hjust=1, vjust=1),
          axis.title.x = element_blank()) +
    labs(y = "Count",
         fill = legend_name) +
    scale_y_continuous(labels = scales::comma) +
    geom_errorbar(aes(ymin=count-count_moe, ymax=count+count_moe),
                  size=.5, width=.2,
                  position=position_dodge(0.9))
}  

