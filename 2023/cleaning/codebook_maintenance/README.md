List of HTS data changes 12/16/2024:

- adult_student: rename from student
- bike_frequency added: combine bike_freq and bike_freq_pre_2023 to get values over 2017-2023
- commute_subsidy_transit: combined benefits_3 and commute_subsidy_1 to get values over 2017-2023
- dest_purpose_cat recode
- dest_purpose_cat_5 added: group dest_purpose_cat into 5 categories
- hhincome_broad: fix typo in label $199,000 -> $199,999 
- hhincome_followup: fix typo in label $199,000 -> $199,999 
- mode_class: replace mode_characterization and mode_simple
- mode_class_5: group mode_class into 5 categories
- origin_purpose_cat: recode
- origin_purpose_cat_5: group origin_purpose_cat into 5 categories
- race_category: recode (earlier in the year)
- school_loc_lat: fix 2019 location that were mislpaced as work location
- school_loc_lng: fix 2019 location that were mislpaced as work location
- transit_frequency: rename from transit_freq
- travelers_total: recode to cap at 5+
- walk_frequency: combine walk_freq and walk_freq_pre_2023 to get values over 2017-2023


removed variables
- commute_mode: duplicated, use work_mode
- consolidated_transit_pass
- mode_characterization
- mode_simple
- student

recoded to match current boundaries (October 2024)
- dest_rgcname
- dest_jurisdiction
- home_jurisdiction	
- home_rgcname
- origin_jurisdiction
- origin_rgcname
- prev_home_jurisdiction
- prev_home_rgcname
- school_county
- school_jurisdiction
- school_rgcname
- work_county
- work_jurisdiction
- work_rgcname


not yet completed (December 2024)
- lifecycle

