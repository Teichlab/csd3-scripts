#!/bin/bash
set -eo pipefail

#run with two positional argument - the library name to add the publication entry to...
LIBRARY=$1
#...and the publication entry as a tsv
#expected columns:
# - identifying author, i.e. likely the head of the project and one of the co-firsts
# - manuscript title
# - repository where uploaded, e.g. ArrayExpress, EGA; just the name, not an ID
# - DOI of paper/preprint, if not available then "in progress" or something similar
PUBLICATION=$2

#the various hashes to get into the library structure
PROJECT=`echo ${LIBRARY} | cut -f 1 -d "_"`
LHASH=`echo ${LIBRARY} | cut -f 2 -d "_" | cut -c 1-5`

#stick the publication entry on at the end of the publication file
cat ${PUBLICATION} >> /rfs/project/rfs-iCNyzSAaucw/libraries/${PROJECT}/${LHASH}/${LIBRARY}/publication.tsv
