# Comparing 2017/2019 and 2021 surveys to see how teleworking has changed due to COVID

library(tidyverse)
library(odbc)
library(DBI)

# Read in data from Elmer ====
elmer_conn <- dbConnect(odbc::odbc(),
                        driver = "SQL Server",
                        server = "AWS-PROD-SQL\\Sockeye",
                        database = "Elmer",
                        trusted_connection = "yes"
                        )

households <- dbGetQuery(elmer_conn,
                         "SELECT * FROM HHSurvey.v_households_2017_2019_in_house")

households_2021 <- dbGetQuery(elmer_conn,
                              "SELECT * FROM HHSurvey.households_2021")

persons <- dbGetQuery(elmer_conn,
                      "SELECT * FROM HHSurvey.v_persons_2017_2019_in_house
                       WHERE age_category <> 'Under 18 years'")

persons_2021 <- dbGetQuery(elmer_conn,
                           "SELECT * FROM HHSurvey.persons_2021
                            WHERE age_category <> 'Under 18 years'")

dbDisconnect(elmer_conn)

households$household_id <- as.character(households$household_id)
households_2021$household_id <- as.character(households_2021$household_id)
persons$household_id <- as.character(persons$household_id)
persons$person_id <- as.character(persons$person_id)
persons_2021$household_id <- as.character(persons_2021$household_id)
persons_2021$person_id <- as.character(persons_2021$person_id)

workers <- filter(persons, worker != "No jobs")
workers_2021 <- filter(persons_2021, worker != "No jobs")

# Analysis ====
persons_2021 %>% 
  group_by(employment_pre_covid) %>% 
  summarize(total = sum(combined_adult_weight)) %>% 
  mutate(percent = round(total / sum(total), 2))
# employment_pre_covid                                   total percent
# Employed full-time (35+ hours/week, paid)           1860133.    0.55
# Employed part-time (fewer than 35 hours/week, paid)  363863.    0.11
# Self-employed                                        228213.    0.07
# Unpaid volunteer or intern                            30904.    0.01
# Retired                                              426324.    0.13
# Homemaker                                            173277.    0.05
# Not employed                                         291014.    0.09

persons_2021 %>% 
  group_by(employment) %>% 
  summarize(count = n(),
            total = sum(combined_adult_weight)) %>% 
  mutate(percent = round(total / sum(total), 2),
         moe = round(1.645 * sqrt(0.25 / sum(count)), 2))
# employment                                                              total percent
# Employed full time (35+ hours/week, paid)                            1656146.    0.49
# Employed part time (fewer than 35 hours/week, paid)                   348722.    0.10
# Employed but not currently working (e.g., on leave, furloughed 100%)   40734.    0.01
# Self-employed                                                         217114.    0.06
# Unpaid volunteer or intern                                             17435.    0.01
# Retired                                                               555277.    0.16
# Homemaker                                                             182708.    0.05
# Not currently employed                                                355592.    0.11

employment_by_gender <- persons_2021 %>% 
  group_by(employment, gender) %>% 
  summarize(count = n(),
            total = round(sum(combined_adult_weight), 0)) %>% 
  mutate(percent = round(total / sum(total), 2),
         moe = round(1.645 * sqrt(0.25 / sum(count)), 2))
# Employed, on leave: 68% female vs. 30% male
# Employed full-time: 42% female vs. 56% male
# Employed part-time: 58% female vs. 40% male
# Not employed: 54% female vs. 43% male
# Self-employed is roughly equal

workers_2021 %>% 
  group_by(workplace_pre_covid) %>% 
  summarize(total = sum(combined_respondent_weight)) %>% 
  mutate(percent = round(total / sum(total), 2))
# workplace_pre_covid                                               total percent
# Only one work location outside of home                         1526190.    0.68
# Work location regularly varied (different offices/jobsites)     193818.    0.09
# Drove/traveled for work (driver, sales)                         105651.    0.05
# Teleworked some days and traveled to a work location some days  177645.    0.08
# Worked at home ONLY (telework, self-employed)                   175326.    0.08
# Missing: Skip Logic                                              72328.    0.03

workers_2021 %>% 
  group_by(workplace) %>% 
  summarize(total = sum(combined_adult_weight)) %>% 
  mutate(percent = round(total / sum(total), 2))
# workplace                                                     total percent
# Usually the same location (outside home)                   1109961.    0.50
# Workplace regularly varies (different offices or jobsites)  207574.    0.09
# Drives for a living (e.g., bus driver, salesperson)          81702.    0.04
# Telework some days and travel to a work location some days  236701.    0.11
# At home (telecommute or self-employed with home office)     586043.    0.26
# Missing: Skip Logic                                              0     0   

workplace_by_gender <- workers_2021 %>% 
  group_by(workplace, gender) %>% 
  summarize(count = n(),
            total = round(sum(combined_adult_weight), 0)) %>% 
  mutate(percent = round(total / sum(total), 2),
         moe = round(1.645 * sqrt(0.25 / sum(count)), 2))
# At home overlaps, nearly even split male/female
# Slight overlap with hybrid: 54% female vs 45% male
# No overlap same location outside home: 43% female vs. 55% male
# Almost no overlap workplace varies: 32% female vs. 64% male

workers_2021 %>% 
  group_by(telecommute_freq_pre_covid) %>% 
  summarize(total = sum(combined_respondent_weight)) %>% 
  mutate(percent = round(total / sum(total), 2))
#telecommute_freq_pre_covid    total percent
# Not at all                 1179255.  0.52 
# Less than monthly           204696.  0.09
# 1-3 times per month         183948.  0.08
# 1-2 days a week             152645.  0.07
# 3-4 days a week              88117.  0.04
# 5+ days a week               88992.  0.04
# Missing: Skip Logic         353305.  0.16 

workers_2021 %>% 
  group_by(telecommute_freq) %>% 
  summarize(total = sum(combined_adult_weight)) %>% 
  mutate(percent = round(total / sum(total), 2))
#telecommute_freq       total percent
# Never / None        1075376.  0.48
# 1-2 days             160988.  0.07
# 3-4 days             147187.  0.07
# 5+ days              170291.  0.08
# Missing: Skip Logic  668139.  0.30 

telecommute_by_gender <- workers_2021 %>% 
  group_by(telecommute_freq, gender) %>% 
  summarize(count = n(),
            total = round(sum(combined_adult_weight), 0)) %>% 
  mutate(percent = round(total / sum(total), 2),
         moe = round(1.645 * sqrt(0.25 / sum(count)), 2))
# Never: 42% female vs. 57% male
# 1-2days: even split
# 3-4 days: 55% female vs. 42% male
# 5+ days: 37% female vs. 60% male
# Missing: even split

