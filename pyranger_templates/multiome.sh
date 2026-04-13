#!/bin/bash
set -eo pipefail

#set paths to cellranger and reference(s)
CELLRANGER=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/cellranger-arc-2.0.2/bin/cellranger-arc
REFERENCE=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/refdata-cellranger-arc-GRCh38-2020-A-2.0.0

#cores and time
CORES=16
TIME=36

#oh magical cluster eight-ball, are we cclake or icelake today?
#PARTITION=`bash /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/slurm_partition_scan.sh | grep "himem" | sort -k 3 -n | head -n 1 | cut -f 1`
PARTITION=icelake-himem

#loop over the libraries
#just the two first bits of the name - the suffix is added in the loop
for LIBRARY in 
do
    #GEX/ATAC IDs descend from this common prefix
    GEX=${LIBRARY}_MG
    ATAC=${LIBRARY}_MA
    #descend into subdirectory
    mkdir -p ${GEX}-${ATAC} && cd ${GEX}-${ATAC}
    mkdir -p logs
    #behold! a cellranger wrapper constructor!
    python /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pyranger.py \
        --cellranger ${CELLRANGER} \
        --command count \
        --reference ${REFERENCE} \
        --gex ${GEX} \
        --atac ${ATAC} \
        --cores ${CORES} \
        --no-bam
    #the wrapper is now successfully constructed in N01-ranger.sh, can submit
    /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pysub -p ${PARTITION} -A TEICHLAB-SL2-CPU -c ${CORES} -t ${TIME} -J ${LIBRARY} -l logs "bash N01-ranger.sh" | sbatch
    cd ..
done
