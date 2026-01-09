# Functions to help with statistical analysis of Household Travel Survey data
# The functions help to compare the means of groups to determine if there is a significant difference. 


# Connecting to Data ------------------------------------------------------

# Connecting to Elmer
db.connect <- function() {
  elmer_connection <- dbConnect(odbc(),
                                driver = "SQL Server",
                                server = "AWS-PROD-SQL\\Sockeye",
                                database = "Elmer",
                                trusted_connection = "yes"
  )
}


# Read tables and queries from Elmer
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



# Background Descriptives and Formatting ----------------------------------

# Confidence Interval for mean = sample mean + Z-value for confidence level(sample st. dev/sqrt(number of elements in sample))
Mean.SD_CI <- function(df, cat_var, num_var, weight_var){
  cat_var <- enquo(cat_var)
  num_var <- enquo(num_var)
  weight_var <- enquo(weight_var)
  
  Mean.SD_CI_table <- df %>%
    group_by(!!cat_var) %>%
    summarize(Group_weight = round(sum(!!weight_var),0),
              Weighted_percent = (round(Group_weight/sum(df$hh_wt_2019),4)),
              Weighted_avg = round(weighted.mean(!!num_var, !!weight_var),2),
              sd = round(sd(!!num_var),2),
              se = round(sd/sqrt(n()),2),
              CI_90 = round(z*(sd/sqrt(n())),2),
              CI_95 = round(z_95*(sd/sqrt(n())),2),
              n=n())
  
  # to remove sample size column from table
  Mean.SD_CI_temp<- dplyr::select(Mean.SD_CI_table, -c(n))
  # return(Mean.SD_CI_temp)
  
  # to include sample size column in table
  # return(Mean.SD_CI_table)
  
  # create formatted output table
  formattable(Mean.SD_CI_table,
              list(area(col=c(2,9))~mycomma(digits=0),
                   Weighted_percent=percent),
              align=c("l", rep("c", NCOL(Mean.SD_CI_table))),
              col.names=c("Variable", "2019 Estimate", "2019 Percent", "2019 Average", "SD", "SE", "CI 90%", "CI 95%", "Sample Size"))
}


# adding commas to numbers - thousand separator 
mycomma <- function(digits = 0) {
  formatter("span", x ~ comma(x, digits = digits)
  )
}


# Statistical assumptions for margins of error
p_MOE <- 0.5
z <- 1.645 #90% CI
z_95 <- 1.96 #95% CI



# Analysis Functions ------------------------------------------------------

#  1) Two-way ANOVA test function
anova.test <- function(df_name, dependent, var1, var2) {
  # defining the objects
  dependent <- df_name[dependent]
  variable1 <- df_name[var1]
  variable2 <- df_name[var2]
  df <- data.frame(dependent=unlist(dependent),
                   variable1=unlist(variable1),
                   variable2=unlist(variable2))
  
  # generating ANOVA statistics
  ANOVA.output <<- aov(dependent~variable1+variable2, data=df)
  ANOVA_summary <- summary(ANOVA.output)
  print(ANOVA_summary)
  
  # convert output summary into data.frame to get p-values
  summaries <<- df %>%
    do(tidy(aov(dependent~variable1+variable2, data=df)))
  # print(summaries)
  
  # generate message about next steps
  for(i in 1:(nrow(summaries)-1)){
    if(summaries[i,6] < 0.05){
      print(paste0("The p-value for ",summaries[i,1], " is statistically significant (p<0.05) and should be tested further using the Tukey HSD."))
    } else if (summaries[i,6] < 0.10){
      print(paste0("The p-value for ", summaries[i,1], " is statistically significant (p<0.10) and could be tested further using the Tukey HSD."))
    } else if (summaries[i,6] > 0.1){
      print(paste0("The p-value for ",summaries[i,1], " is not statistically significant and does not require further analysis."))
    } else {NULL}
  }
}


# 1a) Tukey HSD test function
TukeyHSD.test <- function(){
  for (i in 1:2){
    Tukey_test <- TukeyHSD(ANOVA.output, which=paste0("variable",i))
    # result<-data.frame(Tukey_test[paste0("variable",i)])
    # p_val <- result[paste0("variable",i,".p.adj")]
    
    sig_test <- as.data.frame(tidy(Tukey_test))
    print(paste0("The Tukey HSD Test results for ", sig_test$term[1]))
    print(Tukey_test)
    
    #how to count items in p_val
    for(i in 1:(nrow(sig_test))){
      if(sig_test[i,7] < 0.05){
        print(paste0("The difference between: ",sig_test[i,2]," is statistically significant (p<0.05)"))
      } else if(sig_test[i,7] < 0.10){
        print(paste0("The difference between: ",sig_test[i,2]," is statistically significant (p<0.10)"))
      } else {NULL}
    }
  }
}


# 1b) Levene's test function (homogeneity of variances)
levene.check <- function(df_name, dependent, var1, var2){
  # defining the objects
  dependent <- df_name[dependent]
  variable1 <- df_name[var1]
  variable2 <- df_name[var2]
  df <- data.frame(dependent=unlist(dependent),
                   variable1=unlist(variable1),
                   variable2=unlist(variable2))
  
  # generating statistic
  levene.output <<- leveneTest(dependent~variable1*variable2, data=df)
  levene.pvalue <- as.data.frame(levene.output$`Pr(>F)`)
  
  # results
  for(i in 1:(nrow(levene.pvalue)-1)){
    if(levene.pvalue[1,1]< 0.05){
      print(paste0("The p-value is statistically significant (p<0.05), which means that the variance among the groups is significantly different (not equal) - Levene's test rejected the null hypothesis of equal variances."))
    } else if (levene.pvalue[1,1]>= 0.05){
      print(paste0("The p-value is not statistically significant, which means that the variance among the groups is equal."))
    } else {NULL}
  }
}


# 1c) Shapiro Wilk test function (distribution)
shapiro.wilk.check <- function(){
  # extract the residuals using output from ANOVA
  anova_residuals <- residuals(object=ANOVA.output)
  # run Shapiro-Wilk test
  test <- shapiro.test(x=anova_residuals)
  shapiro.pvalue <- test$p.value
  
  # results
  if(shapiro.pvalue< 0.05){
    print(paste0("The p-value is statistically significant (p<0.05), which means that the data are not normally distributed - the null hypothesis that the data are normally distributed is rejected."))
  } else if (shapiro.pvalue>= 0.05){
    print(paste0("The p-value is not statistically significant, which means that there is a normal distribution."))
  } else {NULL}
}


# 2) F-test function (determining variances for t-test)
F.test.check <- function(df_name, dependent, var1){
  # defining the objects
  dependent <- df_name[dependent]
  variable1 <- df_name[var1]
  df <- data.frame(dependent=unlist(dependent),
                   variable1=unlist(variable1))
  
  # generating statistic
  Fstats <- var.test(dependent~variable1, data=df)
  print(Fstats)
  F.pvalue <- Fstats$p.value
  
  # generate message about next steps
  if(F.pvalue< 0.05){
    print(paste0("The p-value is statistically significant (p<0.05), which means that there is a significant difference between the variances of the two sets of data. This means that we cannot use the classic t-test (which assumes equality of the two variances) and must instead use the Welch t-test (which is an adaptated t-test, used when the two samples have unequal variances)."))
  } else if (F.pvalue>= 0.05){
    print(paste0("The p-value is not statistically significant, which means that there is no significant differene between the variances of the two sets of data. This means that we can apply the classic t-test to compare the means of the different groups."))
  } else {NULL}
}


# 2a) Welch Test (comparing means)
Welch.test.check <- function(df_name, dependent, var1){
  # defining the objects
  dependent <- df_name[dependent]
  variable1 <- df_name[var1]
  df <- data.frame(dependent=unlist(dependent),
                   variable1=unlist(variable1))
  
  # generating statistic
  Welchstats <- t.test(dependent~variable1, data=df)
  print(Welchstats)
  Welch.pvalue <- Welchstats$p.value
  
  # generate message about next steps
  if(Welch.pvalue< 0.01){
    print(paste0("Based on these results, the p-value is statistically significant (p<0.01), which means that there is a significant difference between these two groups"))
  } else if (Welch.pvalue< 0.05){
    print(paste0("Based on these results, the p-value is statistically significant (p<0.05), which means that there is a significant difference between these two groups"))
  } else if (Welch.pvalue>= 0.05){
    print(paste0("Based on these results, there is no significant difference between the two groups."))
  } else {NULL}
}


# 2b) Classic t-test (comparing means)
T.test.check <- function(df_name, dependent, var1){
  # defining the objects
  dependent <- df_name[dependent]
  variable1 <- df_name[var1]
  df <- data.frame(dependent=unlist(dependent),
                   variable1=unlist(variable1))
  
  # generating statistic
  Tteststats <- t.test(dependent~variable1, data=df, var.equal=TRUE)
  print(Tteststats)
  Ttest.pvalue <- Tteststats$p.value
  
  # generate message about next steps
  if(Ttest.pvalue< 0.01){
    print(paste0("Based on these results, the p-value is statistically significant (p<0.01), which means that there is a significant difference between these two groups"))
  } else if (Ttest.pvalue< 0.05){
    print(paste0("Based on these results, the p-value is statistically significant (p<0.05), which means that there is a significant difference between these two groups"))
  } else if (Ttest.pvalue>= 0.05){
    print(paste0("Based on these results, there is no significant difference between the two groups."))
  } else {NULL}
}