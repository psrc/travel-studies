USE [HouseholdTravelSurvey2019]
GO

/****** Object:  Table [dbo].[Household]    Script Date: 8/3/2019 6:49:49 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
This copies the data originally delivered in dbo.1_household, dbo.2_Person, dbo.3_Vehicle, dbo.4_Day,
  dbo.4_Trip and dbo.6_Location into copies of these under schema HHSurvey.
The copied tables each have a primary key [recid] that is an alternate to the candidate key provided
  in the original tables in the dbo schema.  
*/

drop table if exists HHSurvey.[Household]

CREATE TABLE [HHSurvey].[Household](
	recid int identity not null,
	[hhid] [decimal](19, 0) not NULL,
	[sample_segment] [real] NULL,
	[sample_county] [nvarchar](150) NULL,
	[cityofseattle] [int] NULL,
	[psrc] [int] NULL,
	[sample_lat] [decimal](28, 6) NULL,
	[sample_lng] [decimal](28, 6) NULL,
	[reported_lat] [decimal](28, 6) NULL,
	[reported_lng] [decimal](28, 6) NULL,
	[final_home_tract] [decimal](19, 0) NULL,
	[final_home_bg] [decimal](19, 0) NULL,
	[final_home_block] [decimal](19, 0) NULL,
	[final_home_puma10] [decimal](19, 0) NULL,
	[final_home_rgcnum] [int] NULL,
	[final_home_uvnum] [int] NULL,
	[hhgroup] [int] not NULL,
	[travelweek] [int] NULL,
	[traveldate_start] [datetime] NULL,
	[traveldate_end] [datetime] NULL,
	[dayofweek] [int] NULL,
	[hhsize] [int] NULL,
	[vehicle_count] [int] NULL,
	[numadults] [int] NULL,
	[numchildren] [int] NULL,
	[numworkers] [int] NULL,
	[lifecycle] [int] NULL,
	[hhincome_detailed] [int] NULL,
	[hhincome_followup] [int] NULL,
	[hhincome_broad] [int] NULL,
	[car_share] [int] NULL,
	[rent_own] [int] NULL,
	[res_dur] [int] NULL,
	[res_type] [int] NULL,
	[res_months] [int] NULL,
	[prev_home_wa] [int] NULL,
	[prev_home_lat] [float] NULL,
	[prev_home_lng] [float] NULL,
	[prev_home_notwa_notus] [int] NULL,
	[prev_home_notwa_city] [nvarchar](max) NULL,
	[prev_home_notwa_state] [int] NULL,
	[prev_home_notwa_zip] [nvarchar](7) NULL,
	[prev_rent_own] [int] NULL,
	[prev_res_type] [int] NULL,
	[res_factors_30min] [int] NULL,
	[res_factors_afford] [int] NULL,
	[res_factors_closefam] [int] NULL,
	[res_factors_hwy] [int] NULL,
	[res_factors_school] [int] NULL,
	[res_factors_space] [int] NULL,
	[res_factors_transit] [int] NULL,
	[res_factors_walk] [int] NULL,
	[prev_res_factors_housing_cost] [int] NULL,
	[prev_res_factors_income_change] [int] NULL,
	[prev_res_factors_community_change] [int] NULL,
	[prev_res_factors_hh_size] [int] NULL,
	[prev_res_factors_more_space] [int] NULL,
	[prev_res_factors_less_space] [int] NULL,
	[prev_res_factors_employment] [int] NULL,
	[prev_res_factors_school] [int] NULL,
	[prev_res_factors_crime] [int] NULL,
	[prev_res_factors_quality] [int] NULL,
	[prev_res_factors_forced] [int] NULL,
	[prev_res_factors_no_answer] [int] NULL,
	[prev_res_factors_other] [int] NULL,
	[prev_res_factors_specify] [nvarchar](max) NULL,
	[rmove_optin] [int] NULL,
	[diary_incentive_type] [int] NULL,
	[contact_email] [int] NULL,
	[contact_phone] [int] NULL,
	[foreign_language] [int] NULL,
	[google_translate] [int] NULL,
	[recruit_start_pt] [datetime] NULL,
	[recruit_end_pt] [datetime] NULL,
	[call_center_recruit] [int] NULL,
	[mobile_device] [int] NULL,
	[recruit_duration_min] [int] NULL,
	[nwkdays] [int] NULL,
	[numdayscomplete] [int] NULL,
	[num_trips] [int] NULL
) ON [PRIMARY]
GO

alter table HHSurvey.[Household] 
	add constraint PK_Household_recid PRIMARY KEY CLUSTERED (recid)

create unique nonclustered index idx_HHSurvey_Household_hhid on HHSurvey.Household (HHID)

INSERT INTO HHSurvey.[Household] (
	HHID
      ,[sample_segment]
      ,[sample_county]
      ,[cityofseattle]
      ,[psrc]
      ,[sample_lat]
      ,[sample_lng]
      ,[reported_lat]
      ,[reported_lng]
      ,[final_home_tract]
      ,[final_home_bg]
      ,[final_home_block]
      ,[final_home_puma10]
      ,[final_home_rgcnum]
      ,[final_home_uvnum]
      ,[hhgroup]
      ,[travelweek]
      ,[traveldate_start]
      ,[traveldate_end]
      ,[dayofweek]
      ,[hhsize]
      ,[vehicle_count]
      ,[numadults]
      ,[numchildren]
      ,[numworkers]
      ,[lifecycle]
      ,[hhincome_detailed]
      ,[hhincome_followup]
      ,[hhincome_broad]
      ,[car_share]
      ,[rent_own]
      ,[res_dur]
      ,[res_type]
      ,[res_months]
      ,[prev_home_wa]
      ,[prev_home_lat]
      ,[prev_home_lng]
      ,[prev_home_notwa_notus]
      ,[prev_home_notwa_city]
      ,[prev_home_notwa_state]
      ,[prev_home_notwa_zip]
      ,[prev_rent_own]
      ,[prev_res_type]
      ,[res_factors_30min]
      ,[res_factors_afford]
      ,[res_factors_closefam]
      ,[res_factors_hwy]
      ,[res_factors_school]
      ,[res_factors_space]
      ,[res_factors_transit]
      ,[res_factors_walk]
      ,[prev_res_factors_housing_cost]
      ,[prev_res_factors_income_change]
      ,[prev_res_factors_community_change]
      ,[prev_res_factors_hh_size]
      ,[prev_res_factors_more_space]
      ,[prev_res_factors_less_space]
      ,[prev_res_factors_employment]
      ,[prev_res_factors_school]
      ,[prev_res_factors_crime]
      ,[prev_res_factors_quality]
      ,[prev_res_factors_forced]
      ,[prev_res_factors_no_answer]
      ,[prev_res_factors_other]
      ,[prev_res_factors_specify]
      ,[rmove_optin]
      ,[diary_incentive_type]
      ,[contact_email]
      ,[contact_phone]
      ,[foreign_language]
      ,[google_translate]
      ,[recruit_start_pt]
      ,[recruit_end_pt]
      ,[call_center_recruit]
      ,[mobile_device]
      ,[recruit_duration_min]
      ,[nwkdays]
      ,[numdayscomplete]
      ,[num_trips]
)
SELECT [hhid]
      ,[sample_segment]
      ,[sample_county]
      ,[cityofseattle]
      ,[psrc]
      ,[sample_lat]
      ,[sample_lng]
      ,[reported_lat]
      ,[reported_lng]
      ,[final_home_tract]
      ,[final_home_bg]
      ,[final_home_block]
      ,[final_home_puma10]
      ,[final_home_rgcnum]
      ,[final_home_uvnum]
      ,[hhgroup]
      ,[travelweek]
      ,[traveldate_start]
      ,[traveldate_end]
      ,[dayofweek]
      ,[hhsize]
      ,[vehicle_count]
      ,[numadults]
      ,[numchildren]
      ,[numworkers]
      ,[lifecycle]
      ,[hhincome_detailed]
      ,[hhincome_followup]
      ,[hhincome_broad]
      ,[car_share]
      ,[rent_own]
      ,[res_dur]
      ,[res_type]
      ,[res_months]
      ,[prev_home_wa]
      ,[prev_home_lat]
      ,[prev_home_lng]
      ,[prev_home_notwa_notus]
      ,[prev_home_notwa_city]
      ,[prev_home_notwa_state]
      ,[prev_home_notwa_zip]
      ,[prev_rent_own]
      ,[prev_res_type]
      ,[res_factors_30min]
      ,[res_factors_afford]
      ,[res_factors_closefam]
      ,[res_factors_hwy]
      ,[res_factors_school]
      ,[res_factors_space]
      ,[res_factors_transit]
      ,[res_factors_walk]
      ,[prev_res_factors_housing_cost]
      ,[prev_res_factors_income_change]
      ,[prev_res_factors_community_change]
      ,[prev_res_factors_hh_size]
      ,[prev_res_factors_more_space]
      ,[prev_res_factors_less_space]
      ,[prev_res_factors_employment]
      ,[prev_res_factors_school]
      ,[prev_res_factors_crime]
      ,[prev_res_factors_quality]
      ,[prev_res_factors_forced]
      ,[prev_res_factors_no_answer]
      ,[prev_res_factors_other]
      ,[prev_res_factors_specify]
      ,[rmove_optin]
      ,[diary_incentive_type]
      ,[contact_email]
      ,[contact_phone]
      ,[foreign_language]
      ,[google_translate]
      ,[recruit_start_pt]
      ,[recruit_end_pt]
      ,[call_center_recruit]
      ,[mobile_device]
      ,[recruit_duration_min]
      ,[nwkdays]
      ,[numdayscomplete]
      ,[num_trips]
  FROM [dbo].[1_Household]
GO


drop table if exists HHSurvey.[Person]
go
CREATE TABLE [HHSurvey].[Person](
	recid int identity not null,
	[hhid] [decimal](19, 0) not NULL,
	[personid] [decimal](19, 0) not NULL,
	[pernum] [int] not NULL,
	[sample_segment] [real] NULL,
	[hhgroup] [int] not NULL,
	[traveldate_start] [datetime] NULL,
	[traveldate_end] [datetime] NULL,
	[relationship] [int] NULL,
	[proxy_parent] [int] NULL,
	[proxy] [int] NULL,
	[age] [int] NULL,
	[gender] [int] NULL,
	[employment] [int] NULL,
	[jobs_count] [int] NULL,
	[worker] [int] NULL,
	[student] [int] NULL,
	[schooltype] [int] NULL,
	[school_travel] [int] NULL,
	[education] [int] NULL,
	[license] [int] NULL,
	[vehicleused] [int] NULL,
	[smartphone_type] [int] NULL,
	[smartphone_qualified] [int] NULL,
	[race_afam] [int] NULL,
	[race_aiak] [int] NULL,
	[race_asian] [int] NULL,
	[race_hapi] [int] NULL,
	[race_hisp] [int] NULL,
	[race_white] [int] NULL,
	[race_other] [int] NULL,
	[race_noanswer] [int] NULL,
	[workplace] [int] NULL,
	[hours_work] [int] NULL,
	[commute_freq] [int] NULL,
	[commute_mode] [int] NULL,
	[commute_dur] [int] NULL,
	[telecommute_freq] [int] NULL,
	[work_park_type] [int] NULL,
	[workpass] [int] NULL,
	[workpass_cost] [int] NULL,
	[workpass_cost_dk] [int] NULL,
	[work_county] [nvarchar](max) NULL,
	[work_lat] [float] NULL,
	[work_lng] [float] NULL,
	[prev_work_wa] [int] NULL,
	[prev_work_lat] [float] NULL,
	[prev_work_lng] [float] NULL,
	[prev_work_county] [nvarchar](max) NULL,
	[prev_work_notwa_city] [nvarchar](max) NULL,
	[prev_work_notwa_state] [int] NULL,
	[prev_work_notwa_zip] [nvarchar](7) NULL,
	[prev_work_notwa_notus] [int] NULL,
	[school_loc_county] [nvarchar](max) NULL,
	[school_loc_lat] [float] NULL,
	[school_loc_lng] [float] NULL,
	[mode_freq_1] [int] NULL,
	[mode_freq_2] [int] NULL,
	[mode_freq_3] [int] NULL,
	[mode_freq_4] [int] NULL,
	[mode_freq_5] [int] NULL,
	[tran_pass_1] [int] NULL,
	[tran_pass_2] [int] NULL,
	[tran_pass_3] [int] NULL,
	[tran_pass_4] [int] NULL,
	[tran_pass_5] [int] NULL,
	[tran_pass_6] [int] NULL,
	[tran_pass_7] [int] NULL,
	[tran_pass_8] [int] NULL,
	[tran_pass_9] [int] NULL,
	[tran_pass_10] [int] NULL,
	[tran_pass_11] [int] NULL,
	[benefits_1] [int] NULL,
	[benefits_2] [int] NULL,
	[benefits_3] [int] NULL,
	[benefits_4] [int] NULL,
	[av_interest_1] [int] NULL,
	[av_interest_2] [int] NULL,
	[av_interest_3] [int] NULL,
	[av_interest_4] [int] NULL,
	[av_interest_5] [int] NULL,
	[av_interest_6] [int] NULL,
	[av_interest_7] [int] NULL,
	[av_concern_1] [int] NULL,
	[av_concern_2] [int] NULL,
	[av_concern_3] [int] NULL,
	[av_concern_4] [int] NULL,
	[av_concern_5] [int] NULL,
	[wbt_transitmore_1] [int] NULL,
	[wbt_transitmore_2] [int] NULL,
	[wbt_transitmore_3] [int] NULL,
	[wbt_bikemore_1] [int] NULL,
	[wbt_bikemore_2] [int] NULL,
	[wbt_bikemore_3] [int] NULL,
	[wbt_bikemore_4] [int] NULL,
	[wbt_bikemore_5] [int] NULL,
	[rmove_incentive] [int] NULL,
	[call_center_diary] [int] NULL,
	[mobile_device] [int] NULL,
	[num_trips] [decimal](19, 0) NULL,
	[nwkdays] [int] NULL
) ON [PRIMARY] 

GO
alter table HHSurvey.[Person] 
	add constraint PK_Person_recid PRIMARY KEY CLUSTERED (recid)

insert into HHSurvey.[Person] (
	HHID
      ,[personid]
      ,[pernum]
      ,[sample_segment]
      ,[hhgroup]
      ,[traveldate_start]
      ,[traveldate_end]
      ,[relationship]
      ,[proxy_parent]
      ,[proxy]
      ,[age]
      ,[gender]
      ,[employment]
      ,[jobs_count]
      ,[worker]
      ,[student]
      ,[schooltype]
      ,[school_travel]
      ,[education]
      ,[license]
      ,[vehicleused]
      ,[smartphone_type]
      ,[smartphone_qualified]
      ,[race_afam]
      ,[race_aiak]
      ,[race_asian]
      ,[race_hapi]
      ,[race_hisp]
      ,[race_white]
      ,[race_other]
      ,[race_noanswer]
      ,[workplace]
      ,[hours_work]
      ,[commute_freq]
      ,[commute_mode]
      ,[commute_dur]
      ,[telecommute_freq]
      ,[work_park_type]
      ,[workpass]
      ,[workpass_cost]
      ,[workpass_cost_dk]
      ,[work_county]
      ,[work_lat]
      ,[work_lng]
      ,[prev_work_wa]
      ,[prev_work_lat]
      ,[prev_work_lng]
      ,[prev_work_county]
      ,[prev_work_notwa_city]
      ,[prev_work_notwa_state]
      ,[prev_work_notwa_zip]
      ,[prev_work_notwa_notus]
      ,[school_loc_county]
      ,[school_loc_lat]
      ,[school_loc_lng]
      ,[mode_freq_1]
      ,[mode_freq_2]
      ,[mode_freq_3]
      ,[mode_freq_4]
      ,[mode_freq_5]
      ,[tran_pass_1]
      ,[tran_pass_2]
      ,[tran_pass_3]
      ,[tran_pass_4]
      ,[tran_pass_5]
      ,[tran_pass_6]
      ,[tran_pass_7]
      ,[tran_pass_8]
      ,[tran_pass_9]
      ,[tran_pass_10]
      ,[tran_pass_11]
      ,[benefits_1]
      ,[benefits_2]
      ,[benefits_3]
      ,[benefits_4]
      ,[av_interest_1]
      ,[av_interest_2]
      ,[av_interest_3]
      ,[av_interest_4]
      ,[av_interest_5]
      ,[av_interest_6]
      ,[av_interest_7]
      ,[av_concern_1]
      ,[av_concern_2]
      ,[av_concern_3]
      ,[av_concern_4]
      ,[av_concern_5]
      ,[wbt_transitmore_1]
      ,[wbt_transitmore_2]
      ,[wbt_transitmore_3]
      ,[wbt_bikemore_1]
      ,[wbt_bikemore_2]
      ,[wbt_bikemore_3]
      ,[wbt_bikemore_4]
      ,[wbt_bikemore_5]
      ,[rmove_incentive]
      ,[call_center_diary]
      ,[mobile_device]
      ,[num_trips]
      ,[nwkdays]
	  )
SELECT [hhid]
      ,[personid]
      ,[pernum]
      ,[sample_segment]
      ,[hhgroup]
      ,[traveldate_start]
      ,[traveldate_end]
      ,[relationship]
      ,[proxy_parent]
      ,[proxy]
      ,[age]
      ,[gender]
      ,[employment]
      ,[jobs_count]
      ,[worker]
      ,[student]
      ,[schooltype]
      ,[school_travel]
      ,[education]
      ,[license]
      ,[vehicleused]
      ,[smartphone_type]
      ,[smartphone_qualified]
      ,[race_afam]
      ,[race_aiak]
      ,[race_asian]
      ,[race_hapi]
      ,[race_hisp]
      ,[race_white]
      ,[race_other]
      ,[race_noanswer]
      ,[workplace]
      ,[hours_work]
      ,[commute_freq]
      ,[commute_mode]
      ,[commute_dur]
      ,[telecommute_freq]
      ,[work_park_type]
      ,[workpass]
      ,[workpass_cost]
      ,[workpass_cost_dk]
      ,[work_county]
      ,[work_lat]
      ,[work_lng]
      ,[prev_work_wa]
      ,[prev_work_lat]
      ,[prev_work_lng]
      ,[prev_work_county]
      ,[prev_work_notwa_city]
      ,[prev_work_notwa_state]
      ,[prev_work_notwa_zip]
      ,[prev_work_notwa_notus]
      ,[school_loc_county]
      ,[school_loc_lat]
      ,[school_loc_lng]
      ,[mode_freq_1]
      ,[mode_freq_2]
      ,[mode_freq_3]
      ,[mode_freq_4]
      ,[mode_freq_5]
      ,[tran_pass_1]
      ,[tran_pass_2]
      ,[tran_pass_3]
      ,[tran_pass_4]
      ,[tran_pass_5]
      ,[tran_pass_6]
      ,[tran_pass_7]
      ,[tran_pass_8]
      ,[tran_pass_9]
      ,[tran_pass_10]
      ,[tran_pass_11]
      ,[benefits_1]
      ,[benefits_2]
      ,[benefits_3]
      ,[benefits_4]
      ,[av_interest_1]
      ,[av_interest_2]
      ,[av_interest_3]
      ,[av_interest_4]
      ,[av_interest_5]
      ,[av_interest_6]
      ,[av_interest_7]
      ,[av_concern_1]
      ,[av_concern_2]
      ,[av_concern_3]
      ,[av_concern_4]
      ,[av_concern_5]
      ,[wbt_transitmore_1]
      ,[wbt_transitmore_2]
      ,[wbt_transitmore_3]
      ,[wbt_bikemore_1]
      ,[wbt_bikemore_2]
      ,[wbt_bikemore_3]
      ,[wbt_bikemore_4]
      ,[wbt_bikemore_5]
      ,[rmove_incentive]
      ,[call_center_diary]
      ,[mobile_device]
      ,[num_trips]
      ,[nwkdays]
  FROM [dbo].[2_Person]
GO

drop table if exists HHSurvey.[Vehicle]
go

CREATE TABLE [HHSurvey].[Vehicle](
	recid int identity not null,
	[hhid] [decimal](19, 0) not NULL,
	[vehnum] [int] not NULL,
	[vehid] [decimal](19, 0) not NULL,
	[year] [nvarchar](150) NULL,
	[make] [nvarchar](150) NULL,
	[model] [nvarchar](150) NULL,
	[fuel] [int] NULL,
	[disability] [int] NULL,
	[purchase_date] [int] NULL
) ON [PRIMARY]


alter table HHSurvey.[Vehicle]
	add constraint PK_Vehicle_recid PRIMARY KEY CLUSTERED (recid)

insert into HHSurvey.[Vehicle] (
	hhid
      ,[vehnum]
      ,[vehid]
      ,[year]
      ,[make]
      ,[model]
      ,[fuel]
      ,[disability]
      ,[purchase_date]
)
SELECT [hhid]
      ,[vehnum]
      ,[vehid]
      ,[year]
      ,[make]
      ,[model]
      ,[fuel]
      ,[disability]
      ,[purchase_date]
  FROM [dbo].[3_Vehicle]
GO


drop table if exists HHSurvey.[Day]
go
CREATE TABLE [HHSurvey].[Day](
	recid int identity not null,
	[hhid] [decimal](19, 0) not NULL,
	[hhgroup] [int] not NULL,
	[personid] [decimal](19, 0) not NULL,
	[pernum] [int] not NULL,
	[daynum] [int] not NULL,
	[dayofweek] [float] NULL,
	[traveldate] [datetime] NULL,
	[svy_complete] [int] NULL,
	[completed_at] [datetime] NULL,
	[revised_at] [datetime] NULL,
	[revised_count] [decimal](28, 6) NULL,
	[diary_start_pt] [datetime] NULL,
	[diary_end_pt] [datetime] NULL,
	[diary_duration_min] [float] NULL,
	[proxy] [int] NULL,
	[copied_first] [int] NULL,
	[copied_last] [int] NULL,
	[loc_start] [int] NULL,
	[loc_start_other] [nvarchar](255) NULL,
	[loc_end] [int] NULL,
	[loc_end_other] [nvarchar](255) NULL,
	[trips_yesno] [int] NULL,
	[notravel_vacation] [int] NULL,
	[notravel_telecommute] [int] NULL,
	[notravel_housework] [int] NULL,
	[notravel_kidsbreak] [int] NULL,
	[notravel_kidshomeschool] [int] NULL,
	[notravel_notransport] [int] NULL,
	[notravel_sick] [int] NULL,
	[notravel_delivery] [int] NULL,
	[notravel_other] [int] NULL,
	[notravel_other_reason] [nvarchar](max) NULL,
	[use_paidpark] [decimal](28, 6) NULL,
	[use_toll] [decimal](28, 6) NULL,
	[telework_time] [int] NULL,
	[online_shop_time] [int] NULL,
	[deliver_package] [int] NULL,
	[deliver_grocery] [int] NULL,
	[deliver_food] [int] NULL,
	[deliver_work] [int] NULL,
	[delivery_pkgs_freq] [int] NULL,
	[delivery_grocery_freq] [int] NULL,
	[delivery_food_freq] [int] NULL,
	[delivery_work_freq] [int] NULL,
	[num_trips] [int] NULL,
	[num_answer] [int] NULL,
	[day_iscomplete] [int] NULL,
	[data_source] [int] NULL
) ON [PRIMARY] 
GO

alter table HHSurvey.[Day]
	add constraint PK_Day_recid PRIMARY KEY CLUSTERED (recid)

insert into HHSurvey.[Day] (
	hhid
      ,[hhgroup]
      ,[personid]
      ,[pernum]
      ,[daynum]
      ,[dayofweek]
      ,[traveldate]
      ,[svy_complete]
      ,[completed_at]
      ,[revised_at]
      ,[revised_count]
      ,[diary_start_pt]
      ,[diary_end_pt]
      ,[diary_duration_min]
      ,[proxy]
      ,[copied_first]
      ,[copied_last]
      ,[loc_start]
      ,[loc_start_other]
      ,[loc_end]
      ,[loc_end_other]
      ,[trips_yesno]
      ,[notravel_vacation]
      ,[notravel_telecommute]
      ,[notravel_housework]
      ,[notravel_kidsbreak]
      ,[notravel_kidshomeschool]
      ,[notravel_notransport]
      ,[notravel_sick]
      ,[notravel_delivery]
      ,[notravel_other]
      ,[notravel_other_reason]
      ,[use_paidpark]
      ,[use_toll]
      ,[telework_time]
      ,[online_shop_time]
      ,[deliver_package]
      ,[deliver_grocery]
      ,[deliver_food]
      ,[deliver_work]
      ,[delivery_pkgs_freq]
      ,[delivery_grocery_freq]
      ,[delivery_food_freq]
      ,[delivery_work_freq]
      ,[num_trips]
      ,[num_answer]
      ,[day_iscomplete]
      ,[data_source]
)
SELECT [hhid]
      ,[hhgroup]
      ,[personid]
      ,[pernum]
      ,[daynum]
      ,[dayofweek]
      ,[traveldate]
      ,[svy_complete]
      ,[completed_at]
      ,[revised_at]
      ,[revised_count]
      ,[diary_start_pt]
      ,[diary_end_pt]
      ,[diary_duration_min]
      ,[proxy]
      ,[copied_first]
      ,[copied_last]
      ,[loc_start]
      ,[loc_start_other]
      ,[loc_end]
      ,[loc_end_other]
      ,[trips_yesno]
      ,[notravel_vacation]
      ,[notravel_telecommute]
      ,[notravel_housework]
      ,[notravel_kidsbreak]
      ,[notravel_kidshomeschool]
      ,[notravel_notransport]
      ,[notravel_sick]
      ,[notravel_delivery]
      ,[notravel_other]
      ,[notravel_other_reason]
      ,[use_paidpark]
      ,[use_toll]
      ,[telework_time]
      ,[online_shop_time]
      ,[deliver_package]
      ,[deliver_grocery]
      ,[deliver_food]
      ,[deliver_work]
      ,[delivery_pkgs_freq]
      ,[delivery_grocery_freq]
      ,[delivery_food_freq]
      ,[delivery_work_freq]
      ,[num_trips]
      ,[num_answer]
      ,[day_iscomplete]
      ,[data_source]
  FROM [dbo].[4_Day]
GO

/*

drop table if exists HHSurvey.[trip]
go
CREATE TABLE [HHSurvey].[Trip](
	recid int identity not null,
	[hhid] [decimal](19, 0) NULL,
	[hhgroup] [int] NULL,
	[personid] [decimal](19, 0) NULL,
	[pernum] [int] NULL,
	[tripid] [decimal](19, 0) NULL,
	[linked_tripid] [decimal](19, 0) NULL,
	[tripnum] [int] NULL,
	[unlinked_trip] [int] NULL,
	[daynum] [int] NULL,
	[dayofweek] [float] NULL,
	[traveldate] [datetime] NULL,
	[data_source] [int] NULL,
	[copied_trip] [int] NULL,
	[nonproxy_derived_trip] [int] NULL,
	[completed_at] [datetime] NULL,
	[revised_at] [datetime] NULL,
	[revised_count] [int] NULL,
	[svy_complete] [int] NULL,
	[depart_time_mam] [int] NULL,
	[depart_time_hhmm] [nvarchar](255) NULL,
	[depart_time_timestamp] [datetime] NULL,
	[arrival_time_mam] [int] NULL,
	[arrival_time_hhmm] [nvarchar](255) NULL,
	[arrival_time_timestamp] [datetime] NULL,
	[origin_lat] [float] NULL,
	[origin_lng] [float] NULL,
	[dest_lat] [float] NULL,
	[dest_lng] [float] NULL,
	[trip_path_distance] [float] NULL,
	[google_duration] [float] NULL,
	[reported_duration] [int] NULL,
	[hhmember1] [decimal](19, 0) NULL,
	[hhmember2] [decimal](19, 0) NULL,
	[hhmember3] [decimal](19, 0) NULL,
	[hhmember4] [decimal](19, 0) NULL,
	[hhmember5] [decimal](19, 0) NULL,
	[hhmember6] [decimal](19, 0) NULL,
	[hhmember7] [decimal](19, 0) NULL,
	[hhmember8] [decimal](19, 0) NULL,
	[travelers_hh] [int] NULL,
	[travelers_nonhh] [int] NULL,
	[travelers_total] [int] NULL,
	[o_purpose] [int] NULL,
	[o_purpose_other] [nvarchar](255) NULL,
	[o_purp_cat] [int] NULL,
	[d_purpose] [int] NULL,
	[d_purpose_other] [nvarchar](255) NULL,
	[d_purp_cat] [int] NULL,
	[mode_1] [int] NULL,
	[mode_2] [int] NULL,
	[mode_3] [int] NULL,
	[mode_4] [int] NULL,
	[mode_type] [int] NULL,
	[driver] [int] NULL,
	[pool_start] [int] NULL,
	[change_vehicles] [int] NULL,
	[park_ride_area_start] [int] NULL,
	[park_ride_area_end] [int] NULL,
	[park_ride_lot_start] [int] NULL,
	[park_ride_lot_end] [int] NULL,
	[toll] [int] NULL,
	[toll_pay] [decimal](28, 6) NULL,
	[taxi_type] [int] NULL,
	[taxi_pay] [decimal](28, 6) NULL,
	[bus_type] [int] NULL,
	[bus_pay] [decimal](28, 6) NULL,
	[bus_cost_dk] [int] NULL,
	[ferry_type] [int] NULL,
	[ferry_pay] [decimal](28, 6) NULL,
	[ferry_cost_dk] [int] NULL,
	[air_type] [int] NULL,
	[air_pay] [decimal](28, 6) NULL,
	[airfare_cost_dk] [int] NULL,
	[mode_acc] [int] NULL,
	[mode_egr] [int] NULL,
	[park] [decimal](28, 6) NULL,
	[park_type] [int] NULL,
	[park_pay] [int] NULL,
	[transit_system_1] [int] NULL,
	[transit_line_1] [int] NULL,
	[transit_system_2] [int] NULL,
	[transit_line_2] [int] NULL,
	[transit_system_3] [int] NULL,
	[transit_line_3] [int] NULL,
	[transit_system_4] [int] NULL,
	[transit_line_4] [int] NULL,
	[transit_system_5] [int] NULL,
	[transit_line_5] [int] NULL,
	[transit_system_6] [int] NULL,
	[transit_line_6] [int] NULL,
	[speed_mph] [float] NULL,
	[user_added] [int] NULL,
	[user_merged] [int] NULL,
	[user_split] [int] NULL,
	[analyst_merged] [int] NULL,
	[analyst_split] [int] NULL,
	[analyst_split_loop] [int] NULL,
	[quality_flag] [nvarchar](255) NULL
) ON [PRIMARY]
go

alter table HHSurvey.[Trip]
	add constraint PK__recid PRIMARY KEY CLUSTERED (recid)

insert into HHSurvey.[Trip] (
	hhid
      ,[hhgroup]
      ,[personid]
      ,[pernum]
      ,[tripid]
      ,[linked_tripid]
      ,[tripnum]
      ,[unlinked_trip]
      ,[daynum]
      ,[dayofweek]
      ,[traveldate]
      ,[data_source]
      ,[copied_trip]
      ,[nonproxy_derived_trip]
      ,[completed_at]
      ,[revised_at]
      ,[revised_count]
      ,[svy_complete]
      ,[depart_time_mam]
      ,[depart_time_hhmm]
      ,[depart_time_timestamp]
      ,[arrival_time_mam]
      ,[arrival_time_hhmm]
      ,[arrival_time_timestamp]
      ,[origin_lat]
      ,[origin_lng]
      ,[dest_lat]
      ,[dest_lng]
      ,[trip_path_distance]
      ,[google_duration]
      ,[reported_duration]
      ,[hhmember1]
      ,[hhmember2]
      ,[hhmember3]
      ,[hhmember4]
      ,[hhmember5]
      ,[hhmember6]
      ,[hhmember7]
      ,[hhmember8]
      ,[travelers_hh]
      ,[travelers_nonhh]
      ,[travelers_total]
      ,[o_purpose]
      ,[o_purpose_other]
      ,[o_purp_cat]
      ,[d_purpose]
      ,[d_purpose_other]
      ,[d_purp_cat]
      ,[mode_1]
      ,[mode_2]
      ,[mode_3]
      ,[mode_4]
      ,[mode_type]
      ,[driver]
      ,[pool_start]
      ,[change_vehicles]
      ,[park_ride_area_start]
      ,[park_ride_area_end]
      ,[park_ride_lot_start]
      ,[park_ride_lot_end]
      ,[toll]
      ,[toll_pay]
      ,[taxi_type]
      ,[taxi_pay]
      ,[bus_type]
      ,[bus_pay]
      ,[bus_cost_dk]
      ,[ferry_type]
      ,[ferry_pay]
      ,[ferry_cost_dk]
      ,[air_type]
      ,[air_pay]
      ,[airfare_cost_dk]
      ,[mode_acc]
      ,[mode_egr]
      ,[park]
      ,[park_type]
      ,[park_pay]
      ,[transit_system_1]
      ,[transit_line_1]
      ,[transit_system_2]
      ,[transit_line_2]
      ,[transit_system_3]
      ,[transit_line_3]
      ,[transit_system_4]
      ,[transit_line_4]
      ,[transit_system_5]
      ,[transit_line_5]
      ,[transit_system_6]
      ,[transit_line_6]
      ,[speed_mph]
      ,[user_added]
      ,[user_merged]
      ,[user_split]
      ,[analyst_merged]
      ,[analyst_split]
      ,[analyst_split_loop]
      ,[quality_flag]
)
SELECT [hhid]
      ,[hhgroup]
      ,[personid]
      ,[pernum]
      ,[tripid]
      ,[linked_tripid]
      ,[tripnum]
      ,[unlinked_trip]
      ,[daynum]
      ,[dayofweek]
      ,[traveldate]
      ,[data_source]
      ,[copied_trip]
      ,[nonproxy_derived_trip]
      ,[completed_at]
      ,[revised_at]
      ,[revised_count]
      ,[svy_complete]
      ,[depart_time_mam]
      ,[depart_time_hhmm]
      ,[depart_time_timestamp]
      ,[arrival_time_mam]
      ,[arrival_time_hhmm]
      ,[arrival_time_timestamp]
      ,[origin_lat]
      ,[origin_lng]
      ,[dest_lat]
      ,[dest_lng]
      ,[trip_path_distance]
      ,[google_duration]
      ,[reported_duration]
      ,[hhmember1]
      ,[hhmember2]
      ,[hhmember3]
      ,[hhmember4]
      ,[hhmember5]
      ,[hhmember6]
      ,[hhmember7]
      ,[hhmember8]
      ,[travelers_hh]
      ,[travelers_nonhh]
      ,[travelers_total]
      ,[o_purpose]
      ,[o_purpose_other]
      ,[o_purp_cat]
      ,[d_purpose]
      ,[d_purpose_other]
      ,[d_purp_cat]
      ,[mode_1]
      ,[mode_2]
      ,[mode_3]
      ,[mode_4]
      ,[mode_type]
      ,[driver]
      ,[pool_start]
      ,[change_vehicles]
      ,[park_ride_area_start]
      ,[park_ride_area_end]
      ,[park_ride_lot_start]
      ,[park_ride_lot_end]
      ,[toll]
      ,[toll_pay]
      ,[taxi_type]
      ,[taxi_pay]
      ,[bus_type]
      ,[bus_pay]
      ,[bus_cost_dk]
      ,[ferry_type]
      ,[ferry_pay]
      ,[ferry_cost_dk]
      ,[air_type]
      ,[air_pay]
      ,[airfare_cost_dk]
      ,[mode_acc]
      ,[mode_egr]
      ,[park]
      ,[park_type]
      ,[park_pay]
      ,[transit_system_1]
      ,[transit_line_1]
      ,[transit_system_2]
      ,[transit_line_2]
      ,[transit_system_3]
      ,[transit_line_3]
      ,[transit_system_4]
      ,[transit_line_4]
      ,[transit_system_5]
      ,[transit_line_5]
      ,[transit_system_6]
      ,[transit_line_6]
      ,[speed_mph]
      ,[user_added]
      ,[user_merged]
      ,[user_split]
      ,[analyst_merged]
      ,[analyst_split]
      ,[analyst_split_loop]
      ,[quality_flag]
  FROM [dbo].[4_Trip]
GO
*/

drop table if exists HHSurvey.[Location]
go
CREATE TABLE [HHSurvey].[Location](
	recid int identity not null,
	[hhid] [decimal](19, 0) NULL,
	[personid] [decimal](19, 0) NULL,
	[pernum] [int] NULL,
	[tripid] [decimal](19, 0) NULL,
	[tripnum] [int] NULL,
	[accuracy] [int] NULL,
	[heading] [int] NULL,
	[speed] [decimal](28, 6) NULL,
	[collected_at] [datetime] NULL,
	[lat] [decimal](13, 5) NULL,
	[lng] [decimal](13, 5) NULL
) ON [PRIMARY]

alter table HHSurvey.[Location]
	add constraint PK_Location_recid PRIMARY KEY CLUSTERED (recid)

insert into HHSurvey.[Location](
	hhid
      ,[personid]
      ,[pernum]
      ,[tripid]
      ,[tripnum]
      ,[accuracy]
      ,[heading]
      ,[speed]
      ,[collected_at]
      ,[lat]
      ,[lng]

)
SELECT [hhid]
      ,[personid]
      ,[pernum]
      ,[tripid]
      ,[tripnum]
      ,[accuracy]
      ,[heading]
      ,[speed]
      ,[collected_at]
      ,[lat]
      ,[lng]
  FROM [dbo].[6_Location]
GO


