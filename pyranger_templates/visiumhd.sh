#!/bin/bash
set -eo pipefail

#set paths to cellranger and reference(s)
CELLRANGER=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/spaceranger-4.0.1/bin/spaceranger
REFERENCE=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/refdata-gex-GRCh38-2020-A
PROBESET=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/Visium_Human_Transcriptome_Probe_Set_v2.0_GRCh38-2020-A.csv

#oh magical cluster eight-ball, are we cclake or icelake today?
#PARTITION=`bash /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/slurm_partition_scan.sh | grep "himem" | sort -k 3 -n | head -n 1 | cut -f 1`
PARTITION=icelake-himem

#cores and time
CORES=16
TIME=24

#loop over the samples
for ENTRY in $(cat meta.csv)
do
    #metadata file featuring the following
    LIBRARY=$(echo ${ENTRY} | cut -f 1 -d ",")
    CYTAIMAGE=$(echo ${ENTRY} | cut -f 2 -d ",")
    IMAGE=$(echo ${ENTRY} | cut -f 3 -d ",")
    SLIDE=$(echo ${ENTRY} | cut -f 4 -d ",")
    AREA=$(echo ${ENTRY} | cut -f 5 -d ",")
    #descend into subdirectory
    mkdir -p ${LIBRARY} && cd ${LIBRARY}
    mkdir -p logs
    #behold! a cellranger wrapper constructor!
    #add extra probes via --extra-probes if needed
    python /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pyranger.py \
        --cellranger ${CELLRANGER} \
        --command count \
        --reference ${REFERENCE} \
        --probe-set ${PROBESET} \
        --cytaimage ${CYTAIMAGE} \
        --image ${IMAGE} \
        --slide ${SLIDE} \
        --area ${AREA} \
        --gex ${LIBRARY} \
        --no-bam
    #the wrapper is now successfully constructed in N01-ranger.sh, can submit
    /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pysub -p ${PARTITION} -A TEICHLAB-SL2-CPU -c ${CORES} -t ${TIME} -J ${LIBRARY} -l logs "bash N01-ranger.sh" | sbatch
    cd ..
done
