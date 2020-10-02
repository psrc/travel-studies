#INSTALL PACKAGES##########################
# List of packages required
packages <- c("data.table","odbc","DBI","summarytools","ggthemes","hrbrthemes",
              "dplyr", "DT", "tidyverse", "psych",
              "ggplot2","tidyr")
# removed: "table1","knitr","kableExtra","reshape2"

# Install packages
lapply(packages, install.packages, character.only = TRUE)

# Load libraries
lapply(packages, library, character.only = TRUE)

# CONNECT TO DATABASE, SET UP WORKSPACE##########################
elmer_conn <- dbConnect(odbc::odbc(),
                        driver = "SQL Server",
                        server = "AWS-PROD-SQL\\Sockeye",
                        database = "Elmer",
                        trusted_connection = "yes")

h <- dbGetQuery(elmer_conn,
                "SELECT * FROM HHSurvey.v_households_2017_2019_in_house")
p <- dbGetQuery(elmer_conn,
                "SELECT * FROM HHSurvey.v_persons_2017_2019_in_house")

dbDisconnect(elmer_conn)

household <- data.table(h)
person <- data.table(p)
# head(household)
# head(person)
glimpse(household)

# Investigate the household weights 
head(household$hh_wt_combined)
# verify number of samples for household dataset (6,319), weighted total (1,656,755)
nrow(household)
sum(household$hh_wt_combined)

# freq(household$hh_wt_combined) #also returns number of samples as total at bottom

# establish MOE (margin of error) variables
p_MOE <- 0.5
z <- 1.645
missing_codes <- c('Missing: Technical Error', 'Missing: Non-response', 
                   'Missing: Skip logic', 'Children or missing', ' Prefer not to answer')

# Number of vehicles##########################

# hhwt_vehcount <- aggregate(household$hh_day_wt_combined,
#                            by = list(VehicleCount=household$vehicle_count), 
#                            FUN = sum)
# colnames(hhwt_vehcount)[colnames(hhwt_vehcount) == "x"] <- "HouseholdWeight"
# hhwt_vehcount
# # does not return correct values?

hhwt_vehcount1 <- household%>% 
  group_by(VehicleCount=vehicle_count)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_vehcount1

# plot household weights by number of vehicles
a1 <-ggplot(data = hhwt_vehcount1, aes(x=VehicleCount, y=HouseholdWeight)) + 
  geom_bar(stat="identity") + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T)
a1


#reorder vehicle_count so "0 (no vehicles)" is at beginning and "10 or more vehicles" is at end
unique(household$vehicle_count)
# factor(household$vehicle_count)
household$vehcount_reordered <- factor(household$vehicle_count, 
                                  levels=c("0 (no vehicles)","1","2","3","4","5",
                                           "6","7","8","9","10 or more vehicles"))
levels(vehcount_reordered)

# plot household weights by number of vehicles (reordered)
hhwt_vehiclecount_reordered <- household%>% 
  group_by(VehicleCount=vehcount_reordered)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_vehiclecount_reordered
# hhwt_vehiclecount <-aggregate(household$hh_day_wt_combined, 
#                               by = list(VehicleCount=household$vehcount_reordered),
#                               FUN = sum)
# colnames(hhwt_vehiclecount)[colnames(hhwt_vehiclecount) == "x"] <- "HouseholdWeight"
# hhwt_vehcount_reordered

a2 <- ggplot(data = hhwt_vehiclecount_reordered, 
             aes(x=VehicleCount, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Vehicles per Household", 
       y = "Estimated Number of Households in Region", title = "Vehicle Ownership")
a2


# Housing tenure (rent_own)##########################
freq(household$rent_own)
housingtenure <-as.factor(household$rent_own)
summary(housingtenure)

# housing tenure by number of household vehicles
housingtenure.veh <- xtabs(~housingtenure + vehcount_reordered, data = household)
summary(housingtenure.veh)
head(housingtenure.veh)
# housing tenure with household weights
hhwt_housingtenure <- household%>% 
  group_by(rent_own)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_housingtenure

# plot household weights by housing tenure
# need to transform to dataframe because as a tibble it was plotting multiple labels 
hhwt_housingtenure_df =as.data.frame(hhwt_housingtenure)
hhwt_housingtenure_df
a3 <-ggplot(hhwt_housingtenure_df, 
            aes(x=rent_own, y=HouseholdWeight)) +
  geom_bar(stat="identity") + 
  geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Number of Vehicles per Household", 
       y = "Estimated Number of Households in Region", 
       title = "Housing Tenure")
a3

unique(household$rent_own)

# filter out missing values
tenure_no_na <- hhwt_housingtenure_df %>% 
  filter(!rent_own == "Prefer not to answer" & !rent_own == "Other")
unique(tenure_no_na)

a3.5 <-ggplot(tenure_no_na, 
            aes(x=rent_own, y=HouseholdWeight)) +
  geom_bar(stat="identity") + 
  geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Number of Vehicles per Household", 
       y = "Estimated Number of Households in Region", 
       title = "Simplified Housing Tenure")
a3.5

# Housing tenure and vehicle ownership##########################
hhwt_vehcount_tenure <- household%>% 
  group_by(vehcount_reordered, rent_own)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined)) %>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_vehcount_tenure

a4 <- ggplot(hhwt_vehcount_tenure, 
             aes(x=vehcount_reordered, y=HouseholdWeight, fill=rent_own)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Vehicles per Household", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Ownership", fill = "Housing Tenure")
a4

# Look at own vs. rent (consolidate tenure categories)
unique(household$rent_own)
household[, rent_v_own := fcase(
  all(rent_own == "Own/paying mortgage"), "Own",
  all(rent_own == "Rent"), "Rent",
  default = "other"), by = "household_id"]

unique(household$rent_v_own)
# plot household weights by number of vehicles (reordered) and housing tenure
a5 <- ggplot(data, aes(fill=(household$rent_v_own), y=household$hh_wt_combined, x=vehcount_reordered)) + 
  geom_bar(position="dodge", stat="identity") + 
  labs(x= "Number of Vehicles", y = "Number of Households", fill= "Housing Tenure",  
       title="Households by Vehicle Ownership and Housing Tenure")
a5


# Vehicle access: number of workers compared to vehicle count##########################
unique(household$numworkers)
describe(household$numworkers)
head(household$numworkers)
unique(household$vehcount_reordered)

# number of households: number of workers by vehicles owned
hhwt_workers_vehown <- with(household, 
                            tapply(hh_wt_combined, 
                              list(vehcount_reordered,numworkers), 
                              sum))
hhwt_workers_vehown

hhwt_workers_vehown1 <- household%>% 
  group_by(vehcount_reordered,numworkers)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_workers_vehown1

a6 <-ggplot(hhwt_workers_vehown1, 
            aes(x=vehcount_reordered, y=HouseholdWeight, fill=numworkers)) +
  geom_bar(stat="identity") + 
  #geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Number of Vehicles to Number of Workers", 
       y = "Estimated Number of Households in Region", 
       title = "Household Vehicle Access",
       fill = "Number of Workers")
a6

# transform vehicle count to numeric?
class(household$vehicle_count)
household$vehicle_count_trans <- recode(household$vehicle_count, 
                                               "0 (no vehicles)" = "0",
                                               "10 or more vehicles" = "10")
unique(vehicle_count_trans)
class(vehicle_count_trans)

household$vehicle_count_num <- as.numeric(vehicle_count_trans)
unique(vehicle_count_num)
class(vehicle_count_num)

# vehicle access categories 
# data.table option - categorical veh count data
household[, hh_veh_access := fcase(
  all(vehicle_count < numworkers), "Limited Access",
  all(vehicle_count = numworkers), "Equal",
  all(vehicle_count > numworkers), "Good Access",
  default = "other"), by = "household_id"]
unique(household$hh_veh_access)


# dplyr option - categorical veh count data
household <- household%>%
  mutate(hh_veh_access1 = case_when(vehicle_count < numworkers ~ "Limited Access",
                                    vehicle_count == numworkers ~ "Equal",
                                    vehicle_count > numworkers ~ "Good Access"))

# data.table option - numerical veh count data
household[, hh_veh_access_num := fcase(
  all(vehicle_count_num < numworkers), "Limited Access",
  all(vehicle_count_num == numworkers), "Equal",
  all(vehicle_count_num > numworkers), "Good Access",
  default = "other"), by = "household_id"]
unique(household$hh_veh_access_num)

# dplyr option - numerical veh count data
household <- household%>%
  mutate(hh_veh_access1_num = case_when(vehicle_count_num < numworkers ~ "Limited Access",
                                    vehicle_count_num == numworkers ~ "Equal",
                                    vehicle_count_num > numworkers ~ "Good Access"))

# comparing the results from the code above - using both categorical and numerical
# how can categorical data be compared to the integer data
# why are these two different sets of recoding producing different results?
xtabs(~hh_veh_access+numworkers, data=household)
xtabs(~hh_veh_access1+numworkers, data=household) #this and previous produce same results
xtabs(~hh_veh_access_num+numworkers, data=household)
xtabs(~hh_veh_access1_num+numworkers, data=household) #produce same results, different than first 2...

xtabs(~vehicle_count_num+ household$numworkers)


hhwt_veh_access <- household %>% 
  group_by(hh_veh_access) %>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined)) %>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_veh_access

# plot household weight by vehicle access categories
a7 <-ggplot(hhwt_veh_access, 
            aes(x=hh_veh_access, y=HouseholdWeight)) +
  geom_bar(stat="identity") + 
  geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Number of Vehicles to Number of Workers", 
       y = "Estimated Number of Households in Region", 
       title = "Household Vehicle Access")
a7

#Race categories##########################
# plot household weights by household race category and veh access categories
# all hh race categories
hhwt_race_cat <- household %>% 
  group_by(hh_race_category, hh_veh_access) %>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined)) %>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_race_cat

# plot - frequency
a8 <-ggplot(hhwt_race_cat, 
            aes(x=hh_race_category, y=HouseholdWeight, fill=hh_veh_access)) +
  geom_bar(stat="identity") + 
  #geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Race",
       fill = "Vehicle Access (Workers)")
a8
# plot - proportion
a9 <-ggplot(hhwt_race_cat, 
            aes(x=hh_race_category, y=HouseholdWeight, fill=hh_veh_access)) +
  geom_bar(stat="identity", position= "fill") + 
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Race",
       fill = "Vehicle Access (Workers)")
a9

# focused hh race categories (consolidate: missing, other, exception)
unique(household$hh_race_category)

# simplifies race categories
household[, hh_race_condcat1 := fcase(
  all(hh_race_category == "White Only"), "While Only",
  all(hh_race_category == "Asian"), "Asian",
  all(hh_race_category == "Hispanic"), "Hispanic",
  all(hh_race_category == "African American"), "African American",
  default = "other"), by = "household_id"]
unique(household$hh_race_condcat1)

# generate tibble showing race by access
hhwt_race_cat1 <- household%>% 
  group_by(hh_race_condcat1, hh_veh_access)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100)%>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_race_cat1


# plot - frequency
a10 <-ggplot(hhwt_race_cat1, 
            aes(x=hh_race_condcat1, y=HouseholdWeight, fill=hh_veh_access)) +
  geom_bar(stat="identity") + 
  geom_text(aes(label=round(HouseholdWeight,0))) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Race",
       fill = "Vehicle Access (Workers)")
a10

# plot - proportion
a11 <- ggplot(hhwt_race_cat1, 
              aes(x=hh_race_condcat1, y=HouseholdWeight, fill=hh_veh_access)) +
  geom_bar(stat="identity", position="fill") + 
  #geom_text(aes(label=round(HouseholdWeight,0))) +
  labs(x = "Household Race", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Race",
       fill = "Vehicle Access (Workers)")
a11


# Household Income (broad)##########################
# broad income, vehicle access
unique(household$hhincome_broad)
hhwt_bincome_access <- household%>% 
  group_by(hhincome_broad, hh_veh_access)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_bincome_access

xtabs(~hh_veh_access + hhincome_broad, data=household)

a12 <- ggplot(hhwt_bincome_access, 
              aes(x=hhincome_broad, 
                  y=HouseholdWeight, fill=hh_veh_access)) +
  geom_bar(stat="identity", position = "dodge") + 
  #geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Household Income (Broad)", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Income",
       fill = "Vehicle Access (Workers)")
a12

# broad income, vehicle access, and race
hhwt_bincome_veh_race <- household%>% 
  group_by(hhincome_broad, hh_veh_access, hh_race_condcat1)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_bincome_veh_race

a13 <- ggplot(hhwt_bincome_veh_race, 
              aes(x=hh_veh_access,
                  y=HouseholdWeight, fill=hhincome_broad)) +
  geom_bar(stat="identity") + facet_grid(.~hh_race_condcat1) +
  geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Vehicle Access (Workers)", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Income and Race",
       fill = "Household Income (Broad)")
a13

# broad income (filter out "prefer not to answer"), vehicle access, and race
unique(household$hhincome_broad)
# trying to filter out 
hhincomebroad_filtered <- household %>% 
  filter(hhincome_broad != "Prefer not to answer")
head(hhincomebroad_filtered)
glimpse(hhincomebroad_filtered)

hhincomebroad_filtered_df <- as.data.frame(hhincomebroad_filtered)
hhincomebroad_filtered_df

# plot
hhwt_broad_no_noanswer <- hhincomebroad_filtered_df %>% 
  group_by(hhincome_broad, hh_veh_access, hh_race_condcat1) %>% 
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_broad_no_noanswer

a14 <- ggplot(hhwt_broad_no_noanswer, 
              aes(x=hh_veh_access,
                  y=HouseholdWeight, fill=hhincome_broad)) +
  geom_bar(stat="identity") + facet_grid(.~hh_race_condcat1) +
  geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Vehicle Access (Workers)", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Income and Race",
       fill = "Household Income (Broad)")
a14

person_no_na %>% group_by(mode_freq_5) %>% summarise(n=n())
person_no_na = person_no_na %>% filter(!mode_freq_5 %in% missing_codes)

#Residential type##########################
xtabs(~hh_veh_access+res_type, data = household)

# residential type, vehicle access, and race
hhwt_access_res_race <- household%>% 
  group_by(res_type, hh_veh_access, hh_race_condcat1)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined))%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/sum(n))^(1/2)*100)
hhwt_access_res_race


a15 <- ggplot(hhwt_access_res_race, 
              aes(x=hh_race_condcat1,
                  y=HouseholdWeight, fill=res_type)) +
  geom_bar(stat="identity") + facet_grid(.~hh_veh_access) +
  #geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Race", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Residential Type and Race",
       fill = "Residential Type")
a15



# Example code from Polina -----------------------------------------------------------

# Load Libraries

library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)
library(psych)


# Functions 

## Read from Elmer

# Statistical assumptions for margins of error
p_MOE <- 0.5
z<-1.645
missing_codes <- c('Missing: Technical Error', 'Missing: Non-response', 
                   'Missing: Skip logic', 'Children or missing', ' Prefer not to answer')

# connecting to Elmer
db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\Sockeye",
                                database = "Elmer",
                                trusted_connection = "yes"
  )
}

# a function to read tables and queries from Elmer
read.dt <- function(astring, type =c('table_name', 'sqlquery')) {
  elmer_connection <- db.connect()
  if (type == 'table_name') {
    dtelm <- dbReadTable(elmer_connection, SQL(astring))
  } else {
    dtelm <- dbGetQuery(elmer_connection, SQL(astring))
  }
  dbDisconnect(elmer_connection)
  dtelm
}


#Create a crosstab from one variable, calculate counts, totals, and shares,
# for categorical data
create_table_one_var = function(var1, table_temp,table_type ) {
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
    ungroup() %>%  mutate(MOE=z*(p_MOE/sum(n))^(1/2)*100) %>% arrange(desc(perc_comb))
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
    mutate(MOE_Percent=z*sqrt(MOE_calc1))
  
  return(sample_w_MOE)
}   


#write out crosstabs
write_cross_tab<-function(out_table, var1, var2, file_loc){
  
  file_name <- paste(var1,'_', var2,'.xlsx')
  file_ext<-file.path(file_loc, file_name)
  write.xlsx(out_table, file_ext, sheetName ="data", 
             col.names = TRUE, row.names = FALSE, append = FALSE)
  
}



# Polina's Code Examples -----------------------------------------------------------
#Read the data from Elmer

#You can do this by using read.dt function. The function has two arguments: 
# first argument passes a sql query or a table name (as shown in Elmer)
# in the second argument user should specify if the first argument is 'table_name' or 'sqlquery'

#Here is an example using sql query - first, you need to create a variable with the sql query
# and then pass this variable to the read.dt function
sql.query = paste("SELECT * FROM HHSurvey.v_persons_2017_2019_in_house")
person = read.dt(sql.query, 'sqlquery')

#If you would like to use the table name, instead of query, you can use the following code
#that will produce the same results
person = read.dt("HHSurvey.v_persons_2017_2019", 'table_name')


#Check the data
# this step will allow you to understand the variable and the table that you are analyzing
#you can use the following functions to check for missing values, categories, etc.

#this function will allow you to see all of the variables in the table, check the data type,
#and see the first couple of values for each of the variables
glimpse(person)

# to check the distribution of a specific variable, you can use the following code
#here, for example, we are looking at mode_freq_5 category 
person %>% group_by() %>% summarise(n=n())

#if you analyze a numerical variable, you can use the following code to see the variable range
describe()


#to delete NA you can use the following code
#the best practices suggest to create a new variable with the updated table

person_no_na = person %>% filter(!is.na(mode_freq_5))

#when we re-run the distribution code, we see that we've eliminated NAs
person_no_na %>% group_by(mode_freq_5) %>% summarise(n=n())

# to exclude missing codes, you can use the following code
#note, that we've assigned missing_codes at the beginning of the script(lines 20-21)
person_no_na = person_no_na %>% filter(!mode_freq_5 %in% missing_codes)


#Create summaries

# to create a summary table based on one variable, you can use create_table_one_var function.
#The function create_table_one_var has 3 arguments:
# first, you have to specify the variable you are analyzing
#second, enter table name
#third, specify the table type e.g. person, household, vehicle, trip, or day. This will
# help to use correct weights

#here is an example for mode_freq_5 variable

create_table_one_var("mode_freq_5", person_no_na,"person" )

