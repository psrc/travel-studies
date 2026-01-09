# Trip Linking

Survey data provided in Public Release 1 includes many dissaggregate trips that were merged for consistency. For example, a survey respondent may have logged 3 trips for the same purpose - go to work. They might have logged their walk trip to their bus or car, the actual bus/car trip, and a final walk trip to their office. Though this level of detail is interesting, the trip should be counted only once, with the access time summed up as part of the total travel time. There are many issues to consider in combining these trips though. For instance, are other respondents recording only their in-vehicle travel time and ignoring the walk access time? When combining a person's trips, should we sum up all of their trips or only trips that access a mode change? It's also challenging to automate scripts that merge this data with appropriate logic. In other words, how do we identify when trips should be merged and how do we define those parameters? Currently a Python script follows set of rules below to identify and merge linked trips.
Identify Linked Trips

Loop through each unique person
Ignore persons who never change modes. We're assuming these people did not log walk access trips.
For each unique person, loop through each of their trips, comparing the current trip to the next trip. For these 2 trips, we can assume they're linked if ALL of the following critera are met:
The mode changes or if both modes are bus (possibly bus transfer)
activity duration is less than 15 minutes (meaning that someone walked to the bus station or their vehicle and at that destination they spent no longer than 15 minutes between modes),
destination purpose is the same or listed as "mode change"
Alternatively, linked trips are self-identified by the traveler, who marked the trip purpose as "change modes." Any trip with this trip purpose is always linked with the following trip.
Apply an ID for each linked trip set. Each trip in a linked set will have the same ID as the others in the set. For instance, 3 trips like walks-rides-walks will have the same ID, 000401, matching a single person.
Individual persons might have multiple sets of linked trips (e.g., someone walks-rides-walks in the morning to work and walks-rides-walks home in the evening). These trip sets are identified by creating a new set ID for a linked trip pair if the 2nd trip's activity duration is longer than 30 minutes. This captures cases where the final trip in a set is for a purpose such as work or even shopping where trips should clearly be considered separate. Sets are increments per person, so a person's first linked-trip set ID might be 000401 and their 2nd set ID would be 000402. A local index is created for each person and is reset every time a new person's trips are evaluated. Additionally, if a trip's end location is home or work, the end of the set is assumed.
A final exclusion was mode changes to airplanes. We generally don't want to link these trips since we only care about travel in the region (to the airport) and not so much about the outbound flight portion.
This process identifies each of the likely linked trips. These trips can be written directly to Excel and combined manually, but there were over 3,900 trips so this is inefficient. Ideally, most of these trips can be combined automatically. However, there are logical issues with trip combinations to consider. For instance, how do we decide which trip is always the linked trip? Should this simple be the trip with the longest travel time or distance, or perhaps other approaches such as a mode heirarchy, where ferries and rail trips take precedence over bus and other modes. The process below describes an incremental approach that merges the clearest cases first, while leaving more complicated outliers for manual consideration. Some clear cases for linking are discussed below.
Merging Multiple Trips to Single Trip

Trip sets with more than 4 records pose potential problems. While it may be possible to have more than 4 linked trips, the situation probably requires manual consideration. Two to 4 linked trips is typical, where a respondent might walk-bus1-bus2-walk or some other combination of modes to reach a destination. A distribution of identified linked trips shows that 90% of all trips meet these critera.

Linked Trips	Count
2	1172
3	282
4	108
5	24
6	18
7	0
8	2
9	3
10	0
11	1

Therefore, only sets with less than 4 linked trips will be considered for automatic merging. For this group of trips, the following steps create a single trip from a set of linked trips:
Identify primary trip
the longest (distance) trip of the set will become the primary trip
Concatenate the mode strings for the set and add to a field on the primary trip record
e.g., "walk-bus-walk" (or 7-8-7 using mode lookup values)
Sum the following fields for all trips in the set and replace existing for the primary trip:
trip distance (gdist)
trip time (gtime)
activity duration (reported and imputed)
Sum non-primary travel times to get out-of-vehicle travel time in a new field
Replace trip start and end time on primary trip with times from surrounding trips
Replace origin fields (otaz, ocity, ozip, place_start, etc.) on primary trip with fields from the first trip in set
Replace destination fields (dtaz, dcity, dzip, place_end, etc.) on primary trip with fields from last trip in set
Combine all transitline and transitsystem fields from the set into the primary trip
get all unique values from the fields transitline1, transitline2, ... transitline4 for all trips in the set, and populate them in the primary trip's fields for transitline1, ... transitline4.
Perform same routine for transitsystem1, ... transitsystem4