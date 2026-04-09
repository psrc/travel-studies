create_trip_purpose_tbl <- function(hts_data) {
  # This section prints a table with weighted/unweighted x Home/Exclude Home x trip purpose

  rs1 <- psrc_hts_stat(hts_data,
                       analysis_unit = "trip",
                       group_vars = c("dest_region","dest_purpose_cat"),
                       incl_na = FALSE) |>
    mutate(type = "Include HOME")
  
  rs1_no_home <- psrc_hts_stat(hts_data,
                               analysis_unit = "trip",
                               group_vars = c("dest_region","dest_purpose_cat_no_home"),
                               incl_na = FALSE)  |>
    mutate(type = "Exclude HOME") |>
    rename(dest_purpose_cat = dest_purpose_cat_no_home)
  
  # Region
  
  rs <- rs1 |>  
    add_row(rs1_no_home)
  
  rs_reg <- rs |>
    mutate(unweighted = percent(count/sum(count)),
           weighted = percent(prop),
           .by = "type")
  
  per_group <- ("dest_purpose_cat")
    
  df <- rs_reg |>
    pivot_wider(id_cols = all_of(per_group),
                names_from = c(type, survey_year),
                values_from = contains("weighted"),
                names_sep = ".") 
}