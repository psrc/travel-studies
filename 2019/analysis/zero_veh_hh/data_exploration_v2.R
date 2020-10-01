##########################
#List of packages required
packages <- c("data.table","odbc","DBI","summarytools","ggthemes","hrbrthemes","dplyr",
              "ggplot2","tidyr","reshape2","table1","knitr","kableExtra","ggthemes","hrbrthemes")
#Install packages
lapply(packages, install.packages, character.only = TRUE)

#Load packages
lapply(packages, library, character.only = TRUE)

##########################


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

# Investigate the household weights 
# head(household$hh_wt_combined)
sum(household$hh_wt_combined)

# Data for household weights by number of vehicles
# hhwt_vehcount <- aggregate(household$hh_day_wt_combined,
#                            by = list(VehicleCount=household$vehicle_count), 
#                            FUN = sum)
# colnames(hhwt_vehcount)[colnames(hhwt_vehcount) == "x"] <- "HouseholdWeight"
# hhwt_vehcount
# # doesn't return correct values?


hhwt_vehcount1 <- household%>% 
  group_by(VehicleCount=vehicle_count)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups = "keep")%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
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
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups = "keep")%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
# hhwt_vehiclecount <-aggregate(household$hh_day_wt_combined, 
#                               by = list(VehicleCount=household$vehcount_reordered),
#                               FUN = sum)
# colnames(hhwt_vehiclecount)[colnames(hhwt_vehiclecount) == "x"] <- "HouseholdWeight"
hhwt_vehiclecount_reordered

hhwt_vehcount_reordered

a2 <- ggplot(data = hhwt_vehcount_reordered, 
             aes(x=vehcount_reordered, y=HouseholdWeight)) +
  geom_bar(stat="identity", position = 'dodge') + 
  geom_text(aes(label=round(HouseholdWeight,0)), 
            hjust=0.5, vjust=-0.5, size=2.5, inherit.aes = T) +
  labs(x = "Number of Vehicles per Household", 
       y = "Estimated Number of Households in Region", title = "Vehicle Ownership")
a2


# investigate housing tenure (rent_own)
freq(household$rent_own)
housingtenure <-as.factor(household$rent_own)
summary(housingtenure)
# housing tenure by number of household vehicles
housingtenure.veh <- xtabs(~housingtenure + vehcount_reordered, data = household)
summary(housingtenure.veh)
head(housingtenure.veh)
# housing tenure 
hhwt_housingtenure <- household%>% 
  group_by(rent_own)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups= "keep")%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
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

# plot household weights by housing tenure and vehicle ownership
hhwt_vehcount_tenure <- household%>% 
  group_by(vehcount_reordered, rent_own)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups = "keep") %>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
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

# Look at own vs. rent
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


# vehicle access: number of workers compared to vehicle count
unique(household$numworkers)
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
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups= "keep")%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
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
vehicle_count_trans <- recode(household$vehicle_count, 
                                               "0 (no vehicles)" = "0",
                                               "10 or more vehicles" = "10")
household %>% mutate(vehicle_count_trans=recode(vehicle_count,
                                                "0 (no vehicles)" = "0",
                                                "10 or more vehicles" = "10"))

unique(vehicle_count_trans)
class(vehicle_count_trans)

vehicle_count_num <- as.numeric(vehicle_count_trans)
unique(vehicle_count_num)
class(vehicle_count_num)
class(household$numworkers)
numworkers_num <- as.numeric(household$numworkers)
class(numworkers_num)
summary(household$numworkers)
summary(household$vehicle_count_num) #corresponds, but not connected to household?

# # vehicle access categories - categorical veh count data
# can't work because vehicle_count is categorical and numworkers is numeric?
household[, hh_veh_access := fcase(
  all(vehicle_count < numworkers), "Limited Access",
  all(vehicle_count = numworkers), "Equal",
  all(vehicle_count > numworkers), "Good Access",
  default = "other"), by = "household_id"]
unique(household$hh_veh_access)

xtabs(~hh_veh_access+numworkers, data=household)
xtabs(~vehicle_count_num+ household$numworkers)


# vehicle access categories - numerical veh count data
# doesn't work?
household[, hh_veh_access_num := fcase(
  all(vehicle_count_num < numworkers), "Limited Access",
  all(vehicle_count_num == numworkers), "Equal",
  all(vehicle_count_num > numworkers), "Good Access",
  default = "other"), by = "household_id"]
unique(household$hh_veh_access_num)
head(vehicle_count_num)
head(household$vehicle_count)


hhwt_veh_access <- household %>% 
  group_by(hh_veh_access) %>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups= "keep") %>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
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


# plot household weights by household race category and veh access categories
# all hh race categories
hhwt_race_cat <- household %>% 
  group_by(hh_race_category, hh_veh_access) %>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups= "keep") %>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
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
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups= "keep")%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100)%>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
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


# Household Income (broad) - vehicle access
hhwt_bincome_access <- household%>% 
  group_by(hhincome_broad, hh_veh_access)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups= "keep")%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
hhwt_bincome_access

a12 <- ggplot(hhwt_bincome_access, 
              aes(x=hhincome_broad, 
                  y=HouseholdWeight, fill=hh_veh_access)) +
  geom_bar(stat="identity") + 
  #geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Household Income (Broad)", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Income",
       fill = "Vehicle Access (Workers)")
a12

# Household Income (broad) - vehicle access and race
hhwt_bincome_veh_race <- household%>% 
  group_by(hhincome_broad, hh_veh_access, hh_race_condcat1)%>%
  summarise(n=n(),HouseholdWeight=sum(hh_wt_combined), .groups= "keep")%>%
  mutate(perc_comb = HouseholdWeight/sum(HouseholdWeight)*100) %>%
  ungroup() %>%
  mutate(MOE=z*((p_MOE*(1-p_MOE))/n)^(1/2)*100)
hhwt_bincome_veh_race

a13 <- ggplot(hhwt_bincome_veh_race, 
              aes(x=hh_veh_access,
                  y=HouseholdWeight, fill=hhincome_broad)) +
  geom_bar(stat="identity") + facet_grid(.~hh_race_condcat1) +
  #geom_text(aes(label=round(HouseholdWeight,0)), hjust=0.5, vjust=-0.5) +
  labs(x = "Vehicle Access (Workers)", 
       y = "Estimated Number of Households in Region", 
       title = "Vehicle Access by Household Income",
       fill = "Household Income (Broad)")
a13

# margin of error
p_MOE <- 0.5
z <- 1.645

# verify number of samples for household dataset (6,319), weighted total (1,656,755)
sum(household$hh_wt_combined)
sample_size <-nrow(household)
# freq(household$hh_wt_combined) #also returns number of samples as total at bottom


