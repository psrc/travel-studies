### Introduction

This repo contains scripts that were created to explore displacement using the Household Travel Survey data. They were generated to look at 2019-2023 survey years.



### Contents

* The **displacement.Rmd** and **displacement.html** (creator: Suzanne) early exploration of the data to generate basic descriptive statistics. This script generated many of the csv files stored within this repo (other than the res\_dur\_regional.csv and the initial\_stats.xlsx files - unsure which script(s) generated these two files)
* The **context\_numbers.qmd** (creator: Mary) generated temporary county-specific tables and compared results to displacement risk data
* 3 data exploration qmd files (creator: Mary) - more details below
* 2 data modeling qmd files (creator: Mary) - more details below



##### 3 data exploration qmd files 

###### **data\_exploration\_202410\_separate\_survey\_year.qmd** 

* code that generates descriptive statistics, bar charts, and line charts to explore the characteristics of households that can be categorized as being displaced
* at the beginning of the script *`focus\_year` is specified so that tables and bar charts are set to that survey year*, while the line charts show trends across all relevant survey years
* a range of topics are explored: socio-economic, previous and current living conditions, and spatial patterns. Displaced households are those that moved within the past 5 years. 

###### **data\_exploration\_202410\_combined\_survey\_year\_2y.qmd**

* code that generates descriptive statistics and bar charts to explore the characteristics of households that can be categorized as being displaced. A range of topics are explored: socio-economic, previous and current living conditions, and spatial patterns. Displaced households are those that moved within the past *2 years*. Data *combines all survey years* - all households that are categorized as displaced or not displaced, regardless of which survey.  

###### **data\_exploration\_202410\_combined\_survey\_year\_5y.qmd**

* similar to previous .wmd, but displaced households are those that moved within the past *5 years*. This script also includes the background work to start modeling. Households are categorized as displaced if they reported one (or more) of the 4 displacement-related reasons when asked about moving from their previous residence. For displacement (any of the four reasons), as well as  



##### 2 data modeling qmd files 

###### **data\_modeling\_20250310\_combined\_survey\_year\_5y\_allmodels.qmd**

* 

###### **data\_modeling\_20250630\_combined\_survey\_year\_5y\_final5models.qmd**

* 

