SELECT p.personid, p.hhid, p.pernum, ac.agedesc AS Age, IIf([p.worker]=0,"No","Yes") AS Works, Switch([p.student]=1,"No",[student]=2,"PT",[p.student]=3,"FT") AS Studies
FROM Mike_person AS p INNER JOIN Mike_hhts_agecodes AS ac ON p.age = ac.agecode
WHERE EXISTS (SELECT 1 FROM Mike_trip_error_flags AS tef WHERE tef.personid = p.personid);

