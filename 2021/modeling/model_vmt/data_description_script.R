library(echarts4r)
library(psrcplot)
library(psrc.travelsurvey)
library(psrccensus)
library(psrcelmer)
library(tidyverse)

install_psrc_fonts()

Sys.setenv(CENSUS_API_KEY = '3fc20d0d6664692c0becc323b82c752408d843d9')
Sys.getenv("CENSUS_API_KEY")

hhts_codebook <- get_table(schema = 'HHSurvey', tbl_name = 'variables_codebook')
