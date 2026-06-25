#!/bin/bash
set -eo pipefail

#set paths to cellranger and reference(s)
CELLRANGER=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/cellranger-10.0.0/bin/cellranger
REFERENCE=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/refdata-gex-GRCh38-2024-A
PROBESET=/rfs/project/rfs-iCNyzSAaucw/ktp27/software/cellranger/cellranger-10.0.0/external/tenx_feature_references/targeted_panels/Chromium_Human_Transcriptome_Probe_Set_v2.0.0_GRCh38-2024-A.csv

#cores and time
CORES=10
TIME=24

#oh magical cluster eight-ball, are we cclake or icelake today?
#PARTITION=`bash /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/slurm_partition_scan.sh | grep "himem" | sort -k 3 -n | head -n 1 | cut -f 1`
PARTITION=icelake-himem

#loop over the libraries
for LIBRARY in 
do
    #while we're here, take note of the path to a CSV with multiplexing info
    #a headerless CSV with the sample name and the corresponding |-delimited
    #barcodes as the columns
    FLEXBCS=$(realpath ${LIBRARY}.csv)
    #descend into subdirectory
    mkdir -p ${LIBRARY} && cd ${LIBRARY}
    mkdir -p logs
    #behold! a cellranger wrapper constructor!
    python /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pyranger.py \
        --cellranger ${CELLRANGER} \
        --command multi \
        --reference ${REFERENCE} \
        --probe-set ${PROBESET} \
        --gex ${LIBRARY} \
        --flex-barcodes ${FLEXBCS} \
        --cores ${CORES} \
        --no-bam
    #the wrapper is now successfully constructed in N01-ranger.sh, can submit
    /rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts/pysub -p ${PARTITION} -A TEICHLAB-SL2-CPU -c ${CORES} -t ${TIME} -J ${LIBRARY} -l logs "bash N01-ranger.sh" | sbatch
    cd ..
done
