library(psrc.travelsurvey)
library(magrittr)
library(data.table)
library(dplyr)
library(stringr)
library(psrcplot)
library(tidyverse)
library(ggplot2)

## palette
psrc_col <- c("#00A7A0", "#8CC63E", "#F05A28", "#91268F", "#BBBDC0", "#76787A",
              "#00A7A0", "#8CC63E", "#F05A28", "#91268F", "#BBBDC0", "#76787A")

## driver vs. non-driver analysis
vars <- c("license", "mode_class", "mode_class_5")

hts_data <- get_psrc_hts(survey_vars = vars)

hts_data$person <- mutate(
  hts_data$person,
  license_cond=case_when(license %in% c("No, does not drive", "No, does not have a license or permit") ~ "No, does not drive",
                         license %in% c("Yes, has an intermediate or unrestricted license",
                                        "Yes, has a learner’s permit", "Yes, drives") ~ "Yes, drives")) %>%
  mutate(license_cond = factor(license_cond, levels = c("Yes, drives",  
                                                        "No, does not drive")))

df <- psrc_hts_stat(hts_data, "trip", c("license_cond", "mode_class_5"), incl_na=FALSE) 

df$survey_year<-as.character(df$survey_year)
df <- df %>% mutate(prop_rounded = round(prop, digits=2))

driver_mode_chart <- ggplot(data = df, aes(x = survey_year, y = prop, fill=license_cond, label=prop_rounded)) +
  geom_col(position="dodge") +
  scale_fill_manual(values=rep(psrc_col)) + 
  labs(title="Mode Share for Drivers vs. Non-drivers", fill="Drives?") +
  facet_wrap(~mode_class_5, nrow=1, scales="free", strip.position = "bottom") +
  theme(strip.placement="outside", axis.title.x=element_blank()) + 
  geom_text(position=position_dodge(1), vjust=-0.25, size = 2.85) +
  theme(panel.background = element_blank())

driver_mode_chart

## filter by year to see margins of error
df_by_year <- df %>% filter(survey_year=="2023")

driver_mode_chart2 <- static_column_chart(df_by_year, x="mode_class_5", y='prop', fill='license_cond',
                                          title = 'Mode Share for Drivers vs. Non-drivers',
                                          ylabel= 'Share',
                                          xlabel='Mode', 
                                          moe='prop_moe'
) + theme(axis.text.x=element_text(size=14),
          axis.text.y=element_text(size=14),
          legend.text = element_text(size=14), 
          axis.title.y=element_text(size=20), 
          axis.title.x=element_text(size=20))

driver_mode_chart2
