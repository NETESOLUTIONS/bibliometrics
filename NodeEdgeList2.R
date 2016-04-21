# copies SQL combined_repatha.sql output into R dataframes for generating
# a node and edgelist

setwd("/home/chackoge/bibliometrics")
if(file.exists("graph")) {system("rm -fr graph")}
system("mkdir graph")
setwd("/home/chackoge/bibliometrics/graph")
system("cp /tmp/temp_repatha*.csv .")
tr_names <- as.vector(dir())
temp_repatha_filelist <- as.list(dir())
temp_repatha_list <- vector("list",length=length(temp_repatha_filelist))
for (i in 1:length(temp_repatha_filelist)) {
temp_repatha_list[[i]] <- read.csv(temp_repatha_filelist[[i]],header=T,stringsAsFactors=FALSE)
}
names(temp_repatha_list) <- tr_names
rm(i)
rm(tr_names)
rm(temp_repatha_filelist)
t <- names(temp_repatha_list)
t1 <- sapply(strsplit(t, "[.]"), "[[", 1)
names(temp_repatha_list) <- t1



