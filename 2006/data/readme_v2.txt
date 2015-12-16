PSRC 2006 Household Activity Survey
Version 3.02
February 7, 2008


Version 3

This dataset contains all the survey data EXCEPT for tours, which are currently being re-worked.
Otherwise, this version can be considered final.  Additional modeling-related fields may be added
in the future, but there should be no more structural changes or changes to existing fields.


-------------------------------------------------------------------------------------------------
DATABASE CONTENTS

HH_DATA_v3.SAV           Household characteristics, including household vehicle information and
                         previous home location.

PERSON_DATA_v3.SAV       Person characteristics, including responses to attitude questions and,
                         where applicable, school and bus pass detail.  Does not include
                         employment and workplace detail.

WKPLACE_DATA_v3.SAV      Employment, workplace, and journey-to-work information, including,
                         where applicable, information about second jobs and previous job.

TRIP_DATA_1_v3.SAV       Travel and activity information from the 2-day Activity Diaries.
                         Includes activities engaged in at each location, mode(s) used to get to
                         location, travel times and distance, vehicle occupancy, and additional
                         information about each leg of the trip to each location (to a maximum of
                         5 legs).

TRIP_DATA_2_v3.SAV       Additional trip information, including who else in the household was on
                         the trip, what household vehicle was used, activities engaged in during
                         the trip, and data about parking at each location.

TRIP_DATA_3_v3.SAV       Detailed information about buses and ferries used during a trip, if
                         any.  Includes bus provider, bus and ferry routes, and fares paid.

STATED_PREF_v1.SAV       Results from Stated Preference surveys

CODEBOOK_v3.XLS          Data dictionary for all files, including code lists.


-------------------------------------------------------------------------------------------------
CORRECTIONS

LINKED TRIPS

While the survey was set up to accomodate trip chains as single records in the diary data, not all
diaries were entered correctly in that way.  We have now made those linkages, removing the links
and updating the trip data accordingly in the record that represents the final destination of the
trip.  Those records are tagged with "1" in the field "link" in trip tables.

OTHER CORRECTIONS AND CHANGES

The database was made available to a few individuals in Fall 2007.  Since then, a number
of changes have been made to the data, including changes to field values in the trip data,
restructuring, deletion of duplicate or invalid trip records, and addition of trip records with
imputed values.

The file "Errata_v1.xls" contains a list of all changes to field values since September 2007, and
the records that were added or deleted from the trip data.

The file "Errata_v3.xls" contains a list of all changes to field values since December 2007, and
the records that were added or deleted from the trip data.

The household vehicle make and model fields have replaced in the HOUSEHOLD and TRIP2 files with
new vehicle type fields (car/van/SUV, etc.).

Fields containing restricted data (employer name, location name, coordinates for homes, jobs
and trip ends) have been removed, along with internal tracking and housekeeping fields.

RELEASE 3.02 CHANGES

Person data
* Added WRKR and PERSTYPE to file
* Replace expansion factor with revised version

Workplace data
* Removed W1TYPE and W2TYPE

Trip1
* Added new travel time field MODELMIN as a placeholder.  We will add the new travel times
  to this field in release 3.03.
  The new TAZ-to-TAZ times are based on our travel demand model and are considered a more
  accurate record of actual trip duration.  We offer this as an alternative to the stated
  travel times (MINUTES), which are based on what the respondent put down as the starting
  and ending time of the trip and are subject to numerous errors.  The user can then choose
  which field best meets the needs of the moment.

* Added TRPTYPE2 (12-category trip type, to/from home).
* Added MODE4 (Mode recoded into 21 categories, based on vehicle occupancy and auto- and walk-
  access transit modes).
* Added DISTCAT (Distance categories in miles).
* Added MINCAT  (Time categories in minutes).

Trip2
* Removed STATUS
* Added WHO1-WHO5 as text fields containing the person numbers of all household members accompanying
  the respondent on the trip.  One field for each of up to five links in a trip chain.


RELEASE 3.03 CHANGES

Trip1
* Most of the changes involve MODE4, primarily corrections between express and local bus.

* The other major change involves one diary that was part of the linked trip work mentioned above.
  Two linked ferry trips that should have been removed at that time was not.  They are removed in
  this version, necessitating changes to TAZ1-TAZ2 pairs, MINUTES, DISTANCE, and TRIPTYPE for the
  final destination record.

-------------------------------------------------------------------------------------------------
AVAILABILITY OF THE DATA

The data are available in the following formats:

SPSS, created by version 11.
SPSS portable files, for transferring data to other versions, platforms, or software.
Tab-delimited ASCII files.

-------------------------------------------------------------------------------------------------
FOR MORE INFORMATION, contact:

Neil Kilgren
Senior Planner
Puget Sound Regional Council
1011 Western Avenue, Suite 500
Seattle, WA 98104
206-464-7964
nkilgren@psrc.org

