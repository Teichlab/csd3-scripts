#!/bin/bash
set -eo pipefail

#run with one positional argument - the library name to check on the crams of
LIBRARY=$1

#get directory this is in to call scripts as needed
SCRIPTDIR=`dirname "$0"`

#the various hashes to get into the library structure
PROJECT=`echo ${LIBRARY} | cut -f 1 -d "_"`
LHASH=`echo ${LIBRARY} | cut -f 2 -d "_" | cut -c 1-5`

#go into appropriate folder
cd /rfs/project/rfs-iCNyzSAaucw/libraries/${PROJECT}/${LHASH}/${LIBRARY}/sequencing

#loop over the various sequencing runs, present as folders here
for CRUKDIR in */
do
    #this is a symlink. go to the actual path just in case
    cd $(realpath ${CRUKDIR})
    #check on the crams matching our library
    for LIBCRAM in *${LIBRARY}*.cram
    do
        #this is the actual base name of the thing so we can check if there's fastqs
        CRAMFILE=$(basename ${LIBCRAM} .cram)
        #so does it exist?
        if [ ! -f ${CRAMFILE}.r_1.fq.gz ]
        then
            echo "${LIBCRAM} missing fastqs, regenerating"
            #hardcode submission to icelake-himem
            PARTITION=icelake-himem
            #make sure there's a logging directory
            mkdir -p logs
            /rfs/project/rfs-iCNyzSAaucw/ktp27/pysub -p ${PARTITION} -A TEICHLAB-SL2-CPU -c 1 -t 12 -J ${CRAMFILE}.cramfastq -l logs "bash ${SCRIPTDIR}/cramfastq.sh ${LIBCRAM}" | sbatch
        else
            echo "${LIBCRAM} has fastqs"
        fi
    done
    #revert to starting library structure folder in case there's more
    cd /rfs/project/rfs-iCNyzSAaucw/libraries/${PROJECT}/${LHASH}/${LIBRARY}/sequencing
done
