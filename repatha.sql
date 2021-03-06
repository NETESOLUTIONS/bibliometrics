-- batch file for repatha test case procedures are quite manual
-- George Chacko 4/3/2016

-- load seedset of 59 pmids from R environment exported as repatha_seedset.csv
<<<<<<< HEAD
-- the R script is seedset.R, the source file is ev_fda_foundational, the output is ev_fda_seedset

\echo loading seedset pmids ***
drop table if exists temp_repatha1;
create table temp_repatha1 (sno int, uid int, pubdate varchar, lastauthor varchar, source varchar, title varchar, year int);
copy temp_repatha1 from '/tmp/repatha_seedset.csv' DELIMITER ',' CSV HEADER;

\echo primary matches against SPIRES
drop table if exists temp_repatha_primary;
create table temp_repatha_primary as select a.uid as pmid ,b.full_project_num_dc,b.admin_phs_org_code,b.match_case,b.external_org_id,b.index_name 
from temp_repatha1 a LEFT JOIN spires_pub_projects b on a.uid=b.pmid;

-- join pmids on wos_mapping to get wos_uid aka source_id
\echo getting corresponding wos_uids aka source_ids***
drop table if exists temp_repatha2;
create table temp_repatha2 as select a.uid,b.pmid_int,b.pmid,b.wos_uid from temp_repatha1 a LEFT JOIN wos_pmid_mapping b ON  a.uid=b.pmid_int;

--- in this case wos_uids were not returned for 6 pmids so the table was manually edited to include them based on a GUI search
\echo adding manually discovered wos_uids by GUI search***
=======
create table temp_repatha1 (sno int, uid int, pubdate varchar, lastauthor varchar, source varchar, title varchar, year int);
copy temp_repatha1 from '/tmp/repatha_seedset.csv' DELIMITER ',' CSV HEADER;

-- join pmids on wos_mapping to get wos_uid aka source_id
create table temp_repatha2 as select a.uid,b.pmid_int,b.wos_uid from temp_repatha1 a LEFT JOIN wos_pmid_mapping b ON  a.uid=b.pmid_int;
--- in this case wos_uids were not returned for 6 pmids so the table was manually edited to include them based on a GUI search
>>>>>>> master
update temp_repatha2 set wos_uid  = 'WOS:000084376400009'  where uid = 10712828;
update temp_repatha2 set wos_uid  = 'WOS:000338999800004'  where uid = 25014686;
update temp_repatha2 set wos_uid  = 'WOS:000367007300004'  where uid = 26696675;
update temp_repatha2 set wos_uid  = 'WOS:000306270800036'  where uid = 22085343;
update temp_repatha2 set wos_uid  = 'WOS:000277311200030'  where uid = 20228404;
update temp_repatha2 set wos_uid  = 'WOS:000284451000032'  where uid = 21067804;
<<<<<<< HEAD
update temp_repatha2 set pmid_int=uid where pmid_int is NULL;

-- get cited references from wos_references using wos_uids in temp_repatha2
\echo getting cited references from wos_references table***
drop table if exists temp_repatha3;
create table temp_repatha3 as select a.pmid_int,a.wos_uid,b.cited_source_uid from temp_repatha2 a LEFT JOIN wos_references b on a.wos_uid=b.source_id;
copy (select * from temp_repatha3) to '/tmp/tr3.csv' DELIMITER ',' CSV HEADER;

-- in R 
-- cleanup cited source_uids in R using George's WosClean.R script, tr3.csv as input and tr4.csv as output
-- copy tr4 into temp_repatha4

--tr3 <- read.csv("~/Desktop/tr3.csv",header=T,stringsAsFactors=FALSE)
--library(dplyr)
--tr4 <- tr3 %>% rowwise() %>% mutate(Clean= WosClean(cited_source_uid)) %>% data.frame()
--write.csv(tr4,file=("~/Desktop/tr4.csv"))

-- copy tr4 back into server at /tmp and edt header in emacs to get serial_no (sno) columnheader;

-- Clean WOS IDs.

\echo Cleaning WOS IDs on temp_repatha3...***
update temp_repatha3
  set cited_source_uid =
  (
    case when cited_source_uid like 'WOS%'
           then substring(cited_source_uid, 1, 19)
         when cited_source_uid like 'MED%' or cited_source_uid like 'NON%' or
         cited_source_uid like 'CSC%' or cited_source_uid like 'INS%' or
         cited_source_uid like 'BCI%' or cited_source_uid=''
           then cited_source_uid
         else substring('WOS:'||cited_source_uid, 1, 19)
    end
  );

--drop table if exists temp_repatha4;
--create table temp_repatha4 (sno int, source_id varchar, cited_source_uid varchar, clean varchar);
--copy temp_repatha4 from '/tmp/tr4.csv' DELIMITER ',' CSV HEADER;
-- get pmids back from the cited_source_uids
\echo mapping back to pmids***
drop table if exists temp_repatha4;
create table temp_repatha4 as  select a.pmid_int as input_pmid,a.wos_uid,a.cited_source_uid,b.pmid,b.pmid_int as pmid_output from temp_repatha3 a 
LEFT JOIN wos_pmid_mapping b on a.cited_source_uid=b.wos_uid;
-- pick up the extra MEDLINE ones as well 
update temp_repatha4 set pmid=cited_source_uid where substring(cited_source_uid,1,8)='MEDLINE:';
update temp_repatha4 set pmid_output=substring(pmid,9)::int  where substring(cited_source_uid,1,8)='MEDLINE:';

-- get SPIRES data when Shixin loads spires_pub_projects
\echo mapping pmid output to SPIRES for grants data***
drop table if exists temp_repatha5;
create table temp_repatha5 as select a.*,b.full_project_num_dc,b.admin_phs_org_code,b.match_case,b.external_org_id,b.index_name 
from temp_repatha4 a 
LEFT JOIN spires_pub_projects b on a.pmid_output=b.pmid;


=======

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
>>>>>>> master

