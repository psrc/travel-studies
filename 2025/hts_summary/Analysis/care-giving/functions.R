plot_facet_wrap <- function(table, facet, var1, var2, title, color_pal = psrc_colors$pognbgy_5) {
  table |> 
    ggplot(aes(x = {{var1}}, y = prop, fill = {{var2}})) + #gender2, x also = fill
    geom_col(position = "dodge") + 
    geom_linerange(aes(ymin = prop - prop_moe, ymax = prop + prop_moe),
                   orientation = "x",
                   position = position_dodge(width = 0.9)
    ) +
    facet_wrap(vars({{facet}}), ncol = 5, nrow = 1, strip.position = "top"#,
               # label_wrap_gen(width = 10, multi_line = TRUE)
               ) + #survey_year
    labs(x = NULL,
         y = NULL,
         fill = NULL,
         title = title) +
    scale_y_continuous(labels = scales::percent) +
    scale_fill_manual(values = color_pal) +
    psrc_style() +
    theme(panel.grid.major.y = element_blank(),
          axis.title = element_blank(),
          axis.text.x = element_text(angle = 90, vjust = 0.7),
          # Shrink the legend text and title
          legend.text = element_text(size = 8),
          legend.title = element_text(size = 9),
          
          # Shrink the legend key boxes (both width and height)
          legend.key.size = unit(0.4, "cm"),
          legend.position = "bottom"
    )
}

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
    add_row(rs_no_home) |> 
    mutate(prop_per = label_percent(accuracy = 0.1)(prop))
  
  df <- rs |>
    pivot_wider(id_cols = "dest_purpose_cat",
                names_from = c(type, survey_year),
                values_from = "prop_per",
                names_sep = ".")
}

create_care_purpose_tbl <- function(hts_data) {
  # region
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c("dest_region", "care_purpose_cat"),
                      incl_na = FALSE) |>
    mutate(prop_per = label_percent(accuracy = 0.1)(prop),
           prop_moe_per = label_percent(accuracy = 0.1)(prop_moe))
  
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
    mutate(prop_per = label_percent(accuracy = 0.1)(prop),
           moe_per = label_percent(accuracy = 0.1)(prop_moe))

  v <- c("survey_year", "dest_loc", "care_purpose_cat", "income_comp", "mode_class_5", "prop_per", "moe_per", "count")

  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "care_purpose_cat", "mode_class_5"),
                names_from = c("survey_year","income_comp"),
                values_from = c("prop_per", "moe_per", "count"),
                names_glue = "{survey_year}.{income_comp}.{.value}"
                ) |>
    relocate("dest_loc","care_purpose_cat","mode_class_5") 
  
  ind01 <- grep("prop_per", colnames(df))
  ind02 <- grep("moe_per", colnames(df))
  ind03 <- grep("count", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc","care_purpose_cat","mode_class_5", unlist(pmap(list(ind01, ind02, ind03), c)))

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
    mutate(prop_per = label_percent(accuracy = 0.1)(prop),
           moe_per = label_percent(accuracy = 0.1)(prop_moe))

  v <- c("survey_year", "dest_loc", "care_purpose_cat", "income_50", "mode_class_5", "prop_per", "moe_per", "count")

  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "care_purpose_cat", "mode_class_5"),
                names_from = c("survey_year", "income_50"),
                values_from = c("prop_per", "moe_per", "count"),
                names_glue = "{survey_year}.{income_50}.{.value}"
    ) |>
    relocate("dest_loc","care_purpose_cat","mode_class_5")
  
  ind01 <- grep("prop_per", colnames(df))
  ind02 <- grep("moe_per", colnames(df))
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
    relocate("dest_loc","care_purpose_cat",  all_of(unlist(map(survey_year, ~grep(.x, names(.), value = TRUE)))))
 
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
    relocate("dest_loc","care_purpose_cat","mode_class_5",  all_of(unlist(map(survey_year, ~grep(.x, names(.), value = TRUE)))))

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
           .by = c("survey_year", "can_drive2")) |> 
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
    relocate("dest_loc", "age", all_of(unlist(map(survey_year, ~grep(.x, names(.), value = TRUE)))))
 
  ind01 <- grep("weighted", colnames(df))
  ind02 <- grep("moe", colnames(df))
  ind03 <- grep("count", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc", "age", unlist(pmap(list(ind01, ind02, ind03), c)))
  
  return(list(long = rs, wide = df_reorder))
}

create_candrive_tbl_gender <- function(geog) {
  # care trips, can drive, gender
  
  geo_col <- case_when(geog == "Region" ~ "dest_region",
                       geog %in% c("King County", "Kitsap County", "Pierce County", "Snohomish County") ~ "dest_county")
  
  rs <- psrc_hts_stat(df_hts,
                      analysis_unit = "trip",
                      group_vars = c(geo_col, "care_purpose_cat", "can_drive2", "gender2"),
                      incl_na = FALSE) |>
    rename(dest_loc = sym(geo_col)) |>
    filter(dest_loc == geog,
           care_purpose_cat == "Care") |>
    mutate(weighted = percent(prop),
           moe = percent(prop_moe))
  
  v <- c("survey_year", "dest_loc", "care_purpose_cat", "can_drive2", "gender2", "weighted", "moe", "count")
  
  df <- rs |>
    select(all_of(v)) |>
    pivot_wider(id_cols = c("dest_loc", "gender2"),
                names_from = c("survey_year","can_drive2"),
                values_from = c("weighted", "moe", "count"),
                names_glue = "{survey_year}.{can_drive2}.{.value}"
    ) |>
    relocate("dest_loc", "gender2", all_of(unlist(map(survey_year, ~grep(.x, names(.), value = TRUE)))))
  
  ind01 <- grep("weighted", colnames(df))
  ind02 <- grep("moe", colnames(df))
  ind03 <- grep("count", colnames(df))
  
  df_reorder <- df |> 
    select("dest_loc", "gender2", unlist(pmap(list(ind01, ind02, ind03), c)))
  
  return(list(long = rs, wide = df_reorder))
}