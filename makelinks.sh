#!/bin/bash
set -eo pipefail

#helper function for symlinking into sample structure

#two positional arguments - the sample ID and the name of the subfolder
SAMPLE=$1
SUBFOLDER=$2

#we need the hashes
PROJECT=`echo ${SAMPLE} | cut -f 1 -d "_"`
SHASH=`echo ${SAMPLE} | cut -f 2 -d "_" | cut -c 1-5`
#there might already be a symlink to this in place
#most likely due to the mapping being reran in some form or other
#-L is the required syntax to see if there's a thing and it's a symlink
FOLDERNAME=$(basename `realpath .`)
if [ ! -L /rds/project/rds-C9woKbOCf2Y/samples/${PROJECT}/${SHASH}/${SAMPLE}/${SUBFOLDER}/${FOLDERNAME} ]
then
    mkdir -p /rds/project/rds-C9woKbOCf2Y/samples/${PROJECT}/${SHASH}/${SAMPLE}/${SUBFOLDER}
    ln -s `realpath .` /rds/project/rds-C9woKbOCf2Y/samples/${PROJECT}/${SHASH}/${SAMPLE}/${SUBFOLDER}
fi
