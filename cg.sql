-- CLinical Guidelines Mapping

--map clinical guidelines from current inventory that have pnids to wos_uids
drop table if exists temp_cg_pmid_wos;
create table temp_cg_pmid_wos as select a.*,b.wos_uid from cg_uid_pmid_mapping a LEFT JOIN wos_pmid_mapping b on a.pmid::int=b.pmid_int;

-- this step speeds things up
set enable_seqscan to 'off';

-- map wos_uids to cited_wos_uids
drop table if exists temp_cg_pmid_wos_citedwos;
create table temp_cg_pmid_wos_citedwos as select a.*,b.cited_source_uid  from temp_cg_pmid_wos a LEFT JOIN wos_references b 
on a.wos_uid=b.source_id;

--clean up cited_source_uids 
update temp_cg_pmid_wos_citedwos       
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
  )
;

--map cited_source_uids to pmids
drop table if exists temp_cg_pmid_wos_citedwos_pmid;
create table temp_cg_pmid_wos_citedwos_pmid as select a.*,b.pmid_int from temp_cg_pmid_wos_citedwos a LEFT JOIN wos_pmid_mapping b on a.cited_source_uid=b.wos_uid;
update temp_cg_pmid_wos_citedwos_pmid set pmid_int=substring(cited_source_uid,9)::int where substring(cited_source_uid,1,8)='MEDLINE:';

-- pmids to spires
drop table if exists temp_cg_pmid_wos_citedwos_pmid_spires;
create table temp_cg_pmid_wos_citedwos_pmid_spires as 
select a.*,b.full_project_num_dc,b.admin_phs_org_code,b.match_case,b.external_org_id,b.index_name
from temp_cg_pmid_wos_citedwos_pmid a LEFT JOIN spires_pub_projects b on a.pmid_int=b.pmid;
