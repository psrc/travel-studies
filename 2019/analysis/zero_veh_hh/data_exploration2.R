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
                   'Missing: Skip logic', 'Children or missing', 'Prefer not to answer')

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

# Create a crosstab from one variable, calculate counts, totals, shares, and MOE
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
                                     vehicle_count == "10 or more vehicles" ~ "4+",
                                   TRUE~.$vehicle_count))
unique(household$vehcount_simp)

create_table_one_var_simp("vehcount_simp", household, "household")
create_table_one_var("vehcount_simp", household, "household")

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

create_table_one_var_simp("numworkers", household, "household")
# group number of workers above 3 individuals
household <- household%>%
  mutate(numworkers_simp = case_when(numworkers >= 3 ~ 3,
                                   TRUE~as.numeric(numworkers)))
unique(household$numworkers_simp)

create_table_one_var_simp("numworkers_simp", household, "household")
create_table_one_var("numworkers_simp", household, "household")

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
household$vehcount_simp_num <- as.numeric(household$vehcount_simp)
class(household$vehcount_simp_num)

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

create_table_one_var("final_cnty", household, "household")
