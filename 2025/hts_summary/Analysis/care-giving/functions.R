create_trip_purpose_tbl <- function(hts_data) {
  # This section prints a table with weighted/unweighted x Home/Exclude Home x trip purpose
  # region
  
  rs <- psrc_hts_stat(hts_data,
                       analysis_unit = "trip",
                       group_vars = c("dest_region","dest_purpose_cat"),
                       incl_na = FALSE) |>
    mutate(type = "Include HOME")
  
  rs_no_home <- psrc_hts_stat(hts_data,
                               analysis_unit = "trip",
                               group_vars = c("dest_region","dest_purpose_cat_no_home"),
                               incl_na = FALSE)  |>
    mutate(type = "Exclude HOME") |>
    rename(dest_purpose_cat = dest_purpose_cat_no_home)
  
  # Region
  
  rs <- rs |>  
    add_row(rs_no_home)
  
  rs_calc <- rs |>
    mutate(unweighted = percent(count/sum(count)),
           weighted = percent(prop),
           .by = c(type, survey_year))
    
  df <- rs_calc |>
    pivot_wider(id_cols = "dest_purpose_cat",
                names_from = c(type, survey_year),
                values_from = contains("weighted"),
                names_sep = ".") 
}

create_care_purpose_tbl <- function(hts_data) {
  # region
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c("dest_region", "care_purpose_cat"),
                      incl_na = FALSE)

  df_calc <- rs |> 
    mutate(unweighted = percent(count/sum(count)),
           weighted = percent(prop),
           moe = percent(prop_moe),
           .by = survey_year)
  
  df <- df_calc |>
    pivot_wider(id_cols = "care_purpose_cat",
                names_from = survey_year,
                values_from = contains("weighted"),
                names_sep = ".") 
  
}

mode_share_income <- function(income, geog){
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")

  rs <- psrc_hts_stat(df_hts,
                       analysis_unit = "trip",
                       group_vars = c(geo_col, "care_purpose_cat", income, "mode_class_5"),
                       incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") |>
    mutate(type = "percent") |>
    mutate(unweighted = percent(count/sum(count)),
           weighted = percent(prop),
           moe = percent(prop_moe),
           .by = c("survey_year", "type", income))

  v <- c("survey_year", "dest_loc", "care_purpose_cat", income, "mode_class_5", "unweighted", "weighted", "moe")

  rs |> 
    select(all_of(v)) |> 
    pivot_wider(id_cols = c("dest_loc", "care_purpose_cat", "mode_class_5"),
                names_from = c("survey_year", contains("income")),
                values_from = c(contains("weighted"), "moe"),
                names_sep = ".") 
}

mode_share_income_set_b <- function(geog){
  # set thresholds: $50k, $50k-99,999, $100k or more
  
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")

  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c(geo_col, "care_purpose_cat", "income_comp", "mode_class_5"),
                      incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") |>
    mutate(type = "percent") |>
    mutate(unweighted = percent(count/sum(count)),
           weighted = percent(prop),
           moe = percent(prop_moe),
           .by = c("survey_year", "type", "income_comp"))

  v <- c("survey_year", "dest_loc", "care_purpose_cat", "income_comp", "mode_class_5", "weighted", "moe")

  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "care_purpose_cat", "mode_class_5"),
                names_from = c("income_comp", "survey_year"),
                values_from = c("weighted", "moe"),
                names_glue = "{income_comp}.{survey_year}.{.value}"
                ) |>
    relocate("dest_loc","care_purpose_cat","mode_class_5", contains("Under"), contains("$50,000"), contains("or more")) 
  
  ind01 <- grep("weighted", colnames(df))
  ind02 <- grep("moe", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc","care_purpose_cat","mode_class_5", unlist(map2(ind01, ind02, c)))

  return(list(long = rs, wide = df_reorder))
}

mode_share_income_set_c <- function(geog){
  # set thresholds: $50k, $50k or more
  
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c(geo_col, "care_purpose_cat", "income_50", "mode_class_5"),
                      incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") |>
    mutate(type = "percent") |>
    mutate(unweighted = percent(count/sum(count)),
           weighted = percent(prop),
           moe = percent(prop_moe),
           .by = c("survey_year", "type", "income_50"))

  v <- c("survey_year", "dest_loc", "care_purpose_cat", "income_50", "mode_class_5", "weighted", "moe", "count")
  
  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "care_purpose_cat", "mode_class_5"),
                names_from = c("survey_year", "income_50"),
                # names_from = c("income_50", "survey_year"),
                values_from = c("weighted", "moe", "count"),
                names_glue = "{survey_year}.{income_50}.{.value}"
                # names_glue = "{income_50}.{survey_year}.{.value}"
    ) |>
    relocate("dest_loc","care_purpose_cat","mode_class_5", contains("2023"), contains("2025"))
    # relocate("dest_loc","care_purpose_cat","mode_class_5", contains("Under"), contains("or more")) 
  
  ind01 <- grep("weighted", colnames(df))
  ind02 <- grep("moe", colnames(df))
  ind03 <- grep("count", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc","care_purpose_cat","mode_class_5", unlist(pmap(list(ind01, ind02, ind03), c)))
  
  return(list(long = rs, wide = df_reorder))
}

create_trips_gender_tbl <- function(geog) {
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c(geo_col, "care_purpose_cat", "gender2"),
                      incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") |>
    mutate(unweighted = percent(count/sum(count)),
           weighted = percent(prop),
           moe = percent(prop_moe),
           .by = c("survey_year", "gender2"))
  
  v <- c("survey_year", "dest_loc", "care_purpose_cat", "gender2", "weighted", "moe", "count")

  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "care_purpose_cat"),
                names_from = c("survey_year", "gender2"),
                values_from = c("weighted", "moe", "count"),
                names_glue = "{survey_year}.{gender2}.{.value}"
    ) |>
    relocate("dest_loc","care_purpose_cat", contains("2023"), contains("2025"))
 
  ind01 <- grep("weighted", colnames(df))
  ind02 <- grep("moe", colnames(df))
  ind03 <- grep("count", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc","care_purpose_cat", unlist(pmap(list(ind01, ind02, ind03), c)))
  
  return(list(long = rs, wide = df_reorder))
  
}

create_mode_gender_tbl <- function(geog) {
  
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c(geo_col, "care_purpose_cat", "gender2", "mode_class_5"),
                      incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") |>
    mutate(unweighted = percent(count/sum(count)),
           weighted = percent(prop),
           moe = percent(prop_moe),
           .by = c("survey_year", "gender2"))
  
  v <- c("survey_year", "dest_loc", "care_purpose_cat", "gender2", "mode_class_5", "weighted", "moe", "count")
  
  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "care_purpose_cat", "mode_class_5"),
                names_from = c("survey_year", "gender2"),
                values_from = c("weighted", "moe", "count"),
                names_glue = "{survey_year}.{gender2}.{.value}"
    ) |>
    relocate("dest_loc","care_purpose_cat","mode_class_5", contains("2023"), contains("2025"))

  ind01 <- grep("weighted", colnames(df))
  ind02 <- grep("moe", colnames(df))
  ind03 <- grep("count", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc","care_purpose_cat","mode_class_5", unlist(pmap(list(ind01, ind02, ind03), c)))
  
  return(list(long = rs, wide = df_reorder))
}

create_candrive_tbl <- function(geog) {
  # care trips, age
  
  age_groups <- c("12-15 years", "16-17 years", "18-24 years", "25-34 years", "35-44 years", "45-54 years",
                 "55-64 years", "65-74 years", "75-84 years", "85 years or older")
  
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c(geo_col, "care_purpose_cat", "age", "can_drive"),
                      incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") |>
    mutate(can_drive2 = str_extract(can_drive, "^[^,]+")) |>
    mutate(weighted = percent(prop),
           moe = percent(prop_moe),
           .by = c("survey_year", "can_drive2", "age")) |> 
    mutate(age = factor(age, levels = age_groups)) |> 
    arrange(age)

  v <- c("survey_year", "dest_loc", "care_purpose_cat", "age", "can_drive2", "weighted", "moe", "count")
  
  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "age"),
                names_from = c("survey_year","can_drive2"),
                values_from = c("weighted", "moe", "count"),
                names_glue = "{survey_year}.{can_drive2}.{.value}"
    ) |>
    relocate("dest_loc", "age", contains("2023"), contains("2025"))
 
  ind01 <- grep("weighted", colnames(df))
  ind02 <- grep("moe", colnames(df))
  ind03 <- grep("count", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc", "age", unlist(pmap(list(ind01, ind02, ind03), c)))
  
  return(list(long = rs, wide = df_reorder))
}

create_candrive_tbl_b <- function(geog) {
  # care trips, age, gender
  
  age_groups <- c("12-15 years", "16-17 years", "18-24 years", "25-34 years", "35-44 years", "45-54 years",
                  "55-64 years", "65-74 years", "75-84 years", "85 years or older")
  
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c(geo_col, "care_purpose_cat", "age", "can_drive", "gender2"),
                      incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") |>
    mutate(can_drive2 = str_extract(can_drive, "^[^,]+")) |>
    mutate(weighted = percent(prop),
           moe = percent(prop_moe),
           .by = c("survey_year", "can_drive2", "age", "gender2")) |> 
    mutate(age = factor(age, levels = age_groups)) |> 
    arrange(age)
  
  v <- c("survey_year", "dest_loc", "care_purpose_cat", "age", "can_drive2", "gender2", "weighted", "moe", "count")
  
  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "age", "gender2"),
                names_from = c("survey_year","can_drive2"),
                values_from = c("weighted", "moe", "count"),
                names_glue = "{survey_year}.{can_drive2}.{.value}"
    ) |>
    relocate("dest_loc", "age", "gender2", contains("2023"), contains("2025"))
  
  ind01 <- grep("weighted", colnames(df))
  ind02 <- grep("moe", colnames(df))
  ind03 <- grep("count", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc", "age", "gender2", unlist(pmap(list(ind01, ind02, ind03), c)))
  
  return(list(long = rs, wide = df_reorder))
}

create_hhstr_tbl <- function(geog) {
  # care trips, hh with children < 18 and 85 +
  
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c(geo_col, "care_purpose_cat", "home_children", "home_elder"),
                      incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") 
}