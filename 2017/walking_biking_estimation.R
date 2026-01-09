library(MASS)
library(nnet)
library(readxl)
library(dplyr)

person_file <- read_excel('J:/Projects/Surveys/HHTravel/Survey2017/Data/travel_crosstab/person_2017.xlsx')

person_file$group <- person_file$'Times gone for a walk in past 30 days'

#person_file$group <- person_file$'Times ridden a bike in past 30 days'
person_file$group  <-recode(person_file$group, "c('1-3 times in the past 30 days', 'I do this, but not in the past 30 days') = 'Less than weekly';
c('2-4 days/week', '1 day/week')= '1-4 days per week';
 c('5 days/week', '6-7 days/week')= '5 days per week or more'")

person_file$fact <-factor(person_file$group)
person_file$prog2 <-relevel(person_file$fact, ref = 'I never do this')

# urban village not null variable

person_file$inc <- person_file$"Household income 2016_ Broad categories_ all respondents"
person_file$very_low_inc <- person_file$"Household income 2016_ Broad categories_ all respondents" =='Under $25,000'
person_file$race_asian <- person_file$"race_category" =='Asian Only'
person_file$non_white_asian <- person_file$'race_category' == 'African-American, Hispanic, Multiracial, and Other'
#person_file$park_home <- person_file$"On-street parking availability at_near residence"

person_file$zero_vehicles <- person_file$vehicle_count == 0
person_file$lotso_vehicles <- person_file$vehicle_count >2
person_file$home_in_rgc <- person_file$'Final home address_ Regional growth center' != 'Not RCG'
person_file$retired<- person_file$'Age 18+_ Employment status' == 'Retired'
#person_file$vehiclesless_adults <- (person_file$vehicle_count<person_file$numadults & person_file$vehicle_count > 0)

#ol <- polr(prog2 ~  factor(sample_county)+ factor(cityofseattle) + factor(very_low_inc)+zero_vehicles + numchildren+ factor(age_category)
#               +factor(race_asian) +factor(non_white_asian)+home_in_rgc,  data = person_file, Hess = TRUE)

#ml <- multinom(prog2 ~  factor(sample_county)+ factor(cityofseattle) + factor(very_low_inc)+zero_vehicles + numchildren+ factor(age_category)+
#            home_in_rgc,  data = person_file)

#ml <- multinom(prog2~  factor(inc) + zero_vehicles +home_in_rgc +race_asian +non_white_asian+ employed, data = person_file)
ml <- multinom(prog2~zero_vehicles+lotso_vehicles+home_in_rgc +race_asian +non_white_asian, data = person_file)
#ml <- multinom(prog2~   zero_vehicles, data = person_file)
z <- summary(ml)$coefficients/summary(ml)$standard.errors

# variables that didn't look that significant numworkers, parking at hoem

summary(ml)
z


