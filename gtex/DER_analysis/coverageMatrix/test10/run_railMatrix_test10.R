library('derfinder')
library('devtools')
library('BiocParallel')
library('getopt')

## Specify parameters
spec <- matrix(c(
    'chr', 'c', 1, 'character', 'Chromosome in the following format: chr1, chrX, chrY',
	'help' , 'h', 0, 'logical', 'Display help'
), byrow=TRUE, ncol=5)
opt <- getopt(spec)


## if help was asked for print a friendly message
## and exit with a non-zero error code
if (!is.null(opt$help)) {
	cat(getopt(spec, usage=TRUE))
	q(status=1)
}


## Options
cutoff <- 0.5

chrs <- opt$chr
## Get chr length
chrInfo <- read.table('/dcl01/leek/data/gtex_work/runs/gtex/hg38.sizes', header = FALSE, stringsAsFactors = FALSE, col.names = c('chr', 'length'))
chrlens <- chrInfo$length[chrInfo$chr %in% chrs]

load('/dcl01/leek/data/gtex_work/runs/gtex/DER_analysis/pheno/pheno_missing_less_10.Rdata')

pheno <- subset(pheno, Run %in% c('SRR1088982', 'SRR1090119', 'SRR1308734', 'SRR1331944', 'SRR1401552', 'SRR1417632', 'SRR1445789', 'SRR1452143', 'SRR598452', 'SRR811491'))


summaryFiles <- '/dcl01/leek/data/gtex_work/gtex_mean_coverage.bw'
sampleFiles <- pheno$BigWigPath
names(sampleFiles) <- gsub('/dcl01/leek/data/gtex/batch_[0-9]*/coverage_bigwigs/|.bw', '', sampleFiles)

## Find count files
counts_files <- file.path(dir('/dcl01/leek/data/gtex', pattern = 'batch', full.names = TRUE), 'cross_sample_results', 'counts.tsv.gz')
names(counts_files) <- dir('/dcl01/leek/data/gtex', pattern = 'batch')

## Read in counts info
counts <- lapply(counts_files, function(i) {
    read.table(i, header = TRUE, sep = '\t', stringsAsFactors = FALSE)
})
counts <- do.call(rbind, counts)
counts$totalMapped <- as.integer(sapply(strsplit(counts$total.mapped.reads, ','), '[[', 1))

## Match files to counts
map <- match(gsub('/dcl01/leek/data/gtex/batch_[0-9]*/coverage_bigwigs/|.bw', '', sampleFiles), counts$X)
counts <- counts[map, ]

## Run railMatrix
regionMat <- railMatrix(chrs, summaryFiles, sampleFiles, L = pheno$avgLength / 2, cutoff = cutoff, targetSize = 40e6, totalMapped = counts$totalMapped, file.cores = 1L, chunksize = 10000, verbose.load = FALSE, chrlens = chrlens)

## Save results
save(regionMat, file=paste0('regionMat-cut', cutoff, '-', opt$chr, '.Rdata'))

## Reproducibility info
proc.time()
Sys.time()
options(width = 120)
devtools::session_info()
