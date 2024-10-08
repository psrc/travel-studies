# To determine the relationship with households that have fewer/zero vehicles
# install.packages("lattice")
library(nnet)
library(data.table)
library(tidyverse)
library(DT)
library(openxlsx)
library(odbc)
library(DBI)
library(dplyr)
library(summarytools)
library(stargazer)
library(MASS)
library(caret) #requires lattice and ggplot2
library(ggplot2)
library(lattice)
library(interactions)

parent_folder <- "C:/Users/mrichards/Documents/GitHub/travel-studies/2019/analysis/zero_veh_hh/model_outputs/"

# Estimating a multinomial logit model for household vehicles
# https://www.princeton.edu/~otorres/LogitR101.pdf


#functions for reading in data
db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\SOCKEYE",
                                database = "Elmer",
                                trusted_connection = "yes"
  )
}

read.dt <- function(astring, type =c('table_name', 'sqlquery')) {
  elmer_connection <- db.connect()
  if (type == 'table_name') {
    dtelm <- dbReadTable(elmer_connection, SQL(astring))
  } else {
    dtelm <- dbGetQuery(elmer_connection, SQL(astring))
  }
  dbDisconnect(elmer_connection)
  setDT(dtelm)
}



#read in the household table
# dbtable.household.query<- paste("SELECT *  FROM HHSurvey.v_households_2017_2019_in_house")
# hh_df<-read.dt(dbtable.household.query, 'tablename') # returning an error message

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


hh_df <- data.table(h)
p_df <- data.table(p)


# this has some information on the Census Tract level that could be useful
displ_index_data<- 'C:/Users/mrichards/Documents/GitHub/travel-studies/2019/analysis/zero_veh_hh/displacement_risk_estimation.csv'
displ_risk_df <- read.csv(displ_index_data)
transit_score_data <- 'T:/2020November/Mary/HHTS/reference_materials/bg_transit_score2018_2_sf_10302020.csv'
transit_sc_df <- read.csv(transit_score_data)

# merge the households to info about the tracts/blocks they live in - displacement risk/transit score (Stefan)
hh_df$final_home_tract<- as.character(hh_df$final_home_tract)
hh_df$final_home_bg<- as.character(hh_df$final_home_bg)
# displacement risk - by tract
displ_risk_df$GEOID<-as.character(displ_risk_df$GEOID)
hh_df_tract<- merge(hh_df,displ_risk_df, by.x='final_home_tract', by.y='GEOID', all.x=TRUE)
glimpse(hh_df_tract)
# transit score - by block
transit_sc_df$geoid10<-as.character(transit_sc_df$geoid10)
glimpse(transit_sc_df$geoid10)
glimpse(hh_df_tract$final_home_bg)
hh_df_tract <- merge(hh_df_tract, transit_sc_df, by.x='final_home_bg', by.y='geoid10', all.x=TRUE )
glimpse(hh_df_tract)

# probably want to predict the vehicle categorization Mary had been using
# lucky there are no NAs
unique(hh_df_tract$vehicle_count)
hh_df_veh <- hh_df_tract %>% mutate(vehicle_group = case_when(vehicle_count== "0 (no vehicles)" ~ 0,
                                                              vehicle_count == "1" ~  1,
                                                              vehicle_count == "2" ~ 2,
                                                              vehicle_count == "3" ~ 3,
                                                              TRUE ~ 4))
hh_df_veh %>% group_by(vehicle_group, vehicle_count) %>% tally()

# look at vehicle access by number of workers in a household
unique(hh_df_veh$numworkers)

hh_df_veh <- hh_df_veh %>%
  mutate(numworkers_simp = case_when(numworkers >= 3 ~ 3,
                                     TRUE~as.numeric(numworkers)))
unique(hh_df_veh$numworkers_simp)

# compare veh count and numworkers to get vehicle access
class(hh_df_veh$vehicle_group)
class(hh_df_veh$numworkers_simp)

hh_df_veh <- hh_df_veh %>%
  mutate(hh_veh_access = case_when(vehicle_group < numworkers_simp ~ 'Reduced access',
                                   vehicle_group == numworkers_simp ~ 'Equal access',
                                   vehicle_group > numworkers_simp ~ 'Good access'))
unique(hh_df_veh$hh_veh_access)
hh_df_veh$hh_veh_access <- factor(hh_df_veh$hh_veh_access, 
                                  levels=c("Reduced access", "Equal access","Good access"))
table(hh_df_veh$hh_veh_access)
xtabs(~hh_veh_access, data=hh_df_veh)


# simplify race category 
unique(hh_df_veh$hh_race_category)

hh_df_veh <- hh_df_veh %>% 
  mutate(hh_race_2 = case_when(hh_race_category == "White Only" ~ 'White Only',
                               hh_race_category == "Missing" | hh_race_category == "Other" ~ "Missing/Other",
                               TRUE ~ 'People of Color')) 
#POC = African American, Asian, Hispanic
freq(hh_df_veh$hh_race_2) #requries summarytools

# remove missing/other category
hh_df_veh <- hh_df_veh %>%
  filter(hh_race_2 != "Missing/Other")
freq(hh_df_veh$hh_race_2)

# get transit score by block group from Stefan
glimpse(hh_df_veh$scaled_score)
# try other geographic variables on the household table and the tract table
hh_df_veh <- hh_df_veh %>%
  mutate(RGC_binary = case_when(final_home_rgcnum == "Not RCG" ~ "Not RGC",
                                TRUE ~ "RGC"))
freq(hh_df_veh$RGC_binary)


# By default the first category is the reference.
table(hh_df_veh$hh_veh_access) # Reduced Access is reference
table(hh_df_veh$RGC_binary) # Not RGC is reference
table(hh_df_veh$scaled_score)
table(hh_df_veh$seattle_home) # Home in Seattle is reference

# To change it so 'lowest' is the reference type
# mydata$ses2 = relevel(mydata$ses, ref = "middle")

# ORDERED LOGIT MODEL: geographic factors and vehicle access -----

# Greene and Hensher (2009): "an unordered model specification is more appropriate when the set of alternative outcomes representing the dependent variable does not follow a natural ordinal ranking" 

# categorical vehicle access: reduced, equal, good
# documentation about function: https://www.rdocumentation.org/packages/MASS/versions/7.3-52/topics/polr
m <-polr(as.factor(hh_veh_access) ~
           RGC_binary + scaled_score + seattle_home,
         data=hh_df_veh, Hess = T)
summary(m)
# odds ratio
exp(coef(m))

modelname <- "access_geog"
stargazer(m, type= 'text', 
          out=paste0(parent_folder, modelname, "_", Sys.Date(),".txt"))

# adding coefficients and p-values store table
ctable <- coef(summary(m))
# calculate and store p values
p <- round(pnorm(abs(ctable[,"t value"]), lower.tail = F)*2,2)
# combined table
(ctable <-cbind(ctable, "p value"=p))

# convert coefficients into odd radios
m2 <- exp(coef(m))
modelname <- "access_geog_2"
stargazer(m2, type= 'text', 
          out=paste0(parent_folder, modelname, "_", Sys.Date(),".txt"))



# HOUSEHOLD VEHICLE OWNERSHIP -----

# Greene and Hensher (2009): "a looser interpretation of the vehicle ownership count as a reflection of the underlying preference intensity for ownership suggests an ordered choice model...though a somewhat fuzzy ordering might still seem natural, several authors have opted instead, to replace the ordered choice model with an ordered choice framework, the multinomial logit model and variants"

# Cui (2018): "The results show that the number of driver's licenses has the most significant impact on car ownership, followed by owning house, family size, household income and household registration in Beijing. Different from previous studies, it is found that the age of households between 35-44 and 55-64 will significantly affect the number of car ownership" - age of households is determined by the householder

table(hh_df_veh$vehicle_group) #0 vehicles is reference

# join household and person tables -----
person_and_household <- left_join(p_df, hh_df_veh,
                                  by=c("household_id"="household_id"))
# check number of rows to make sure no data lost
nrow(person_and_household) #same as the person table - 11940
# any NAs in person_id or household_id?
glimpse(person_and_household)
sum(is.na(person_and_household$person_id)) #0
sum(is.na(person_and_household$household_id)) #0

# household drivers licenses
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
# need to run MOE calculations?
table(person_and_household$hh_license)
# should licenses be simplified - recategorized to consolidate 3+ or 4+? 
person_and_household <- person_and_household %>%
  mutate(hh_license_cat = case_when(hh_license == "5" ~ "4",
                                    hh_license == "4" ~ "4",
                                    hh_license == "3" ~ "3",
                                    hh_license == "2" ~ "2",
                                    hh_license == "1" ~ "1",
                                    hh_license == "0" ~ "0")) %>%
  filter(hh_license != "NA")
freq(person_and_household$hh_license_cat)
table(person_and_household$hh_license_cat) # 0 household licenses is reference
person_and_household$hh_license_num <- as.integer(person_and_household$hh_license_cat)
summary(person_and_household$hh_license_num)

# housing tenure [rent_own]
unique(person_and_household$rent_own)
head(person_and_household$rent_own)


person_and_household <- person_and_household %>% 
  mutate(tenure_binary = case_when(rent_own == "Prefer not to answer" |
                                     rent_own == "Other" |
                                     rent_own == "Provided by job or military" ~ "Other",
                                   rent_own == "Own/paying mortgage" ~ "Own",
                                   TRUE ~ "Rent"))

freq(person_and_household$tenure_binary)

# reorder tenure
person_and_household$tenure_binary_reordered <- 
  factor(person_and_household$tenure_binary, levels=c("Own","Rent","Other"))
freq(person_and_household$tenure_binary_reordered)


# household size [hhsize]
freq(person_and_household$hhsize) # need to run MOE calculations

# based on small n as household size increases, consolidate 6,7,8
person_and_household$hh_size_cat <- recode(person_and_household$hhsize,
                                           "6 people" = "6 or more people",
                                           "7 people" = "6 or more people",
                                           "8 people" = "6 or more people")
freq(person_and_household$hh_size_cat)
table(person_and_household$hh_size_cat) # 1 person is reference

# household size as number, not categorical
person_and_household$hhsize_num <- recode(person_and_household$hhsize,
                                          "1 person" = 1,
                                          "2 people" = 2,
                                          "3 people" = 3,
                                          "4 people" = 4,
                                          "5 people" = 5,
                                          "6 people" = 6,
                                          "7 people" = 6,
                                          "8 people" = 6)

table(person_and_household$hhsize_num)

# household income [hhincome_broad]
freq(person_and_household$hhincome_broad)

person_and_household$hhincomeb_reordered <- factor(person_and_household$hhincome_broad, 
                                                   levels=c("Under $25,000","$25,000-$49,999",
                                                            "$50,000-$74,999","$75,000-$99,999",
                                                            "$100,000 or more","Prefer not to answer"))
table(person_and_household$hhincomeb_reordered)

# householder age
freq(person_and_household$lifecycle)
person_and_household$lifecycle <- as.factor(person_and_household$lifecycle)

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


# By default the first category is the reference.
table(person_and_household$vehicle_group) # 0 vehicles is reference
table(person_and_household$numworkers) # 0 workers is reference
table(person_and_household$hhincomeb_reordered) # Under $25k is reference
table(person_and_household$hh_race_2) # People of Color is reference
table(person_and_household$hh_license_cat) # 0 is reference
table(person_and_household$tenure_binary_reordered) # Own is reference
table(person_and_household$hh_size_cat) # 1 person is reference
table(person_and_household$hh_lifecycle) # Under age 35 is reference


# INDIVIDUAL PREDICTORS: SES factors and household vehicle ownership -----
# Multinomial Logit: SES factors and household vehicle ownership -----

# Potogolou and Susilo (2008): "results show that the multinomial logit model is the one to be selected for modeling the level of household car ownership over ordered logit and ordered probit"


# documentation about function: https://www.rdocumentation.org/packages/nnet/versions/7.3-14/topics/multinom

# factors from Cui study + additional: numworkers

# MULTINOMIAL LOGIT - categorical predictors rather than numerical ----
vehicle_multinom_cat <- multinom(vehicle_group ~ numworkers + 
                                  hhincomeb_reordered + hh_race_2 +
                                  hh_license_cat + tenure_binary_reordered +
                                  hh_size_cat + hh_lifecycle, 
                                data = person_and_household, Hess = T)
vehicle_multinom_cat

modelname <- "SES_multinom_cat"
stargazer(vehicle_multinom_cat, type= 'text', 
          out=paste0(parent_folder, modelname, "_", Sys.Date(),".txt"))

# relative risk ratios
multi1.rrr <-  exp(coef(vehicle_multinom_cat))

modelname <- "SES_multinom_cat_relriskratio"
stargazer(vehicle_multinom_cat, type="text", coef=list(multi1.rrr), p.auto=FALSE, 
          out=paste0(parent_folder, modelname, "_", Sys.Date(),".txt"))


# MULTINOMIAL LOGIT - numerical predictors rather than categorical ----
vehicle_multinom_num <- multinom(vehicle_group ~ numworkers + hhincomeb_reordered + 
                                  hh_race_2 + hh_license_num + tenure_binary_reordered + 
                                  hhsize_num + hh_lifecycle, 
                                data=person_and_household)
vehicle_multinom_num

modelname <- "SES_multinom_num"
stargazer(vehicle_multinom_num, type= 'text', 
          out=paste0(parent_folder, modelname, "_", Sys.Date(),".txt"))

# relative risk ratios
multi1.rrr <-  exp(coef(vehicle_multinom_num))

modelname <- "SES_multinom_num_relriskratio"
stargazer(vehicle_multinom_num, type="text", coef=list(multi1.rrr), p.auto=FALSE, 
          out=paste0(parent_folder, modelname, "_", Sys.Date(),".txt"))




# Ordered Logit: SES factors and household vehicle ownership -----

# Cui (2018): "it is not suitable to use the multinomial logit model, so this paper uses the ordered logistic regression model"


# ORDERED LOGIT - categorical predictors rather than numeric ----
vehicle_ordered_cat <-polr(as.factor(vehicle_group) ~ numworkers + hhincomeb_reordered + 
                             hh_race_2 + hh_license_cat + tenure_binary_reordered + 
                             hh_size_cat + hh_lifecycle,
                           data=person_and_household, Hess = T)
summary(vehicle_ordered_cat)
# odds ratio
exp(coef(vehicle_ordered_cat))

modelname <- "SES_ordered_cat"
stargazer(vehicle_ordered_cat, type= 'text',
          out=paste0(parent_folder, modelname, "_", Sys.Date(),".txt"))

# add p-values store table
ctable <- coef(summary(vehicle_ordered_cat))
# calculate and store p values
p <- round(pnorm(abs(ctable[,"t value"]), lower.tail = F)*2,2)
# combined table
ctable <-cbind(ctable, "p value"=p)


# ORDERED LOGIT - numerical predictors rather than character ----
vehicle_ordered_num <-polr(as.factor(vehicle_group) ~ numworkers + hhincomeb_reordered + 
                            hh_race_2 + hh_license_num + tenure_binary_reordered + 
                            hhsize_num + hh_lifecycle, 
                          data=person_and_household, Hess = T)
summary(vehicle_ordered_num)
# convert coefficients into odd radios
exp(coef(vehicle_ordered_num))

modelname <- "SES_ordered_num"
stargazer(vehicle_ordered_num, type= 'text', 
          out=paste0(parent_folder, modelname, "_", Sys.Date(),".txt"))

# add p-values store table
ctable <- coef(summary(vehicle_ordered_num))
# calculate and store p values
p <- round(pnorm(abs(ctable[,"t value"]), lower.tail = F)*2,2)
# combined table
ctable <-cbind(ctable, "p value"=p)


# Correlation Matrix -----
correl_data <- person_and_household %>%
  dplyr::select(vehicle_group, numworkers, hh_license_num, hhsize_num) %>%
  glimpse()
cor_SES_matrix <- round(cor(x = as.matrix(correl_data), 
                      method = "pearson", use = "pairwise.complete.obs"),3)

# Significance levels (p-values)
library(Hmisc)
install.packages("RcmdrMisc")
library(RcmdrMisc)

correl_data.rcorr  <-  rcorr.adjust(as.matrix(correl_data))
correl_data.rcorr
# # Extract the correlation coefficients
# correl_data.rcorr$r
# # Extract p-values
# correl_data.rcorr$P



# Interactions: PREDICTORS -----
# correlation between hh size (hhsize_num), license (hh_license_num), and workers (numworkers) impacting household vehicle ownership
# plot - survey household size (up to 9), household license (up to 6)
ggplot(person_and_household, 
       aes(x=hh_license, y=numworkers, color=hhsize)) + 
  geom_jitter(alpha=0.5, shape=1) +
  scale_x_continuous(breaks=seq(0,8,1)) +
  scale_y_continuous(breaks=seq(0,8,1)) +
  labs(x = "# Household Licenses", 
       y = "# Household Workers",
       color = "Household Size",
       title = "Interactions between Model Predictors")

# plot - simplified household size (6+), household license (4+) 
ggplot(person_and_household, 
       aes(x=hh_license_num, y=numworkers, color=hhsize_num)) + 
  geom_jitter(alpha=0.5) +
  scale_x_continuous(breaks=seq(0,5,1)) +
  scale_y_continuous(breaks=seq(0,7,1)) +
  labs(x = "Number of Household Licenses", 
       y = "Number of Household Workers",
       color = "Household Size",
       title = "Interactions between Model Predictors") + 
  geom_smooth(method='lm', formula= y~x)

# proportion of workers with licenses - add field
freq(person_and_household$hh_license)
freq(person_and_household$numworkers)

person_and_household <- person_and_household %>%
  mutate(workers_license = hh_license/numworkers) 
freq(person_and_household$workers_license)
# >1: more licenses than workers ()
# <1: fewer licenses than workers ()



# Models With Interactions: explore two-factor interactions
# https://data.princeton.edu/wws509/r/c6s5 

# simplified - numerical values
# compare each model against the additive to focus on the improvement
deviance(vehicle_ordered_num) - deviance(update(vehicle_ordered_num, . ~ . + numworkers:hh_license_num)) #44.75

deviance(vehicle_ordered_num) - deviance(update(vehicle_ordered_num, . ~ . + numworkers:hhsize_num)) #37.46

deviance(vehicle_ordered_num) - deviance(update(vehicle_ordered_num, . ~ . + hh_license_num:hhsize_num)) #69.09

# The interaction between household licenses and household size reduces the deviance by 69. The interaction between household workers and household licenses makes a smaller dent of 45, and the interaction between household licenses and household size is smaller at 37.


# To examine parameter estimates we refit the ordered logit model
polr(as.factor(vehicle_group) ~ numworkers + hhincomeb_reordered + hh_race_2 + 
       hh_license_num + tenure_binary_reordered + hhsize_num + hh_lifecycle + 
       hh_license_num*numworkers,
     data=person_and_household, Hess = T)

# checking AIC for different interactions of three predictor variables 
# in interaction term - ":" is the same as "*"
# hh_license_num:hhsize_num:20222
# hh_license_num:numworkers: 20247
# hhsize_num:numworkers: 20254
# without interaction: 20289






# fit model with 3-way-interaction
library(jtools) # for summ()
fiti_1 <- lm(vehicle_group ~ numworkers * hhsize_num + hh_license_num, 
             data = person_and_household)
summ(fiti_1)

fiti_2 <- lm(vehicle_group ~ hhsize_num * hh_license_num + numworkers, 
             data = person_and_household)
summ(fiti_2)

fiti_3 <- lm(vehicle_group ~ hh_license_num * numworkers + hhsize_num, 
             data = person_and_household)
summ(fiti_3)

fiti_4 <- lm(vehicle_group ~ hh_license_num * numworkers * hhsize_num, 
             data = person_and_household)
summ(fiti_4)

interact_plot(fiti_1, pred = numworkers, modx = hhsize_num)
interact_plot(fiti_2, pred = hhsize_num, modx = hh_license_num)
interact_plot(fiti_3, pred = hh_license_num, modx = numworkers)


interact_plot(fiti_1, pred = numworkers, modx = hhsize_num, partial.residuals = TRUE)


# Woolf's test for interaction (also known as Woolf's test for the homogeneity of odds ratios) provides a formal test for Interaction
# https://tbrieder.org/epidata/course_e_ex03_task.pdf
# Test for interaction, using the script for
# Woolf's test provided by Mark Myatt

tabofl <- table(person_and_household$hhsize_num, 
                person_and_household$vehicle_group, 
                person_and_household$hh_license_num)
woolf.test(tabofl)


# https://daviddalpiaz.github.io/appliedstats/categorical-predictors-and-interactions.html#building-larger-models
plot(vehicle_group ~ numworkers, data = person_and_household, cex = 2)

plot1 = lm(vehicle_group ~ numworkers, data = person_and_household)
plot(vehicle_group ~ numworkers, data = person_and_household, cex = 2)
abline(plot1, lwd = 3, col = "grey")

plot2 = lm(vehicle_group ~ hhsize_num, data = person_and_household)
plot(vehicle_group ~ hhsize_num, data = person_and_household, cex = 2)
abline(plot2, lwd = 3, col = "grey")

plot3 = lm(vehicle_group ~ hh_license_num, data = person_and_household)
plot(vehicle_group ~ hh_license_num, data = person_and_household, cex = 2)
abline(plot3, lwd = 3, col = "grey")
