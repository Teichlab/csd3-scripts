#!/bin/bash
set -eo pipefail

#helper function for fastq ingestion
#assumes you're already in the fastq folder

#one positional argument - the sample ID
SAMPLE=$1

#get directory this is in to call scripts as needed
SCRIPTDIR=`dirname "$0"`

#pick up the reads, use the sample-level folder for it, so we need the hashes
PROJECT=`echo ${SAMPLE} | cut -f 1 -d "_"`
SHASH=`echo ${SAMPLE} | cut -f 2 -d "_" | cut -c 1-5`
#we need to do this separately for each pool-flowcell combo this sample appears in
#otherwise the CRUK renaming script overrides the resulting read files
#we'll fakely rename the files to S2, S3, etc. to circumvent this
scount=2
for SEQ in /rds/project/rds-C9woKbOCf2Y/samples/${PROJECT}/${SHASH}/${SAMPLE}/sequencing/*
do
    rsync -P ${SEQ}/*.${SAMPLE}.*.fq.gz .
    #use the official renaming script: https://genomicshelp.cruk.cam.ac.uk/tools/crukci_to_illumina.py
    python3 ${SCRIPTDIR}/crukci_to_illumina.py
    #at this point the files are named illumina style, and S is set to S1
    #move to whatever the number is, starting at 2 and going up as mentioned
    rename _S1_ _S${scount}_ *.fastq.gz
    echo "moved S1 to S${scount}"
    ((scount++))
done
