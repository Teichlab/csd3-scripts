#!/bin/bash
set -eo pipefail

#set paths to cellranger and reference(s)
CELLRANGER=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/cellranger-9.0.1/bin/cellranger
REFERENCE=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/refdata-cellranger-vdj-GRCh38-alts-ensembl-7.1.0
PRIMERS=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/gd_inner_primers.txt

#cores and time
CORES=10
TIME=12

#oh magical cluster eight-ball, are we cclake or icelake today?
#PARTITION=`bash /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/slurm_partition_scan.sh | grep "himem" | sort -k 3 -n | head -n 1 | cut -f 1`
PARTITION=icelake-himem

#loop over the libraries
for LIBRARY in 
do
    #descend into subdirectory
    mkdir -p ${LIBRARY} && cd ${LIBRARY}
    mkdir -p logs
    #behold! a cellranger wrapper constructor!
    python /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pyranger.py \
        --cellranger ${CELLRANGER} \
        --command multi \
        --vdj-reference ${REFERENCE} \
        --primers ${PRIMERS} \
        --tcrgd ${LIBRARY} \
        --cores ${CORES}
    #the wrapper is now successfully constructed in N01-ranger.sh, can submit
    /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pysub -p ${PARTITION} -A TEICHLAB-SL2-CPU -c ${CORES} -t ${TIME} -J ${LIBRARY} -l logs "bash N01-ranger.sh" | sbatch
    cd ..
done
