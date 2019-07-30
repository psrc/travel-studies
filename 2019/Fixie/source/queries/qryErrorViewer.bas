SELECT Mike_data2frontend.recid, Mike_data2frontend.personid, Mike_data2frontend.tripnum, Mike_data2frontend.modes_desc, Mike_data2frontend.daynum, Mike_data2frontend.depart_dhm, Mike_data2frontend.mph, Mike_data2frontend.miles, Mike_data2frontend.arrive_dhm, Mike_data2frontend.Error, Mike_data2frontend.cotravelers, Mike_data2frontend.dest_name, Mike_data2frontend.dest_purpose, Mike_data2frontend.duration_at_dest
FROM Mike_data2frontend
ORDER BY Mike_data2frontend.personid, Mike_data2frontend.tripnum;

