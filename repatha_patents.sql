-- First find relevant patnet numbers by the method of Google
-- then search for these number in uspto_patents
-- select patent_num from uspto_patents where patent_num like '%8871913' or patent_num like '%8871914';
-- returns 
-- patent_num
-- ------------
--  08871913
--  08871914

-- search aaain with correct numbers

drop table if exists temp_repatha_patent_citations;
create table temp_repatha_patent_citations as select *  from uspto_pat_citations where patent_num in ('08871913', '08871914');
drop table if exists temp_repatha_patent_wos;
create table temp_repatha_patent_wos as select * from wos_patent_mapping where patent_num in ('US8871913','US8871914');
drop table if exists temp_repatha_patent_pmid;
create table temp_repatha_patent_pmid as select wos_uid,pmid_int from wos_pmid_mapping where wos_uid in (select distinct wos_id from temp_repatha_patent_wos);
drop table if exists temp_repatha_patent_spires;
create table temp_repatha_patent_spires as select a.*,b.* from temp_repatha_patent_pmid a INNER JOIN spires_pub_projects b on a.pmid_int=b.pmid;

