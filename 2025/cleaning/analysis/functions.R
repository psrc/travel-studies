library(tidyverse)
library(psrcelmer)
library(config)

# lookup tool
library(qdapTools)
# summary table
library(tableone)
library(sf)

config <- config::get()
codebook <- read_csv(config$codebook)


# get PSRC layers
county_layer <- st_read_elmergeo('COUNTY_BACKGROUND',project_to_wgs84 = FALSE)
city_layer <- st_read_elmergeo('CITIES',project_to_wgs84 = FALSE)
center_layer <- st_read_elmergeo('URBAN_CENTERS',project_to_wgs84 = FALSE)
rg_layer <- st_read_elmergeo('REGIONAL_GEOGRAPHIES',project_to_wgs84 = FALSE)

get_labels <- function(.data, varname, table_name, order=TRUE){
  
  var_lookup <- codebook[codebook$table == table_name & codebook$variable == varname,]
  var_lookup <- data.frame(var_lookup$value,var_lookup$label)
  
  s_unordered <- lookup(.data, var_lookup)
  s_ordered <- factor(s_unordered, levels=var_lookup[['var_lookup.label']])
  
  return( if(order){s_ordered} else{s_unordered} )
}

get_county <- function(.data, varname, rename){
  counties <- data.frame(value=c("53033", "53035", "53053", "53061"),
                         county = c("King","Kitsap","Pierce","Snohomish")
  )
  
  test <- .data %>%
    mutate(geog_county = lookup(substr(.[[varname]],1,5),counties))
  .data[[rename]] <- test[['geog_county']]
  
  return(.data)
  
}

# get summary table
get_vars_summary <- function(table_name, summary_vars, order = TRUE){
  
  df <- tables[[table_name]] %>%
    mutate(across(all_of(summary_vars), ~get_labels(., varname = cur_column(), table_name, order = order)))
  
  return(
    CreateTableOne(data = df,
                   vars = summary_vars,
                   includeNA = TRUE
    )
  )
}

# join county, city, center layers
get_psrc_geographies <- function(data, id, lng, lat, prefix_name){
  
  gdf <- data %>% 
    select(all_of(c(id,lng,lat))) %>%
    st_as_sf(coords = c(lng, lat), crs = 4326) %>%
    st_transform(2285)
  
  df <- gdf %>% 
    st_join(county_layer %>% select(county_nm), join = st_intersects) %>%
    st_join(city_layer %>% select(city_name), join = st_intersects) %>%
    st_join(center_layer %>% select(name), join = st_intersects) %>%
    st_join(rg_layer %>% select(class_desc), join = st_intersects) %>%
    rename(county = county_nm,
           city = city_name,
           center = name,
           rg = class_desc) %>%
    rename_with(~ paste0(prefix_name, .), all_of(c("county","city","center", "rg")))
  
  st_geometry(df) <- NULL
  
  return(df)
}