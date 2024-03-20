library(data.table)
library(stringr)
library(travelSurveyTools)

### Load in Data --------
user = Sys.info()[['user']]

# load in data received from PSRC on 1/24
trip = fread(str_glue("C:/Users/{user}/Resource Systems Group, Inc/Transportation MR - Documents/",
                      "PSRC Survey Program/210252_PSRC_HTS/2023 Puget Sound Travel Study/",
                      "5.Deliverables/7_Data&Documentation/0_Data_Inputs_From_PSRC/from_psrc_20240201/Trip.csv"))

# load in combined dataset from portal (PSRC change to their path)
household_trips = read.csv(str_glue('C:/Users/{user}/Downloads/Household_Travel_Survey_Trips.csv'))
setDT(household_trips)

# load in new codebook from PSRC (PSRC change to their path)
variable_list = readxl::read_xlsx(str_glue('C:/Users/{user}/OneDrive - Resource Systems Group, Inc/Documents/PSRC_Combined_Codebook_2023_groupings.xlsx'),
                                  sheet = 'variable_list_2023')
value_labels = readxl::read_xlsx(str_glue('C:/Users/{user}/OneDrive - Resource Systems Group, Inc/Documents/PSRC_Combined_Codebook_2023_groupings.xlsx'),
                                 sheet = 'value_labels_2023')
setDT(variable_list)
setDT(value_labels)

### Data Updates -------

# make mode_simple in 2023 trip table
mode_simple_labels = value_labels[group_1_title == 'mode_simple', c('value', 'group_1_value')]
trip = merge(trip, mode_simple_labels, by.x = 'mode_1', by.y = 'value')
setnames(trip, 'group_1_value', 'mode_simple')
setnames(trip, 'tripid', 'trip_id')

# add 2023 trip table to combined trip table
household_trips = rbind(household_trips, trip, fill = TRUE)

# make hts_data a list of just the combined trip table
hts_data = list(trip = household_trips)

# codebook updates
variable_list[, shared_name := ifelse(
  grepl('--', description_2023),
  sub('_[^_]*$', '', variable), variable)
]
variable_list[, is_checkbox := ifelse(grepl('--', description_2023), 1, 0)]
setnames(variable_list, 'trip_final', 'trip')
setnames(variable_list, 'data_type_2023', 'data_type')
variable_list[variable == 'survey_year', data_type := 'character']
setnames(variable_list, 'description_2023', 'description')


### Use package for summary -----
prepped_dt = hts_prep_data(summarize_var = 'mode_simple',
                           summarize_by = 'survey_year',
                           data = hts_data,
                           id_cols = 'trip_id',
                           wt_cols = 'trip_weight',
                           weighted = FALSE,
                           missing_values = '')

hts_summary(prepped_dt = prepped_dt$cat,
            summarize_var = 'mode_simple',
            summarize_by = 'survey_year',
            id_cols = 'trip_id',
            weighted = FALSE)
