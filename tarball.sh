#!/bin/bash
set -eo pipefail

#run with one positional argument - a folder in rds/sharedData to archive
#turn it into its actual real path as that's what we need
TOTARBALL=$(realpath $1)

#first off, are we even in sharedData here?
if [$(echo ${TOTARBALL} | grep "/rds/project/rds-C9woKbOCf2Y/sharedData" | wc -l) == 0 ]
then
    echo "Not a /rds/project/rds-C9woKbOCf2Y/sharedData path, exiting"
    exit 1
fi

#need to prepare the path where this will end up
#replace current sharedData path with the tape one
TARBALLDIR=$(dirname ${TOTARBALL} | sed "s|/rds/project/rds-C9woKbOCf2Y/sharedData|/rcs/project/sat1003/rcs-sat1003-teichlab-cold/sharedData_CSCI_tarballs|")
#the name is simple, just the basename with a .tar.gz at the end
TARBALLNAME=$(basename ${TOTARBALL}.tar.gz)

#and we're good. commencing tarballing
mkdir -p ${TARBALLDIR}
tar -czvf ${TOTARBALL} ${TARBALLDIR}/${TARBALLNAME}