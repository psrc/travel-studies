source('global.R')
source('travel_crosstab.R')


# where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel-studies/2019/story_maker"

#where you want to output tables
file_loc <- 'C:/Users/SChildress/Documents/HHSurvey/telecommute'


telecommute_data <-c('telecommute_freq')
summarize_simple_tables(telecommute_data)

age_cat <-c('age_category')
summarize_cross_tables(age_cat, telecommute_data)

inc_cat <-c('hhincome_broad')
summarize_cross_tables(inc_cat,telecommute_data)