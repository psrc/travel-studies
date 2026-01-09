library(tidyverse)
library(plotly)
library(travelSurveyTools)
library(psrc.travelsurvey)
library(psrcelmer)
library(psrcplot)
library(sf)
library(spatialEco)
library(kableExtra)
library(leaflet)
library(data.table)

# read in functions for new package
source("region_dest_data.R")
source('../../../../2023/summary/survey-23-preprocess_JLin.R')


# 2023 population and employment

df_rgc_2023 <- read_csv("activity_units.csv") %>%
  filter((d_rgcname=="RGC" & category=="Total") | (d_rgcname=="Not RGC")) %>%
  select(all_of(c("d_rgcname","2023 AU"))) %>%
  rename(activity_unit = `2023 AU`) %>%
  left_join(rgc_area, by="d_rgcname")

df_metro_urban_2023 <-  read_csv("activity_units.csv") %>%
  filter(category %in% c("Metro", "Urban","Not RGC")) %>%
  select(all_of(c("category","2023 AU"))) %>%
  rename(activity_unit = `2023 AU`) %>%
  left_join(metro_urban_area, by="category")


# get codebook ----
cb_path = str_glue("PSRC_Codebook_2023_fix.xlsx")

variable_list <- readxl::read_xlsx(cb_path, sheet = 'variable_list') %>%
  filter(!is.na(trip))


setDT(variable_list)

# 1. add grouping variables to variable_list ----
variable_list<-rbind(
  variable_list,
  data.table(
    variable = c("mode_simple","d_rgcname","category","trip_type"),
    is_checkbox = c(0,0,0,0),
    hh = c(0,0,0,0),
    person = c(0,0,0,0),
    day = c(0,0,0,0),
    trip = c(1,1,1,1),
    vehicle = c(0,0,0,0),
    location = c(0,0,0,0),
    description = c("mode_simple","d_rgcname","category","trip_type"),
    logic = c("mode_simple","d_rgcname","category","trip_type"),
    data_type = c("integer/categorical","integer/categorical","integer/categorical","integer/categorical"),
    shared_name = c("mode_simple","d_rgcname","category","trip_type")
  )
)
value_labels <- readxl::read_xlsx(cb_path, sheet = 'value_labels')
setDT(value_labels)


# 2. add grouping variables to value_labels ----
# Add variables from existing grouping
list_mode_simple <- get_var_grouping(value_tbl = value_labels, group_number = "1", grouping_name = "mode_simple")
list_dest_purpose_simple <- get_var_grouping(value_tbl = value_labels, group_number = "1", grouping_name = "dest_purpose_simple")
# Add custom variable 
add_d_rgcname <- create_custom_variable(value_labels, variable_name="d_rgcname",
                                        label_vector = c("RGC", "Not RGC"))
add_category <- create_custom_variable(value_labels, variable_name="category",
                                       label_vector = c("Metro","Urban", "Not RGC"))
add_trip_type <- create_custom_variable(value_labels, variable_name="trip_type",
                                       label_vector = c("Work", "Non-work"))


value_labels <- value_labels %>%
  add_row(list_mode_simple[[1]]) %>%
  add_row(list_dest_purpose_simple[[1]]) %>%
  add_row(add_d_rgcname) %>%
  add_row(add_category) %>%
  add_row(add_trip_type)

# 3. Create HTS data ----
essential_vars <- c("survey_year", "trip_id", "household_id as hh_id", "day_id", "person_id", "trip_weight")
trip_vars = c("driver","mode_1","dest_purpose", "dest_rgcname", "dest_lng", "dest_lat")

trip_data_23 <- get_query(sql= paste("select", 
                                     paste(essential_vars,collapse = ","), 
                                     ",",
                                     paste(trip_vars,collapse = ","),
                                     "from HHSurvey.v_trips_labels")) 
setDT(trip_data_23)

# Set IDs as characters
cols <- c("survey_year", "trip_id","hh_id","person_id","day_id")
trip_data_23[, (cols) := lapply(.SD, function(x) as.character(x)), .SDcols = cols]


df_trip_data_23 <- trip_data_23 %>%
  add_variable_to_data(list_mode_simple[[2]]) %>%
  add_variable_to_data(list_dest_purpose_simple[[2]]) %>% 
  left_join(rgc_indv_area %>% select(name,category), by = c("dest_rgcname"="name")) %>%
  mutate(trip_type = case_when(dest_purpose_simple %in% c("Errand/Other","Shop","Social/Recreation","Escort","Meal")~"Non-work", 
                               dest_purpose_simple %in% c("Primary Work","Work-related","School")~"Work",
                               TRUE~NA),
         # d_rgcname_indv = ifelse(is.na(dest_rgcname), "Not RGC", dest_rgcname),
         d_rgcname = factor(case_when(is.na(dest_rgcname)~ "Not RGC", 
                                      dest_rgcname=="Not RGC"~ "Not RGC",
                                      TRUE~ "RGC"), 
                            levels=c("RGC", "Not RGC")),
         category = factor(ifelse(is.na(category), "Not RGC", category), levels=c("Metro","Urban", "Not RGC"))) %>%
  filter(!is.na(trip_type),!is.na(dest_lat))

# include only UGA trips
sf_trip_23 <- st_as_sf(df_trip_data_23, coords = c("dest_lng","dest_lat"),crs=4326)
sf_trip_uga_23 <- sf_trip_23 %>%
  st_join(., uga.lyr[,c("UGA")]) %>%
  mutate(UGA = replace_na(UGA,"not UGA")) %>%
  filter(UGA=="UGA")

df_trip_data_23_uga <- df_trip_data_23 %>% filter(trip_id %in% sf_trip_uga_23$trip_id)
# hts_data = list(# hh = hh,
#                 # person = person,
#                 # day = day,
#                 trip = df_trip_data_23_uga)


addLegend_decreasing <- function (map, position = c("topright", "bottomright", "bottomleft", 
                                                    "topleft"), pal, values, na.label = "NA", bins = 7, colors, 
                                  opacity = 0.5, labels = NULL, labFormat = labelFormat(), 
                                  title = NULL, className = "info legend", layerId = NULL, 
                                  group = NULL, data = getMapData(map), decreasing = FALSE) {
  position <- match.arg(position)
  type <- "unknown"
  na.color <- NULL
  extra <- NULL
  if (!missing(pal)) {
    if (!missing(colors)) 
      stop("You must provide either 'pal' or 'colors' (not both)")
    if (missing(title) && inherits(values, "formula")) 
      title <- deparse(values[[2]])
    values <- evalFormula(values, data)
    type <- attr(pal, "colorType", exact = TRUE)
    args <- attr(pal, "colorArgs", exact = TRUE)
    na.color <- args$na.color
    if (!is.null(na.color) && col2rgb(na.color, alpha = TRUE)[[4]] == 
        0) {
      na.color <- NULL
    }
    if (type != "numeric" && !missing(bins)) 
      warning("'bins' is ignored because the palette type is not numeric")
    if (type == "numeric") {
      cuts <- if (length(bins) == 1) 
        pretty(values, bins)
      else bins	
      
      if (length(bins) > 2) 
        if (!all(abs(diff(bins, differences = 2)) <= 
                 sqrt(.Machine$double.eps))) 
          stop("The vector of breaks 'bins' must be equally spaced")
      n <- length(cuts)
      r <- range(values, na.rm = TRUE)
      cuts <- cuts[cuts >= r[1] & cuts <= r[2]]
      n <- length(cuts)
      p <- (cuts - r[1])/(r[2] - r[1])
      extra <- list(p_1 = p[1], p_n = p[n])
      p <- c("", paste0(100 * p, "%"), "")
      if (decreasing == TRUE){
        colors <- pal(rev(c(r[1], cuts, r[2])))
        labels <- rev(labFormat(type = "numeric", cuts))
      }else{
        colors <- pal(c(r[1], cuts, r[2]))
        labels <- rev(labFormat(type = "numeric", cuts))
      }
      colors <- paste(colors, p, sep = " ", collapse = ", ")
      
    }
    else if (type == "bin") {
      cuts <- args$bins
      n <- length(cuts)
      mids <- (cuts[-1] + cuts[-n])/2
      if (decreasing == TRUE){
        colors <- pal(rev(mids))
        labels <- rev(labFormat(type = "bin", cuts))
      }else{
        colors <- pal(mids)
        labels <- labFormat(type = "bin", cuts)
      }
      
    }
    else if (type == "quantile") {
      p <- args$probs
      n <- length(p)
      cuts <- quantile(values, probs = p, na.rm = TRUE)
      mids <- quantile(values, probs = (p[-1] + p[-n])/2, 
                       na.rm = TRUE)
      if (decreasing == TRUE){
        colors <- pal(rev(mids))
        labels <- rev(labFormat(type = "quantile", cuts, p))
      }else{
        colors <- pal(mids)
        labels <- labFormat(type = "quantile", cuts, p)
      }
    }
    else if (type == "factor") {
      v <- sort(unique(na.omit(values)))
      colors <- pal(v)
      labels <- labFormat(type = "factor", v)
      if (decreasing == TRUE){
        colors <- pal(rev(v))
        labels <- rev(labFormat(type = "factor", v))
      }else{
        colors <- pal(v)
        labels <- labFormat(type = "factor", v)
      }
    }
    else stop("Palette function not supported")
    if (!any(is.na(values))) 
      na.color <- NULL
  }
  else {
    if (length(colors) != length(labels)) 
      stop("'colors' and 'labels' must be of the same length")
  }
  legend <- list(colors = I(unname(colors)), labels = I(unname(labels)), 
                 na_color = na.color, na_label = na.label, opacity = opacity, 
                 position = position, type = type, title = title, extra = extra, 
                 layerId = layerId, className = className, group = group)
  invokeMethod(map, data, "addLegend", legend)
}
