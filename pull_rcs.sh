#!/bin/bash
set -euo pipefail

#run with the path of the RCS file to absorb to the current working directory
RCS=$1

#get the base name of the RCS file for nohup logging purposes
RCSBASENAME=$(basename ${RCS})

#park a nohupped, &'ed rsync of the file
#this continues running in the background after you log out
#nohup by default needs to make a log somewhere, this sends the output to a useful place
#and also captures stderr by virtue of 2>&1
nohup rsync -P ${RCS} . > ${RCSBASENAME}.nohup.log 2>&1 &