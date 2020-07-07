source('global.R')
source('travel_crosstab.R')

# where you are running your R code
wrkdir <- "C:/Users/SChildress/Documents/GitHub/travel_studies_may/2019/story_maker"

#where you want to output tables
file_loc <- 'C:/Users/SChildress/Documents/HHSurvey/race_story'

race_data <-c('race_category')


# How many people of different races took the survey? What are the weighted totals of people by
# race groups
race_data <-c('race_category')
summarize_simple_tables(race_data)



#Are people of color experiencing more residential displacement than other groups?
#Displacement factors by race

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
  summarize_cross_tables(race_data, res_factor, group1=TRUE)
}
  

#Q1. How does vehicle ownership vary by race?

summarize_cross_tables(race_data, c('vehicle_count'))

#size<-c('hhsize')
# sizes<-values.lu[variable=='hhsize'][['value_text']]
# for(this_size in sizes){
#   print(this_size)
#   summarize_cross_tables(race_data,c('vehicle_count'),size, this_size)
# }


#summarize_cross_tables(race_data, c('vehicle_count'), group1=TRUE)

#Q2. How do mode shares differ by race?
summarize_cross_tables(race_data,c('mode_simple'))

# Person Race by Trip Mode by Trip Purpose, 3 dimension data summary example
d_purp_cat<-c('d_purp_cat')
purposes<-values.lu[variable=='d_purp_cat'][['value_text']]
for(this_purpose in purposes){
  summarize_cross_tables(race_data,mode,d_purp_cat, this_purpose)
  }

mode<-c('mode_simple')
#Person Race by Trip Mode by Household Income, 
inc<-c('hhincome_broad')
incomes<-values.lu[variable=='hhincome_broad'][['value_text']]
for(this_income in incomes){
  summarize_cross_tables(race_data,mode,inc, this_income)
}
#- by gender 
gender<-c('gender')
incomes<-values.lu[variable=='gender'][['value_text']]
for(this_gender in gender){
  summarize_cross_tables(race_data,mode,gender, gender)
}

#Q3. Do people of color have longer or shorter commutes than others? Are people of color being forced to have longer commutes?
#Commute Travel Time by Race
summarize_cross_tables(race_data, c('commute_auto_time'))
summarize_cross_tables(race_data, c('commute_auto_distance'))


#Q4. Are people of color using non-SOV modes at the same rate as other groups? 
#Are people of color using active transportation as much as other groups? 
#Do people of color have to drive more than others to conduct daily business (person miles or vehicle miles of travel)? This may indicate if the non-motorized network and new services are meeting people’s needs.
# Times ridden transit/walk/biked/ridehailing in past 30 days 
# -	By race
# mode_freq_1..mode_freq_5
summarize_cross_tables(race_data, c('mode_freq_1'))
summarize_cross_tables(race_data,c('mode_freq_2'))
summarize_cross_tables(race_data, c('mode_freq_3'))
summarize_cross_tables(race_data,c('mode_freq_4'))
summarize_cross_tables(race_data, c('mode_freq_5'))


#Q5. Who is benefiting from TDM strategies?
#Usual way of paying for parking at work by race
#Work parking costs per month by race
#Employer commuter benefits by race (flextime, compressed workweek, transit pass ownership)
#AV interest and concern by race

summarize_cross_tables(race_data, c('workpass'))
summarize_cross_tables(race_data, c('benefits_1'))
summarize_cross_tables(race_data, c('benefits_2'))
summarize_cross_tables(race_data, c('benefits_3'))
summarize_cross_tables(race_data,c('benefits_4'))

#Q6. What impact could non-motorized improvements have on usage by people of color?
summarize_cross_tables(race_data, c('wbt_transitmore_1'))
summarize_cross_tables(race_data,c('wbt_transitmore_2'))
summarize_cross_tables(race_data,c('wbt_transitmore_3'))
summarize_cross_tables(race_data,c('wbt_bikemore_1'))
summarize_cross_tables(race_data,c('wbt_bikemore_2'))
summarize_cross_tables(race_data,c('wbt_bikemore_3'))