library(data.table)
library(stringr)
library(travelSurveyTools)
library(psrcelmer)
library(dplyr)
library(psrcplot)
library(tidyverse)
library(ggplot2)

source("C:/temp/2023/summary/transit/survey-23-preprocess.R")

## Read in codebook

cb_path = str_glue("J:/Projects/Surveys/HHTravel/Survey2023/Data/data_published/PSRC_Codebook_2023_v1.xlsx")

variable_list = readxl::read_xlsx(cb_path, sheet = 'variable_list')
value_labels = readxl::read_xlsx(cb_path, sheet = 'value_labels')

setDT(variable_list)
setDT(value_labels)

## Read in data from Elmer

hh <- get_query(sql = "SELECT household_id as hh_id, num_trips AS h_num_trips, hhsize, vehicle_count, hhincome_broad,
                       home_rgcname, home_county, survey_year, hh_weight
                       FROM HHSurvey.v_households_labels;")

person <- get_query(sql = "SELECT person_id, household_id as hh_id, num_trips AS p_num_trips, age, gender, race_category, disability_person, consolidated_transit_pass, industry,
                           employment, workplace, transit_freq, commute_freq, commute_mode, work_mode, survey_year, person_weight, student
                           FROM HHSurvey.v_persons_labels;")

trip <- get_query(sql = "SELECT trip_id, household_id as hh_id, person_id, origin_x_coord, origin_y_coord, origin_county, origin_rgcname,
                         dest_x_coord, dest_y_coord, dest_county, dest_rgcname, distance_miles, duration_minutes,
                         origin_purpose_cat, origin_purpose, dest_purpose, mode_acc,
                         mode_type, mode_1, mode_characterization, mode_simple, travelers_total, travelers_hh,
                         survey_year, trip_weight 
                         FROM HHSurvey.v_trips_labels
                         WHERE travel_dow NOT IN ('Friday', 'Saturday', 'Sunday');")

setDT(hh)
setDT(person)
setDT(trip)


## Set IDs as character type

hh[, hh_id := as.character(hh_id)]

person[, hh_id := as.character(hh_id)]
person[, person_id := as.character(person_id)]

trip[, hh_id := as.character(hh_id)]
trip[, person_id := as.character(person_id)]
trip[, trip_id := as.character(trip_id)]

hh[, survey_year := as.character(survey_year)]
person[, survey_year := as.character(survey_year)]
trip[, survey_year := as.character(survey_year)]

## Get unique modes from trips

trip_modes <- unique(trip[, c("mode_1", "mode_type", "mode_characterization", "mode_simple")])

# add mode_simple to variables list
# variable_list <- add_variable(variable_list, "mode_simple", "trip")
# group_labels <- get_grouped_labels(group_id = "group_1", group_name = "mode_simple")
# value_labels <- add_values_code(group_name = "mode_simple")

## Based on the modes in the trip data, will need to filter on `mode_characterization` to remove "Airplane"
## Remove Airplane

trip <- filter(trip, mode_characterization != "Airplane")


## Adding a new variable to the codebook
##make a function with bunch of default #to do make this easier

variable_list<-rbind(
    variable_list,
    data.table(
      variable = "mode_characterization",
      is_checkbox = c(0,0),
      hh = c(0,0),
      person = c(0,0),
      day = c(0,0),
      trip = c(1,1),
      vehicle = c(0,0),
      location = c(0,0),
      description = "mode aggregation",
      logic = "mode aggregation",
      data_type = "integer/categorical",
      shared_name = "mode_characterization"
    )
  )

# Add associated values

# A few more questions came up about transit for TOC and TOD.
# 
# Transit Access Mode
# - 2023
# and trend
# Transit Trips by purpose
# -2023
# and trend
# 
# The intersection between work at home and transit use.
# Work location by number of trips by mode
# 
# Transit Access Mode

hh_data<-
  list(hh=hh, person=person, day=day, trip=trip)
ids = c('hh_id', 'person_id', 'day_id', 'trip_id')
wts = c('hh_weight', 'person_weight', 'day_weight', 'trip_weight')

variable_list<-add_variable(variable_list, 'mode_acc_1','trip')
group_labels<-get_grouped_labels(group_id='group_1', group_name='mode_acc_1')
value_labels<-add_values_code(group_name='mode_acc_1')
trip<-grp_to_tbl(tbl=trip, ungrouped_name='mode_acc', grouped_name='mode_acc_1')

#some how a duplicate snuck into the variable list not sure how
variable_list<-variable_list%>%distinct(variable, .keep_all=TRUE)

transit_trips<-trip%>%filter(mode_characterization=='Transit')%>%filter(!mode_acc_1 %in% c("Missing", "Transfer"))%>%drop_na(mode_acc_1)

## very many missing data points...

access_mode<-transit_trips%>%group_by(survey_year, mode_acc, mode_characterization)%>%summarize(n=n())
#write.csv(access_mode, 'access_mode.csv')

hh_transit_data<-
  list(hh=hh, person=person, day=day, trip=transit_trips)
ids = c('hh_id', 'person_id', 'day_id', 'trip_id')
wts = c('hh_weight', 'person_weight', 'day_weight', 'trip_weight')


output <- summarize_weighted(hts_data= hh_transit_data,
                             summarize_var = 'mode_acc',
                             summarize_by = c('survey_year'),
                             id_cols=ids,
                             wt_cols=wts,
                             wtname= 'trip_weight'
)


output_summary<-output$summary$wtd%>%mutate(moe=prop_se*1.645)
static<-static_column_chart(output_summary, y='prop', x='survey_year', fill='mode_acc_1', color='pognbgy_10', pos='stack') + theme(axis.text.x=element_text(size=16), axis.text.y=element_text(size=16),legend.text = element_text(size=16), axis.title.y=element_text(size=20), axis.title.x=element_text(size=20))


output <- summarize_weighted(hts_data= hh_transit_data,
                             summarize_var = 'mode_acc_1',
                             summarize_by = c('survey_year', 'dest_purpose_simpler'),
                             id_cols=ids,
                             wt_cols=wts,
                             wtname= 'trip_weight'
)


output_summary<-output$summary$wtd%>%mutate(moe=prop_se*1.645)%>%filter(survey_year=='2023')
static<-static_column_chart(output_summary, y='prop', x='dest_purpose_simpler', fill='mode_acc_1', color='pognbgy_10', pos='stack') + theme(axis.text.x=element_text(size=16), axis.text.y=element_text(size=16),legend.text = element_text(size=16), axis.title.y=element_text(size=20), axis.title.x=element_text(size=20))


output <- summarize_weighted(hts_data= hh_transit_data,
                             summarize_var = 'mode_acc_1',
                             summarize_by = c('survey_year', 'homegeog'),
                             id_cols=ids,
                             wt_cols=wts,
                             wtname= 'trip_weight'
)


output_summary<-output$summary$wtd%>%mutate(moe=prop_se*1.645)%>%filter(survey_year=='2023')
static<-static_column_chart(output_summary, y='prop', x='homegeog', fill='mode_acc_1', color='pognbgy_10', pos='stack') + theme(axis.text.x=element_text(size=16), axis.text.y=element_text(size=16),legend.text = element_text(size=16), axis.title.y=element_text(size=20), axis.title.x=element_text(size=20))

transit_trips<-trip%>%filter(mode_characterization=='Transit')


hh_transit_data<-
  list(hh=hh, person=person, day=day, trip=transit_trips)
ids = c('hh_id', 'person_id', 'day_id', 'trip_id')
wts = c('hh_weight', 'person_weight', 'day_weight', 'trip_weight')


output <- summarize_weighted(hts_data= hh_transit_data,
                             summarize_var = 'dest_purpose_simplest',
                             summarize_by = c('survey_year'),
                             id_cols=ids,
                             wt_cols=wts,
                             wtname= 'trip_weight'
)

# Percent of transit trips by broad purpose

output_summary<-output$summary$wtd%>%mutate(moe=prop_se*1.645)%>%filter(dest_purpose_simplest!='Missing')
static<-static_column_chart(output_summary, y='prop', x='survey_year', fill='dest_purpose_simplest', color='pognbgy_10', pos='stack') + theme(axis.text.x=element_text(size=16), axis.text.y=element_text(size=16),legend.text = element_text(size=16), axis.title.y=element_text(size=20), axis.title.x=element_text(size=20))


# Percent of transit trips by broad purpose

output_summary<-output$summary$wtd%>%mutate(moe=prop_se*1.645)%>%filter(dest_purpose_simplest!='Missing')
static<-static_column_chart(output_summary, y='est', x='survey_year', fill='dest_purpose_simplest', color='pognbgy_10', pos='stack') + theme(axis.text.x=element_text(size=16), axis.text.y=element_text(size=16),legend.text = element_text(size=16), axis.title.y=element_text(size=20), axis.title.x=element_text(size=20))



work_trips<-trip%>%filter(grepl("Work"))
worker_data<-
  list(hh=hh, person=workers, day=day, trip=work_trips)
ids = c('hh_id', 'person_id', 'day_id', 'trip_id')
wts = c('hh_weight', 'person_weight', 'day_weight', 'trip_weight')



output <- summarize_weighted(hts_data= worker_data,
                             summarize_var = 'mode_characterization',
                             summarize_by = c('survey_year', 'workgeog'),
                             id_cols=ids,
                             wt_cols=wts,
                             wtname= 'trip_weight'
)


output_summary<-output$summary$wtd%>%mutate(moe=prop_se*1.645)%>%mutate(workgeog=factor(workgeog, levels=c('Kitsap', 'Pierce','Snohomish-King Suburban', 'Seattle Outside Downtown', 'Bellevue','Seattle Downtown')))%>%filter(!is.na(workgeog))%>%filter(survey_year==2023)
static<-static_column_chart(output_summary, y='est', x='mode_characterization', fill='workgeog',color='pognbgy_10', pos='stack') + theme(axis.text.x=element_text(size=16), axis.text.y=element_text(size=16),legend.text = element_text(size=16), axis.title.y=element_text(size=20), axis.title.x=element_text(size=20))


## add mode_drive to the trip table

trip<- trip%>%mutate(travelers_total_fix= ifelse(travelers_total!='1 traveler', 'More than 1', '1 traveler'))
trip<-trip%>%mutate(mode_simple= replace_na(mode_simple, 'Drive'))%>%
mutate(mode_w_sov=case_when(
  mode_simple=="Drive"& travelers_total=='1 traveler' ~ 'SOV',
  is.na(travelers_total) ~ 'SOV',
  mode_simple=="Drive"& travelers_total!='1 traveler'~  'HOV',
  .default= mode_simple
))

#add mode_acc_1 to variables list
variable_list<-add_variable(variable_list, 'mode_acc_1','trip')
group_labels<-get_grouped_labels(group_id='group_1', group_name='mode_acc_1')
value_labels<-add_values_code(group_name='mode_acc_1')
trip<-grp_to_tbl(tbl=trip, ungrouped_name='mode_acc', grouped_name='mode_acc_1')

#add dest_purpose_simple to variables list
variable_list<-add_variable(variable_list, 'dest_purpose_simple','trip')
group_labels<-get_grouped_labels(group_id='group_1', group_name='dest_purpose_simple')
value_labels<-add_values_code(group_name='dest_purpose_simple')
trip<-grp_to_tbl(tbl=trip, ungrouped_name='dest_purpose', grouped_name='dest_purpose_simple')

#work_mode to variables list
variable_list <- add_variable(variable_list, "work_mode", "person") 
group_labels <- get_grouped_labels(group_id = "group_1", group_name = "work_mode") 
value_labels <- add_values_code(group_name = "work_mode") 
person<-grp_to_tbl(tbl=person, ungrouped_name="work_mode", grouped_name="work_mode")

## Get transit_freq

# add transit_freq to variables list
variable_list <- add_variable(variable_list, "transit_freq", "person") 
group_labels <- get_grouped_labels(group_id = "group_1", group_name = "transit_freq") 
value_labels <- add_values_code(group_name = "transit_freq") 
person<-grp_to_tbl(tbl=person, ungrouped_name="transit_freq", grouped_name="transit_freq")

### Get Gender
#gender
variable_list <- add_variable(variable_list,
                              variable_name = "gender",
                              table_name = "person",
                              data_type = "character")  

#dest_purpose
variable_list <- add_variable(variable_list, "dest_purpose", "trip")  
group_labels <- get_grouped_labels(group_id = "group_1", group_name = "dest_purpose") 
value_labels <- add_values_code(group_name = "dest_purpose")  
trip<-grp_to_tbl(tbl=trip, ungrouped_name="dest_purpose", grouped_name="dest_purpose") 


# add dest_purpose to variables list
# 
# variable_list <- add_variable(variable_list, "dest_purpose_simple", "trip")  
# group_labels <- get_grouped_labels(group_id = "group_1", group_name = "dest_purpose_simple") 
# value_labels <- add_values_code(group_name = "dest_purpose_simple")  
# trip<-grp_to_tbl(tbl=trip, ungrouped_name="dest_purpose", grouped_name="dest_purpose_simple") 


## Get Industry
# add industry_cond to variables list 

variable_list <- add_variable(variable_list, "industry_cond", "person")
group_labels <- get_grouped_labels(group_id = "group_1", group_name = "industry_cond")
value_labels <- add_values_code(group_name = "industry_cond")
person<-grp_to_tbl(tbl=person, ungrouped_name="industry", grouped_name="industry_cond")

## Get Commute Pass
# add consolidated_transit_pass to variables list  
variable_list <- add_variable(variable_list, "consolidated_transit_pass", "person")
group_labels <- get_grouped_labels(group_id = "group_1", group_name = "consolidated_transit_pass") 
value_labels <- add_values_code(group_name = "consolidated_transit_pass") 
person<-grp_to_tbl(tbl=person, ungrouped_name="consolidated_transit_pass", grouped_name="consolidated_transit_pass")

# add age_category to variables list  
variable_list <- add_variable(variable_list, "age_category", "person")
group_labels <- get_grouped_labels(group_id = "group_1", group_name = "age_category") 
value_labels <- add_values_code(group_name = "age_category") 
person<-grp_to_tbl(tbl=person, ungrouped_name="age", grouped_name="age_category")

# add student to variables list  
variable_list <- add_variable(variable_list, "student", "person")
group_labels <- get_grouped_labels(group_id = "group_1", group_name = "student") 
value_labels <- add_values_code(group_name = "student") 
person<-grp_to_tbl(tbl=person, ungrouped_name="student", grouped_name="student")


## Summaries

#remove duplicates
variable_list<-variable_list%>%distinct(variable, .keep_all=TRUE)

#add age_condensed
variable_list <- add_variable(variable_list, 
                              variable_name = "age_condensed",
                              table_name = "person", 
                              data_type = "character")  

person <- person %>%    
  mutate(age_condensed = case_when(age %in% c("Under 5 years old", "5-11 years", "12-15 years", "16-17 years") ~ "Under 18 years old", age %in% c("18-24 years", "25-34 years") ~ "18-34 years", age %in% c("35-44 years", "45-54 years", "55-64 years") ~ "35-64 years", age %in% c("65-74 years", "75-84 years", "85 or years older") ~ "65 years or older")) %>% mutate(age_condensed = factor(age_condensed, levels = c("Under 18 years old", "18-34 years", "35-64 years", "65 years or older")))

#add mode_condensed
variable_list <- add_variable(variable_list, 
                              variable_name = "mode_condensed",
                              table_name = "trip", 
                              data_type = "character")  

trip <- trip %>%   
   mutate(mode_condensed = case_when(mode_characterization %in% c("Drive HOV2", "Drive HOV3+", "Drive SOV") ~ "Drive", mode_characterization %in% c("Bike/Micromobility") ~ "Bike/Micromobility", mode_characterization %in% c("Transit") ~ "Transit", mode_characterization %in% c("Walk") ~ "Walk")) %>% mutate(mode_condensed = factor(mode_condensed, levels = c("Bike/Micromobility", "Drive", "Transit", "Walk")))
 

#add purp_condensed
variable_list <- add_variable(variable_list, 
                              variable_name = "purp_condensed",
                              table_name = "trip", 
                              data_type = "character")  

trip <- trip %>%   
   mutate(purp_cond = case_when(dest_purpose %in% c("Went to school/daycare (e.g., daycare, K-12, college)", "Attend K-12 school",
                                                         "Attend daycare or preschool", "Attend vocational education class"
                                                         ) ~ "School", 
                                     dest_purpose %in% c("Went to work-related place (e.g., meeting, second job, delivery)", "Went to primary workplace",
                                                         "Went to other work-related activity", "Went to work-related activity (e.g., meeting, delivery, worksite)"
                                                         ) ~ "Work", 
                                     dest_purpose %in% c("Went home", "Went to another residence (e.g., someone else's home, second home)",
                                                         "Went to temporary lodging (e.g., hotel, vacation rental)") ~ "Go Home", 
                                     dest_purpose %in% c("Conducted personal business (e.g., bank, post office)", "Went to other shopping (e.g., mall, pet store)",
                                                         "Dropped off/picked up someone (e.g., son at a friend's house, spouse at bus stop)", "Went to medical appointment (e.g., doctor, dentist)", 
                                                         "Went grocery shopping", "Other purpose", "Other appointment/errands (rMove only)",
                                                         "Transferred to another mode of transportation (e.g., change from ferry to bus)",
                                                         "Personal business (e.g., bank, post office)", "Other activity only (e.g., attend meeting, pick-up or drop-off item)",
                                                         "Pick someone up", "Grocery shopping", "Drop someone off", "Other shopping (e.g., mall, pet store)",
                                                         "Medical appointment (e.g., doctor, dentist)", "Other appointment/errands", "Got gas",
                                                         "Other reason", "Accompany someone only (e.g., go along for the ride)", "BOTH pick up AND drop off",
                                                         "Changed or transferred mode (e.g., change from ferry to bus)", "Appointment, shopping, or errands (e.g., gas)",
                                                         "other") ~ "Shopping/Errands", 
                                     dest_purpose %in% c("Went to religious/community/volunteer activity", "Social, leisure, religious, entertainment activity", 
                                                         "Went to restaurant to eat/get take-out", "Attended recreational event (e.g., movies, sporting event)",
                                                         "Attended social event (e.g., visit with friends, family, co-workers)",
                                                         "Went to exercise (e.g., gym, walk, jog, bike ride)", "Other social/leisure (rMove only)",
                                                         "Went to a family activity (e.g., child's softball game)", "Recreational event (e.g., movies, sporting event)",
                                                         "Exercise or recreation (e.g., gym, jog, bike, walk dog)", "Social event (e.g., visit friends, family, co-workers)",
                                                         "Other social/leisure", "Volunteering", "Religious/civic/volunteer activity", "Attend other type of class (e.g., cooking class)",
                                                         "Attend college/university", "Attend other education-related activity (e.g., field trip)",
                                                         "Vacation/Traveling (rMove only)") ~ "Social/Recreation",
                                     dest_purpose %in% c("Missing: Non-response", "NA") ~ "Missing")) 

## Gender

variable_list <- add_variable(variable_list,
                              variable_name = "gender_group",
                              table_name = "person",
                              data_type = "character")

person <- person %>% 
  mutate(gender_group = case_when(gender == "Girl/Woman (cisgender or transgender)" ~ "Female",
                                  gender == "Boy/Man (cisgender or transgender)" ~ "Male",
                                  gender %in% c("Non-Binary", "Non-binary/Something else fits better", "Another") ~ "Non-Binary/Other",
                                  gender == "Not listed here / prefer not to answer" ~ "Prefer not to answer",
                                  TRUE ~ gender))



#income_variable

variable_list <- add_variable(variable_list,
                              variable_name = "hhincome_broad_combined", 
                              table_name = "hh", 
                              data_type = "character")  

hh <- hh %>%    
      mutate(hhincome_broad_combined = ifelse(hhincome_broad %in% c("$100,000-$199,000", "$200,000 or more"), "$100,000 or more", hhincome_broad)) %>% mutate(hhincome_broad_combined = factor(hhincome_broad_combined, levels = c("Under $25,000", "$25,000-$49,999", "$50,000-$74,999", "$75,000-$99,999", "$100,000 or more", "Prefer not to answer")))

variable_list <- add_variable(variable_list,
                              variable_name = "hhincome_broad_combined2", 
                              table_name = "hh", 
                              data_type = "character")  

#vehicle_ownership
variable_list <- add_variable(variable_list, 
                              variable_name = "vehicle_ownership", 
                              table_name = "hh", 
                              data_type = "character")  

hh <- hh %>%    
  mutate(vehicle_ownership = ifelse(vehicle_count == "0 (no vehicles)", "Not a vehicle owner", "Vehicle owner"))

## data exploration for zero vehicle households

# hh_test <- hh %>%
#   filter(vehicle_count == "0 (no vehicles)")
# 
# aggregate(hh_test$hh_weight, by=list(survey_year=hh_test$survey_year), FUN=sum)
# 
# # count zero vehicle households
# hh_count <- hh %>%
#    count(vehicle_count == "0 (no vehicles)")

# hh_total <- hh_test %>%
#   mutate(Num = readr::parse_number(hhsize))
# 
# aggregate(hh_total$Num, by=list(survey_year=hh_total$survey_year), FUN=sum)
# 
# person_w <- person %>%
#   select("person_id", "hh_id", "person_weight")
# 
# person_W_noveh <- left_join(hh_total, person_w, by = "hh_id")
# 
# aggregate(person_W_noveh$person_weight, by=list(survey_year=person_W_noveh$survey_year), FUN=sum)


##Summary

hts_data <- list(hh = hh, 
                 person = person,
                 trip = trip) 
ids <- c("hh_id", "person_id", "trip_id") 
wts <- c("hh_weight", "person_weight", "trip_weight") 

#remove duplicates
variable_list<-variable_list%>%distinct(variable, .keep_all=TRUE)

#mode_simple
# summary_trips_simple <- summarize_weighted(hts_data = hts_data, 
#                                     summarize_var = "mode_simple", 
#                                     summarize_by = "survey_year",
#                                     id_cols = ids, 
#                                     wt_cols = wts, 
#                                     wtname = "trip_weight")  
# 
# mode_summary_simple <- summary_trips_simple$summary$wtd %>% 
#   mutate(moe = prop_se * 1.645)
# 
# mode_summary_simple <- mode_summary_simple %>%
#   filter(mode_simple != "NA")

#mode_characterization
summary_trips <- summarize_weighted(hts_data = hts_data,
                                    summarize_var = "mode_characterization",
                                    summarize_by = "survey_year",
                                    id_cols = ids,
                                    wt_cols = wts,
                                    wtname = "trip_weight"
                                    )

mode_summary <- summary_trips$summary$wtd %>% 
  mutate(moe_p = prop_se * 1.645) %>%
  mutate(moe_e = est_se * 1.645)

transit <- mode_summary %>% filter(mode_characterization == "Transit")


#transit_frequency
summary_transit <- summarize_weighted(hts_data = hts_data,
                                    summarize_var = "transit_freq",
                                    summarize_by = "survey_year",
                                    id_cols = ids,
                                    wt_cols = wts,
                                    wtname = "trip_weight"
                                    )

transit_summary <- summary_transit$summary$wtd %>% 
  mutate(moe = prop_se * 1.645) 

#gender
transit_freq_gender <- summarize_weighted(hts_data = hts_data,
                                       summarize_var = "mode_characterization",
                                       summarize_by = c("survey_year", "gender"),
                                       id_cols = ids,
                                       wt_cols = wts,
                                       wtname = "person_weight"
                                       )

transit_gender_summary <- transit_freq_gender$summary$wtd %>%
  mutate(moe = prop_se * 1.645)

#gender_transit_chart
static_column_chart(filter(transit_gender_summary, mode_characterization == "Transit"),                     
                    x = "gender", y = "prop", fill = "survey_year",                     
                    ylabel = "% of Trips", xlabel = "Survey Year", title = "Transit Trips by Gender - Share",
                    moe = "moe") + theme(                       axis.text.x = element_text(size = 14),  
                                                                axis.text.y = element_text(size = 14),
                                                                axis.title.y = element_text(size = 20),
                                                                axis.title.x = element_text(size = 20),
                                                                legend.text = element_text(size=14), 
                                                                plot.title = element_text(size = 24)  
                    )

### Mode Share by Purpose

##Looking at walking and biking trips by trip purpose: "utility" trips (work, shopping, errands, etc.) versus recreational trips

# dest_purpose_counts <- trip %>%  #   group_by(survey_year, dest_purpose_cat) %>%  #   summarize(count = NROW(trip_id))  

#trip_purpose_type
mode_by_purpose <- summarize_weighted(hts_data = hts_data,                                       
                                      summarize_var = "mode_characterization",
                                      summarize_by = c("survey_year", "dest_purpose_simple"),
                                      id_cols = ids,                                       
                                      wt_cols = wts,                                      
                                      wtname = "trip_weight"                                       )  

purpose_summary <- mode_by_purpose$summary$wtd %>%
  mutate(moe = prop_se * 1.645)

#access
access <- summarize_weighted(hts_data = hts_data,                                       
                                      summarize_var = "mode_characterization",
                                      summarize_by = c("survey_year", "mode_acc_1"),
                                      id_cols = ids,                                       
                                      wt_cols = wts,                                      
                                      wtname = "trip_weight"                                       )  

access_summary <- access$summary$wtd %>%
  mutate(moe = prop_se * 1.645)

access_summary <- access_summary %>%
  filter(mode_characterization == "Transit") %>%
  filter(mode_acc_1 != "NA") %>%
  filter(mode_acc_1 != "Missing")

#walk and bike/micromobility
walk_bike_by_purpose <- mode_by_purpose$summary$wtd %>%    
  filter(mode_characterization %in% c("Walk", "Bike/Micromobility") & !(is.na(trip_purpose_type))) %>%    
  mutate(moe = prop_se * 1.645)


#walk_trip_purpose_chart
static_column_chart(filter(purpose_summary, mode_characterization == "Transit"),                     
                    x = "survey_year", y = "prop", fill = "dest_purpose_simple",                     
                    ylabel = "% of Trips", xlabel = "Survey Year", title = "Transit Trips by Purpose - Share",
                    moe = "moe") + theme(                       axis.text.x = element_text(size = 14),  
                                                                axis.text.y = element_text(size = 14),
                                                                axis.title.y = element_text(size = 20),
                                                                axis.title.x = element_text(size = 20),
                                                                legend.text = element_text(size=14), 
                                                                plot.title = element_text(size = 24)  
                    )

# hts_data$trip <- hts_data$trip %>%    
#   mutate(trip_purpose_type = case_when(dest_purpose_simple == "Social/Recreation" ~ "Recreation Trips",                                        dest_purpose_simple %in% c("Missing: Non-response", "Not imputable", "Home") ~ NA_character_,                                        is.na(dest_purpose_simple) ~ NA_character_,                                        TRUE ~ "Utility Trips"))



#transit and walk
tandw <- c("Transit", "Walk")

transitandwalk <- mode_summary %>% filter(mode_characterization %in% tandw)
 
#rgcs
summary_trips_centers <- summarize_weighted(hts_data = hts_data,
                                    summarize_var = "work_mode",
                                    summarize_by=c("survey_year","home_rgcname"),
                                    id_cols = ids,
                                    wt_cols = wts,
                                    wtname = "trip_weight"
                                    )

mode_summary_centers <- summary_trips_centers$summary$wtd %>%
  mutate(moe = prop_se * 1.645)

#origin rgc
summary_origin_centers <- summarize_weighted(hts_data = hts_data,
                                    summarize_var = "work_mode",
                                    summarize_by=c("survey_year","origin_rgcname"),
                                    id_cols = ids,
                                    wt_cols = wts,
                                    wtname = "trip_weight"
                                    )

mode_origin_centers <- summary_origin_centers$summary$wtd %>%
  mutate(moe = prop_se * 1.645)

#destination rgc
summary_dest_centers <- summarize_weighted(hts_data = hts_data,
                                             summarize_var = "work_mode",
                                             summarize_by=c("survey_year","dest_rgcname"),
                                             id_cols = ids,
                                             wt_cols = wts,
                                             wtname = "trip_weight"
)

mode_dest_centers <- summary_dest_centers$summary$wtd %>%
  mutate(moe = prop_se * 1.645)

#clean up
transit_centers <- mode_origin_centers %>%
  mutate(work_mode2 = case_when(work_mode %in% c("Commuter rail (Sounder, Amtrak)", "Bus (public transit)", "Rail (e.g., train, subway)", 
                                                   "Bus, shuttle, or vanpool (public transit, private service, or shuttles for older adults and people with disabilities",
                                                   "Ferry or water taxi", "Streetcar", "Urban rail (Link light rail, monorail)", 	
                                                   "Urban rail (Link light rail, monorail, streetcar", "Paratransit") ~ "Transit",
         work_mode %in% c("Bicycle or e-bicycle", "Bicycle or e-bike", "Scooter or e-scooter (e.g., Lime, Bird, Razor)",
                                                "Scooter, moped, skateboard") ~ "Bike/Micromobility", 
         work_mode %in% c("Carpool ONLY with other household members", "Carpool with other people not in household (may also include household members)", 
                                                "Drive alone", "Household vehicle (or motorcycle)", "Motorcycle/moped", 
                                                "Motorcycle/moped/scooter", "Other hired service (Uber, Lyft, or other smartphone-app car service)", 	
                                                "Other vehicle (e.g., friend's car, rental, carshare, work car)", "Private bus or shuttle",
                                                "Taxi (e.g., Yellow Cab)", "Uber/Lyft, taxi, or car service", "Vanpool") ~ "Drive",
         work_mode %in% c("Walk (or jog/wheelchair)", "Walk, jog, or wheelchair") ~ "Walk",
         work_mode %in% c("Other (e.g. skateboard)", "Other") ~ "Other",
         work_mode %in% c("Missing: Skip Logic") ~ "Missing")) %>%
  mutate(RGC = case_when(origin_rgcname != "Not RGC" ~ "RGC", origin_rgcname == "Not RGC" ~ "Not RGC")) %>%
     group_by(RGC == "RGC") %>%
  mutate(rgc_tot = sum(est)) %>%
  mutate(moe = prop_se * 1.645)

transit_centers_test <- transit_centers %>%
  group_by(RGC == "Not RGC") %>%
  mutate(notrgc_tot = sum(est))
         
         
  group_by(work_mode2 == "Transit") %>%
  mutate(transit_tot = sum(est))
  
transit_centers_dest <- mode_dest_centers %>%
    mutate(work_mode2 = case_when(work_mode %in% c("Commuter rail (Sounder, Amtrak)", "Bus (public transit)", "Rail (e.g., train, subway)", 
                                                   "Bus, shuttle, or vanpool (public transit, private service, or shuttles for older adults and people with disabilities",
                                                   "Ferry or water taxi", "Streetcar", "Urban rail (Link light rail, monorail)", 	
                                                   "Urban rail (Link light rail, monorail, streetcar", "Paratransit") ~ "Transit",
                                  work_mode %in% c("Bicycle or e-bicycle", "Bicycle or e-bike", "Scooter or e-scooter (e.g., Lime, Bird, Razor)",
                                                   "Scooter, moped, skateboard") ~ "Bike/Micromobility", 
                                  work_mode %in% c("Carpool ONLY with other household members", "Carpool with other people not in household (may also include household members)", 
                                                   "Drive alone", "Household vehicle (or motorcycle)", "Motorcycle/moped", 
                                                   "Motorcycle/moped/scooter", "Other hired service (Uber, Lyft, or other smartphone-app car service)", 	
                                                   "Other vehicle (e.g., friend's car, rental, carshare, work car)", "Private bus or shuttle",
                                                   "Taxi (e.g., Yellow Cab)", "Uber/Lyft, taxi, or car service", "Vanpool") ~ "Drive",
                                  work_mode %in% c("Walk (or jog/wheelchair)", "Walk, jog, or wheelchair") ~ "Walk",
                                  work_mode %in% c("Other (e.g. skateboard)", "Other") ~ "Other",
                                  work_mode %in% c("Missing: Skip Logic") ~ "Missing")) %>%
    mutate(RGC = case_when(dest_rgcname != "Not RGC" ~ "RGC", dest_rgcname == "Not RGC" ~ "Not RGC")) %>%
    group_by(RGC == "RGC") %>%
    mutate(rgc_tot = sum(est)) %>%
    mutate(moe = prop_se * 1.645)
          


    filter(home_rgcname != "Not RGC") %>%

# t <- get_table(schema = "HHSurvey", tbl = "households_2021")
# tbltrips <- get_table(schema = "HHSurvey", tbl = "trips_2021")

# teverett <- t %>%
#   filter(final_home_rgcnum == "Kirkland Totem Lake")
# 
# tripseverett <- right_join(tbltrips, teverett, by = "household_id")
# 
# t23 <- get_table(schema = "HHSurvey", tbl = "household_fact_2023")

#origin rgc
mode_centers_ng <- mode_origin_centers %>%
   filter(origin_rgcname == "Seattle Northgate")

mode_centers_u <- mode_origin_centers %>%
   filter(origin_rgcname == "Seattle University Community")

transit_centers_origin <- mode_origin_centers %>%
  filter(mode_characterization == "Transit") %>%
  filter(origin_rgcname != "Not RGC")

#home rgc
transit_centers <- mode_summary_centers %>%
  filter(mode_characterization == "Transit") %>%
  filter(home_rgcname != "Not RGC")

walk_centers <- mode_summary_centers %>%
  filter(mode_characterization == "Walk")


## Demographics

#income with $100K+
mode_by_income <- summarize_weighted(hts_data = hts_data,
                                       summarize_var = "mode_characterization",
                                       summarize_by = c("survey_year", "hhincome_broad_combined"),
                                       id_cols = ids,
                                       wt_cols = wts,
                                       wtname = "trip_weight"
                                       )

transit_by_income <- mode_by_income$summary$wtd %>%
  filter(mode_characterization == "Transit") %>%
  filter(survey_year == "2023") %>%
  mutate(moe = prop_se * 1.645)

#income with $100K-199K and $200K+ 
mode_by_income2 <- summarize_weighted(hts_data = hts_data,
                                       summarize_var = "mode_characterization",
                                       summarize_by = c("survey_year", "hhincome_broad"),
                                       id_cols = ids,
                                       wt_cols = wts,
                                       wtname = "trip_weight"
                                       )

transit_by_income2 <- mode_by_income2$summary$wtd %>%
  filter(mode_characterization == "Transit") %>%
  filter(survey_year == "2023") %>%
  mutate(moe = prop_se * 1.645)

transit_by_income2 <- transit_by_income2 %>%    
  filter(hhincome_broad != "Prefer not to answer") %>%
      mutate(hhincome_broad = factor(hhincome_broad, levels = c("Under $25,000", "$25,000-$49,999", "$50,000-$74,999", "$75,000-$99,999", "$100,000-$199,000", "$200,000 or more")))

# commute pass/aggregate to fewer age groups

pass_by_age <- summarize_weighted(hts_data = hts_data,
                                       summarize_var = "consolidated_transit_pass",
                                       summarize_by = c("survey_year", "age_category"),
                                       id_cols = ids,
                                       wt_cols = wts,
                                       wtname = "trip_weight"
                                       )

transit_by_age_cond <- mode_by_age_cond$summary$wtd %>%
  filter(mode_characterization == "Transit", age_condensed != "NA") %>%
  mutate(moe = prop_se * 1.645)

#race
mode_by_race <- summarize_weighted(hts_data = hts_data,
                                   summarize_var = "mode_characterization",
                                   summarize_by = c("survey_year", "race_category"),
                                   id_cols = ids,
                                   wt_cols = wts,
                                   wtname = "trip_weight"
                                   )

transit_by_race <- mode_by_race$summary$wtd %>% 
  filter(mode_characterization == "Transit")

#clean up
t_by_race <- transit_by_race %>%
  filter(race_category != "Child") %>%
  filter(race_category != "Missing/No response") %>%
  filter(race_category != "Some Other Race non-Hispanic") %>%
  filter(race_category != "Two or More Races non-Hispanic") %>%
  mutate(race_category = recode(race_category, 'White non-Hispanic' = 'White')) %>%
  mutate(race_category = recode(race_category, 'Hispanic' = 'Hispanic or Latinx')) %>%
  mutate(race_category = recode(race_category, 'Black or African American non-Hispanic' = 'Black or African American')) %>%
  mutate(race_category = recode(race_category, 'Asian non-Hispanic' = 'Asian/Native Hawaiian/Pacific Islander')) %>%
    mutate(moe = prop_se * 1.645)

transit_by_race_23 <- t_by_race %>%
  filter(survey_year == "2023")


share_by_race <- transit_by_race %>%
  group_by(survey_year) %>%
  mutate(total = sum(est)) %>%
  mutate(share = (est/total))

#disability
mode_by_dis <- summarize_weighted(hts_data = hts_data,
                                   summarize_var = "mode_characterization",
                                   summarize_by = c("survey_year", "disability_person"),
                                   id_cols = ids,
                                   wt_cols = wts,
                                   wtname = "trip_weight"
                                   )

transit_by_dis <- mode_by_dis$summary$wtd %>% 
  filter(mode_characterization == "Transit", survey_year == "2023") %>% 
  mutate(moe = prop_se * 1.645)

#destination purpose
mode_by_purp <- summarize_weighted(hts_data = hts_data,
                                   summarize_var = "mode_characterization",
                                   summarize_by = c("survey_year", "dest_purpose_cat"),
                                   id_cols = ids,
                                   wt_cols = wts,
                                   wtname = "trip_weight"
                                   )

transit_by_purp <- mode_by_purp$summary$wtd %>% 
  filter(mode_characterization == "Transit", survey_year == "2023") %>%
  mutate(moe = prop_se * 1.645)

#job industry
summary_trips_ind <- summarize_weighted(hts_data = hts_data,
                                    summarize_var = "mode_characterization",
                                    summarize_by = c("survey_year", "industry_cond"),
                                    id_cols = ids,
                                    wt_cols = wts,
                                    wtname = "trip_weight"
                                    )

mode_summary_ind <- summary_trips_ind$summary$wtd %>% 
  mutate(moe = prop_se * 1.645)

transit_by_ind <- mode_summary_ind %>% 
    filter(mode_characterization == "Transit", industry_cond != "NA", industry_cond != "Missing: Skip Logic")

#vehicle ownership in centers
summary_trips_veh <- summarize_weighted(hts_data = hts_data,
                                    summarize_var = "mode_condensed",
                                    summarize_by = c("survey_year", "vehicle_ownership"),
                                    id_cols = ids,
                                    wt_cols = wts,
                                    wtname = "trip_weight"
                                    )

mode_summary_veh <- summary_trips_veh$summary$wtd %>% 
  mutate(moe = prop_se * 1.645)

transit_by_veh <- mode_summary_veh %>% 
    filter(mode_condensed == "Transit")

No_veh <- mode_summary_veh %>% 
    filter(vehicle_ownership == "Not a vehicle owner", mode_condensed != "NA")

#vehicle ownership in centers
summary_trips_veh_cen <- summarize_weighted(hts_data = hts_data,
                                    summarize_var = "mode_characterization",
                                    summarize_by = c("survey_year", "vehicle_ownership", "home_rgcname"),
                                    id_cols = ids,
                                    wt_cols = wts,
                                    wtname = "trip_weight"
                                    )

mode_summary_veh_cen <- summary_trips_veh_cen$summary$wtd %>% 
  mutate(moe = prop_se * 1.645)

#write.csv(mode_summary_veh, 'noveh2.csv')

transit_by_veh_Cen <- mode_summary_veh_cen %>% 
    filter(mode_characterization == "Transit")

No_veh_cen <- mode_summary_veh %>% 
    filter(vehicle_ownership == "Not a vehicle owner", mode_characterization != "NA")

## Initial Mode Charts

#chart for simple mode
# mode_chart <- static_column_chart(mode_summary_simple,
#                       x = "survey_year", y = "prop", fill = "mode_simple",
#                     ylabel = "% of Trips", xlabel = "Survey Year", title = "Trips - Prop",
#                     moe = "prop_se") + theme(
#                       axis.text.x = element_text(size = 14),
#                       axis.text.y = element_text(size = 14),
#                       axis.title.y = element_text(size = 20),
#                       axis.title.x = element_text(size = 20),
#                       plot.title = element_text(size = 24)
#                       )

#chart for mode characterization
mode_char_chart <- static_column_chart(transit,
                    x = "survey_year", y = "prop", fill = "survey_year",
                    ylabel = "% of Trips", 
                    #xlabel = "Year", 
                    title = "Transit Trips - Share",  
                    moe = "moe_p") + theme(
                      #axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      #axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )
mode_char_chart


#chart for transit frequency
transit_chart <- static_bar_chart(transit_summary,
                    x = "prop", y = "transit_freq", fill = "survey_year",
                    ylabel = "% of Trips", xlabel = "Survey Year", title = "Trips - Prop",  moe = "moe") + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )
transit_chart

## Transit Charts

#transit by race
transitbyrace_chart <- static_bar_chart(transit_by_race_23,
                    x = "prop", y = "race_category", fill = "survey_year",
                    ylabel = "Race/Ethnicity", xlabel = "Share of Trips", #title = "Transit Mode Share by Race for 2023", 
                    moe = "moe"
                    ) + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )


transitsharebyrace_chart <- static_line_chart(share_by_race,
                    x = "survey_year", y = "share", fill = "race_category",
                    ylabel = "Share", xlabel = "Survey Year", title = "Transit Trips by Race - Share"
                    #moe = "moe"
                    ) + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

#transit by disability
transitbydis_chart <- static_column_chart(transit_by_dis,
                    x = "disability_person", y = "prop", fill = "disability_person",
                    ylabel = "Share of Trips", 
                    #xlabel = "Survey Year", #title = "Transit Trips by Disability - Estimate",
                    moe = "moe") + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

#transit by destination purpose
transitbypurp_chart <- static_column_chart(transit_by_purp,
                    x = "dest_purpose_cat", y = "prop", fill = "survey_year",
                    ylabel = "Share of Trips", 
                    #xlabel = "Survey Year", #title = "Transit Trips by Disability - Estimate",
                    moe = "moe") + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

#access to transit
accesstransit_chart <- static_column_chart(access_summary,
                                        x = "survey_year", y = "est", fill = "mode_acc_1", 
                                        color = "gnbopgy_10",
                                        ylabel = "Share of Trips", xlabel = "Survey Year", title = "Access to Transit Trips - Prop",
                                        #moe = "prop_se"
) + 
  theme(
    axis.text.x = element_text(size = 14),
    axis.text.y = element_text(size = 14),
    axis.title.y = element_text(size = 20),
    axis.title.x = element_text(size = 20),
    plot.title = element_text(size = 24)
  )

#transit by industry
transitbyind_chart <- static_line_chart(transit_by_ind,
                    x = "survey_year", y = "prop", fill = "industry_cond", 
                    color = "gnbopgy_10",
                    ylabel = "# of Trips", xlabel = "Survey Year", title = "Transit Trips by Job Industry - Prop",
                    #moe = "prop_se"
                    ) + 
                      theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )
#income chart
transitbyincome_chart <- static_bar_chart(transit_by_income2,
                    x = "prop", y = "hhincome_broad", fill = "survey_year",
                    ylabel = "Household Income", xlabel = "Transit Mode Share", moe = "moe") + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

#age chart
transitbyage_chart <- static_column_chart(transit_by_age_cond,
                    x = "survey_year", y = "est", fill = "age_condensed",
                    ylabel = "# of Trips", xlabel = "Survey Year", title = "Transit Trips - Estimate",
                    moe = "est_se") + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

#vehicle ownership charts
transitbyveh_chart <- static_column_chart(transit_by_veh,
                    x = "vehicle_ownership", y = "prop", fill = "survey_year",
                    ylabel = "Share of Trips", xlabel = "Vehicle Ownership", 
                    , moe = "moe"
                    ) + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

noveh_chart_mode <- static_bar_chart(No_veh,
                    x = "prop", y = "mode_condensed", fill = "survey_year",
                    ylabel = "Mode", xlabel = "Share of Trips", 
                    #title = "Trips by Mode for Zero Vehicle HH - Prop, 
                    moe = "moe"
                    ) + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

#centers

centers_chart_mode <- static_column_chart(transit_centers_origin,
                    x = "mode_characterization", y = "prop", fill = "survey_year",
                    ylabel = "% of Trips", xlabel = "Survey Year", title = "Mode by Center - Prop"
                    #, moe = "moe"
                    ) + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

originrgc_work_mode <- static_column_chart(transit_centers,
                                          x = "survey_year", y = "prop", fill = "work_mode2",
                                          ylabel = "% of Trips", xlabel = "Survey Year", title = "Mode by Center - Prop"
                                          #, moe = "moe"
) + theme(
  axis.text.x = element_text(size = 14),
  axis.text.y = element_text(size = 14),
  axis.title.y = element_text(size = 20),
  axis.title.x = element_text(size = 20),
  plot.title = element_text(size = 24)
)

destrgc_work_mode <- static_column_chart(transit_centers_dest,
                                           x = "survey_year", y = "est", fill = "work_mode2",
                                           ylabel = "% of Trips", xlabel = "Survey Year", title = "Mode by Center - Prop"
                                           #, moe = "moe"
) + theme(
  axis.text.x = element_text(size = 14),
  axis.text.y = element_text(size = 14),
  axis.title.y = element_text(size = 20),
  axis.title.x = element_text(size = 20),
  plot.title = element_text(size = 24)
)

#chart for transit 
transit_chart <- static_column_chart(transit_centers,
                    x = "survey_year", y = "est", fill = "survey_year",
                    ylabel = "% of Trips", xlabel = "Survey Year", title = "Transit Trips - Share"
                    #, moe = "moe"
                    ) + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

centers_chart_walk <- static_column_chart(walk_centers,
                    x = "home_rgcname", y = "prop", fill = "survey_year",
                    ylabel = "% of Trips", xlabel = "Survey Year", title = "Walking by Center - Prop"
                    , moe = "moe"
                    ) + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )

## Summary for Simple Trips

hts_data <- list(hh = hh, 
                 person = person, 
                 trip = trip) 
ids <- c("hh_id", "person_id", "trip_id") 
wts <- c("hh_weight", "person_weight", "trip_weight")

summary_trips_simp <- summarize_weighted(hts_data = hts_data, 
                                    summarize_var = "mode_simple", 
                                    summarize_by = "survey_year", 
                                    id_cols = ids, wt_cols = wts, 
                                    wtname = "trip_weight" )

mode_summary_simp <- summary_trips_simp$summary$wtd %>% mutate(moe = prop_se * 1.645)

#filter for Urban Rail

#mode_summary_rail <- mode_summary |> filter(grepl('Urban Rail', mode_1))

static_column_chart(na.omit(mode_summary_simp),
                    x = "mode_simple", y = "prop", fill = "survey_year",
                    ylabel = "% of Trips", xlabel = "Survey Year", title = "Trips - Share",
                    moe = "moe") + theme(
                      axis.text.x = element_text(size = 14),
                      axis.text.y = element_text(size = 14),
                      axis.title.y = element_text(size = 20),
                      axis.title.x = element_text(size = 20),
                      plot.title = element_text(size = 24)
                      )