#!/bin/bash
set -eo pipefail

#run with two positional arguments - the sample ID, and the path to the image
#spaces in the image path are technically allowed, but discouraged
#the stashed copy will be devoid of them
SAMPLE=$1
IMPATH=$2

#we need sample hashes
PROJECT=`echo ${SAMPLE} | cut -f 1 -d "_"`
SHASH=`echo ${SAMPLE} | cut -f 2 -d "_" | cut -c 1-5`

#create directory where the image will live
mkdir -p /rfs/project/rfs-iCNyzSAaucw/sample_images/${PROJECT}/${SHASH}/${SAMPLE}

#the uni cluster is benevolent and just wrapping a space containing path in quotes sorts it out
#nevertheless, let's replace any spaces with underscores for safety
IMNAME=$(basename "${IMPATH}" | sed "s/ /_/g")

#copy over the file into the folder if it doesn't exist there yet
if [ ! -f /rfs/project/rfs-iCNyzSAaucw/sample_images/${PROJECT}/${SHASH}/${SAMPLE}/${IMNAME} ]
then
    #quotes here mean things go through fine
    #no progress on rsync to be able to cleanly catch subsequent echo
    rsync "${IMPATH}" /rfs/project/rfs-iCNyzSAaucw/sample_images/${PROJECT}/${SHASH}/${SAMPLE}/${IMNAME}
fi

#echo the stashed path for invoking scripts to catch/use
echo "/rfs/project/rfs-iCNyzSAaucw/sample_images/${PROJECT}/${SHASH}/${SAMPLE}/${IMNAME}"