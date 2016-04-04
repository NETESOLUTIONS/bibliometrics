-- batch file for repatha test case procedures are quite manual
-- George Chacko 4/3/2016

-- load seedset of 59 pmids from R environment exported as repatha_seedset.csv
create table temp_repatha1 (sno int, uid int, pubdate varchar, lastauthor varchar, source varchar, title varchar, year int);
copy temp_repatha1 from '/tmp/repatha_seedset.csv' DELIMITER ',' CSV HEADER;

-- join pmids on wos_mapping to get wos_uid aka source_id
create table temp_repatha2 as select a.uid,b.pmid_int,b.wos_uid from temp_repatha1 a LEFT JOIN wos_pmid_mapping b ON  a.uid=b.pmid_int;
--- in this case wos_uids were not returned for 6 pmids so the table was manually edited to include them based on a GUI search
update temp_repatha2 set wos_uid  = 'WOS:000084376400009'  where uid = 10712828;
update temp_repatha2 set wos_uid  = 'WOS:000338999800004'  where uid = 25014686;
update temp_repatha2 set wos_uid  = 'WOS:000367007300004'  where uid = 26696675;
update temp_repatha2 set wos_uid  = 'WOS:000306270800036'  where uid = 22085343;
update temp_repatha2 set wos_uid  = 'WOS:000277311200030'  where uid = 20228404;
update temp_repatha2 set wos_uid  = 'WOS:000284451000032'  where uid = 21067804;

-- get cited references from wos_references using wos_uids in temp_repatha2
create table temp_repatha3 as select source_id, cited_source_uid from wos_references where source_id in (select wos_uid from temp_repatha2);
copy (select * from temp_repatha3) to '/tmp/tr3.csv' DELIMITER ',' CSV HEADER;

-- cleanup cited source_uids in R using George's WosClean.R script, tr3.csv as input and tr4.csv as output
-- copy tr4 into temp_repatha4
create table temp_repatha4 (sno int, source_id varchar, cited_source_uid varchar, clean varchar);
copy temp_repatha4 from '/tmp/tr4.csv' DELIMITER ',' CSV HEADER;

-- get pmids back from the cited_source_uids
create table temp_repatha5 as  select a.*,b.pmid,b.pmid_int  from temp_repatha4 a LEFT JOIN wos_pmid_mapping b on a.clean=b.wos_uid;
-- pick up the extra MEDLINE ones as well 
update temp_repatha5 set pmid=clean where substring(clean,1,8)='MEDLINE:';
update temp_repatha5 set pmid_int=substring(pmid,9)::int  where substring(clean,1,8)='MEDLINE:';

-- get SPIRES data when Shixin loads spires_pub_projects

