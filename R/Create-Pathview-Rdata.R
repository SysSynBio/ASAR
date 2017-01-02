## THESE ARE FUNCTIONS TO PREPARE "Pathview.RData" file
## if you have required files for each sample, running this code should create pathview.Rdata file containing files needed to visualize paths and make tables and heatmaps.
#' Separate functional analysis data into a new table in a file removing duplicates.
#'
#'Checks md5sum and removes duplicates and copies functional analysis data into the file "d.uspfun".
#'@param file file from which functional analysis data is going to be extracted. 
#'@details Copies coloumns, namely `query sequence id`,`hit m5nr id (md5sum)`,fun and sp with all rows from file "d.merge" to the file "d".
#'@details Changes names of coloumns `query sequence id`,`hit m5nr id (md5sum)`,fun and sp to 'id','md5sum','fun'and 'sp' respectively.
#'@details Checks coloumn 'md5sum' and removes duplicates by transfering rows to "d.ufun" and removes quare brackets. 
#'@details Checks coloumn 'md5sum' and 'ufun' and removes duplicates by transfering rows to "d.uspfun" and removes quare brackets. 
#'@return table in the file "d.uspfun" which consists of ids, md5sum, function and species name.  
#'@export
expandNamesDT<-function(d.merge){
  d<-d.merge[,.(`query sequence id`,`hit m5nr id (md5sum)`,fun,sp)]
  names(d)<-c('id','md5sum','fun','sp')
  #dt[ , list( pep = unlist( strsplit( pep , ";" ) ) ) , by = pro ]
  unique(d[ , list(ufun = gsub('(\\]|\\[)','',unlist( strsplit( fun, "\\]; *\\[" ) )) ,fun,sp,ab=.N) , by = md5sum ])->d.ufun
  unique(d.ufun[ , list(fun,usp=gsub('(\\]|\\[)','',unlist( strsplit( sp, "\\]; *\\[" ) )) ,sp,ab) , by = .(md5sum,ufun) ])->d.uspfun
  return(d.uspfun)
}

#'Calculates number of sequences. 
#'@details First calculates sum of sequences ('ab') for every group in bacterial species (usp) and function (ufun) and renames coloumn as 'sum'. Then names 'md5sum as a 'md5' and separates elements of it by comma.
#'@details Columns 'species' (usp), 'functions' (ufun), 'sum' (sum) and md5 of sequences are returned as a data.table and duplicated rows by all columns are removed..
#'@param file
#'@return file that was input, but adding sum of sequences in the table.
#'@export
getAbundanceMD5FromDT<-function(d.ab){
  d.ab<-d.ab[,.(sum=sum(ab),md5=paste(md5sum,collapse = ',')),by=.(usp,ufun)]
  d.ab<-unique(d.ab[,.(usp,ufun,sum,md5)])
  return(d.ab)
}

#'Load metadata of metagenome samples
#'
#'Takes in a file containing metadata and assigns source and origin values depending on MetagenomeID
#'@param file file containing metadata of selected samples ususally exported from MG-RAST
#'@return formatted tab-delimited metadata table called "mdt"
#'@export
#'command "mdt <- load.metadata("jobs.tsv")" should be run
load.metadata <- function(file) {
  mdt<-read.delim(file)
  mdt$Name<-sub('^[0-9]+_([^_]+)_[^_]+_([^_]+).*$','\\1_\\2',mdt$Metagenome.Name)
  mdt$EID<-sub('^([^_]+)_.*$','\\1',mdt$Name)
  mdt$MFCID<-NA
  mdt$MFCID[mdt$EID=='S5'|mdt$EID=='S6']<-'MFC1_p'
  mdt$MFCID[mdt$EID=='S7'|mdt$EID=='S8']<-'MFC3_p'
  mdt$MFCID[mdt$EID=='S9'|mdt$EID=='S10']<-'MFC1_a'
  mdt$MFCID[mdt$EID=='S11'|mdt$EID=='S12']<-'MFC3_a'
  mdt$MFCID[mdt$EID=='S9'|mdt$EID=='S10']<-'MFC1_a'
  mdt$MFCID[mdt$EID=='S11'|mdt$EID=='S12']<-'MFC3_a'
  mdt$MFCID[mdt$EID=='S1']<-'inflowSW'
  mdt$MFCID[mdt$EID=='S2']<-'rIS'
  mdt$MFCID[mdt$EID=='S3']<-'rSW'
  mdt$MFCID[mdt$EID=='S4']<-'sMiz'
  mdt$Source<-NA
  samplesToKeep<-grep('_a',mdt$MFCID)
  mdt$Source[samplesToKeep]<-'anode'
  samplesToKeep<-grep('_p',mdt$MFCID)
  mdt$Source[samplesToKeep]<-'plankton'
  samplesToKeep<-grep('^r',mdt$MFCID)
  mdt$Source[samplesToKeep]<-'inoculum'
  samplesToKeep<-grep('^inflow',mdt$MFCID)
  mdt$Source[samplesToKeep]<-'inflow'
  mdt$Origin<-NA
  samplesToKeep<-grep('S(3|5|9|6|10)',mdt$Metagenome.Name)
  mdt$Origin[samplesToKeep]<-'sws'
  samplesToKeep<-grep('S(2|7|11|8|12)',mdt$Metagenome.Name)
  mdt$Origin[samplesToKeep]<-'is'
  mdt$Origin[mdt$MFCID=="inflowSW"]<-'inflow'
  rownames(mdt) <- as.character(mdt[, 1])
  return(mdt)
}
#'@return fannot
#' command ">fannot <- load.fdata.from.file()" should be run
load.fdata.from.file <- function(path = ".") {
  flist<-dir(path = path, pattern = "*.3.fseed$")
  cat(paste(flist,collapse = "\n"))
  fannot<-lapply(flist,function(.x){fread(paste0('ghead -n -1 ./', .x),sep='\t',header = TRUE)})
}

#'@return ko
#' command ">ko <- load.kodata.from.file()" should be run
load.kodata.from.file <- function(path = '.') {
  klist<-dir(path = path, pattern = '^m.*.ko$')
  cat(paste(klist,collapse = '\n'))
  ko<-lapply(klist,function(.x){fread(paste0('ghead -n -1 ./', .x),sep='\t',header = TRUE)})
}

#'@return sannot
#' command ">sannot <- load.sdata.from.file()" should be run
load.sdata.from.file <- function(path = '.') {
  slist<-dir(path = path,pattern = '*.3.seed$')
  flist<-dir(path = path, pattern = "*.3.fseed$")
  cat(paste(slist,collapse = '\n'))
  if(length(slist)!=length(flist)) stop('Length of functional and specie annotation should match\n')
  sannot<-lapply(slist,function(.x){fread(paste0('ghead -n -1 ./', .x),sep='\t',header = TRUE)})
}

#command "kres.res <- our.merge()" should be run
our.merge <- function() {
  flist<-dir(path = ".", pattern = "*.3.fseed$")
  nms<-gsub('.fseed$','',flist)
  res<-list()
  kres<-list()
  #fannot <- load.fdata.from.file()
  #sannot <- load.sdata.from.file()
  #ko <- load.kodata.from.file()
  for(i in 1:length(fannot)){
    f<-fannot[[i]]
    #f$`query sequence id`<-gsub('\\|KO$','',f$`query sequence id`)
    s<-sannot[[i]]
    #s$`query sequence id`<-gsub('\\|SEED$','',s$`query sequence id`)
    d.k<-unique(ko[[i]][,list(`hit m5nr id (md5sum)`,`semicolon separated list of annotations`)])
    #creates 3rd column with accession number itself only
    d.k1<-d.k[,list(`semicolon separated list of annotations`,ko=unlist(gsub('accession=\\[K([0-9]+)\\].*','K\\1',unlist(str_split(`semicolon separated list of annotations`,';'))))),by=.(`hit m5nr id (md5sum)`)]
    names(d.k1)<-c('md5','annotation','ko')
    #kres is ready
    kres[[nms[i]]]<-list(ab=d.k1,name=nms[i])
    
    keycols<-names(f)[1:12]
    setkeyv(f,keycols)
    setkeyv(s,keycols)
    d.merge<-merge(f,s,all=TRUE,suffixes = c('.fun','.sp'))
    names(d.merge)<-gsub('semicolon separated list of annotations.','',names(d.merge))
    d.uspfun<-expandNamesDT(d.merge)
    d.ab<-getAbundanceMD5FromDT(d.uspfun)
    #res is ready
    res[[nms[i]]]<-list(ab=d.ab,name=nms[i])
    
    #d.m.t<-table(d.merge$fun,d.merge$sp)
    cat(paste(i,nms[i],'\n'))
  }
  return(list(kres=kres, res=res))
}

#command "d.res <- make.d.res(kres.res)" should be run
make.d.res <- function(.list) {
  d.res<-ldply(.data = .list$res,
               .fun = function(.x){
                 ab<-.x$ab;
                 ab$mgid=.x$name;
                 return(ab)
               })
}

#command "d.kres <- make.d.kres(kres.res)" should be run
make.d.kres <- function(.list){
  d.kres<-unique(ldply(.data = .list$kres,
                       .fun = function(.x){
                         ab<-.x$ab;
                         return(ab)
                       }))
}

our.aggregate <- function() {
  dcast(setDT(d.res),usp+ufun+md5 ~ mgid,value.var = 'sum',fill = 0)->d.bm
  
  d.sp<-aggregate(.~usp,as.data.frame(d.bm)[,-c(2,3)],FUN = sum)
  d.fun<-aggregate(.~ufun,as.data.frame(d.bm)[,-c(1,3)],FUN = sum)
  return(d.bm)
}

#Calls of functions
mdt <- load.metadata("jobs.tsv")
fannot <- load.fdata.from.file()
ko <- load.kodata.from.file()
sannot <- load.sdata.from.file()
kres.res <- our.merge()
d.res <- make.d.res(kres.res)
d.kres <- make.d.kres(kres.res)
d.bm <- our.aggregate()
pwlist<-sort(unique(c('00020','00062','00561','00564','00620','00640','00650','00660','00680','00720','00790','00920','02024','02025','05111','00130','00190','00400','00860','00910','01053','01057','02010','02020')))
save(pwlist,d.bm,mdt,d.res,d.kres,fannot,sannot,ko,file = 'pathview.Rdata')