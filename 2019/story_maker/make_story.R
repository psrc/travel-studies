source('global.R')
source('travel_crosstab.R')

# read in data
variables.lu <- read.dt(dbtable.variables, 'table_name')
variables.lu <- na.omit(variables.lu)
variables.lu <- variables.lu[order(category_order, variable_name)]
values.lu <- read.dt(dbtable.values, 'table_name')
values.lu<- values.lu[order(value_order)]

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

for(res_factor in prev_res_vars){
  print(stabTable(res_factor))
}


