## general expressions
# rMove only
f.rMove <- quo(diary_platform == "rmove")
# adult: 18+ years old
f.adult <- quo(age_detailed >= 18)
# adult: 16+ years old
f.adult16 <- quo(age_detailed >= 16)
# if employment is not “not employed for pay”
f.employed_for_pay <- quo(employment %in% c(1,2,3,4,8))
# job_type "work only from home"
f.only_wfh <- quo(workplace == 4)
# job_type "leave from home to drive/bike/travel for work”
f.work_as_driver <- quo(workplace %in% c(8,9))

## variable targets
# 1. frequency variables
f.var.share_1 <- quo(!!f.adult)
f.var.share_2 <- quo(!!f.adult)
f.var.share_3 <- quo(!!f.adult)
f.var.share_4 <- quo(!!f.adult)
f.var.share_5 <- quo(!!f.adult)
f.var.share_996 <- quo(!!f.adult)
f.var.walk_freq <-     quo(!!f.adult & share_1==1)
f.var.bike_freq <-     quo(!!f.adult & share_2==1)
f.var.transit_freq <-  quo(!!f.adult & share_3==1)
f.var.tnc_freq <-      quo(!!f.adult & share_4==1)
f.var.carshare_freq <- quo(!!f.adult & share_5==1)
# 2. commute subsidy: if employment is not “not employed for pay”
f.var.commute_subsidy_1 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_2 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_3 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_4 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_5 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_6 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_7 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_996 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_998 <- quo(!!f.employed_for_pay)
f.var.commute_subsidy_use_1 <- quo(commute_subsidy_1==1)
f.var.commute_subsidy_use_2 <- quo(commute_subsidy_2==1)
f.var.commute_subsidy_use_3 <- quo(commute_subsidy_3==1)
f.var.commute_subsidy_use_4 <- quo(commute_subsidy_4==1)
f.var.commute_subsidy_use_5 <- quo(commute_subsidy_5==1)
f.var.commute_subsidy_use_6 <- quo(commute_subsidy_6==1)
f.var.commute_subsidy_use_7 <- quo(commute_subsidy_7==1)
# if any commute subsidy is selected
f.var.commute_subsidy_use_996 <- quo(
  if_any(c(commute_subsidy_1,commute_subsidy_2,commute_subsidy_3,commute_subsidy_4,
           commute_subsidy_5,commute_subsidy_6,commute_subsidy_7), 
         ~ .==1))

# 3. other frequency variables
# commute_freq: if employment is not “not employed for pay” and 
# job_type IS NOT “leave from home to drive/bike/travel for work”
f.var.commute_freq <- quo(!!f.employed_for_pay & !(!!(f.only_wfh) | !!(f.work_as_driver)))
f.var.telecommute_freq <- quo(!!f.employed_for_pay & commute_freq!=1)
# remote_class_freq: if child who is not cared for at home or attending daycare 
f.var.remote_class_freq <- quo(!(!!f.adult) & !schooltype %in% c(1,11,995))
f.var.school_freq <- quo(!(!!f.adult) & !schooltype %in% c(5,11,995))

# 4. other variables
f.var.workplace <- quo(!!f.employed_for_pay)
f.var.drive_for_work <- quo(!!f.adult16 & workplace %in% c(8,9))
f.var.school_mode_typical <- quo(
  # child
  (!(!!f.adult) & !schooltype %in% c(5,11,995)) |
  # adult student and not home school
    (!!f.adult & !schooltype %in% c(5,995)))
f.var.work_mode <- quo(!commute_freq %in% c(995,9))
f.var.school_loc_lat <- quo(
  # child
  (!(!!f.adult) & !schooltype %in% c(5,11,995)) |
    # adult student in-person
    (!!f.adult & student %in% c(4,6)))

f.var.work_lat <- quo(office_available==1)










