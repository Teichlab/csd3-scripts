#!/bin/bash
set -eo pipefail

#run with one positional argument - the library name to check on the crams of
LIBRARY=$1

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
            #case one - no fastqs present at all. report
            echo "${LIBCRAM} has no fastqs"
        elif [ -f ${CRAMFILE}.fqsuccess ]
        then
            #case two - fastqs present, and fqsuccess file implies they're repopulated
            echo "${LIBCRAM} has repopulated fastqs, cleaning"
            #carefully remove exactly just the exact read files
            rm ${CRAMFILE}.r_1.fq.gz
            rm ${CRAMFILE}.r_2.fq.gz
            #there may or may not be index files present
            if [ -f ${CRAMFILE}.i_1.fq.gz ]
            then
                rm ${CRAMFILE}.i_1.fq.gz
            fi
            if [ -f ${CRAMFILE}.i_2.fq.gz ]
            then
                rm ${CRAMFILE}.i_2.fq.gz
            fi
            #and delete the repopulation success file
            rm ${CRAMFILE}.fqsuccess
        else
            #case three - fastqs present, but no fqsuccess file, so primary
            echo "${LIBCRAM} has primary fastqs, keeping"
        fi
    done
    #revert to starting library structure folder in case there's more
    cd /rfs/project/rfs-iCNyzSAaucw/libraries/${PROJECT}/${LHASH}/${LIBRARY}/sequencing
done
