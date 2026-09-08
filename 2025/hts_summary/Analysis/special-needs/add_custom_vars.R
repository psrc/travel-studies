library(dplyr)
library(data.table)

`%between%`<- function(x, range) x>=range[1] & x<=range[2]

add_custom_vars <- function(dt) {
  # explicit copy avoids the data.table "shallow copy" warning on := below,
  # since dt may arrive without proper over-allocated truelength (e.g. via %>%)
  dt <- data.table::copy(dt) %>% setDT()
  rgx_age <- "^.*\\b(\\d+) [y|Y]ears.*$"
  dt[, `:=`(
    age65plus = factor(
      fcase(is.na(age), NA_character_,
            as.integer(age) > 64, "65 and over",
            default = "Under 65"),
      levels = c("65 and over", "Under 65"), ordered = TRUE),

    age_bin5 = factor(
      fcase(is.na(age), NA_character_,
            as.integer(age) < 18, "Under 18 Years",
            as.integer(age) <= 24, "18-24 Years",
            as.integer(age) <= 44, "25-44 Years",
            as.integer(age) <= 64, "45-64 Years",
            as.integer(age) > 64, "65 years or older"),
      levels=c("Under 18 Years","18-24 Years","25-44 Years",
               "45-64 Years","65 years or older"), ordered = TRUE),

    gender_bin3 = factor(
      fcase(grepl("^Man", as.character(gender)),    "Man",
            grepl("^Woman", as.character(gender)), "Woman",
            !is.na(gender), "Another/No answer"),
      levels=c("Woman","Man","Another/No answer"), ordered = TRUE),

    disability = factor(
      fcase(is.na(disability_person), NA_character_,
            disability_person == "Yes", "Disability",
            disability_person == "No", "No Disability",
            grepl("Prefer", disability_person), "No answer"),
      levels = c("Disability", "No Disability", "No Answer"), ordered = TRUE),

    low_income = factor(
      if_else(is.na(hhincome_detailed) | is.na(hhsize), NA_character_,
      if_else(fcase(grepl("^Under \\$10,", hhincome_detailed), 0,
                    grepl("^\\s*\\$\\d+", hhincome_detailed),
                      as.numeric(gsub(",", "", stringr::str_extract(hhincome_detailed, "(?<=\\$)[0-9,]+"))),
                    default = NA_real_) <
          (suppressWarnings(as.integer(stringr::str_extract(as.character(hhsize), "^\\d+"))) * 11000 + 20300),
            "Low-income", "Not Low-income")),
      levels = c("Low-income", "Not Low-income"), ordered = TRUE),

    poc = factor(
      fcase(is.na(race_5), NA_character_,
            race_5 == "Not Selected", "POC",
            race_5 == "Selected", "Not POC"),
      levels = c("POC", "Not POC"), ordered = TRUE),

    zero_vehicles = factor(
      fcase(is.na(vehicle_count), NA_character_,
            grepl("^0", as.character(vehicle_count)), "No vehicle",
            default = "Own vehicle"),
      levels = c("No vehicle", "Own vehicle"), ordered = TRUE)
    )]
}
