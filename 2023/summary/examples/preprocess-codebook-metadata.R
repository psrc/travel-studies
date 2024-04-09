# new_groups <- data.table(
#   variable = c("mode_simple", 'dest_purpose_simple', 'telework_time_broad', 'gender_grp', 'telecommute_freq_simple','seattle_bellevue'),
#   is_checkbox = c(0,0,0,0,0,0),
#   hh = c(0,0,0,0,0,1),
#   person = c(0,0,0,1, 1,0),
#   day = c(0,0,1,0, 0,1),
#   trip = c(1,1, 0, 0,0,0),
#   vehicle = c(0,0,0,0,0,0),
#   location = c(0,0,0,0,0,0),
#   description = c("Mode Group", "Trip Purpose", "Telework Hours", "Gender", 'Telecommute Frequency', 'Home City'),
#   logic = c('mode aggregation', 'destination aggregation',"telework time aggregation", "gender group", 'telecommute frequency group', 'home in Seattle or Bellevue'),
#   data_type = c("integer/categorical", "integer/categorical", "integer/categorical", "integer/categorical", "integer/categorical","integer/categorical"),
#   shared_name = c("mode_simple", 'dest_purpose_simple', 'telework_time_broad', 'gender_grp', 'telecommute_freq_simple', 'seattle_bellevue')
# )

var_mode_simple <- list(variable = "mode_simple",
                        is_checkbox = 0,
                        hh = 0,
                        person = 0,
                        day = 0,
                        trip = 1,
                        vehicle = 0,
                        location = 0,
                        description = "Mode Group",
                        logic = "mode aggregation",
                        data_type = "integer/categorical",
                        shared_name = "mode_simple"
)

var_dest_purpose_simple <- list(variable = "dest_purpose_simple",
                                is_checkbox = 0,
                                hh = 0,
                                person = 0,
                                day = 0,
                                trip = 1,
                                vehicle = 0,
                                location = 0,
                                description = "Trip Purpose",
                                logic = "destination aggregation",
                                data_type = "integer/categorical",
                                shared_name = "dest_purpose_simple"
)

var_telework_time_broad <- list(variable = "telework_time_broad",
                                is_checkbox = 0,
                                hh = 0,
                                person = 0,
                                day = 1,
                                trip = 0,
                                vehicle = 0,
                                location = 0,
                                description = "Telework Hours",
                                logic = "telework time aggregation",
                                data_type = "integer/categorical",
                                shared_name = "telework_time_broad"
)

var_gender_grp <- list(variable = "gender_grp",
                       is_checkbox = 0,
                       hh = 0,
                       person = 1,
                       day = 0,
                       trip = 0,
                       vehicle = 0,
                       location = 0,
                       description = "Gender",
                       logic = "gender group",
                       data_type = "integer/categorical",
                       shared_name = "gender_grp"
)

var_telecommute_freq_simple <- list(variable = "telecommute_freq_simple",
                                    is_checkbox = 0,
                                    hh = 0,
                                    person = 1,
                                    day = 0,
                                    trip = 0,
                                    vehicle = 0,
                                    location = 0,
                                    description = "Telecommute Frequency",
                                    logic = "telecommute frequency group",
                                    data_type = "integer/categorical",
                                    shared_name = "telecommute_freq_simple"
)

var_seattle_bellevue <- list(variable = "seattle_bellevue",
                             is_checkbox = 0,
                             hh = 1,
                             person = 0,
                             day = 1,
                             trip = 0,
                             vehicle = 0,
                             location = 0,
                             description = "Home City",
                             logic = "home in Seattle or Bellevue",
                             data_type = "integer/categorical",
                             shared_name = "seattle_bellevue"
)

vars <- str_subset(ls(all.names = TRUE), "var_.*")
new_groups <- map(vars, ~get(.x)) |> rbindlist()

rm(list = vars)
