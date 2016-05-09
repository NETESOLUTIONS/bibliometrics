-- Dataset for PARDI Clinical Guidelines
-- User: selects clinical guideline(s) from a list
 
-- System returns: Files containing:
-- 1. Guideline(s) metadata: Silverchair ID, Title, (if available) WOS ID, PMID, PMCID, WOS or PubMed Citation.
-- 2. First-Generation guideline references (G1): Silverchair ID, WOS ID, PMID, PMCID, Title, Authors, Citation
-- 3. G1 Support: G1 PMID, core_project_num, admin_phs_org_code, match_case, external_org_id, index_name, PI name(s)
-- 4. Second-Generation references (G2): WOS and/or PMID from file 2 and metadata on cited references: WOS ID, PMID, PMCID, Title, Authors, Citation
-- 5. G2 Support, G2 PMID, core_project_num, admin_phs_org_code, match_case, external_org_id, index_name, PI name(s).

-- The following tables are exported to /tmp
-- temp_cg_summary.csv
-- temp_cg_spires.csv
-- temp_cg_citedg1_spires.csv
-- temp_cg_citedg2_spires.csv


select current_timestamp;
set log_temp_files=0;
set temp_tablespaces = 'temp_tbs';

--map clinical guidelines to pmids
drop table if exists temp_cg_pmid;
create table temp_cg_pmid as select a.uid as silverchair_id, b.pmid from cg_uids a LEFT JOIN cg_uid_pmid_mapping b on a.uid=b.uid;

--map clinical guidelines from current inventory that have pmids to wos_uids
drop table if exists temp_cg_pmid_wos;
create table temp_cg_pmid_wos as select a.*,b.wos_uid from cg_uid_pmid_mapping a LEFT JOIN wos_pmid_mapping b on a.pmid::int=b.pmid_int;

-- this step speeds things up YMMV
set enable_seqscan = 'off';

-- map wos_uids to cited_wos_uids
drop table if exists temp_cg_pmid_wos_citedwos_g1;
create table temp_cg_pmid_wos_citedwos_g1 as select a.*,b.cited_source_uid  from temp_cg_pmid_wos a LEFT JOIN wos_references b 
on a.wos_uid=b.source_id;

--clean up cited_source_uids 
update temp_cg_pmid_wos_citedwos_g1       
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

--add seq number to temp_cg_pmid_wos_citedwos_g1 to enable chunking
drop sequence if exists g1_seq;
create sequence g1_seq;
alter table temp_cg_pmid_wos_citedwos_g1  add column g1_seq integer not null default nextval('g1_seq');

-- build index on temp_cg_pmid_wos_citedwos_g1
drop index if exists temp_cg_pmid_idx;
create index temp_cg_pmid_idx on temp_cg_pmid_wos_citedwos_g1(cited_source_uid) tablespace wosindex_tbs;

--map cited_source_uids to second generation cited_source_uids in chunks
drop table if exists temp_cg1;
create table temp_cg1 as
select a.*,b.cited_source_uid as cited_source_uid_g2 
from temp_cg_pmid_wos_citedwos_g1 a 
LEFT JOIN  wos_references b on a.cited_source_uid=b.source_id 
where b.cited_source_uid is not null and a.g1_seq <=10000;

drop table if exists temp_cg2;
create table temp_cg2 as
select a.*,b.cited_source_uid as cited_source_uid_g2 
from temp_cg_pmid_wos_citedwos_g1 a 
LEFT JOIN  wos_references b on a.cited_source_uid=b.source_id 
where b.cited_source_uid is not null and a.g1_seq > 10000 and a.g1_seq <=20000;

drop table if exists temp_cg3;
create table temp_cg3 as
select a.*,b.cited_source_uid as cited_source_uid_g2 
from temp_cg_pmid_wos_citedwos_g1 a 
LEFT JOIN  wos_references b on a.cited_source_uid=b.source_id 
where b.cited_source_uid is not null and a.g1_seq > 20000 and a.g1_seq <=30000;

drop table if exists temp_cg4;
create table temp_cg4 as
select a.*,b.cited_source_uid as cited_source_uid_g2 
from temp_cg_pmid_wos_citedwos_g1 a 
LEFT JOIN  wos_references b on a.cited_source_uid=b.source_id 
where b.cited_source_uid is not null and a.g1_seq > 30000 and a.g1_seq <=40000;

drop table if exists temp_cg5;
create table temp_cg5 as
select a.*,b.cited_source_uid as cited_source_uid_g2 
from temp_cg_pmid_wos_citedwos_g1 a 
LEFT JOIN  wos_references b on a.cited_source_uid=b.source_id 
where b.cited_source_uid is not null and a.g1_seq > 40000 and a.g1_seq <=50000;

drop table if exists temp_cg6;
create table temp_cg6 as
select a.*,b.cited_source_uid as cited_source_uid_g2 
from temp_cg_pmid_wos_citedwos_g1 a 
LEFT JOIN  wos_references b on a.cited_source_uid=b.source_id 
where b.cited_source_uid is not null and a.g1_seq > 50000 and a.g1_seq <=60000;

drop table if exists temp_cg7;
create table temp_cg7 as
select a.*,b.cited_source_uid as cited_source_uid_g2 
from temp_cg_pmid_wos_citedwos_g1 a 
LEFT JOIN  wos_references b on a.cited_source_uid=b.source_id 
where b.cited_source_uid is not null and a.g1_seq > 60000;
select current_timestamp;

drop table if exists temp_cg_pmid_wos_citedwos_g1_g2;
create table temp_cg_pmid_wos_citedwos_g1_g2
as (select * from temp_cg1 union 
select * from temp_cg2 union 
select * from temp_cg3 union 
select * from temp_cg4 union 
select * from temp_cg5 union 
select * from temp_cg6 union 
select * from temp_cg7);

update temp_cg_pmid_wos_citedwos_g1_g2
  set cited_source_uid_g2 =
  (
    case when cited_source_uid_g2 like 'WOS%'
           then substring(cited_source_uid_g2, 1, 19)
         when cited_source_uid_g2 like 'MED%' or cited_source_uid_g2 like 'NON%' or
         cited_source_uid_g2 like 'CSC%' or cited_source_uid_g2 like 'INS%' or
         cited_source_uid_g2 like 'BCI%' or cited_source_uid_g2=''
           then cited_source_uid_g2
         else substring('WOS:'||cited_source_uid_g2, 1, 19)
    end
  );

select current_timestamp;

--clean up
drop table temp_cg1;
drop table temp_cg2;
drop table temp_cg3;
drop table temp_cg4;
drop table temp_cg5;
drop table temp_cg6;
drop table temp_cg7;

--create summary table of mapping counts
drop table if exists temp_cg_summary; 
create table temp_cg_summary as 
select uid, count(distinct pmid) as pmid,
count(distinct wos_uid) as wos_uid,
count(distinct cited_source_uid) as cited_wos_uid_g1,
count(distinct cited_source_uid_g2) as cited_wos_uid_g2 
from temp_cg_pmid_wos_citedwos_g1_g2 group by uid order by uid::int;

-- SPIRES mapping to pmid, cited_wos_uid_g1, and cited_wos_uid_g2

--cg to pmid to spires
drop table if exists temp_cg_working_table;
create table temp_cg_working_table as 
select distinct(uid),pmid from temp_cg_pmid_wos_citedwos_g1_g2;

drop table if exists temp_cg_spires;
create table temp_cg_spires as
select a.*,b.core_project_num,b.admin_phs_org_code,b.match_case,b.external_org_id,b.index_name
from temp_cg_working_table a LEFT JOIN spires_pub_projects b on a.pmid::int=b.pmid;

-- cg to cited_source_id_g1 to pmid to spires
drop table if exists temp_cg_working_table;
create table temp_cg_working_table as
select  distinct uid, pmid, cited_source_uid as cited_source_uid_g1 
from temp_cg_pmid_wos_citedwos_g1_g2  order by uid;

drop table if exists temp_cg_working_table2;
create table temp_cg_working_table2 as
select a.*,b.pmid_int from temp_cg_working_table a 
INNER JOIN wos_pmid_mapping b on a.cited_source_uid_g1=b.wos_uid;

drop table if exists temp_cg_citedg1_spires;
create table temp_cg_citedg1_spires as
select a.*,b.core_project_num,b.admin_phs_org_code,b.match_case,b.external_org_id,b.index_name
from temp_cg_working_table2 a INNER JOIN spires_pub_projects b on a.pmid_int=b.pmid;

--cg to cited_source_id_g2 to pmid to spires
drop table if exists temp_cg_working_table;
create table temp_cg_working_table as
select  distinct uid, pmid, cited_source_uid_g2
from temp_cg_pmid_wos_citedwos_g1_g2  order by uid;

drop table if exists temp_cg_working_table2;
create table temp_cg_working_table2 as
select a.*,b.pmid_int from temp_cg_working_table a 
INNER JOIN wos_pmid_mapping b on a.cited_source_uid_g2=b.wos_uid;

drop table if exists temp_cg_citedg2_spires;
create table temp_cg_citedg2_spires as
select a.*,b.core_project_num,b.admin_phs_org_code,b.match_case,b.external_org_id,b.index_name
from temp_cg_working_table2 a INNER JOIN spires_pub_projects b on a.pmid_int=b.pmid;


copy(select * from temp_cg_summary) to '/tmp/temp_cg_summary.csv' CSV HEADER DELIMITER ',';
copy(select * from temp_cg_spires) to '/tmp/temp_cg_spires.csv' CSV HEADER DELIMITER ',';
copy(select * from temp_cg_citedg1_spires) to '/tmp/temp_cg_citedg1_spires.csv' CSV HEADER DELIMITER ',';
copy(select * from temp_cg_citedg2_spires) to '/tmp/temp_cg_citedg2_spires.csv' CSV HEADER DELIMITER ',';

select current_timestamp;

--clean up 
drop table if exists temp_cg_working_table;
drop table if exists temp_cg_working_table2;

