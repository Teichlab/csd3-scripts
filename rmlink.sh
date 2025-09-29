#!/bin/bash
set -eo pipefail

#helper function for removing a symlink to . from the sample structure

#two positional arguments - the sample ID and the name of the subfolder
SAMPLE=$1
SUBFOLDER=$2

#we need the hashes
PROJECT=`echo ${SAMPLE} | cut -f 1 -d "_"`
SHASH=`echo ${SAMPLE} | cut -f 2 -d "_" | cut -c 1-5`
#-L is the required syntax to see if there's a thing and it's a symlink
FOLDERNAME=$(basename `realpath .`)
if [ -L /rfs/project/rfs-iCNyzSAaucw/libraries/${PROJECT}/${SHASH}/${SAMPLE}/${SUBFOLDER}/${FOLDERNAME} ]
then
    #get rid of the symlink
    rm /rfs/project/rfs-iCNyzSAaucw/libraries/${PROJECT}/${SHASH}/${SAMPLE}/${SUBFOLDER}/${FOLDERNAME}
fi
