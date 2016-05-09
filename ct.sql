-- get nct_ids and pmids from references (no pubs were noted in this case)
select nct_id,pmid,citation from ct_references where nct_id in (select nct_id from ct_interventions where lower(intervention_name) like '%evolocumab%' or lower(intervention_name) like '%repatha%');
