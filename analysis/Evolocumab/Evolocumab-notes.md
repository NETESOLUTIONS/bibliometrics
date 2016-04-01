####Evolocumab-FDA-NDA-Medical.txt

As of July 30, 2015, evolocumab (Repatha) has not been approved by FDA, but there are plenty of references to work with in the clinical trials, the FDA Briefing Document, and Amgen press release:
* https://clinicaltrials.gov/ct2/results?term=evolocumab&Search=Search
* http://www.fda.gov/downloads/AdvisoryCommittees/CommitteesMeetingMaterials/Drugs/EndocrinologicandMetabolicDrugsAdvisoryCommittee/UCM450072.pdf
* http://www.amgen.com/media/news-releases/2014/11/fda-accepts-amgens-biologics-license-application-for-ldl-cholesterollowering-medication-evolocumab/

Evolocumab has since been approved and I found the following link on 3/29/2016 
* http://www.accessdata.fda.gov/scripts/cder/drugsatfda/index.cfm?fuseaction=Search.Label_ApprovalHistory#apphist

I'll hazard a guess that that before approval, Advisory Committee notes are more useful to identify presumably influential papers and maybe after approval too. In addition, they include non-clinical review. However, human judgment is critical must be exercised and is critical in identifying foundational publications.

In March 2016:

1. Foundational References: Start with a txt file into which you paste references copied one a time from the [Advisory Committee Review document](http://www.fda.gov/downloads/AdvisoryCommittees/CommitteesMeetingMaterials/Drugs/EndocrinologicandMetabolicDrugsAdvisoryCommittee/UCM450072.pdf). This process is time consuming but involves critical human judgment. In the case of Repatha, I also looked at the [Medical Review Document](http://www.accessdata.fda.gov/scripts/cder/drugsatfda/index.cfm?fuseaction=Search.Label_ApprovalHistory#apphist) (which lacks the non clinical review), the [Advisory Committee report](http://www.fda.gov/downloads/AdvisoryCommittees/CommitteesMeetingMaterials/Drugs/EndocrinologicandMetabolicDrugsAdvisoryCommittee/UCM450072.pdf) and an [Amgen PR document] (http://www.amgen.com/media/news-releases/2014/11/fda-accepts-amgens-biologics-license-application-for-ldl-cholesterollowering-medication-evolocumab/) as per Alex Pico. In fact, the combination of Advisory Committee notes and PR document provided the best dataset. I'll gratuitously comment that the practice of embedding references in footnotes is deplorable. I wish the FDA would insist on a machine readable list of uids and correctly formatted citations in *plain text*. I manually number the references and edit out the umlaut and diacritics etc. Then I *manually search PubMED* and recover pmids for this seed set. This involves more human judgment, which cannot be easily substituted for but a combination of at least one author, most of the title, and the journal name usually gets you what you want. We're working on developing an algorithm to automate this search strategy- stay tuned. The resultant dataset is named ev\_fda\_foundational. At this point, I import it into R and submit an Rentrez request to retrieve stuctured data via the seedset.R script, which generates a dataframe named ev\_fda\_foundational that serves as a reference point to start from.
2. Run a PubMed search for evolocumab using various search terms and combine the output into a single R dataframe ev\_pubmed\_all that contains pmids. 130 in this case, which is identical to just searching for all evolocumab in PubMed but YMMV depending on how recently your drug/biologic of interest was released. 
3. Search clinicaltrials.gov for evolocumab. We have downloaded the full XML dataset (we refresh it weekly) and parsed it into PostgreSQL. Thus we query ct\_interventions for instances of the string "evolocumab" and retrieve corresponding nct\_ids. These nct\_ids are then used to retrieve publications and references, which are combined into a three-column table. nct_id, pmid, pub\_or\_reference.
4. Search USPTO and Derwent Patent Citation Index. We downloaded the full USPTO dataset and also loaded the Derwent Patent Citation Index so that we could search by patent number. A Google search for evolocumab, revealed litigation between Amgen and Sanofi and the court judgment provided the patent numbers that I used to search our USPTO and Derwent tables. This resulted in cited patents and cited non-patent litearature (npl). 



Then I preprocess with sed and import into R as a two column dataframe (df), use dplyr to clean up null values and add a new cleaned up column "ncit_text"

In bash

```
cat evolocumab3  | sed -E 's/^[0-9]{1,2}\./+/' | sed -E '/^\s*$/d' > evolocumab4
```

In R

```
df <- read.csv("~/evolocumab4",header=FALSE,sep="+", stringsAsFactors=FALSE)
colnames(df) <- c("blank","cit_text")
library(dplyr)
df <- df %>% select(cit_text) %>% mutate(ncit_text=ifelse(cit_text=="","BINGO",cit_text))
```

and then run the nplcit_pubmed_search function I wrote

```
nplcit\_pubmed\_search(substring(t$ncit_text,1,220))
```

which generates a list of vectors. This protocol needs some fine tuning.

``` 
{r nplcit\_pubmed\_search} nplcit_pubmed_search <- function (x)	{
print(length(x))
nplcit_list <- vector("list",length(x))
library(rentrez)
for (i in 1:length(x)){	
t<- entrez_search(db="pubmed", term=x[i],retstart=0,retmax=3)	
nplcit_list[[i]] <- t$ids	
print(i)
print(t$ids)
rm(t)
}
print(nplcit_list)
return(nplcit_list)
}
``` 

####Evolocumab-core.pklz
```
python src/topdown.py --format cse --levels 2 input/Evolocumab-FDA-NDA-Medical.txt output/Evolocumab-core.pklz
```
Ran o/n.

####Evolocumab-core-individual-indegree.pklz, Evolocumab-core-propagate-sum.pklz
```
python src/score.py --article-scoring individual --neighbor-scoring indegree output/Evolocumab-core.pklz output/Evolocumab-core-individual-indegree.pklz
python src/score.py --article-scoring propagate --neighbor-scoring sum output/Evolocumab-core.pklz output/Evolocumab-core-propagate-sum.pklz
```

####Evolocumab-core-individual-indegree.xgmml, Evolocumab-core-propagate-sum.xgmml
```
python src/xgmml.py output/Evolocumab-core-individual-indegree.pklz output/Evolocumab-core-individual-indegree.xgmml
python src/xgmml.py output/Evolocumab-core-propagate-sum.pklz output/Evolocumab-core-propagate-sum.xgmml
```
Network properties:
* 1548 articles (1950-2015)
* 7350 authors
* 4846 institutions
* 37 grant agencies
* 26 clinical trials 


####Evolocumab-Pubmed-Search-PMIDs*.txt
For the peripheral network, we will try sampling from the following search term:
* (("1900/1/1"[Date - Publication] : "2015/03/11"[Date - Publication])) AND ldl cholesterol reduction
 * 9593 hits spanning 1971-2015 
  * took 200 pmids from every 6th page to collect 1600 pubs, 5 
   * 1,7,13,...43 | 2,8,14,...44 | 3,9,15,...45 | 4,10,16,..46 | 5,11,17,..47,48(1794)

##Evolocumab-peripheral*.pklz
Note: only level 1 if providing comparable number of pmids from pubmed search, i.e., comparable to core network article count.
```
python src/topdown.py --format pmid --dont-search-trials --levels 1 input/Evolocumab-Pubmed-Search-PMIDs1.txt output/Evolocumab-peripheral1.pklz
python src/topdown.py --format pmid --dont-search-trials --levels 1 input/Evolocumab-Pubmed-Search-PMIDs2.txt output/Evolocumab-peripheral2.pklz
python src/topdown.py --format pmid --dont-search-trials --levels 1 input/Evolocumab-Pubmed-Search-PMIDs3.txt output/Evolocumab-peripheral3.pklz
python src/topdown.py --format pmid --dont-search-trials --levels 1 input/Evolocumab-Pubmed-Search-PMIDs4.txt output/Evolocumab-peripheral4.pklz
python src/topdown.py --format pmid --dont-search-trials --levels 1 input/Evolocumab-Pubmed-Search-PMIDs5.txt output/Evolocumab-peripheral5.pklz
```
Ran in 9-30 min each.

####Evolocumab-peripheral-individual-indegree*.pklz
```
python src/score.py --article-scoring individual --neighbor-scoring indegree output/Evolocumab-peripheral1.pklz output/Evolocumab-peripheral-individual-indegree1.pklz
python src/score.py --article-scoring individual --neighbor-scoring indegree output/Evolocumab-peripheral2.pklz output/Evolocumab-peripheral-individual-indegree2.pklz
python src/score.py --article-scoring individual --neighbor-scoring indegree output/Evolocumab-peripheral3.pklz output/Evolocumab-peripheral-individual-indegree3.pklz
python src/score.py --article-scoring individual --neighbor-scoring indegree output/Evolocumab-peripheral4.pklz output/Evolocumab-peripheral-individual-indegree4.pklz
python src/score.py --article-scoring individual --neighbor-scoring indegree output/Evolocumab-peripheral5.pklz output/Evolocumab-peripheral-individual-indegree5.pklz
```

####Evolocumab-peripheral-scored-*.xgmml
```
python src/xgmml.py output/Evolocumab-peripheral-individual-indegree1.pklz output/Evolocumab-peripheral-individual-indegree1.xgmml
python src/xgmml.py output/Evolocumab-peripheral-individual-indegree2.pklz output/Evolocumab-peripheral-individual-indegree2.xgmml
python src/xgmml.py output/Evolocumab-peripheral-individual-indegree3.pklz output/Evolocumab-peripheral-individual-indegree3.xgmml
python src/xgmml.py output/Evolocumab-peripheral-individual-indegree4.pklz output/Evolocumab-peripheral-individual-indegree4.xgmml
python src/xgmml.py output/Evolocumab-peripheral-individual-indegree5.pklz output/Evolocumab-peripheral-individual-indegree5.xgmml
```
Network properties (average):
* 1639 articles (8193 unique articles total)
* 7598 authors
* 4460 institutions
* 31 grantagencies

####Analysis
* Opened scored xgmml in Cytoscape
* Selected authors into new subnetwork; selected institutes into new subnetwork
* Exported default node tables for each subnetwork
* Opened csv in excel
* Pasted authors and scores from core-scored-sum author subnetworks into CP-Prop columns in analysis.xlsx template
* Pasted authors and ct_scores from core-scored-sum author subnetworks into CT-Count columns
* Pasted authors and score from core-scored-indegree author subnetworks into CP-Indegree columns
* Pasted authors and score from peripheral-scored-indegree author subnetwork into Denom-Indegree columns
* Pasted authors and score from peripheral-scored-indegree2 author subnetwork into Denom-Indegree2 columns
* Template formulas calculation ranks and ratios
* Note: averaged ratios across multiple samples of peripheral to get a better RBR filter criteria, i.e., it covers more of the pubmed search result space, without compromizing the scope and size contraints of a given peripheral network. 

CPI subnetwork:
* 342 articles (1974-2014)
* 27 authors
* 7 institutes (4 unique)
