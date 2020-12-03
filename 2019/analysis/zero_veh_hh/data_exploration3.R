# INSTALL PACKAGES----------------------------------
# List of packages required
packages <- c("data.table","odbc","DBI","summarytools",
              "dplyr", "tidyverse", "psych", "openxlsx",
              "ggplot2","tidyr", "gridExtra")
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

# set up excel file
output_WB <- paste("T:/2020November/Mary/HHTS/OutputTables/test_",Sys.Date(),".xlsx", sep = "")
# Create blank workbook
wb <- createWorkbook()

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

# Add sheets to workbook
addWorksheet(wb, "VehicleCount_MOE")
# Write data to sheets
writeData(wb, sheet = "VehicleCount_MOE", x=hhwt_vehiclecount_reordered)
# Export file
saveWorkbook(wb,output_WB, overwrite = T)

# plot - household weights
a1<- ggplot(data = hhwt_vehiclecount_reordered, 
            aes(x=VehicleCount, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Vehicles per Household", 
       y = "Estimated Number of Households in Region", title = "Vehicle Ownership")
a1

# plot - shares
a1.2<- ggplot(data = hhwt_vehiclecount_reordered, 
              aes(x=VehicleCount, y=n)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(n,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Vehicles per Household", 
       y = "Share of Surveyed Households", title = "Vehicle Ownership")
a1.2

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

# plot - household weights
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

# plot - shares
vehicleplot <- household %>%
  group_by(vehcount_simp) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))

a2.2 <- ggplot(data = vehicleplot, 
               aes(x=vehcount_simp, y=n)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(n,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Vehicles per Household", 
       y = "Share of Surveyed Households", title = "Vehicle Ownership")
a2.2

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
numworkers_MOE2

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

# plot - household weights
workersplot <- household %>%
  group_by(numworkers_simp) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))

a3 <- ggplot(data = workersplot, 
             aes(x=numworkers_simp, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Workers per Household", 
       y = "Estimated Number of Households in Region", title = "Household Workers")
a3

# plot - shares
a3.2 <- ggplot(data = workersplot, 
               aes(x=numworkers_simp, y=n)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(n,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Workers per Household", 
       y = "Share of Surveyed Households", title = "Household Workers")
a3.2

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
# shares and MOEs
vehaccess_MOE1<- create_table_one_var_simp("hh_veh_access_num", household, "household")
vehaccess_MOE1
vehaccess_MOE2<- create_table_one_var("hh_veh_access_num", household, "household")
vehaccess_MOE2

# save to workbook
addWorksheet(wb,"VehAccess1")
addWorksheet(wb,"VehAccess2")
writeData(wb, sheet = "VehAccess1", x=vehaccess_MOE1)
writeData(wb, sheet = "VehAccess2", x=vehaccess_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)


# plot - household weights
accessplot <- household %>%
  group_by(hh_veh_access_num) %>%
  summarise(n=n(),HouseholdWeight = sum(hh_wt_combined))

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

# plot - shares
a4.2 <- ggplot(data = accessplot, 
               aes(x=hh_veh_access_num, y=n)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(n,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Vehicle Access", 
       y = "Share of Households", 
       title = "Household Vehicle Ownership and Household Workers")
a4.2

grid.arrange(a4, a4.2, nrow=1, ncol=2)

# vehicle access by county
unique(household$final_cnty)

county_no_na <- household %>%
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
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_veh_access_num'
# this is the second variable you want to summarize by
var <- 'final_cnty'

# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
#if you think you need to filter out NAs and missing categories, please use the code below
hh_no_na = hh_no_na %>% 
  filter(!final_cnty %in% missing_codes,
         !is.na(final_cnty))
# now find the sample size of your subgroup
sample_size_group<- hh_no_na %>%
  group_by(hh_veh_access_num) %>%
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
addWorksheet(wb,"County_and_VehAccess")
writeData(wb, sheet = "County_and_VehAccess", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot
county_access <- household%>%
  filter(!is.na(final_cnty)) %>%
  group_by(hh_veh_access_num,final_cnty) %>%
  summarise(n=n(),HouseholdWeight = sum(hh_wt_combined))
county_access

# plot - household weights
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

# plot - household weights - proportion
a5.1 <- ggplot(data = county_access, 
               aes(x=hh_veh_access_num, y=HouseholdWeight, 
                   fill= final_cnty)) +
  geom_bar(stat="identity", position="fill") +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Household Vehicle Access by County",
       fill = "County")
a5.1

# plot - shares
a5.2 <- ggplot(data = county_access, 
               aes(x=hh_veh_access_num, y=n, 
                   fill= final_cnty)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(n,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Vehicle Access", 
       y = "Share of Surveyed Households", 
       title = "Household Vehicle Access by County",
       fill = "County")
a5.2

# plot - shares - proportion
a5.3 <- ggplot(data = county_access, 
               aes(x=hh_veh_access_num, y=n, 
                   fill= final_cnty)) +
  geom_bar(stat="identity", position="fill") +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Vehicle Access", 
       y = "Share of Surveyed Households", 
       title = "Household Vehicle Access by County",
       fill = "County")
a5.3

# Race----------------------------------
unique(household$hh_race_category)

# shares and MOEs
race_MOE1<- create_table_one_var_simp("hh_race_category", household, "household")
race_MOE1
race_MOE2<- create_table_one_var("hh_race_category", household, "household")
race_MOE2

# save to workbook
addWorksheet(wb,"Race1")
addWorksheet(wb,"Race2")
writeData(wb, sheet = "Race1", x=race_MOE1)
writeData(wb, sheet = "Race2", x=race_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# plot - household weights
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


# plot - shares
a7.2 <- ggplot(data = hh_race, 
               aes(x=hh_race_category, y=n)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(n,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title = "Share of Surveyed Households")
a7.2

freq(household$hh_race_category) 
# when compared to % of household weights in race_MOE1, higher 

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
         !is.na(hh_race_category))
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

# plot - household weight
hh_race_access <- household%>%
  filter(!hh_race_category %in% missing_codes, !is.na(hh_race_category)) %>%
  group_by(hh_race_category, hh_veh_access_num) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_race_access

a7.3 <- ggplot(data = hh_race_access, 
               aes(x=hh_race_category, y=HouseholdWeight,
                   fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  #geom_text(aes(label=round(HouseholdWeight,0)), 
  #hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Race",
       fill="Vehicle Access")
a7.3

# plot - household shares
a7.4 <- ggplot(data = hh_race_access, 
               aes(x=hh_race_category, y=n,
                   fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  #geom_text(aes(label=round(n,0)), 
  #hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Share of Surveyed Households in Region", 
       title = "Vehicle Access by Race",
       fill="Vehicle Access")
a7.4

grid.arrange(a7.3, a7.4, nrow=1, ncol=2)

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

hh_income <- household%>%
  group_by(hhincomeb_reordered) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_income

# plot 
i1 <-ggplot(data=hh_income, aes(x=hhincomeb_reordered, y=HouseholdWeight))+
  geom_bar(stat="identity")
i2<-ggplot(data=hh_income, aes(x=hhincomeb_reordered, y=n))+
  geom_bar(stat="identity")

grid.arrange(i1, i2, nrow=1, ncol=2)


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

# plot: race and income - household weights
hh_race_income <- household%>%
  filter(!hh_race_category %in% missing_codes, !is.na(hh_race_category)) %>%
  group_by(hhincomeb_reordered,hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_race_income 

a7.5 <- ggplot(data = hh_race_income, 
               aes(x=hh_race_category, y=HouseholdWeight,
                   fill=hhincomeb_reordered)) +
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle = 60, hjust = 1)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Regional Households by Race and Income",
       fill = "Income")
a7.5

# plot - proportion
a7.6 <- ggplot(data = hh_race_income, 
               aes(x=hh_race_category, y=HouseholdWeight,
                   fill=hhincomeb_reordered)) +
  geom_bar(stat="identity", position="fill") +
  theme(axis.text.x=element_text(angle = 60, hjust = 1)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Regional Households by Race and Income",
       fill = "Income")
a7.6


# plot: race and income - shares
a7.7 <- ggplot(data = hh_race_income, 
               aes(x=hh_race_category, y=n,
                   fill=hhincomeb_reordered)) +
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle = 60, hjust = 1)) +
  labs(x = "Race", 
       y = "Share of Surveyed Households", 
       title = "Share of Households by Race and Income",
       fill = "Income")
a7.7

# plot - proportion
a7.8 <- ggplot(data = hh_race_income, 
               aes(x=hh_race_category, y=n,
                   fill=hhincomeb_reordered)) +
  geom_bar(stat="identity", position="fill") +
  theme(axis.text.x=element_text(angle = 60, hjust = 1)) +
  labs(x = "Race", 
       y = "Share of Surveyed Housholds", 
       title = "Share of Households by Race and Income",
       fill = "Income")
a7.8


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


# plot - household weights
hh_income_access <- household%>%
  filter(!hh_race_category %in% missing_codes, !is.na(hh_race_category)) %>%
  group_by(hh_veh_access_num, hhincomeb_reordered) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_income_access

a8 <- ggplot(data = hh_income_access, 
             aes(x=hhincomeb_reordered, y=HouseholdWeight,
                 fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Income",
       fill = "Vehicle Access")
a8

# proportion
a8.2 <-ggplot(data = hh_income_access, 
              aes(x=hhincomeb_reordered, y=HouseholdWeight,
                  fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'fill') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Income",
       fill = "Vehicle Access")
a8.2

# plot - shares
a8.3 <- ggplot(data = hh_income_access, 
               aes(x=hhincomeb_reordered, y=n,
                   fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(n,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Share of Surveyed Households", 
       title = "Vehicle Access by Income",
       fill = "Vehicle Access")
a8.3

# proportion
a8.4 <-ggplot(data = hh_income_access, 
              aes(x=hhincomeb_reordered, y=n,
                  fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'fill') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Share of Surveyed Households", 
       title = "Vehicle Access by Income",
       fill = "Vehicle Access")
a8.4

# INCOME, RACE, and VEHICLE ACCESS----------------------------------
hh_income_race_access <- household%>%
  filter(!hh_race_category %in% missing_codes, !is.na(hh_race_category)) %>%
  group_by(hhincomeb_reordered, hh_race_category, hh_veh_access_num) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_income_race_access

# plot - stacked
a8.5 <- ggplot(data = hh_income_race_access, 
               aes(x=hhincomeb_reordered, y=HouseholdWeight,
                   fill=hh_race_category)) +
  geom_bar(stat="identity") + 
  facet_wrap(~hh_veh_access_num) +
  # geom_text(aes(label=round(HouseholdWeight,0)), 
  #           hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 0)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title ="Vehicle Access by Income and Race",
       fill = "Household Race")
a8.5

# plot - dodge
a8.51 <- ggplot(data = hh_income_race_access, 
                aes(x=hhincomeb_reordered, y=HouseholdWeight,
                    fill=hh_race_category)) +
  geom_bar(stat="identity", position='dodge') + 
  facet_wrap(~hh_veh_access_num) +
  # geom_text(aes(label=round(HouseholdWeight,0)), 
  #           hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 0)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title ="Vehicle Access by Income and Race",
       fill = "Household Race")
a8.51

# plot - proportion
a8.52 <- ggplot(data = hh_income_race_access, 
                aes(x=hhincomeb_reordered, y=HouseholdWeight,
                    fill=hh_race_category)) +
  geom_bar(stat="identity", position='fill') + 
  facet_wrap(~hh_veh_access_num) +
  # geom_text(aes(label=round(HouseholdWeight,0)), 
  #           hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 0)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title ="Vehicle Access by Income and Race",
       fill = "Household Race")
a8.52

# compare
compare_income_race_2 <- grid.arrange(a8.5, a8.52, nrow=1, ncol=2)
compare_income_race_3 <- grid.arrange(a8.5, a8.51, a8.52, nrow=1, ncol=3)

# Limited Vehicle Access----------------------------------
household <- household %>% 
  mutate(hh_veh_access_lim = case_when(hh_veh_access_num == "Limited Access" ~ "Fewer",
                                       TRUE~ "Equal or Greater"))
# investigate recategorization
household %>%
  group_by(hh_veh_access_lim, hh_veh_access_num) %>%
  tally() #1634 - fewer cars than workers

# BINARY LIMITED VEHICLE ACCESS AND INCOME----------------------------------
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hhincomeb_reordered'
# this is the second variable you want to summarize by
var <- 'hh_veh_access_lim'
# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
# now find the sample size of your subgroup
sample_size_group<- household %>%
  # filter(hh_veh_access_num == "Limited Access") %>%
  group_by(hhincomeb_reordered) %>%
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
addWorksheet(wb,"SimpVehAccess_Income")
writeData(wb, sheet = "SimpVehAccess_Income", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot - values - weights
income_vehaccess <-household %>%
  filter(!hh_race_category=="Missing") %>%
  group_by(hh_veh_access_lim, hhincomeb_reordered) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))

income_access <- ggplot(data = income_vehaccess, 
                        aes(x=hhincomeb_reordered, y=HouseholdWeight,
                            fill=hh_veh_access_lim)) +
  geom_bar(stat="identity", position='dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title ="Fewer Vehicles by Income",
       fill="Vehicle Access")
income_access

# plot - proportion - weights
income_access.2 <- ggplot(data = income_vehaccess, 
                          aes(x=hhincomeb_reordered, y=HouseholdWeight,
                              fill=hh_veh_access_lim)) +
  geom_bar(stat="identity", position='fill') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title ="Fewer Vehicles by Income",
       fill="Vehicle Access")
income_access.2

grid.arrange(income_access, income_access.2, nrow=1, ncol=2)

# plot - values - shares
income_access.3 <- ggplot(data = income_vehaccess, 
                          aes(x=hhincomeb_reordered, y=n,
                              fill=hh_veh_access_lim)) +
  geom_bar(stat="identity", position='dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Surveyed Households", 
       title ="Fewer Vehicles by Income",
       fill="Vehicle Access")
income_access.3

# plot - proportion - shares
income_access.4 <- ggplot(data = income_vehaccess, 
                          aes(x=hhincomeb_reordered, y=n,
                              fill=hh_veh_access_lim)) +
  geom_bar(stat="identity", position='fill') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Surveyed Households", 
       title ="Fewer Vehicles by Income",
       fill="Vehicle Access")
income_access.4

grid.arrange(income_access, income_access.2, 
             income_access.3, income_access.4,
             nrow=2, ncol=2)

# BINARY LIMITED VEHICLE ACCESS AND RACE----------------------------------
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_race_category'
# this is the second variable you want to summarize by
var <- 'hh_veh_access_lim'
# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
# now find the sample size of your subgroup
sample_size_group<- household %>%
  # filter(hh_veh_access_num == "Limited Access") %>%
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
addWorksheet(wb,"SimpVehAccess_Race")
writeData(wb, sheet = "SimpVehAccess_Race", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot - values - weights
race_vehaccess <-household %>%
  filter(!hh_race_category=="Missing") %>%
  group_by(hh_veh_access_lim, hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))

race_access <- ggplot(data = race_vehaccess, 
                      aes(x=hh_race_category, y=HouseholdWeight,
                          fill=hh_veh_access_lim)) +
  geom_bar(stat="identity", position='dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title ="Fewer Vehicles by Race",
       fill="Vehicle Access")
race_access

# plot - proportion - weights
race_access.2 <- ggplot(data = race_vehaccess, 
                        aes(x=hh_race_category, y=HouseholdWeight,
                            fill=hh_veh_access_lim)) +
  geom_bar(stat="identity", position='fill') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title ="Fewer Vehicles by Race",
       fill="Vehicle Access")
race_access.2

grid.arrange(income_access, income_access.2, nrow=1, ncol=2)

# plot - values - shares
race_access.3 <- ggplot(data = race_vehaccess, 
                        aes(x=hh_race_category, y=n,
                            fill=hh_veh_access_lim)) +
  geom_bar(stat="identity", position='dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Surveyed Households", 
       title ="Fewer Vehicles by Race",
       fill="Vehicle Access")
race_access.3

# plot - proportion - shares
race_access.4 <- ggplot(data = race_vehaccess, 
                        aes(x=hh_race_category, y=n,
                            fill=hh_veh_access_lim)) +
  geom_bar(stat="identity", position='fill') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Surveyed Households", 
       title ="Fewer Vehicles by Race",
       fill="Vehicle Access")
race_access.4

grid.arrange(race_access, race_access.2, 
             race_access.3, race_access.4,
             nrow=2, ncol=2)

# compare income and race for limited access households - household weights
binary_race_and_income <- grid.arrange(income_access, income_access.2, 
                                       race_access, race_access.2,
                                       nrow=2, ncol=2)


# JUST LIMITED VEHICLE ACCESS AND INCOME----------------------------------
hh_limvehaccess <-household %>%
  filter(hh_veh_access_lim == "Fewer")
glimpse(hh_limvehaccess)
nrow(hh_limvehaccess) #1634

# shares and MOEs
limvehaccess_income_MOE1<- create_table_one_var_simp("hhincomeb_reordered", hh_limvehaccess, "household")
limvehaccess_income_MOE1
limvehaccess_income_MOE2<- create_table_one_var("hhincomeb_reordered", hh_limvehaccess, "household")
limvehaccess_income_MOE2

# save to workbook
addWorksheet(wb,"Income_limVehAccess1")
addWorksheet(wb,"Income_limVehAccess2")
writeData(wb, sheet = "Income_limVehAccess1", x=limvehaccess_income_MOE1)
writeData(wb, sheet = "Income_limVehAccess1", x=limvehaccess_income_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# plot - household weights
limveh_income <- hh_limvehaccess %>%
  group_by(hhincomeb_reordered) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
limveh_income

income.1 <- ggplot(data = limveh_income, 
                   aes(x=hhincomeb_reordered, y=HouseholdWeight)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Estimated Number of Households in Region", 
       title ="Households with Fewer Vehicles by Income")
income.1

# plot - shares
income.2 <- ggplot(data = limveh_income, 
                   aes(x=hhincomeb_reordered, y=n)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Income", 
       y = "Surveyed Households", 
       title ="Households with Fewer Vehicles by Income")
income.2

grid.arrange(income.1, income.2, nrow=1, ncol=2)


# JUST LIMITED VEHICLE ACCESS AND RACE----------------------------------
limvehaccess_race_MOE1<- create_table_one_var_simp("hh_race_category", hh_limvehaccess, "household")
limvehaccess_race_MOE1
limvehaccess_race_MOE2<- create_table_one_var("hh_race_category", hh_limvehaccess, "household")
limvehaccess_race_MOE2

# save to workbook
addWorksheet(wb,"Race_limVehAccess1")
addWorksheet(wb,"Race_limVehAccess2")
writeData(wb, sheet = "Race_limVehAccess1", x=limvehaccess_race_MOE1)
writeData(wb, sheet = "Race_limVehAccess2", x=limvehaccess_race_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# plot - household weights
limveh_race <- hh_limvehaccess %>%
  filter(!hh_race_category=="Missing") %>%
  group_by(hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
limveh_race

race.1 <- ggplot(data = limveh_race, 
                 aes(x=hh_race_category, y=HouseholdWeight)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title ="Households with Fewer Vehicles by Race")
race.1

# plot - shares
race.2 <- ggplot(data = limveh_race, 
                 aes(x=hh_race_category, y=n)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Race", 
       y = "Surveyed Households", 
       title ="Households with Fewer Vehicles by Race")
race.2

grid.arrange(race.1, race.2, nrow=1, ncol=2)

# JUST LIMITED VEHICLE ACCESS, RACE, AND INCOME----------------------------------
# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_race_category'
# this is the second variable you want to summarize by
var <- 'hhincomeb_reordered'
# filter data missing weights 
hh_no_na<-hh_limvehaccess %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(hh_limvehaccess$household_id))
# now find the sample size of your subgroup
sample_size_group<- hh_limvehaccess %>%
  # filter(hh_veh_access_num == "Limited Access") %>%
  group_by(hh_race_category) %>%
  summarize(sample_size = n())
sample_size_group
# get the margins of error for your groups
sample_size_MOE<- categorical_moe(sample_size_group)
sample_size_MOE
# calculate totals and shares
cross_table<-cross_tab_categorical(hh_limvehaccess,group_cat,var, hh_wt_field)
cross_table
# merge the cross tab with the margin of error
cross_table_w_MOE<-merge(cross_table, sample_size_MOE, by=group_cat)
cross_table_w_MOE
# save to workbook
addWorksheet(wb,"LimVehAccess_Race")
writeData(wb, sheet = "LimVehAccess_Race", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot - household weight
hh_limaccess_race_income <- hh_limvehaccess%>%
  filter(!hh_race_category=="Missing") %>%
  group_by(hhincomeb_reordered, hh_race_category) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_limaccess_race_income

d1 <- ggplot(data = hh_limaccess_race_income, 
             aes(x=hh_race_category, y=HouseholdWeight,
                 fill = hhincomeb_reordered)) +
  geom_bar(stat="identity", position = 'dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Households with Fewer Vehicles than Workers",
       fill= "Household Income")
d1


# plot - shares
d1.2 <- ggplot(data = hh_limaccess_race_income, 
               aes(x=hh_race_category, y=n,
                   fill = hhincomeb_reordered)) +
  geom_bar(stat="identity", position = 'dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Race", 
       y = "Share of Surveyed Households", 
       title = "Households by Race and Limited Vehicle Access")
d1.2

# compare plots
grid.arrange(d1, d1.2, nrow=1, ncol=2)



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

# plot - household weights
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

# plot - shares
a9.2 <- ggplot(data = hh_tenure, 
               aes(x=tenure_no_na, y=n)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(n,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Household Tenure", 
       y = "Share of Surveyed Households", 
       title = "Survey Households by Housing Tenure")
a9.2

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

# plot - household weights
hh_tenure_access <- household%>%
  group_by(tenure_no_na, hh_veh_access_num) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
hh_tenure_access

a10 <- ggplot(data = hh_tenure_access, 
              aes(x=tenure_no_na, y=HouseholdWeight,
                  fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  theme(axis.text.x=element_text(angle = 45, hjust = 1)) +
  labs(x = "Housing Tenure", 
       y = "Estimated Number of Households in Region", 
       title = "Households by Tenure and Vehicle Access",
       fill = "Vehicle Access")
a10

# plot - household weights
a10.2 <- ggplot(data = hh_tenure_access, 
                aes(x=tenure_no_na, y=n,
                    fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  theme(axis.text.x=element_text(angle = 45, hjust = 1)) +
  labs(x = "Housing Tenure", 
       y = "Share of Surveyed Households", 
       title = "Households by Tenure and Vehicle Access",
       fill = "Vehicle Access")
a10.2

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

# plot - household weight
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


# plot - household weight
a11.2 <- ggplot(data = hh_rent_access_race, 
                aes(x=hh_race_category, y=n,
                    fill=hh_veh_access_num)) +
  geom_bar(stat="identity", position = 'dodge') + 
  theme(axis.text.x=element_text(angle = 90, hjust = 1)) +
  labs(x = "Race", 
       y = "Share of Surveyed Households", 
       title = "Renting Households by Race and Vehicle Access",
       fill = "Vehicle Access")
a11.2

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
# plot - household weights
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

# plot - shares
a14.2 <- ggplot(data = hh_restypesimp2_race, 
                aes(x=hh_race_category, y=n,
                    fill=restype_simp2)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Race", 
       y = "Share of Surveyed Households", 
       title = "Residential Type by Household Race",
       fill = "Residential Type")
a14.2

grid.arrange(a14, a14.2, nrow=1, ncol=2)

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
       y = "Estimated Number of Individuals in Region", 
       title = "Population Distribution",
       fill = "Gender")
b1

person <- person%>%
  mutate(gender_simp = case_when(gender == "Female" ~ "Female",
                                 gender == "Male" ~ "Male",
                                 gender == "Another" | gender == "Prefer not to answer" ~ "Another"))
unique(person$gender_simp)
simp_gender_age<- person %>% 
  group_by(gender_simp, age) %>% 
  summarise(n=n(), PersonWeight=sum(hh_wt_combined))

# plot simplified gender - household weights
b2 <- ggplot(simp_gender_age,
             aes(x=age, y=PersonWeight, fill=gender_simp)) +
  geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Age", 
       y = "Estimated Number of Individuals in Region", 
       title = "Population Distribution",
       fill = "Gender")
b2

# plot simplified gender - shares
b2.2 <- ggplot(simp_gender_age,
               aes(x=age, y=n, fill=gender_simp)) +
  geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Age", 
       y = "Share of Surveyed Individuals", 
       title = "Population Distribution",
       fill = "Gender")
b2.2

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
           license_simp== "No") %>%
  group_by(n=n(), PersonWeight=sum(hh_wt_combined))
xtabs(~race_category + license_simp, data=simp_license_race)

# plot - person weights
b5 <- ggplot(simp_license_race,
             aes(x=race_category, y=PersonWeight, fill=license_simp)) +
  geom_bar(stat="identity") +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Race", 
       y = "Estimated Number of People in Region", 
       title = "License Status by Race",
       fill = "License Status")
b5

# plot - shares
b5.2 <- ggplot(simp_license_race,
               aes(x=race_category, y=n, fill=license_simp)) +
  geom_bar(stat="identity") +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Race", 
       y = "Surveyed Individuals", 
       title = "License Status by Race",
       fill = "License Status")
b5.2

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


# Create a simplified crosstab from one variable, calculate counts, totals, shares, and MOE
# for categorical data
create_table_one_var_simp_joined= function(var1, table_temp,table_type) {
  #table_temp = recategorize_var_upd(var2,table_temp)
  #print(table_temp)
  if (table_type == "household" | table_type == "person" ) {
    weight_2017 = "hh_wt_revised.x"
    weight_2019 = "hh_wt_2019.x"
    weight_comb = "hh_wt_combined.x"
  } else if (table_type == "trip") {
    weight_2017 = "trip_weight_revised.x"
    weight_2019 = "trip_wt_2019.x"
    weight_comb = "trip_wt_combined.x"  
  } 
  
  temp = table_temp %>% 
    # select(!!sym(var1), all_of(weight_2017), all_of(weight_2019), all_of(weight_comb)) %>% 
    # filter(!.[[1]] %in% missing_codes, !is.na(.[[1]])) %>% 
    group_by(!!sym(var1)) %>% 
    summarise(n=n(),sum_wt_comb = sum(.data[[weight_comb]],na.rm = TRUE)) %>% 
    mutate(perc_comb = sum_wt_comb/sum(sum_wt_comb)*100) %>% 
    ungroup() %>%  mutate(MOE=1.65*(0.25/sum(n))^(1/2)*100) %>% arrange(desc(perc_comb))
  return(temp)
}


# Create a crosstab from one variable, calculate counts, totals, and shares,
# for categorical data
create_table_one_var_joined = function(var1, table_temp,table_type) {
  #table_temp = recategorize_var_upd(var2,table_temp)
  #print(table_temp)
  if (table_type == "household" | table_type == "person" ) {
    weight_2017 = "hh_wt_revised.x"
    weight_2019 = "hh_wt_2019.x"
    weight_comb = "hh_wt_combined.x"
  } else if (table_type == "trip") {
    weight_2017 = "trip_weight_revised.x"
    weight_2019 = "trip_wt_2019.x"
    weight_comb = "trip_wt_combined.x"  
  } 
  
  temp = table_temp %>% 
    # select(!!sym(var1), all_of(weight_2017), all_of(weight_2019), all_of(weight_comb)) %>% 
    # filter(!.[[1]] %in% missing_codes, !is.na(.[[1]])) %>% 
    group_by(!!sym(var1)) %>% 
    summarise(n=n(),sum_wt_comb = sum(.data[[weight_comb]],na.rm = TRUE),sum_wt_2017 = sum(.data[[weight_2017]],na.rm = TRUE),sum_wt_2019 = sum(.data[[weight_2019]],na.rm = TRUE)) %>% 
    mutate(perc_comb = sum_wt_comb/sum(sum_wt_comb)*100, perc_2017 = sum_wt_2017/sum(sum_wt_2017)*100, perc_2019 = sum_wt_2019/sum(sum_wt_2019)*100,delta = perc_2019-perc_2017) %>% 
    ungroup() %>%  mutate(MOE=1.65*(0.25/sum(n))^(1/2)*100) %>% arrange(desc(perc_comb))
  return(temp)
}

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

# plot - person weights
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

# proportion
c3.2 <- ggplot(data = income_commutemode, 
               aes(x=hhincomeb_reordered, y=HouseholdWeight,
                   fill=simp_commute)) +
  geom_bar(stat="identity", position='fill') + 
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Income", 
       y = "Estimated Number of People in Region", 
       title = "Commute Mode by Income",
       fill = "Commute Mode")
c3.2

# plot - shares
c3.3 <- ggplot(data = income_commutemode, 
               aes(x=hhincomeb_reordered, y=n,
                   fill=simp_commute)) +
  geom_bar(stat="identity") + 
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Income", 
       y = "Surveyed Individuals", 
       title = "Commute Mode by Income",
       fill = "Commute Mode")
c3.3

# proportion
c3.4 <- ggplot(data = income_commutemode, 
               aes(x=hhincomeb_reordered, y=n,
                   fill=simp_commute)) +
  geom_bar(stat="identity", position='fill') + 
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Income", 
       y = "Surveyed Individuals", 
       title = "Commute Mode by Income",
       fill = "Commute Mode")
c3.4

# HOUSING LOCATION AND VEHICLE ACCESS----------------------------------
# based on Regional Growth Centers
unique(household$final_home_rgcnum)

# recategorize final home RGC (binary)
household <- household %>% 
  mutate(RGC_binary = case_when(final_home_rgcnum == "Not RCG" ~ "Not RGC",
                                TRUE ~ "RGC"))
xtabs(~RGC_binary + hh_veh_access_num, data=household)

# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_veh_access_num'
# this is the second variable you want to summarize by
var <- 'RGC_binary'
# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
# now find the sample size of your subgroup
sample_size_group<- household %>%
  group_by(hh_veh_access_num) %>%
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
addWorksheet(wb,"ResRGC_and_VehAccess")
writeData(wb, sheet = "ResRGC_and_VehAccess", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)


# plot
RGC_vehaccess <- household %>%
  group_by(hh_veh_access_num, RGC_binary) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
RGC_vehaccess

# plot - weights
c4.1 <- ggplot(RGC_vehaccess, aes(x=hh_veh_access_num, y=HouseholdWeight, 
                                  fill=RGC_binary)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Housing Location (RGC)",
       fill = "Housing Location")
c4.1

# plot - weights, proportion
c4.2 <- ggplot(RGC_vehaccess, aes(x=hh_veh_access_num, y=HouseholdWeight, 
                                  fill=RGC_binary)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Housing Location (RGC)",
       fill = "Housing Location")
c4.2

# plot - shares
c4.3 <- ggplot(RGC_vehaccess, aes(x=hh_veh_access_num, y=n, 
                                  fill=RGC_binary)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Share of Surveyed Households", 
       title = "Vehicle Access by Housing Location (RGC)",
       fill = "Housing Location")
c4.3

# plot - shares, proportion
c4.4 <- ggplot(RGC_vehaccess, aes(x=hh_veh_access_num, y=n, 
                                  fill=RGC_binary)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Share of Surveyed Households", 
       title = "Vehicle Access by Housing Location (RGC)",
       fill = "Housing Location")
c4.4

grid.arrange(c4.1, c4.2, c4.3, c4.4, nrow=2, ncol=2)

# based on in/out of Seattle
unique(household$seattle_home)
freq(household$seattle_home)

xtabs(~seattle_home + hh_veh_access_num, data=household)

# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_veh_access_num'
# this is the second variable you want to summarize by
var <- 'seattle_home'
# filter data missing weights 
hh_no_na<-household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(household$household_id))
# now find the sample size of your subgroup
sample_size_group<- household %>%
  group_by(hh_veh_access_num) %>%
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
# # save to workbook
addWorksheet(wb,"Seattlehome_and_VehAccess")
writeData(wb, sheet = "Seattlehome_and_VehAccess", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)


# plot
SEAhome_vehaccess <- household %>%
  group_by(hh_veh_access_num, seattle_home) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined))
SEAhome_vehaccess

# plot - weights
c5.1 <- ggplot(SEAhome_vehaccess, aes(x=hh_veh_access_num, y=HouseholdWeight, 
                                      fill=seattle_home)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Housing Location",
       fill = "Housing Location")
c5.1

# plot - weights, proportion
c5.2 <- ggplot(SEAhome_vehaccess, aes(x=hh_veh_access_num, y=HouseholdWeight, 
                                      fill=seattle_home)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Housing Location",
       fill = "Housing Location")
c5.2

# plot - shares
c5.3 <- ggplot(SEAhome_vehaccess, aes(x=hh_veh_access_num, y=n, 
                                      fill=seattle_home)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Share of Surveyed Households", 
       title = "Vehicle Access by Housing Location",
       fill = "Housing Location")
c5.3

# plot - shares, proportion
c5.4 <- ggplot(SEAhome_vehaccess, aes(x=hh_veh_access_num, y=n, 
                                      fill=seattle_home)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Share of Surveyed Households", 
       title = "Vehicle Access by Housing Location",
       fill = "Housing Location")
c5.4

grid.arrange(c5.1, c5.2, c5.3, c5.4, nrow=2, ncol=2)

# TRANSIT SCORE AND VEHICLE ACCESS----------------------------------
transit_score_data <- 'T:/2020November/Mary/HHTS/reference_materials/bg_transit_score2018_2_sf_10302020.csv'
transit_sc_df <- read.csv(transit_score_data)

household$final_home_bg<- as.character(household$final_home_bg)

# transit score - by block
transit_sc_df$geoid10<-as.character(transit_sc_df$geoid10)
glimpse(transit_sc_df$geoid10)
glimpse(hh_df_tract$final_home_bg)
household<- merge(household, transit_sc_df, by.x='final_home_bg', by.y='geoid10', all.x=TRUE )
glimpse(household)

# reorder vehicle access
household$hh_veh_access_num <- factor(household$hh_veh_access_num, 
                                      levels=c("Limited Access", "Equal","Good Access"))
# plot transit score mean
summary(household$scaled_score)

transitscore_vehaccess <- household %>%
  group_by(hh_veh_access_num, RGC_binary) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined), 
            TransitScore_average = mean(scaled_score, na.rm=T),
            TransitScore_median = median(scaled_score, na.rm=T))
transitscore_vehaccess

addWorksheet(wb,"TransitScore_and_VehAccess")
writeData(wb, sheet = "TransitScore_and_VehAccess", x=transitscore_vehaccess)
saveWorkbook(wb,output_WB, overwrite = T)

# plot - weights
c6 <- ggplot(transitscore_vehaccess, aes(x=hh_veh_access_num, y=HouseholdWeight, 
                                         fill=TransitScore_average)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access and Transit Score",
       fill = "Transit Score") +
  scale_fill_gradient(low = "red", high = "blue")
c6

# plot - shares
c6.2 <- ggplot(transitscore_vehaccess, aes(x=hh_veh_access_num, y=n, 
                                           fill=TransitScore_average)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Vehicle Access", 
       y = "Share of Surveyed Households", 
       title = "Vehicle Access and Transit Score",
       fill = "Transit Score") +
  scale_fill_gradient(low = "red", high = "blue")
c6.2

grid.arrange(c6, c6.2, nrow=1, ncol=2)

# look at transit score by RGC 
c6.3 <- ggplot(transitscore_vehaccess, aes(x=hh_veh_access_num, y=HouseholdWeight, 
                                           fill=TransitScore_average)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  facet_wrap(~RGC_binary) +
  labs(x = "Vehicle Access", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access and Transit Score",
       fill = "Transit Score") +
  scale_fill_gradient(low = "red", high = "blue")
c6.3

# HOUSEHOLD LICENSE (SUM)----------------------------------
unique(person_and_household$license)
freq(person_and_household$license)

person_and_household <- person_and_household %>% 
  mutate(license_simp = case_when(
    license == "Yes, has an intermediate or unrestricted license" ~ "Yes",
    license == "No, does not have a license or permit" ~ "No",
    license == "Yes, has a learner's permit" ~ "Permit",
    TRUE ~ "Other"))
freq(person_and_household$license_simp)

person_and_household <- person_and_household %>%
  mutate(license_binary = ifelse(license_simp == "Yes", 1, 0)) %>%
  group_by(household_id) %>%
  mutate(hh_license=sum(license_binary))

freq(person_and_household$license_binary) 
freq(person_and_household$hh_license)

glimpse(person_and_household)
# shares and MOEs
hh_license_MOE1<- create_table_one_var_simp_joined("hh_license", person_and_household, "household")
hh_license_MOE1
hh_license_MOE2<- create_table_one_var_joined("hh_license", person_and_household, "household")
hh_license_MOE2

# save to workbook
addWorksheet(wb,"HH_License_simp1")
addWorksheet(wb,"HH_License_simp2")
writeData(wb, sheet = "HH_License_simp1", x=hh_license_MOE1)
writeData(wb, sheet = "HH_License_simp2", x=hh_license_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)


# based on small n as household licenses increase, consolidate 4 and 5
person_and_household <- person_and_household %>%
  mutate(hh_license_cat = case_when(hh_license == "5" ~ "4",
                                    hh_license == "4" ~ "4",
                                    hh_license == "3" ~ "3",
                                    hh_license == "2" ~ "2",
                                    hh_license == "1" ~ "1",
                                    hh_license == "0" ~ "0")) %>%
  filter(hh_license != "NA")
freq(person_and_household$hh_license_cat)

# shares and MOEs
hh_license_cat_MOE1<- create_table_one_var_simp_joined("hh_license_cat", person_and_household, "household")
hh_license_cat_MOE1
hh_license_cat_MOE2<- create_table_one_var_joined("hh_license_cat", person_and_household, "household")
hh_license_cat_MOE2

# save to workbook
addWorksheet(wb,"HH_License_cat_simp1")
addWorksheet(wb,"HH_License_cat_simp2")
writeData(wb, sheet = "HH_License_cat_simp1", x=hh_license_cat_MOE1)
writeData(wb, sheet = "HH_License_cat_simp2", x=hh_license_cat_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# HOUSEHOLD LICENSE (SUM) AND VEH COUNT ----------------------------------
freq(person_and_household$vehcount_simp)

xtabs(~hh_license_cat + vehcount_simp, data=person_and_household)

# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined.x'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_license_cat'
# this is the second variable you want to summarize by
var <- 'vehcount_simp'
# filter data missing weights 
hh_no_na<-person_and_household %>% drop_na(all_of(hh_wt_field.x))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(person_and_household$household_id))
# now find the sample size of your subgroup
sample_size_group<- person_and_household %>%
  group_by(hh_license_cat) %>%
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
# # save to workbook
addWorksheet(wb,"HHLicense_VehCount")
writeData(wb, sheet = "HHLicense_VehCount", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)

# plot
hhlicense_vehcount <- person_and_household %>%
  group_by(hh_license_cat, vehcount_simp) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined.x))
hhlicense_vehcount

# plot - weights
e1.1 <- ggplot(hhlicense_vehcount, aes(x=hh_license_cat, y=HouseholdWeight, 
                                       fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Number of Household Licenses", 
       y = "Estimated Number of Households in Region", 
       title = "Household License Count and Vehicle Count",
       fill = "Number of Vehicles")
e1.1

# plot - weights, proportion
e1.2 <- ggplot(hhlicense_vehcount, aes(x=hh_license_cat, y=HouseholdWeight, 
                                       fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Number of Household Licenses", 
       y = "Estimated Number of Households in Region", 
       title = "Household License Count and Vehicle Count",
       fill = "Number of Vehicles")
e1.2

# plot - shares
e1.3 <- ggplot(hhlicense_vehcount, aes(x=hh_license_cat, y=n, 
                                       fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Number of Household Licenses", 
       y = "Share of Surveyed Households", 
       title = "Household License Count and Vehicle Count",
       fill = "Number of Vehicles")
e1.3

# plot - shares, proportion
e1.4 <- ggplot(hhlicense_vehcount, aes(x=hh_license_cat, y=n, 
                                       fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Number of Household Licenses", 
       y = "Share of Surveyed Households", 
       title = "Household License Count and Vehicle Count",
       fill = "Number of Vehicles")
e1.4

grid.arrange(e1.1, e1.2, e1.3, e1.4, nrow=2, ncol=2)

# HOUSEHOLD SIZE ----------------------------------
freq(person_and_household$hhsize)

# shares and MOEs
hh_size_MOE2<- create_table_one_var_joined("hhsize", person_and_household, "household")
hh_size_MOE2

addWorksheet(wb,"HH_size_simp1")
writeData(wb, sheet = "HH_size_simp1", x=hh_size_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

summary(person_and_household$hhsize) #character
person_and_household$hhsize <- as.factor(person_and_household$hhsize)

# based on small n as household size increases, consolidate 6,7,8
person_and_household$hh_size_cat <- recode(person_and_household$hhsize,
                                           "6 people" = "6 or more people",
                                           "7 people" = "6 or more people",
                                           "8 people" = "6 or more people")
freq(person_and_household$hh_size_cat)

# shares and MOEs
hh_size_cat_MOE2<- create_table_one_var_joined("hh_size_cat", person_and_household, "household")
hh_size_cat_MOE2

# save to workbook
addWorksheet(wb,"HH_size_cat_simp2")
writeData(wb, sheet = "HH_size_cat_simp2", x=hh_size_cat_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# HOUSEHOLD SIZE AND VEH COUNT ----------------------------------
xtabs(~hh_size_cat + vehcount_simp, data=person_and_household)

# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined.x'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_size_cat'
# this is the second variable you want to summarize by
var <- 'vehcount_simp'
# filter data missing weights 
hh_no_na<-person_and_household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(person_and_household$household_id))
# now find the sample size of your subgroup
sample_size_group<- person_and_household %>%
  group_by(hh_size_cat) %>%
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
# # save to workbook
addWorksheet(wb,"HHSize_VehCount")
writeData(wb, sheet = "HHSize_VehCount", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)


# plot
hhsize_vehcount <- person_and_household %>%
  group_by(hh_size_cat, vehcount_simp) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined.x))
hhsize_vehcount

# plot - weights
e2.1 <- ggplot(hhsize_vehcount, aes(x=hh_size_cat, y=HouseholdWeight, 
                                    fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Household Size", 
       y = "Estimated Number of Households in Region", 
       title = "Household License Count by Household Size",
       fill = "Number of Vehicles")
e2.1

# plot - weights, proportion
e2.2 <- ggplot(hhsize_vehcount, aes(x=hh_size_cat, y=HouseholdWeight, 
                                    fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Household Size", 
       y = "Estimated Number of Households in Region", 
       title = "Household License Count by Household Size",
       fill = "Number of Vehicles")
e2.2

# plot - shares
e2.3 <- ggplot(hhsize_vehcount, aes(x=hh_size_cat, y=n, 
                                    fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Household Size", 
       y = "Share of Surveyed Households", 
       title = "Household License Count by Household Size",
       fill = "Number of Vehicles")
e2.3

# plot - shares, proportion
e2.4 <- ggplot(hhsize_vehcount, aes(x=hh_size_cat, y=n, 
                                    fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Household Size", 
       y = "Share of Surveyed Households", 
       title = "Household License Count by Household Size",
       fill = "Number of Vehicles")
e2.4

grid.arrange(e2.1, e2.2, e2.3, e2.4, nrow=2, ncol=2)


# HOUSEHOLD LIFECYCLE ----------------------------------
freq(person_and_household$lifecycle)

# shares and MOEs
hh_lifecycle_MOE1<- create_table_one_var_simp_joined("lifecycle", person_and_household, "household")
hh_lifecycle_MOE1
hh_lifecycle_MOE2<- create_table_one_var_joined("lifecycle", person_and_household, "household")
hh_lifecycle_MOE2

# save to workbook
addWorksheet(wb,"HH_Lifecycle_simp1")
addWorksheet(wb,"HH_Lifecycle_simp2")
writeData(wb, sheet = "HH_Lifecycle_simp1", x=hh_lifecycle_MOE1)
writeData(wb, sheet = "HH_Lifecycle_simp2", x=hh_lifecycle_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# simplify lifecycle categories by age
person_and_household <- person_and_household %>%
  mutate(hh_lifecycle = case_when(lifecycle == "Household size = 1, Householder under age 35" |
                                    lifecycle == "Household size > 1, Householder under age 35" ~
                                    "Under age 35",
                                  lifecycle == "Household size = 1, Householder age 35 - 64" |
                                    lifecycle == "Household size > 1, Householder age 35 - 64" ~ 
                                    "Age 35-64",
                                  lifecycle == "Household size = 1, Householder age 65+" |
                                    lifecycle == "Household size > 1, Householder age 65+" ~
                                    "Age 65+",
                                  lifecycle == "Household includes children under 5" ~
                                    "With children under 5",
                                  lifecycle == "Household includes children age 5-17" ~
                                    "With children age 5-17"))

person_and_household$hh_lifecycle <- factor(person_and_household$hh_lifecycle, 
                                            levels=c("Under age 35","Age 35-64",
                                                     "Age 65+","With children under 5",
                                                     "With children age 5-17"))
freq(person_and_household$hh_lifecycle)

# shares and MOEs
hh_lifecycle_simp_MOE1<- create_table_one_var_simp_joined("hh_lifecycle", person_and_household, "household")
hh_lifecycle_simp_MOE1
hh_lifecycle_simp_MOE2<- create_table_one_var_joined("hh_lifecycle", person_and_household, "household")
hh_lifecycle_simp_MOE1

# save to workbook
addWorksheet(wb,"HH_Lifecycle_simplified1")
addWorksheet(wb,"HH_Lifecycle_simplified2")
writeData(wb, sheet = "HH_Lifecycle_simplified1", x=hh_lifecycle_simp_MOE1)
writeData(wb, sheet = "HH_Lifecycle_simplified2", x=hh_lifecycle_simp_MOE2)
saveWorkbook(wb,output_WB, overwrite = T)

# HOUSEHOLD SIZE AND VEH COUNT ----------------------------------
xtabs(~hh_lifecycle + vehcount_simp, data=person_and_household)

# User defined variables on each analysis:
# this is the weight for summing in your analysis
hh_wt_field<- 'hh_wt_combined.x'
# # this is a field to count the number of records
# person_count_field<-'person_dim_id'
# this is how you want to group the data in the first dimension,
# this is how you will get the n for your sub group
group_cat <- 'hh_lifecycle'
# this is the second variable you want to summarize by
var <- 'vehcount_simp'
# filter data missing weights 
hh_no_na<-person_and_household %>% drop_na(all_of(hh_wt_field))
#filter data missing values
#before you filter out the data, you have to investigate if there are any NAs or missing values in your variables and why they are there.
sum(is.na(person_and_household$household_id))
# now find the sample size of your subgroup
sample_size_group<- person_and_household %>%
  group_by(hh_lifecycle) %>%
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
# # save to workbook
addWorksheet(wb,"HHLifecycle_VehCount")
writeData(wb, sheet = "HHLifecycle_VehCount", x=cross_table_w_MOE)
saveWorkbook(wb,output_WB, overwrite = T)


# plot
hhlifecycle_vehcount <- person_and_household %>%
  group_by(hh_lifecycle, vehcount_simp) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined.x))
hhlifecycle_vehcount

# plot - weights
f2.1 <- ggplot(hhlifecycle_vehcount, aes(x=hh_lifecycle, y=HouseholdWeight, 
                                         fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Household Lifecycle", 
       y = "Estimated Number of Households in Region", 
       title = "Household Vehicle Count by Household Lifecycle",
       fill = "Number of Vehicles")
f2.1

# plot - weights, proportion
f2.2 <- ggplot(hhlifecycle_vehcount, aes(x=hh_lifecycle, y=HouseholdWeight, 
                                         fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Household Lifecycle", 
       y = "Estimated Number of Households in Region", 
       title = "Household Vehicle Count by Household Lifecycle",
       fill = "Number of Vehicles")
f2.2

# plot - shares
f2.3 <- ggplot(hhlifecycle_vehcount, aes(x=hh_lifecycle, y=n, 
                                         fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='dodge') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Household Lifecycle", 
       y = "Share of Surveyed Households", 
       title = "Household Vehicle Count by Household Lifecycle",
       fill = "Number of Vehicles")
f2.3

# plot - shares, proportion
f2.4 <- ggplot(hhlifecycle_vehcount, aes(x=hh_lifecycle, y=n, 
                                         fill=vehcount_simp)) + 
  geom_bar(stat="identity", position='fill') +
  theme(axis.text.x=element_text(angle=90, hjust=1, vjust=0.5)) +
  labs(x = "Household Lifecycle", 
       y = "Share of Surveyed Households", 
       title = "Household Vehicle Count by Household Lifecycle",
       fill = "Number of Vehicles")
f2.4

grid.arrange(f2.1, f2.2, f2.3, f2.4, nrow=2, ncol=2)


# RELATIONSHIP: NUMWORKERS AND LICENSE ----------------------------------
unique(person_and_household$hh_license_cat)
xtabs(~hh_license_cat + numworkers, data=person_and_household)

# proportion of workers with licenses - add field
freq(person_and_household$hh_license)
freq(person_and_household$numworkers)


person_and_household <- person_and_household %>%
  mutate(workers_license = hh_license/numworkers) 
freq(person_and_household$workers_license)

hh_workers_license <-  person_and_household %>%
  group_by(household_id) %>%
  summarise(n=n(), HouseholdWeight = sum(hh_wt_combined.x), Proportion = workers_license)
hh_workers_license  
