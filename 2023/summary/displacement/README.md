### Introduction

This repo contains scripts that were created to explore displacement using the Household Travel Survey data. They were generated to look at 2019-2023 survey years.



### Contents

* The **displacement.Rmd** and **displacement.html** (creator: Suzanne) early exploration of the data to generate basic descriptive statistics. This script generated many of the csv files stored within this repo (other than the res\_dur\_regional.csv and the initial\_stats.xlsx files - unsure which script(s) generated these two files)
* The **context\_numbers.qmd** (creator: Mary) generated temporary county-specific tables and compared results to displacement risk data
* 3 data exploration qmd files (creator: Mary) - more details below
* 2 data modeling qmd files (creator: Mary) - more details below



#### 3 data exploration qmd files 

##### **data\_exploration\_202410\_separate\_survey\_year.qmd** 

This code generates descriptive statistics, bar charts, and line charts to explore the characteristics of households that can be categorized as being displaced. Households within the sample are only those that moved within the past *5 years* of the survey. A range of topics are explored: socio-economic, previous and current living conditions, and spatial patterns. At the beginning of the script `focus\_year` is specified so that tables and bar charts are set to that *specific survey year*, while the line charts show trends across all relevant survey years.



##### **data\_exploration\_202410\_combined\_survey\_year\_2y.qmd**

This code generates descriptive statistics and bar charts to explore the characteristics of households that can be categorized as being displaced. Households within the sample are only those that moved within the past *2 years* of the survey. A range of topics are explored: socio-economic, previous and current living conditions, and spatial patterns. When exploring topics, the data set *combines all survey years* - all households that are categorized as displaced or not displaced, regardless of which survey. 

&#x20;

##### **data\_exploration\_202410\_combined\_survey\_year\_5y.qmd**

This code is similar to the previous .qmd, but households within the sample are only those that moved within the past *5 years* of the survey. This script also includes the background work to start modeling. Households are categorized as displaced if they reported one (or more) of the 4 displacement-related reasons (forced, income change, increase in housing cost, or community change) when asked about moving from their previous residence. Initial modeling-related analyses are conducted to test 6 dependent displacement-related outcomes - 



1. combined displacement (households reporting any of the 4 displacement-related reasons)
2. combined displacement (households reporting any 3 of the displacement-related reasons, excluding community change)
3. forced displacement
4. income change-related displacement
5. housing cost-related displacement
6. community change-related displacement



For each of these 5 dependent variables there are a series of analyses run to set up the initial modeling:



###### null model

###### bivariate analyses for each of the variables of interest

Testing each of the independent variables against the dependent variable to check for a relationship. When exploring the first 'general displacement' dependent variable, there are some additional tests that are run that are excluded for the others, such as looking at the current and previous home location tract's displacement risk score. 

###### multivariate analysis a

This model includes all of the variables that were significant in the bivariate analyses.

###### multivariate analysis b

this model includes all of the variables that were significant in the bivariate analyses and then refined to those significant in the multivariate analysis a 



#### 2 data modeling qmd files 

##### **data\_modeling\_20250310\_combined\_survey\_year\_5y\_allmodels.qmd**

This code is a continuation of the **data\_exploration\_202410\_combined\_survey\_year\_5y.qmd** file, but refined to 5 dependent-related outcomes - excludes #2 from above. It expands upon the exploration script because it includes additional refined models for each of the outcomes - adding independent variables back in the model one at a time because of collinearity. 



##### **data\_modeling\_20250630\_combined\_survey\_year\_5y\_final5models.qmd**

This code further refines the previous to only include the final five models - excludes the null models and bivariate analyses. 

