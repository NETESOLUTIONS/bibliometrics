-- batch file for repatha test case some stages procedures are quite manual
-- George Chacko 4/14/2016

--PATENT BRANCH
-- Find relevant patent numbers by the method of Google
-- then search for these number in uspto_patents and Derwent tables
-- select patent_num from uspto_patents where patent_num like '%8871913' or patent_num like '%8871914';
-- returns
-- patent_num
-- ------------
--  08871913
--  08871914
-- search aaain with correct numbers for cited patents and cited literature
-- run this script as 'psql -d pardi < combined_repatha.sql > repathalog;'

\echo create patents awarded to drug***
drop table if exists temp_repatha_patents_g1;
create table temp_repatha_patents_g1 (drug varchar, patent_num_orig varchar);
insert into temp_repatha_patents_g1 values ('Repatha','08871913');
insert into temp_repatha_patents_g1 values ('Repatha','08871914');

\echo getting patents cited by Repatha patents (G2) 
drop table if exists temp_repatha_patents_g2;
create table temp_repatha_patents_g2 as select patent_num_orig, cited_patent_orig 
from derwent_pat_citations 
where patent_num_orig in (select patent_num_orig from temp_repatha_patents_g1);

-- note patent_num_orig and cited_patent_orig are combined into drug_patents
\echo combining into single list of patent_numbers aka drug_patents**
drop table if exists temp_repatha_patents_combined;
create table temp_repatha_patents_combined as select cited_patent_orig as drug_patents from temp_repatha_patents_g2;
insert into temp_repatha_patents_combined select substring(patent_num_orig,2) from temp_repatha_patents_g1;

\echo retrieve wosids for patents (contains elegant Shixin construct)***
drop table if exists temp_repatha_patents_wos;
create table temp_repatha_patents_wos as 
select * from wos_patent_mapping where patent_orig in (select 
distinct lpad(drug_patents,8,'0') from temp_repatha_patents_combined 
where length(drug_patents) = 7);

\echo joining on wos_pmid_mapping to get pmids **
drop table if exists temp_repatha_patents_pmid;
create table temp_repatha_patents_pmid as
select a.patent_num,a.wos_id,b.pmid_int from temp_repatha_patents_wos a 
LEFT JOIN wos_pmid_mapping b on a.wos_id=b.wos_uid;

-- LITERATURE BRANCH
-- begin with drug or biologic name, e.g. repatha aka evolocumab aka AMG145
-- assemble seedset of pmids by scraping from FDA approval documents and identifying corresponding pmids
-- use R script is seedset.R to get back structured data from eutuils, the source file is ev_fda_foundational, 
-- the output is ev_fda_seedset

-- load seedset of 59 pmids from R environment exported as repatha_seedset.csv

\echo loading seedset pmids ***
drop table if exists temp_repatha1;
create table temp_repatha1 (sno int, uid int, pubdate varchar, lastauthor varchar, source varchar, title varchar, year int);
copy temp_repatha1 from '/tmp/seedset.csv' DELIMITER ',' CSV HEADER;


-- create CT to pmid table (temp_repatha_ct)
\echo search for repatha in CT tables in PARDI and identify pmids from cited references in ct_references***
drop table if exists temp_repatha_ct;
create table temp_repatha_ct as select nct_id,pmid from ct_references where nct_id in (select nct_id from ct_interventions 
where lower(intervention_name) ='evolocumab' or lower(intervention_name) like 'repatha');

--create first generation pmid list (citg1)
\echo creating first generation pmid list***
drop table if exists temp_repatha_citg1;
create table temp_repatha_citg1 (source varchar, citg1 int);
insert into temp_repatha_citg1 select patent_num, pmid_int  from temp_repatha_patents_pmid;
insert into temp_repatha_citg1 select nct_id,pmid from temp_repatha_ct;
insert into temp_repatha_citg1 select 'seedset',uid from temp_repatha1 where uid not in (select pmid from temp_repatha_ct);
--map citg1 to SPIRES for 

drop table if exists temp_repatha_citg1_spires;
create table temp_repatha_citg1_spires as select a.*,b.full_project_num_dc,b.admin_phs_org_code,b.match_case,
b.external_org_id,b.index_name from temp_repatha_citg1 a LEFT JOIN spires_pub_projects b on a.citg1=b.pmid;

\echo creating second generation pmid list***

--get wos ids
drop table if exists temp_repatha2;
create table temp_repatha2 as select a.*,b.wos_uid from temp_repatha_citg1 a LEFT JOIN wos_pmid_mapping b on a.citg1=b.pmid_int;
--- in this case wos_uids were not returned for 6 pmids so the table was manually edited to include them based on 
--a GUI search
\echo adding manually discovered wos_uids by GUI search***
update temp_repatha2 set wos_uid  = 'WOS:000084376400009'  where citg1  = 10712828;
update temp_repatha2 set wos_uid  = 'WOS:000338999800004'  where citg1  = 25014686;
update temp_repatha2 set wos_uid  = 'WOS:000367007300004'  where citg1  = 26696675;
update temp_repatha2 set wos_uid  = 'WOS:000306270800036'  where citg1  = 22085343;
update temp_repatha2 set wos_uid  = 'WOS:000277311200030'  where citg1  = 20228404;
update temp_repatha2 set wos_uid  = 'WOS:000284451000032'  where citg1  = 21067804;
-- get cited references
set enable_seqscan to 'off';
drop table if exists temp_repatha3;
create table temp_repatha3 as select a.*,b.cited_source_uid from temp_repatha2 a 
LEFT JOIN wos_references b on a.wos_uid=b.source_id;

\echo cleaning wos ids***
-- clean WOS IDs.
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

copy (select * from temp_repatha3) to '/tmp/tr3.csv' DELIMITER ',' CSV HEADER;

\echo mapping back to pmids***
drop table if exists temp_repatha4;
create table temp_repatha4 as  select a.citg1 as input_pmid,a.wos_uid,a.cited_source_uid,b.pmid,b.pmid_int 
as pmid_output from temp_repatha3 a LEFT JOIN wos_pmid_mapping b on a.cited_source_uid=b.wos_uid;

-- pick up the extra MEDLINE ones as well 
update temp_repatha4 set pmid=cited_source_uid where substring(cited_source_uid,1,8)='MEDLINE:';
update temp_repatha4 set pmid_output=substring(pmid,9)::int  where substring(cited_source_uid,1,8)='MEDLINE:';

-- get SPIRES data for Gen2
\echo mapping pmid output to SPIRES for grants data***
drop table if exists temp_repatha_citg2_spires;
create table temp_repatha_citg2_spires as select a.*,b.full_project_num_dc,b.admin_phs_org_code,b.match_case,
b.external_org_id,b.index_name from temp_repatha4 a 
LEFT JOIN spires_pub_projects b on a.pmid_output=b.pmid;

\echo export all relevant tables to /tmp***
copy(select * from temp_repatha_patents_pmid) to '/tmp/temp_repatha_patents_pmid.csv' DELIMITER ',' CSV HEADER;
copy(select * from temp_repatha_citg1_spires) to '/tmp/temp_repatha_citg1_spires.csv' DELIMITER ',' CSV HEADER;
copy(select * from temp_repatha_citg2_spires) to '/tmp/temp_repatha_citg2_spires.csv' DELIMITER ',' CSV HEADER;

