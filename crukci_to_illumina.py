#!/usr/bin/env python3

# This script converts CRUK-CI named FASTQ files into the names one would
# expect to be produced by Illumina's bcl2fastq tool.
# Some third party tools, for example 10x's CellRanger, need the files named
# like this.

import os
import re
import sys

fastq_dir = os.getcwd()

if len(sys.argv) > 1:
    fastq_dir = sys.argv[1]

# Must be sorted to go through the files in a consistent manner. Not sorting
# can result in the sample numbers given to a sample in a lane going wrong.
files = os.listdir(fastq_dir)
files.sort()

barcodes_in_lane = dict()

for f in files:
    m = re.search("^SLX-\d+\.(\w+)\.[-\w]+\.s_(\d)\.([ir])_(\d)\.fq\.gz$", f)
    if m is not None:
        barcode = m.group(1)
        lane = int(m.group(2))
        itype = m.group(3).upper()
        read = int(m.group(4))

        lane_barcodes = barcodes_in_lane.get(lane)
        if lane_barcodes is None:
            lane_barcodes = dict()
            barcodes_in_lane[lane] = lane_barcodes

        sample_number = lane_barcodes.get(barcode)
        if sample_number is None:
            sample_number = len(lane_barcodes) + 1
            lane_barcodes[barcode] = sample_number

        illumina = "{}_S{}_L{:03d}_{}{}_001.fastq.gz".format(barcode, sample_number, lane, itype, read)

        print("{} -> {}".format(f, illumina))

        os.rename(os.path.join(fastq_dir, f), os.path.join(fastq_dir, illumina))

    m = re.search("^SLX-\d+\.[-\w]+\.s_(\d)\.([ir])_(\d)\.lostreads\.fq\.gz$", f)
    if m is not None:
        lane = int(m.group(1))
        itype = m.group(2).upper()
        read = int(m.group(3))

        illumina = "Undetermined_S0_L{:03d}_{}{}_001.fastq.gz".format(lane, itype, read)

        print("{} -> {}".format(f, illumina))

        os.rename(os.path.join(fastq_dir, f), os.path.join(fastq_dir, illumina))

