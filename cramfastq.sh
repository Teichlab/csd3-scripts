#!/bin/bash
set -eo pipefail

#run with the CRAM file name to convert as the positional argument
#but we actually care about its basename, with the .cram gone
CRAMFILE=$(basename $1 .cram)

#we need samtools here
module load ceuadmin/samtools/1.20

#at the time of writing, there are three types of crams based on their BC: tags
#1. single index BCs with no delimiter present, old style CRUK ATAC
#for those we don't care about the index reads
#2. dual index BCs with + as the delimiter, any non-ATAC paired index library
#for those we don't care about the index reads
#+ is the delimiter as that's what's in the casava identifier from CRUK
#3. dual index bcs with - as the delimiter, new style CRUK ATAC
#the BC tag is created by the cram conversion script from actual I1/I2 reads
#and that cram creation procedure inserts - as the delimiter between the two indices
#in this exact case we care about the index reads

#extract the first encountered BC tag in the CRAM and check if it has a - in there
#the tags are tab-separated, remove everything that may show up after the BC tag is done
#CSD3 PSA - can't catch the BC into a variable as SIGPIPE kicks in and the script errors out, but this works fine!
if [ $(samtools view ${CRAMFILE}.cram | grep "BC:Z:" | head -n 1 | sed "s/.*BC:Z://" | sed "s/\\t.*//" | grep "-" | wc -l) == 1 ]
then
    #generate index reads, we don't care about casava identifiers
    samtools fastq -1 ${CRAMFILE}.r_1.fq.gz -2 ${CRAMFILE}.r_2.fq.gz --i1 ${CRAMFILE}.i_1.fq.gz --i2 ${CRAMFILE}.i_2.fq.gz --index-format i*i* -n ${CRAMFILE}.cram
else
    #do not generate index reads, and we still don't care about casava identifiers
    samtools fastq -1 ${CRAMFILE}.r_1.fq.gz -2 ${CRAMFILE}.r_2.fq.gz -n ${CRAMFILE}.cram
fi

#touch a success file just in case of cluster weird
touch ${CRAMFILE}.fqsuccess
