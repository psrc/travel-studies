# INSTALL PACKAGES----------------------------------
# List of packages required
packages <- c("data.table","odbc","DBI","summarytools",
              "dplyr", "tidyverse", "psych", "openxlsx",
              "ggplot2","tidyr")
lapply(packages, install.packages, character.only = TRUE)

# LOAD LIBRARIES----------------------------------
lapply(packages, library, character.only = TRUE)
lapply(packages, require, character.only = TRUE)


# CONNECT TO DATABASE, SET UP WORKSPACE----------------------------------
elmer_connection <- dbConnect(odbc::odbc(),
                        driver = "SQL Server",
                        server = "AWS-PROD-SQL\\Sockeye",
                        database = "Elmer",
                        trusted_connection = "yes")
h <- dbGetQuery(elmer_connection,
                "SELECT * FROM HHSurvey.v_households_2017_2019_in_house")
p <- dbGetQuery(elmer_connection,
                "SELECT * FROM HHSurvey.v_persons_2017_2019_in_house")

dbDisconnect(elmer_connection)

household <- data.table(h)
person <- data.table(p)
# Statistical assumptions for margins of error
p_MOE <- 0.5
z<-1.645
missing_codes <- c('Missing: Technical Error', 'Missing: Non-response', 
                   'Missing: Skip logic', 'Children or missing', 'Prefer not to answer',
                   'Missing')

# FUNCTIONS----------------------------------
# Create a crosstab from one variable, calculate counts, totals, and shares,
# for categorical data
create_table_one_var = function(var1, table_temp,table_type) {
  #table_temp = recategorize_var_upd(var2,table_temp)
  #print(table_temp)
  if (table_type == "household" | table_type == "person" ) {
    weight_2017 = "hh_wt_revised"
    weight_2019 = "hh_wt_2019"
    weight_comb = "hh_wt_combined"
  } else if (table_type == "trip") {
    weight_2017 = "trip_weight_revised"
    weight_2019 = "trip_wt_2019"
    weight_comb = "trip_wt_combined"  
  } 
  
  temp = table_temp %>% select(!!sym(var1), all_of(weight_2017), all_of(weight_2019), all_of(weight_comb)) %>% 
    filter(!.[[1]] %in% missing_codes, !is.na(.[[1]])) %>% 
    group_by(!!sym(var1)) %>% 
    summarise(n=n(),sum_wt_comb = sum(.data[[weight_comb]],na.rm = TRUE),sum_wt_2017 = sum(.data[[weight_2017]],na.rm = TRUE),sum_wt_2019 = sum(.data[[weight_2019]],na.rm = TRUE)) %>% 
    mutate(perc_comb = sum_wt_comb/sum(sum_wt_comb)*100, perc_2017 = sum_wt_2017/sum(sum_wt_2017)*100, perc_2019 = sum_wt_2019/sum(sum_wt_2019)*100,delta = perc_2019-perc_2017) %>% 
    ungroup() %>%  mutate(MOE=1.65*(0.25/sum(n))^(1/2)*100) %>% arrange(desc(perc_comb))
  return(temp)
}

# Create a simplified crosstab from one variable, calculate counts, totals, shares, and MOE
# for categorical data
create_table_one_var_simp= function(var1, table_temp,table_type) {
  #table_temp = recategorize_var_upd(var2,table_temp)
  #print(table_temp)
  if (table_type == "household" | table_type == "person" ) {
    weight_2017 = "hh_wt_revised"
    weight_2019 = "hh_wt_2019"
    weight_comb = "hh_wt_combined"
  } else if (table_type == "trip") {
    weight_2017 = "trip_weight_revised"
    weight_2019 = "trip_wt_2019"
    weight_comb = "trip_wt_combined"  
  } 
  
  temp = table_temp %>% select(!!sym(var1), all_of(weight_2017), all_of(weight_2019), all_of(weight_comb)) %>% 
    filter(!.[[1]] %in% missing_codes, !is.na(.[[1]])) %>% 
    group_by(!!sym(var1)) %>% 
    summarise(n=n(),sum_wt_comb = sum(.data[[weight_comb]],na.rm = TRUE)) %>% 
    mutate(perc_comb = sum_wt_comb/sum(sum_wt_comb)*100) %>% 
    ungroup() %>%  mutate(MOE=1.65*(0.25/sum(n))^(1/2)*100) %>% arrange(desc(perc_comb))
  return(temp)
}

#Create a crosstab from two variables, calculate counts, totals, and shares,
# for categorical data
cross_tab_categorical <- function(table, var1, var2, wt_field) {
  expanded <- table %>% 
    group_by(.data[[var1]],.data[[var2]]) %>%
    summarize(Count= n(),Total=sum(.data[[wt_field]])) %>%
    group_by(.data[[var1]])%>%
    mutate(Percentage=Total/sum(Total)*100)
  
  
  expanded_pivot <-expanded%>%
    pivot_wider(names_from=.data[[var2]], values_from=c(Percentage,Total, Count))
  
  return (expanded_pivot)
  
} 

# Create margins of error for dataset
categorical_moe <- function(sample_size_group){
  sample_w_MOE<-sample_size_group %>%
    mutate(p_col=p_MOE) %>%
    mutate(MOE_calc1= (p_col*(1-p_col))/sample_size) %>%
    mutate(MOE_Percent=z*sqrt(MOE_calc1)*100)
  
  sample_w_MOE<- select(sample_w_MOE, -c(p_col, MOE_calc1))
  
  return(sample_w_MOE)
}   

# write out crosstabs function
write_cross_tab<-function(out_table, var1, var2, file_loc){
  
  file_name <- paste(var1,'_', var2,'.xlsx')
  file_ext<-file.path(file_loc, file_name)
  write.xlsx(out_table, file_ext, sheetName ="data", 
             col.names = TRUE, row.names = FALSE, append = FALSE)
}

output_WB <- "T:/2020October/Mary/HHTS/OutputTables/test.xlsx"

# ~~~~~~~~~~~~~~~~ ----------------------------------
# Household DATASET----------------------------------
# Vehicle ownership----------------------------------
# to check distribution of vehicle ownership
glimpse(household)
household %>% 
  group_by(vehicle_count) %>% 
  summarise(n=n())
# create table with function
create_table_one_var("vehicle_count",household, "household")

# reorder vehicle_count so "0 (no vehicles)" is at beginning and "10 or more vehicles" is at end
unique(household$vehicle_count)
household$vehcount_reordered <- factor(household$vehicle_count, 
                                       levels=c("0 (no vehicles)","1","2","3","4","5",
                                                "6","7","8","9","10 or more vehicles"))

# check new order
levels(household$vehcount_reordered)
# find sample size of group
xtabs(~vehcount_reordered, data=household)

# table household weights by number of vehicles (reordered)
hhwt_vehiclecount_reordered <- household%>% 
  group_by(VehicleCount=vehcount_reordered)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_vehiclecount_reordered

# Create blank workbook
wb <- createWorkbook()
# Add sheets to workbook
addWorksheet(wb, "VehicleCount_MOE")
# Write data to sheets
writeData(wb, sheet = "VehicleCount_MOE", x=hhwt_vehiclecount_reordered)
# Export file
saveWorkbook(wb,output_WB, overwrite = T)

# plot
a1<- ggplot(data = hhwt_vehiclecount_reordered, 
            aes(x=VehicleCount, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Vehicles per Household", 
       y = "Estimated Number of Households in Region", title = "Vehicle Ownership")
a1

# Vehicle ownership simplified----------------------------------
# group vehicle ownership above 3 vehicles
household <- household%>%
  mutate(vehcount_simp = case_when(vehicle_count == "0 (no vehicles)" ~ "0",
                                   vehicle_count == "4"|
                                     vehicle_count == "5"|
                                     vehicle_count == "6"|
                                     vehicle_count == "7"|
                                     vehicle_count == "8"|
                                     vehicle_count == "9"|
                                     vehicle_count == "10 or more vehicles" ~ "4",
                                   TRUE~.$vehicle_count))
unique(household$vehcount_simp)

VehicleCount_MOE1_temp <- create_table_one_var_simp("vehcount_simp", household, "household")
VehicleCount_MOE1<-VehicleCount_MOE1_temp%>%
  arrange(vehcount_simp)
VehicleCount_MOE1
VehicleCount_MOE2_temp <- create_table_one_var("vehcount_simp", household, "household")
VehicleCount_MOE2<-VehicleCount_MOE2_temp%>%
  arrange(vehcount_simp)
VehicleCount_MOE2

# Add sheets to workbook
addWorksheet(wb, "VehicleCount_simp1")
addWorksheet(wb, "VehicleCount_simp2")
# Write data to sheets
writeData(wb, sheet = "VehicleCount_simp1", x=VehicleCount_MOE1)
writeData(wb, sheet = "VehicleCount_simp2", x=VehicleCount_MOE2)
# Export file
saveWorkbook(wb,output_WB, overwrite = T)

# plot
vehicleplot <- household %>%
  group_by(vehcount_simp) %>%
  summarise(HouseholdWeight = sum(hh_wt_combined))

a2 <- ggplot(data = vehicleplot, 
             aes(x=vehcount_simp, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Vehicles per Household", 
       y = "Estimated Number of Households in Region", title = "Vehicle Ownership")
a2

# Number of workers----------------------------------
unique(household$numworkers)
describe(household$numworkers)
xtabs(~numworkers, data=household)

numworkers_MOE1_temp <- create_table_one_var_simp("numworkers", household, "household")
numworkers_MOE1 <- numworkers_MOE1_temp%>%
  arrange(numworkers)
numworkers_MOE1
numworkers_MOE2_temp <- create_table_one_var("numworkers", household, "household")
numworkers_MOE2 <-numworkers_MOE2_temp%>%
  arrange(numworkers)
numworkers_MOE

# save to workbook
addWorksheet(wb,"Number_of_workers_all1")
addWorksheet(wb,"Number_of_workers_all2")
writeData(wb, sheet = "Number_of_workers_all1", x=numworkers_MOE1)
writeData(wb, sheet = "Number_of_workers_all2", x=numworkers_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# Number of workers simplified----------------------------------
# group number of workers above 3 individuals
household <- household%>%
  mutate(numworkers_simp = case_when(numworkers >= 3 ~ 3,
                                   TRUE~as.numeric(numworkers)))
unique(household$numworkers_simp)

numworkers_MOE1_simp_temp<- create_table_one_var_simp("numworkers_simp", household, "household")
numworkers_MOE1_simp<-numworkers_MOE1_simp_temp%>%
  arrange(numworkers_simp)
numworkers_MOE1_simp
numworkers_MOE2_simp_temp<- create_table_one_var("numworkers_simp", household, "household")
numworkers_MOE2_simp<-numworkers_MOE2_simp_temp%>%
  arrange(numworkers_simp)
numworkers_MOE2_simp

# save to workbook
addWorksheet(wb,"Number_of_workers_simp1")
addWorksheet(wb,"Number_of_workers_simp2")
writeData(wb, sheet = "Number_of_workers_simp1", x=numworkers_MOE1_simp)
writeData(wb, sheet = "Number_of_workers_simp2", x=numworkers_MOE2_simp)
saveWorkbook(wb,output_WB, overwrite = T)

# plot
workersplot <- household %>%
  group_by(numworkers_simp) %>%
  summarise(HouseholdWeight = sum(hh_wt_combined))

a3 <- ggplot(data = workersplot, 
             aes(x=numworkers_simp, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Workers per Household", 
       y = "Estimated Number of Households in Region", title = "Household Workers")
a3

# Vehicle Access----------------------------------
# compare number of vehicles with number of workers
class(household$vehcount_simp)
class(household$numworkers_simp)
# need to convert the vehcount to numerical
vehcount_simp_num <- as.numeric(household$vehcount_simp)
class(vehcount_simp_num)

household <- household%>%
  mutate(hh_veh_access_num = case_when(vehcount_simp_num < numworkers_simp ~ "Limited Access",
                                       vehcount_simp_num == numworkers_simp ~ "Equal",
                                       vehcount_simp_num > numworkers_simp ~ "Good Access"))

xtabs(~hh_veh_access_num, data=household)
create_table_one_var_simp("hh_veh_access_num", household, "household")
create_table_one_var("hh_veh_access_num", household, "household")

# plot
accessplot <- household %>%
  group_by(hh_veh_access_num) %>%
  summarise(HouseholdWeight = sum(hh_wt_combined))

a4 <- ggplot(data = accessplot, 
             aes(x=hh_veh_access_num, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Household Vehicle Ownership and Household Workers")
a4

# vehicle access by county
unique(household$final_cnty)

county_no_na = household %>%
  filter(!is.na(final_cnty))

county_no_na = county_no_na %>%
  filter(!is.na(final_cnty)) %>%
  group_by(final_cnty) %>%
  summarise(n=n(), HouseholdWeight=sum(hh_wt_combined))
county_no_na

county_MOE1<- create_table_one_var_simp("final_cnty", household, "household")
county_MOE1
county_MOE2<- create_table_one_var("final_cnty", household, "household")
county_MOE2

# save to workbook
addWorksheet(wb,"County1")
addWorksheet(wb,"County2")
writeData(wb, sheet = "County1", x=county_MOE1)
writeData(wb, sheet = "County2", x=county_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)


# county and vehicle access
xtabs(~hh_veh_access_num + final_cnty, data=household)

county_access <- household%>%
  filter(!is.na(final_cnty)) %>%
  group_by(hh_veh_access_num,final_cnty) %>%
  summarise(HouseholdWeight = sum(hh_wt_combined))

a5 <- ggplot(data = county_access, 
             aes(x=hh_veh_access_num, y=HouseholdWeight, 
                 fill= final_cnty)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Household Vehicle Access by County",
       fill = "County")
a5

# plot - proportion
a6 <- ggplot(data = county_access, 
             aes(x=hh_veh_access_num, y=HouseholdWeight, 
                 fill= final_cnty)) +
  geom_bar(stat="identity", position="fill") + 
  # geom_text(aes(label=round(HouseholdWeight,0)), 
  #           hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Household Vehicle Access by County",
       fill = "County")
a6


# Race----------------------------------
glimpse(household$hh_race_category)

# plot
hh_race <- household%>%
  filter(!hh_race_category %in% missing_codes, !is.na(hh_race_category)) %>%
  group_by(hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_race

a7 <- ggplot(data = hh_race, 
             aes(x=hh_race_category, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title = "Survey Respondents' Household Race")
a7

# RACE AND VEHICLE ACCESS----------------------------------
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_race_category'
# this is the second variable you want to summarize by
var <- 'hh_veh_access_num'

# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))

#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
#if you think you need to filter out NAs and missing categories, please use the code below
hh_no_na = hh_no_na %>% 
  filter(!hh_race_category %in% missing_codes, 
         !hh_veh_access_num %in% missing_codes, 
         !is.na(hh_race_category), 
         !is.na(hh_veh_access_num))

glimpse(hh_no_na)

# now find the sample size of your subgroup
sample_size_group<- hh_no_na %>%
  group_by(hh_race_category) %>%
  summarize(sample_size = n())
sample_size_group

# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)

# calculate totals and shares
cross_table<-cross_tab_categorical(hh_no_na,group_cat,var, hh_wt_field)

# merge the cross tab with the margin of error
cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=group_cat)
cross_table_w_MOE

# save to workbook
addWorksheet(wb,"Race_and_VehAccess")
writeData(wb, sheet = "Race_and_VehAccess", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)


# Income----------------------------------
unique(household$hhincome_broad)
household$hhincomeb_reordered <- factor(household$hhincome_broad, 
                                       levels=c("Under $25,000","$25,000-$49,999",
                                                "$50,000-$74,999","$75,000-$99,999",
                                                "$100,000 or more","Prefer not to answer"))

# check new order
levels(household$hhincomeb_reordered)
# find sample size of group
xtabs(~hhincomeb_reordered, data=household)


# INCOME AND RACE----------------------------------
xtabs(~hhincomeb_reordered + hh_race_category, data=household)
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hhincomeb_reordered'
# this is the second variable you want to summarize by
var <- 'hh_race_category'

# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
# now find the sample size of your subgroup
sample_size_group<- household %>%
  filter(!hh_race_category=="Missing") %>%
  group_by(hhincomeb_reordered) %>%
  summarize(sample_size = n()) %>%
  arrange(hhincomeb_reordered)
sample_size_group
# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)
sample_size_MOE
# calculate totals and shares
cross_table<-cross_tab_categorical(household,group_cat,var, hh_wt_field)
cross_table
# merge the cross tab with the margin of error
cross_table_w_MOE_temp<-merge(cross_table, sample_size_MOE, by=group_cat)
cross_table_w_MOE <- cross_table_w_MOE_temp %>%
  arrange(hhincomeb_reordered)
cross_table_w_MOE

# save to workbook
addWorksheet(wb,"Income_and_Race")
writeData(wb, sheet = "Income_and_Race", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot: race and income
hh_race_income <- household%>%
  filter(!hh_race_category %in% missing_codes, !is.na(hh_race_category)) %>%
  group_by(hhincomeb_reordered,hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_race_income 

a7.5 <- ggplot(data = hh_race_income, 
              aes(x=hh_race_category, y=HouseholdWeight,
                  fill=hhincomeb_reordered)) +
  geom_bar(stat="identity") +
  theme(axis.text.x=element_text(angle = 60, hjust = 1)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Renting Households by Race and Income",
       fill = "Income")
a7.5

a7.75 <- ggplot(data = hh_race_income, 
               aes(x=hh_race_category, y=HouseholdWeight,
                   fill=hhincomeb_reordered)) +
  geom_bar(stat="identity", position="fill") +
  theme(axis.text.x=element_text(angle = 60, hjust = 1)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Renting Households by Race and Income",
       fill = "Income")
a7.75

# INCOME AND VEHICLE ACCESS----------------------------------
xtabs(~hhincomeb_reordered + hh_veh_access_num, data=household)
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hhincomeb_reordered'
# this is the second variable you want to summarize by
var <- 'hh_veh_access_num'

# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))

#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))

# now find the sample size of your subgroup
sample_size_group<- household %>%
  group_by(hhincomeb_reordered) %>%
  summarize(sample_size = n()) %>%
  arrange(hhincomeb_reordered)
sample_size_group

# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)
sample_size_MOE

# calculate totals and shares
cross_table<-cross_tab_categorical(household,group_cat,var, hh_wt_field)
cross_table

# merge the cross tab with the margin of error
cross_table_w_MOE_temp<-merge(cross_table, sample_size_MOE, by=group_cat)
cross_table_w_MOE <- cross_table_w_MOE_temp %>%
  arrange(hhincomeb_reordered)
cross_table_w_MOE

# save to workbook
addWorksheet(wb,"Income_and_VehAccess")
writeData(wb, sheet = "Income_and_VehAccess", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)


# plot
hh_income <- household%>%
  filter(!hh_race_category %in% missing_codes, !is.na(hh_race_category)) %>%
  group_by(hhincomeb_reordered, hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_income

a8 <- ggplot(data = hh_income, 
             aes(x=hhincomeb_reordered, y=HouseholdWeight,
                 fill=hh_race_category)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title = "Survey Respondents' by Income and Race",
       fill = "Household Race")
a8

a8.5 <-ggplot(data = hh_income, 
              aes(x=hh_race_category, y=HouseholdWeight,
                  fill=hhincomeb_reordered)) +
  geom_bar(stat="identity", position = 'fill') + 
  # geom_text(aes(label=round(HouseholdWeight,0)),
  #           hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title = "Survey Respondents' by Income and Race",
       fill = "Household Income")
a8.5

# Housing Tenure----------------------------------
freq(household$rent_own) #requires summarytools #returns that there are no NAs
housingtenure <-as.factor(household$rent_own)
xtabs(~rent_own, data=household)

# calculate shares and MOEs
htenure_allMOE1<- create_table_one_var_simp("rent_own", household, "household")
htenure_allMOE1
htenure_allMOE2<- create_table_one_var("rent_own", household, "household")
htenure_allMOE2
# save to workbook
addWorksheet(wb,"HousingTenure_all1")
addWorksheet(wb,"HousingTenure_all2")
writeData(wb, sheet = "HousingTenure_all1", x=htenure_allMOE1)
writeData(wb, sheet = "HousingTenure_all2", x=htenure_allMOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# simplify housing tenure categories
unique(household$rent_own)
household <- household %>% 
  mutate(tenure_no_na = case_when(rent_own == "Prefer not to answer" | 
           rent_own == "Other" |
           rent_own == "Provided by job or military" ~ "Other",
           TRUE~.$rent_own))

# calculate shares and MOEs
htenure_MOE1<- create_table_one_var_simp("tenure_no_na", household, "household")
htenure_MOE1
htenure_MOE2<- create_table_one_var("tenure_no_na", household, "household")
htenure_MOE2
# save to workbook
addWorksheet(wb,"HousingTenure_simp1")
addWorksheet(wb,"HousingTenure_simp2")
writeData(wb, sheet = "HousingTenure_simp1", x=htenure_MOE1)
writeData(wb, sheet = "HousingTenure_simp2", x=htenure_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# plot
hh_tenure <- household%>%
  group_by(tenure_no_na) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_tenure

a9 <- ggplot(data = hh_tenure, 
             aes(x=tenure_no_na, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Tenure", 
       y = "Estimated Number of Households in Region", 
       title = "Survey Households by Housing Tenure")
a9

# HOUSING TENURE AND VEHICLE ACCESS----------------------------------
xtabs(~tenure_no_na + hh_veh_access_num, data=household)
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'tenure_no_na'
# this is the second variable you want to summarize by
var <- 'hh_veh_access_num'
# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
# now find the sample size of your subgroup
sample_size_group<- household %>%
  group_by(tenure_no_na) %>%
  summarize(sample_size = n())
sample_size_group
# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)
sample_size_MOE
# calculate totals and shares
cross_table<-cross_tab_categorical(household,group_cat,var, hh_wt_field)
cross_table
# merge the cross tab with the margin of error
cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=group_cat)
cross_table_w_MOE
# save to workbook
addWorksheet(wb,"Tenure_and_VehAccess")
writeData(wb, sheet = "Tenure_and_VehAccess", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot
hh_tenure_access <- household%>%
  group_by(tenure_no_na, hh_veh_access_num) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_tenure_access

a10 <- ggplot(data = hh_tenure_access, 
             aes(x=tenure_no_na, y=HouseholdWeight,
                 fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Housing Tenure", 
       y = "Estimated Number of Households in Region", 
       title = "Households by Tenure and Vehicle Access",
       fill = "Vehicle Access")
a10

# HOUSING TENURE (RENT) AND VEHICLE ACCESS BY HH RACE----------------------------------
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_race_category'
# this is the second variable you want to summarize by
var <- 'hh_veh_access_num'
# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
# now find the sample size of your subgroup
sample_size_group<- household %>%
  filter(rent_own == "Rent") %>%
  filter(!hh_race_category=="Missing") %>%
  group_by(hh_race_category) %>%
  summarize(sample_size = n())
sample_size_group
# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)
sample_size_MOE
# calculate totals and shares
cross_table<-cross_tab_categorical(household,group_cat,var, hh_wt_field)
cross_table
# merge the cross tab with the margin of error
cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=group_cat)
cross_table_w_MOE
# save to workbook
addWorksheet(wb,"Rent_and_VehAccessRace")
writeData(wb, sheet = "Rent_and_VehAccessRace", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot
hh_rent_access_race <- household%>%
  filter(rent_own == "Rent", !hh_race_category=="Missing") %>%
  group_by(hh_veh_access_num, hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_rent_access_race

a11 <- ggplot(data = hh_rent_access_race, 
              aes(x=hh_race_category, y=HouseholdWeight,
                  fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Renting Households by Race and Vehicle Access",
       fill = "Vehicle Access")
a11

# HOUSING TENURE (RENT) AND VEHICLE ACCESS BY HH RACE AND INCOME----------------------------------
# plot: housing tenure (rent), income, race, vehicle access
hh_rent_access_race_income <- household%>%
  filter(rent_own == "Rent") %>%
  filter(!hh_race_category %in% missing_codes, !is.na(hh_race_category)) %>%
  group_by(hh_veh_access_num, hh_race_category, hhincomeb_reordered) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_rent_access_race_income

a12 <- ggplot(data = hh_rent_access_race_income, 
              aes(x=hh_race_category, y=HouseholdWeight,
                  fill=hhincomeb_reordered)) +
  geom_bar(stat="identity") + 
  facet_grid(.~hh_veh_access_num)+
  theme(axis.text.x=element_text(angle = 60, hjust = 1)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Renting Households by Race, Vehicle Access, Income",
       fill = "Vehicle Access")
a12

# Housing Type----------------------------------
freq(household$res_type)
xtabs(~res_type + hh_race_category, data=household)

# shares and MOEs
restype_MOE1<- create_table_one_var_simp("res_type", household, "household")
restype_MOE1
restype_MOE2<- create_table_one_var("res_type", household, "household")
restype_MOE2
# save to workbook
addWorksheet(wb,"ResType_all1")
addWorksheet(wb,"ResType_all2")
writeData(wb, sheet = "ResType_all1", x=restype_MOE1)
writeData(wb, sheet = "ResType_all2", x=restype_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# need to simplify because of high MOEs (compared to perc_combined)
unique(household$res_type)
household <- household %>% 
  mutate(restype_simp = case_when(res_type == "Mobile home/trailer" | 
                                    res_type == "Dorm or institutional housing" |
                                    res_type == "Other (including boat, RV, van, etc.)" ~ "Other",
                                  TRUE~.$res_type))
unique(household$restype_simp)

# shares and MOEs
restype_simpMOE1<- create_table_one_var_simp("restype_simp", household, "household")
restype_simpMOE1
restype_simpMOE2<- create_table_one_var("restype_simp", household, "household")
restype_simpMOE2
# save to workbook
addWorksheet(wb,"ResType_simp1")
addWorksheet(wb,"ResType_simp2")
writeData(wb, sheet = "ResType_simp1", x=restype_simpMOE1)
writeData(wb, sheet = "ResType_simp2", x=restype_simpMOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# RESIDENTIAL TYPE (SIMP) AND HH RACE----------------------------------
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'restype_simp'
# this is the second variable you want to summarize by
var <- 'hh_race_category'
# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
# now find the sample size of your subgroup
sample_size_group<- household %>%
  filter(!hh_race_category=="Missing") %>%
  group_by(restype_simp) %>%
  summarize(sample_size = n())
sample_size_group
# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)
sample_size_MOE
# calculate totals and shares
cross_table<-cross_tab_categorical(household,group_cat,var, hh_wt_field)
cross_table
# merge the cross tab with the margin of error
cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=group_cat)
cross_table_w_MOE
# save to workbook
addWorksheet(wb,"ResType_and_Race")
writeData(wb, sheet = "ResType_and_Race", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot
hh_restype_race <- household%>%
  filter(!hh_race_category=="Missing") %>%
  group_by(restype_simp, hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_restype_race

a13 <- ggplot(data = hh_restype_race, 
              aes(x=hh_race_category, y=HouseholdWeight,
                  fill=restype_simp)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Residential Type by Race",
       fill = "Residential Type")
a13

# RESIDENTIAL TYPE (SIMPx2) AND HH RACE----------------------------------
# need to FURTHER simplify
unique(household$restype_simp)
household <- household %>% 
  mutate(restype_simp2 = case_when(restype_simp == "Single-family house (detached house)" ~ "Single, Detached",
                                   restype_simp == "Townhouse (attached house)" |
                                    restype_simp == "Building with 3 or fewer apartments/condos" ~ "Low Density",
                                   restype_simp == "Building with 4 or more apartments/condos" ~ "High Density",
                                  TRUE~.$restype_simp))
unique(household$restype_simp2)
# plot
hh_restypesimp2_race <- household%>%
  filter(!hh_race_category=="Missing") %>%
  group_by(restype_simp2, hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_restypesimp2_race

a14 <- ggplot(data = hh_restypesimp2_race, 
              aes(x=hh_race_category, y=HouseholdWeight,
                  fill=restype_simp2)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Residential Type by Household Race",
       fill = "Residential Type")
a14

# ~~~~~~~~~~~~~~~~ ----------------------------------
# Person DATASET----------------------------------
# Investigate the person weights 
head(person$hh_wt_combined)
# verify number of samples for person dataset (11,940), weighted total (~4 million)
nrow(person)
sum(person$hh_wt_combined)


# Demographics: Age and Gender----------------------------------
xtabs(~age+gender, data=person)

# plot
b1 <- ggplot(person,
             aes(x=age, y=sum(hh_wt_combined), fill=gender)) +
  geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Age", 
       y = "Estimated Number of Households in Region", 
       title = "Population Distribution",
       fill = "Gender")
b1

person <- person%>%
  mutate(gender_simp = case_when(gender == "Female" ~ "Female",
                                 gender == "Male" ~ "Male",
                                 gender == "Another" | gender == "Prefer not to answer" ~ "Another"))
unique(person$gender_simp)
person %>% group_by(gender_simp) %>% summarise(n=n())
  
# plot simplified gender
b2 <- ggplot(person,
             aes(x=age, y=sum(hh_wt_combined), fill=gender_simp)) +
  geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Age", 
       y = "Estimated Number of Households in Region", 
       title = "Population Distribution",
       fill = "Gender")
b2

# Commute Mode----------------------------------
unique(person$commute_mode)
person %>% 
  group_by(commute_mode) %>% 
  summarise(n=n())

# commute mode categorized into non-motorized or motorized
person <- person%>%
  mutate(commute_type = case_when(commute_mode == "Walk, jog, or wheelchair" |
                                    commute_mode == "Bicycle or e-bike" |
                                    commute_mode =="Scooter or e-scooter (e.g., Lime, Bird, Razor)" ~"non-motorized",
                                  TRUE ~ "motorized"))

person %>%group_by(commute_type)%>%summarise(n=n())

# simplified commuting modes
person <- person%>%
  mutate(simp_commute = case_when(commute_mode == "Walk, jog, or wheelchair" | 
                                    commute_mode == "Bicycle or e-bike" | 
                                    commute_mode =="Scooter or e-scooter (e.g., Lime, Bird, Razor)"~ "non_motorized",
                                  commute_mode == "Drive alone" ~"SOV", 
                                  commute_mode == "Carpool with other people not in household (may also include household members)" |
                                    commute_mode == "Carpool ONLY with other household members" |
                                    commute_mode == "Vanpool"~ "carpool",
                                  commute_mode == "Bus (public transit)" |
                                    commute_mode == "Commuter rail (Sounder, Amtrak)" |
                                    commute_mode == "Urban rail (Link light rail, monorail)" |
                                    commute_mode == "Ferry or water taxi" |
                                    commute_mode == "Streetcar" |
                                    commute_mode == "Paratransit"~"public_transit",
                                  commute_mode == "Motorcycle/moped/scooter"|
                                    commute_mode == "Motorcycle/moped"~ "small_veh",
                                  commute_mode == "Private bus or shuttle" |
                                    commute_mode == "Airplane or helicopter" | 
                                    commute_mode == "Other (e.g. skateboard)"~ "other",
                                  commute_mode == "Other hired service (Uber, Lyft, or other smartphone-app car service)" |
                                    commute_mode == "Taxi (e.g., Yellow Cab)"~ "hired",
                                  TRUE ~ "missing"))

unique(person$simp_commute)
person %>% group_by(simp_commute) %>% summarise(n=n())

# simplified commute modes by all gender categories
xtabs(~simp_commute + gender, data = person)

# simplified commute modes by simplified gender categories
xtabs(~simp_commute + gender_simp, data = person)

# focus on non-motorized commutes
nonmotorized <- person %>% 
  filter(commute_type== "non-motorized")
xtabs(~age+gender_simp, data = nonmotorized)

b3 <- ggplot(nonmotorized,
             aes(x=age, y=sum(hh_wt_combined), fill=gender_simp)) +
  geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Age", 
       y = "Estimated Number of People in Region", 
       title = "Non-motorized Commuting by Age and Gender",
       fill = "Gender")
b3

# License Status----------------------------------
unique(person$license)
freq(person$license)

# focus on yes/no
binary_license <- person %>% 
  filter(license== "Yes, has an intermediate or unrestricted license"| 
                                      license== "No, does not have a license or permit")
binary_license %>% group_by(license) %>% summarise(n=n(), sum(hh_wt_combined))

# simplify license categories
person <- person %>% 
  mutate(license_simp = case_when(
    license == "Yes, has an intermediate or unrestricted license" ~ "Yes",
    license == "No, does not have a license or permit" ~ "No",
    license == "Yes, has a learner's permit" ~ "Permit",
    license == "Missing: Skip logic" ~ "Other"))
freq(person$license_simp)

# shares and MOEs
license_MOE1<- create_table_one_var_simp("license_simp", person, "person")
license_MOE1
license_MOE2<- create_table_one_var("license_simp", person, "person")
license_MOE2
# save to workbook
addWorksheet(wb,"License_simp1")
addWorksheet(wb,"License_simp2")
writeData(wb, sheet = "License_simp1", x=license_MOE1)
writeData(wb, sheet = "License_simp1", x=license_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)


# LICENSE STATUS (SIMP) AND PERSON RACE----------------------------------
unique(person$race_category)
freq(person$race_category)

xtabs(~race_category + license_simp, data=person)

# simplify race and license categories
simp_license_race <- person %>%
  filter(!race_category %in% missing_codes, 
         !is.na(race_category),
         !race_category=="Child",
         license_simp== "Yes"| 
           license_simp== "No")
xtabs(~race_category + license_simp, data=simp_license_race)

# plot
b5 <- ggplot(simp_license_race,
             aes(x=race_category, y=sum(hh_wt_combined), fill=license_simp)) +
  geom_bar(stat="identity") +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Race", 
       y = "Estimated Number of People in Region", 
       title = "License Status by Race",
       fill = "License Status")
b5

# ~~~~~~~~~~~~~~~~ ----------------------------------
# Person & Household DATASETS----------------------------------
glimpse(person)
glimpse(household)

person_and_household <- left_join(person, household,
                                  by=c("household_id"="household_id"))
# check number of rows to make sure no data lost
nrow(person_and_household) #same as the person table - 11940
# any NAs in person_id or household_id?
glimpse(person_and_household)
sum(person_and_household$hh_wt_combined.x) #4051580
sum(person_and_household$hh_wt_combined.y) #4051580
sum(is.na(person_and_household$person_id)) #0
sum(is.na(person_and_household$household_id)) #0

# LICENSE STATUS (SIMP) AND RACE----------------------------------
xtabs(~license_simp+simp_commute, data=person_and_household)

# plot license and race
c1 <- ggplot(person_and_household,
             aes(x=license_simp, y=sum(hh_wt_combined.x), fill=race_category)) +
  geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "License", 
       y = "Estimated Number of People in Region", 
       title = "Commute Mode by License Status and Race",
       fill = "Race")
c1

# LICENSE STATUS (SIMP), COMMUTE MODE, AND RACE----------------------------------
xtabs(~license_simp+simp_commute, data=person_and_household)

# plot license, race, commute simplified
c2 <- ggplot(person_and_household,
             aes(x=license_simp, y=sum(hh_wt_combined.x), fill=race_category)) +
  geom_bar(stat="identity") + facet_grid(.~commute_type) +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "License", 
       y = "Estimated Number of People in Region", 
       title = "Commute Mode by License Status and Age",
       fill = "Race")
c2

# COMMUTE MODE (SIMP) AND INCOME (BROAD)----------------------------------
unique(person_and_household$simp_commute)
unique(person_and_household$hhincomeb_reordered)

xtabs(~hhincomeb_reordered + simp_commute, data=person_and_household)
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined.x'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hhincomeb_reordered'
# this is the second variable you want to summarize by
var <- 'simp_commute'
# filter data missing weights 
hh_no_na<-person_and_household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(person_and_household$household_id))
# now find the sample size of your subgroup
sample_size_group<- person_and_household %>%
  group_by(hhincomeb_reordered) %>%
  summarize(sample_size = n())
sample_size_group
# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)
sample_size_MOE
# calculate totals and shares
cross_table<-cross_tab_categorical(person_and_household,group_cat,var, hh_wt_field)
cross_table
# merge the cross tab with the margin of error
cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=group_cat)
cross_table_w_MOE
# save to workbook
addWorksheet(wb,"Income_and_CommuteMode")
writeData(wb, sheet = "Income_and_CommuteMode", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot
income_commutemode <- person_and_household%>%
  filter(!simp_commute=="missing") %>%
  group_by(hhincomeb_reordered, simp_commute) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined.x))
income_commutemode

c3 <- ggplot(data = income_commutemode, 
              aes(x=hhincomeb_reordered, y=HouseholdWeight,
                  fill=simp_commute)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Income", 
       y = "Estimated Number of People in Region", 
       title = "Commute Mode by Income",
       fill = "Commute Mode")
c3

# plot - proportion
c3.5 <- ggplot(data = income_commutemode, 
             aes(x=hhincomeb_reordered, y=HouseholdWeight,
                 fill=simp_commute)) +
  geom_bar(stat="identity", position='fill') + 
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Income", 
       y = "Estimated Number of People in Region", 
       title = "Commute Mode by Income",
       fill = "Commute Mode")
c3.5
