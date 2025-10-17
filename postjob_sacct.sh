#!/bin/bash
set -eo pipefail

#run with the job ID as the positional argument
JOBID=$1

#retrieve path to the job's log file via scontrol
LOGFILE=$(scontrol show job ${JOBID} | grep StdOut | cut -f 2 -d "=")

#park sacct at the end of the log file
sacct -j "${JOBID}" --format=JobID,State,ExitCode,AllocCPUS,ReqCPUS,ReqMem,Timelimit,Elapsed,MaxRSS >> ${LOGFILE}
