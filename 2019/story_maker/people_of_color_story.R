source('global.R')
source('travel_crosstab.R')
source('summarize_these.R')



# read in data
variables.lu <- read.dt(dbtable.variables, 'table_name')
variables.lu <- na.omit(variables.lu)
variables.lu <- variables.lu[order(category_order, variable_name)]
values.lu <- read.dt(dbtable.values, 'table_name')
values.lu<- values.lu[order(value_order)]


#Q0. Are people of color experiencing more residential displacement than other groups?
#  -	Displacement factors by race

#First, explore the data by race

summarize_simple_tables(race_data)

for (res_factor in prev_res_vars){
  summarize_cross_tables(race_data, res_factor)
}
  







