library(tidyverse)
library(plotly)
library(psrc.travelsurvey)
library(psrcelmer)
library(psrcplot)
library(sf)
library(spatialEco)
library(kableExtra)
library(leaflet)


# calculate centers and region area
sf_use_s2(FALSE)

# get all layers
bg2020.lyr <- st_read_elmergeo("BLOCKGRP2020_NOWATER")
block2020.lyr <- st_read_elmergeo("BLOCK2020") %>% select(county_name,geoid20,placename,land_acres,total_pop20)
uga.lyr <- st_read_elmergeo("urban_growth_area_evw") %>% select(county_name,sum_acres,SDE_STATE_ID,Shape) %>% mutate(UGA = "UGA")
center.lyr <- st_read_elmergeo('URBAN_CENTERS')


# calculate geography area
psrc_region_area <- sum(bg2020.lyr$land_acres)
uga_area <- sum(uga.lyr$sum_acres)
centers_area <- sum(center.lyr$acres)

center_data <- center.lyr
st_geometry(center_data) <- NULL
# areas: individual rgcs, rgc, urban/metro
rgc_indv_area <- center_data %>%
  mutate(d_rgcname="RGC") %>%
  select(name,d_rgcname,category,acres) %>%
  add_row(data.frame(name=c("Not RGC"),
                     d_rgcname=c("Not RGC"),
                     category=c("Not RGC"),
                     acres=c(uga_area-centers_area)))

rgc_area <- rgc_indv_area %>%
  group_by(d_rgcname) %>%
  summarise_at(vars(acres),sum)

metro_urban_area <- rgc_indv_area %>%
  group_by(category) %>%
  summarise_at(vars(acres),sum)

# population and employment
df_au <- read_csv("activity_units.csv") 

df_rgc <- read_csv("activity_units.csv") %>%
  filter((d_rgcname=="RGC" & category=="Total") | (d_rgcname=="Not RGC")) %>%
  select(all_of(c("d_rgcname","2017/2019 AU"))) %>%
  rename(activity_unit = `2017/2019 AU`) %>%
  left_join(rgc_area, by="d_rgcname")

# df_centers <- read_csv("indv_center_pop_emp_2020.csv") %>%
#   # add not rgc data
#   add_row(df_rgc %>% select(d_rgcname,population,employment) %>% rename(d_rgcname_indv=d_rgcname) %>% filter(d_rgcname_indv=="Not RGC")) %>%
#   left_join(rgc_indv_area[,c("name","acres")], by=c("d_rgcname_indv"="name")) %>%
#   mutate(activity_unit=population+employment)

df_metro_urban <-  read_csv("activity_units.csv") %>%
  filter(category %in% c("Metro", "Urban","Not RGC")) %>%
  select(all_of(c("category","2017/2019 AU"))) %>%
  rename(activity_unit = `2017/2019 AU`) %>%
  left_join(metro_urban_area, by="category")

# get 2017/2019 trip data
trip_vars = c("trip_id","driver","mode_1","mode_simple",'dest_purpose_cat', 'origin_purpose_cat',
              "google_duration", 'trip_path_distance',
              "origin_lat","origin_lng","o_rgcname","dest_lat","dest_lng","d_rgcname")

trip_data_17_19 <- get_hhts("2017_2019", "t", vars=trip_vars) %>%
  left_join(rgc_indv_area %>% select(name,category), by = c("d_rgcname"="name")) %>%
  mutate(trip_type = case_when(dest_purpose_cat %in% c("Errand/Other","Shop","Social/Recreation","Escort","Meal")~"Non-work", 
                               dest_purpose_cat %in% c("Work","Work-related","School")~"Work",
                               TRUE~NA),
         mode_simple = case_when(mode_1 == "Bicycle owned by my household (rMove only)" ~"Bike",
                                 mode_1 == "Bike-share bicycle (rMove only)" ~"Bike",
                                 mode_1 == "Borrowed bicycle (e.g., from a friend) (rMove only)" ~"Bike",
                                 mode_1 == "Other motorcycle/moped" ~"Other",
                                 mode_1 == "Other rented bicycle (rMove only)" ~"Bike",
                                 mode_1 == "Scooter or e-scooter (e.g., Lime, Bird, Razor)" ~"Other",
                                 is.na(mode_simple)~"Drive",
                                 TRUE~mode_simple),
         d_rgcname_indv = ifelse(is.na(d_rgcname), "Not RGC", d_rgcname),
         d_rgcname = factor(ifelse(is.na(d_rgcname), "Not RGC", "RGC"), levels=c("RGC", "Not RGC")),
         category = factor(ifelse(is.na(category), "Not RGC", category), levels=c("Metro","Urban", "Not RGC"))) %>%
  filter(!is.na(trip_type),!is.na(dest_lat))


# include only UGA trips
sf_trip <- st_as_sf(trip_data_17_19, coords = c("dest_lng","dest_lat"),crs=4326)
sf_trip_uga <- sf_trip %>%
  st_join(., uga.lyr[,c("UGA")]) %>%
  mutate(UGA = replace_na(UGA,"not UGA")) %>%
  filter(UGA=="UGA")

trip_data_uga_17_19 <- trip_data_17_19 %>% filter(trip_id %in% sf_trip_uga$trip_id)


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
