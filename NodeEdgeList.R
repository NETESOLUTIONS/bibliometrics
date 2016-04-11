# read in output from repatha2.sql on dev2 (three csv files)
# and transform into an edge list and a node list

temp_repatha_ct <- read.csv("~/Desktop/temp_repatha_ct.csv",stringsAsFactors=FALSE)
temp_repatha_primary <- read.csv("~/Desktop/temp_repatha_primary.csv",stringsAsFactors=FALSE)
temp_repatha_secondary <- read.csv("~/Desktop/temp_repatha_secondary.csv",stringsAsFactors=FALSE)

#- Create node list
library(dplyr)
n1 <- c("Repatha","drug")
n2 <- temp_repatha_ct %>% select(nct_id) %>% mutate(ntype="CT")
n2 <- rbind(n1,n2)
colnames(n2) <- c("nodeID","ntype")
n3 <- temp_repatha_primary %>% select(pmid) %>% mutate(ntype="G1")
colnames(n3) <- c("nodeID","ntype")
n4 <- temp_repatha_secondary %>% select (pmid_output) %>% mutate(ntype="G2")
colnames(n4) <- c("nodeID","ntype")
n5 <- temp_repatha_primary %>% select(full_project_num_dc) %>% filter(full_project_num_dc!="") %>% mutate(ntype="grant")
colnames(n5) <- c("nodeID","ntype")
n6 <- temp_repatha_secondary %>% select(full_project_num_dc) %>% filter(full_project_num_dc!="") %>% mutate(ntype="grant")
colnames(n6) <- c("nodeID","ntype")
nodelist <- rbind(n2,n3,n4,n5,n6)
nodelist <- nodelist %>% unique()

nodelist <- rbind(n2,n3,n4)
# suppress duplicates
nodelist <- nodelist %>% unique()

# create edgelist
#master edges- drug to CT
e1 <- temp_repatha_ct %>% mutate(source="Repatha") %>% select(source,nct_id)
colnames(e1) <- c("source","target")
#CT to pmid
e2 <- temp_repatha_ct %>% select(nct_id,pmid)
colnames(e2) <- c("source","target")
# primary pmids to grants
e3 <- temp_repatha_primary %>% select (pmid,full_project_num_dc) %>% filter(full_project_num_dc!="")
colnames(e3) <- c("source","target")
# primary pmids to secondary pmids
e4 <- temp_repatha_secondary %>% select(input_pmid,pmid_output) %>% unique() 
colnames(e4) <- c("source","target")
# secondary pmids to grants
e5 <- temp_repatha_secondary %>% select(pmid_output,full_project_num_dc) %>% filter(full_project_num_dc!="") %>% unique()
colnames(e5) <- c("source","target")
edgelist <- rbind(e1,e2,e3,e4,e5)

# Export
write.csv(nodelist,file="~/Desktop/nodelist.csv")
write.csv(edgelist,file="~/Desktop/edgelist.csv")
save(nodelist,edgelist,file="~/Desktop/NodeEdge.RData")



