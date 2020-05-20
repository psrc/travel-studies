source('global.R')
source('travel_crosstab.R')

# where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel_studies_may/travel-studies/2019/story_maker"
#where you want to output tables
file_loc <- 'C:/Users/SChildress/Documents/HHSurvey/race_story'


# How many people of different races took the survey? What are the weighted totals of people by
# race groups
race_data <-c('race_category')
#seattle_home_name <-c('seattle_home')
#seattle_home<-c('Home in Seattle', 'Home not in Seattle')

prev_res_vars <-
  c('prev_res_factors_housing_cost',
    'prev_res_factors_income_change',
    'prev_res_factors_community_change',
    'prev_res_factors_hh_size',
    'prev_res_factors_more_space',
    'prev_res_factors_less_space',
    'prev_res_factors_employment',
    'prev_res_factors_school',
    'prev_res_factors_crime',
    'prev_res_factors_quality',
    'prev_res_factors_forced')

for (res_factor in prev_res_vars){
  summarize_simple_tables(prev_res_vars)
}


# for (res_factor in prev_res_vars){
#   summarize_cross_tables(seattle_home_name, prev_res_vars)
# }
# 
# for(seattle_or_not in seattle_home){
#   for (res_factor in prev_res_vars){
#     print(seattle_or_not)
#     summarize_cross_tables(race_data, res_factor, seattle_home_name, seattle_or_not)
#   }
# }
