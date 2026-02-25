#!/bin/bash
set -eo pipefail

#run with the job ID and the job's StdOut as the positional arguments
JOBID=$1
LOGFILE=$2

#can't pull location of log file from scontrol as that only persists for ~1h
#so better to play it safe and just take it from input in case of cluster gunkage

#park seff at the end of the log file
seff ${JOBID} >> ${LOGFILE}
