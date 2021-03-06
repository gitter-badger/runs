#!/bin/bash
#$ -cwd
#$ -m e
#$ -l mem_free=3G,h_vmem=20G,h_fsize=30G
#$ -N region-cuts
#$ -pe local 25

echo '**** Job starts ****'
date


## Make logs dir
mkdir -p logs

# Find region cuts
module load R/3.2.x
Rscript find_region_cuts.R

## Move log files into the logs directory
mv region-cuts.* logs/

echo '**** Job ends ****'
date
