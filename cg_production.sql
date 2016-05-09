-- Dataset for PARDI Clinical Guidelines
-- User: selects clinical guideline(s) from a list
 
-- System returns: Files containing:
-- 1. Guideline(s) metadata: Silverchair ID, Title, (if available) WOS ID, PMID, PMCID, WOS or PubMed Citation.
-- 2. First-Generation guideline references (G1): Silverchair ID, WOS ID, PMID, PMCID, Title, Authors, Citation
-- 3. G1 Support: G1 PMID, core_project_num, admin_phs_org_code, match_case, external_org_id, index_name, PI name(s)
-- 4. Second-Generation references (G2): WOS and/or PMID from file 2 and metadata on cited references: WOS ID, PMID, PMCID, Title, Authors, Citation
-- 5. G2 Support, G2 PMID, core_project_num, admin_phs_org_code, match_case, external_org_id, index_name, PI name(s).

-- The following tables are created
-- temp_cg_pmid
-- temp_cg_pmid_wos
-- temp_cg_pmid_wos_citedwos_g1
-- temp_cg_pmid_wos_citedwos_g1_citedwos_g2
-- grants_G1
-- grants_G2

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


--add seq number to temp_cg_pmid_wos_citedwos_g1
drop sequence if exists g1_seq;
create sequence g1_seq;
alter table temp_cg_pmid_wos_citedwos_g1  add column g1_seq integer not null default nextval('g1_seq');

-- build index on temp_cg_pmid_wos_citedwos_g1
drop index if exists temp_cg_pmid_index;
create index temp_cg_pmid_index on temp_cg_pmid_wos_citedwos_g1(cited_source_uid) tablespace wosindex_tbs;

--map cited_source_uids to second generation cited_source_uids in chunks
drop table if exists temp_cg1;
create table temp_cg1 as 
select source_id, cited_source_uid from wos_references where source_id 
in (select cited_source_uid from temp_cg_pmid_wos_citedwos_g1 where cited_source_uid is not null and g1_seq <=10000);
select current_timestamp;

drop table if exists temp_cg2;
create table temp_cg2 as 
select source_id, cited_source_uid from wos_references  where source_id 
in (select cited_source_uid from temp_cg_pmid_wos_citedwos_g1 where cited_source_uid is not null and g1_seq > 10000 and g1_seq <=20000);
select current_timestamp;

drop table if exists temp_cg3;
create table temp_cg3 as 
select source_id, cited_source_uid from wos_references where source_id 
in (select cited_source_uid from temp_cg_pmid_wos_citedwos_g1 where cited_source_uid is not null and g1_seq > 20000 and g1_seq <=30000);
select current_timestamp;

drop table if exists temp_cg4;
create table temp_cg4 as 
select source_id, cited_source_uid from wos_references  where source_id 
in (select cited_source_uid from temp_cg_pmid_wos_citedwos_g1 where cited_source_uid is not null and g1_seq > 30000 and g1_seq <=40000);
select current_timestamp;

drop table if exists temp_cg5;
create table temp_cg5 as 
select source_id, cited_source_uid from wos_references where source_id 
in (select cited_source_uid from temp_cg_pmid_wos_citedwos_g1 where cited_source_uid is not null and g1_seq > 40000 and g1_seq <=50000);
select current_timestamp;

drop table if exists temp_cg6;
create table temp_cg6 as 
select source_id, cited_source_uid from wos_references where source_id 
in (select cited_source_uid from temp_cg_pmid_wos_citedwos_g1 where cited_source_uid is not null and g1_seq > 50000 and g1_seq <=60000);
select current_timestamp;

drop table if exists temp_cg7;
create table temp_cg7 as 
select source_id, cited_source_uid from wos_references where source_id 
in (select cited_source_uid from temp_cg_pmid_wos_citedwos_g1 where cited_source_uid is not null and g1_seq > 60000 and g1_seq <=70000);
select current_timestamp;

drop table if exists temp_cg_pmid_wos_citedwos_g1_citedwos_g2;
create table temp_cg_pmid_wos_citedwos_g1_citedwos_g2
as (select * from temp_cg1 union 
select * from temp_cg2 union 
select * from temp_cg3 union 
select * from temp_cg4 union 
select * from temp_cg5 union 
select * from temp_cg6 
union select * from temp_cg7);

update temp_cg_pmid_wos_citedwos_g1_citedwos_g2
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

select current_timestamp;















