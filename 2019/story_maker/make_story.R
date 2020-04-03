source('global.R')
source('travel_crosstab.R')

file_loc <- 'C:/Users/SChildress/Documents/HHSurvey'

# read in data
variables.lu <- read.dt(dbtable.variables, 'table_name')
variables.lu <- na.omit(variables.lu)
variables.lu <- variables.lu[order(category_order, variable_name)]
values.lu <- read.dt(dbtable.values, 'table_name')
values.lu<- values.lu[order(value_order)]


### summarize previous
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

first = 1

for(res_factor in prev_res_vars){
  region_tab<-stabTable(res_factor, 'Region')
  seattle_tab<-stabTable(res_factor, 'Seattle')
  tbl_output <-merge(region_tab, seattle_tab, by=res_factor, suffixes =c(' Region', ' Seattle'))  
  vars <-variables.lu[variable==res_factor]
  var_name <-unique(vars[,variable_name])
  setnames(tbl_output, res_factor, var_name)
  share_fields <-c(var_name, paste('share', 'Region'), paste('share', 'Seattle'))
  tbl_output <- tbl_output[, ..share_fields]
  setnames(tbl_output,'share Region', paste(var_name,'share Region') )
  setnames(tbl_output,'share Seattle', paste(var_name,'share Seattle'))
  file_name <- paste(var_name,'.csv')
  file_ext<-file.path(file_loc, file_name)
  write.csv(tbl_output, file_ext)

}





