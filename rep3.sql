drop table if exists temp_repatha3;
create table temp_repatha3 as select a.*,b.cited_source_uid from temp_repatha2 a
LEFT JOIN wos_references b on a.wos_uid=b.source_id;
