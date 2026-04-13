#!/bin/bash
set -eo pipefail

#set paths to cellranger and reference(s)
CELLRANGER=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/cellranger-7.0.1/bin/cellranger
REFERENCE=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/refdata-gex-GRCh38-2020-A
FEATUREREF=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/common_feature_refs/claudi_13_cmos_25-09-22.csv

#cores and time
CORES=10
TIME=24

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
        --command count \
        --reference ${REFERENCE} \
        --cite ${LIBRARY} \
        --feature-ref ${FEATUREREF} \
        --chemistry ARC-v1 \
        --cores ${CORES} \
        --no-bam
    #the wrapper is now successfully constructed in N01-ranger.sh, can submit
    /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pysub -p ${PARTITION} -A TEICHLAB-SL2-CPU -c ${CORES} -t ${TIME} -J ${LIBRARY} -l logs "bash N01-ranger.sh" | sbatch
    cd ..
done
