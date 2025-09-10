from packaging.version import Version
import subprocess
import argparse
import math
import os

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--cellranger', dest='cellranger', type=str, required=True, help='Path to cellranger binary to use.')
    parser.add_argument('--command', dest='command', type=str, required=True, help='The cellranger command (e.g. count) to use.')
    parser.add_argument('--gex', dest='gex', type=str, default=None, help='Optional. GEX sample ID.')
    parser.add_argument('--cite', dest='cite', type=str, default=None, help='Optional. CITE sample ID.')
    parser.add_argument('--atac', dest='atac', type=str, default=None, help='Optional. ATAC sample ID.')
    parser.add_argument('--tcrab', dest='tcrab', type=str, default=None, help='Optional. TCR-AB sample ID.')
    parser.add_argument('--bcr', dest='bcr', type=str, default=None, help='Optional. BCR sample ID.')
    parser.add_argument('--tcrgd', dest='tcrgd', type=str, default=None, help='Optional. ATAC sample ID.')
    parser.add_argument('--runid', dest='runid', type=str, default=None, help='Optional. Manual override of the ID to use when running cellranger')
    parser.add_argument('--reference', dest='reference', type=str, default=None, help='Path to cellranger reference to use')
    parser.add_argument('--vdj-reference', dest='vdj_reference', type=str, default=None, help='Path to cellranger VDJ reference to use specifically for multi calls')
    parser.add_argument('--probe-set', dest='probe_set', type=str, default=None, help='Path to probe file to use, if probes were used')
    parser.add_argument('--feature-ref', dest='feature_ref', type=str, default=None, help='CITE only. Path to feature reference file to use.')
    parser.add_argument('--primers', dest='primers', type=str, default=None, help='VDJ only. Optional. Path to file with inner enrichment primers.')
    parser.add_argument('--cytaimage', dest='cytaimage', type=str, default=None, help='Visium only. Path to CytAssist image.')
    parser.add_argument('--image', dest='image', type=str, default=None, help='Visium only. Path to morphology (H&E) image.')
    parser.add_argument('--slide', dest='slide', type=str, default=None, help='Visium only. Optional. Slide ID.')
    parser.add_argument('--area', dest='area', type=str, default=None, help='Visium only. Optional. Area on slide.')
    parser.add_argument('--loupe-alignment', dest='loupe_alignment', type=str, default=None, help='Visium only. Optional. Path to Loupe alignment JSON of the two images.')
    parser.add_argument('--chemistry', dest='chemistry', type=str, help='Optional. 10X chemistry argument to pass to Cellranger.')
    parser.add_argument('--cores', dest='cores', type=int, default=10, help='Number of cores to use. Default: 10')
    parser.add_argument('--no-bam', dest='no_bam', action='store_true', help='Flag. If provided, will skip creating BAMs in output if applicable.')
    parser.add_argument('--extras', dest='extras', type=str, default="", help='Extra arguments for cellranger, wrap in quotes if providing multiple')
    parser.add_argument('--script', dest='script', type=str, default="N01-ranger.sh", help='The path to write the constructed script to. Default: N01-ranger.sh')
    parser.add_argument('--no-link', dest='no_link', action='store_true', help='Flag. If provided, will skip creating symlinks in central sample storage for mappings.')
    args = parser.parse_args()
    #create a combined ID joining the various IDs present
    samples = [args.gex, args.cite, args.atac, args.tcrab, args.bcr, args.tcrgd]
    args.samples = [i for i in samples if i is not None]
    if len(args.samples) == 0:
        raise ValueError("At least one of the various sample IDs needs to be provided")
    #set the run ID unless manually overridden
    if args.runid is None:
        args.runid = "-".join(args.samples)
    #need a feature ref if we're doing a CITE
    if (args.cite is not None) and (args.feature_ref is None):
        raise ValueError("Need to specify feature reference for CITE")
    #need cytaimage and image if we're doing a spaceranger
    if os.path.basename(args.cellranger) == "spaceranger":
        if args.cytaimage is None:
            raise ValueError("--cytaimage needs to be set for spaceranger")
        if args.image is None:
            raise ValueError("--image needs to be set for spaceranger")
    #need a reference if we're doing a non-multi
    if (args.command != "multi") and (args.reference is None):
        raise ValueError("Need to specify --reference with a non-multi command")
    if args.command == "multi":
        if (args.reference is None) and ((args.gex is not None) or (args.cite is not None)):
            raise ValueError("Need to specify --reference with GEX/CITE in multi")
        if (args.vdj_reference is None) and ((args.tcrab is not None) or (args.bcr is not None) or (args.tcrgd is not None)):
            raise ValueError("Need to specify --vdj-reference with VDJ libraries in multi")
    #set up path to csd3-scripts, i.e. where this is
    #get the realpath to this file and then strip out the pyranger.py at the end
    args.location = '/'.join(os.path.realpath(__file__).split('/')[:-1])
    return args

def subwrap(call):
	'''
	A helper function that calls shell commands and returns the stdout for python processing.
	
	Input:
	 * call - the shell command to run and acquire the stdout of
	
	Returns the stdout of the command
	'''
	return subprocess.run(call, shell=True, stdout=subprocess.PIPE).stdout.decode('utf-8').rstrip()

def compare_version(cellranger, min_version):
    #cellranger versions come in the form cellranger cellranger-#.#.#
    cellranger_version = subwrap(cellranger+" --version").split("-")[-1]
    return Version(cellranger_version) >= Version(min_version)

def main():
    #soak up the multitude of arguments
    args = parse_args()
    #prepare script header
    script_lines = ["#!/bin/bash", "set -eo pipefail", ""]
    #absorb fastqs
    script_lines.append("#copy over fastqs from central location")
    script_lines.append("if [ ! -d fastq ]")
    script_lines.append("then")
    script_lines.append("    mkdir fastq && cd fastq")
    #retrieve fastqs for various set sample IDs
    for present_sample in args.samples:
        script_lines.append("    bash "+args.location+"/getfastq.sh "+present_sample)
    script_lines.append("    cd ..")
    script_lines.append("fi")
    script_lines.append("")
    #construct cellranger call as a list. always provide our ID
    cellranger_call = [args.cellranger, args.command, "--id="+args.runid]
    #count prep
    if args.command == "count":
        #we may need to construct a libraries file
        if (args.cite is not None) or (args.atac is not None):
            script_lines.append("#prepare libraries file with info")
            script_lines.append('echo "fastqs,sample,library_type" > libraries.csv')
            #need absolute path to the fastq folder in libraries
            if args.gex is not None:
                script_lines.append('echo "$(realpath fastq),'+args.gex+',Gene Expression" >> libraries.csv')
            if args.cite is not None:
                script_lines.append('echo "$(realpath fastq),'+args.cite+',Antibody Capture" >> libraries.csv')
            if args.atac is not None:
                script_lines.append('echo "$(realpath fastq),'+args.atac+',Chromatin Accessibility" >> libraries.csv')
            script_lines.append("")
            cellranger_call.append("--libraries=libraries.csv")
        else:
            #need to pass fastq folder to count, relative path okay here
            cellranger_call.append("--fastqs=fastq")
        #couple of differences based on whether it's arc, space or vanilla count
        if os.path.basename(args.cellranger) == "cellranger-arc":
            #arc uses the more stock reference name for the arguments
            cellranger_call.append("--reference="+args.reference)
            #at this point, it uses the old --no-bam nomenclature
            if args.no_bam:
                cellranger_call.append("--no-bam")
        elif os.path.basename(args.cellranger) == "cellranger":
            #good old vanilla count, sticking with transcriptome
            cellranger_call.append("--transcriptome="+args.reference)
            #we may have a feature reference to stick in there
            if args.feature_ref is not None:
                cellranger_call.append("--feature-ref="+args.feature_ref)
            #NOTE: pre-5.0.0 cellrangers don't have --no-bam support
            #cellranger 8.0.0 reworked --no-bam into a mandatory --create-bam= instead
            if compare_version(args.cellranger, "8.0.0"):
                if args.no_bam:
                    cellranger_call.append("--create-bam=false")
                else:
                    cellranger_call.append("--create-bam=true")
            else:
                if args.no_bam:
                    cellranger_call.append("--no-bam")
        elif os.path.basename(args.cellranger) == "spaceranger":
            #spaceranger also uses transcriptome
            cellranger_call.append("--transcriptome="+args.reference)
            #a bunch of spaceranger stuff - probe sets, images, slides/areas
            if args.probe_set is not None:
                cellranger_call.append("--probe-set="+args.probe_set)
            #for the images, we've got to also stash them into the RFS image bank
            script_lines.append("#stash images in RFS")
            #use helper script to potentially copy image to the storage
            #in the process, strip out any spaces from the image name
            #and yield the stored path for us to use here
            #provide the image path wrapped in quotes as a safeguard against spaces
            script_lines_append('CYTAIMAGE=$(bash '+args.location+'/stashimage.sh '+args.gex+' "'+args.cytaimage+'")')
            #use this yielded path for spaceranger
            cellranger_call.append("--cytaimage=${CYTAIMAGE}")
            #same deal, second image
            script_lines_append('IMAGE=$(bash '+args.location+'/stashimage.sh '+args.gex+' "'+args.image+'")')
            cellranger_call.append("--image=${IMAGE}")
            #the slide/area stuff might be readable from the cytaimage, so don't just error if absent
            if args.slide is not None:
                cellranger_call.append("--slide="+args.slide)
            if args.area is not None:
                cellranger_call.append("--area="+args.area)
            if args.loupe_alignment is not None:
                #may as well stash it with the images for safety
                script_lines.append("#stash loupe alignment for safekeeping too")
                script_lines_append('LOUPE=$(bash '+args.location+'/stashimage.sh '+args.gex+' "'+args.loupe_alignment+'")')
                cellranger_call.append("--loupe-alignment=${LOUPE}")
            script_lines.append("")
            #no-bam/create-bam version breakpoint is 3.0.0
            if compare_version(args.cellranger, "3.0.0"):
                if args.no_bam:
                    cellranger_call.append("--create-bam=false")
                else:
                    cellranger_call.append("--create-bam=true")
            else:
                if args.no_bam:
                    cellranger_call.append("--no-bam")
        #sort out chemistry
        if args.chemistry is not None:
            cellranger_call.append("--chemistry="+args.chemistry)
    #vdj prep
    if args.command == "vdj":
        #easily pass fastqs as relative path
        cellranger_call.append("--fastqs=fastq")
        #pass reference
        cellranger_call.append("--reference="+args.reference)
        #set chain
        if args.bcr is not None:
            #we passed a BCR
            cellranger_call.append("--chain=IG")
        else:
            #both TCR-AB and TCR-GD would qualify as TR per this
            cellranger_call.append("--chain=TR")
        #there may be inner enrichment primers
        if args.primers is not None:
            cellranger_call.append("--inner-enrichment-primers="+args.primers)
        #sort out chemistry
        if args.chemistry is not None:
            cellranger_call.append("--chemistry="+args.chemistry)
    #multi prep
    if args.command == "multi":
        #TODO: expand with non-VDJ functionality as necessary
        #the actual command itself is trivial
        cellranger_call.append("--csv=config.csv")
        #the building of the config itself though, not so much
        script_lines.append("#constructing multi config, create empty file to write to")
        script_lines.append('echo -n "" > config.csv')
        #VDJ specifics!
        if (args.tcrab is not None) or (args.bcr is not None) or (args.tcrgd is not None):
            script_lines.append('echo "[vdj]" >> config.csv')
            script_lines.append('echo "reference-path,'+args.vdj_reference+'" >> config.csv')
            #stash primers if provided
            if args.primers is not None:
                script_lines.append('echo "inner-enrichment-primers,'+args.primers+'" >> config.csv')
            script_lines.append('echo "" >> config.csv')
        #library definition section
        script_lines.append('echo "[libraries]" >> config.csv')
        script_lines.append('echo "fastq_id,fastqs,feature_types" >> config.csv')
        #need absolute path to the fastq folder
        if args.tcrab is not None:
            script_lines.append('echo "'+args.tcrab+',$(realpath fastq),VDJ-T" >> config.csv')
        if args.bcr is not None:
            script_lines.append('echo "'+args.bcr+',$(realpath fastq),VDJ-B" >> config.csv')
        if args.tcrgd is not None:
            script_lines.append('echo "'+args.tcrgd+',$(realpath fastq),VDJ-T-GD" >> config.csv')
        script_lines.append("")
    #do resource stuff
    cellranger_call.append("--localcores="+str(args.cores))
    #6.6GB of RAM per core, and let's take a smidge off for safety
    cellranger_call.append("--localmem="+str(math.floor(6.6*args.cores)-1))
    #add extras at the very end
    cellranger_call.append(args.extras)
    #can now collapse into actual command
    script_lines.append("#cellranger time!")
    script_lines.append(" ".join(cellranger_call))
    script_lines.append("")
    #clean up after run
    script_lines.append("#clean up the various workflow temporary files")
    script_lines.append("mv "+args.runid+"/outs .")
    script_lines.append("rm -r "+args.runid)
    script_lines.append("#clean up the reads too")
    script_lines.append("rm -r fastq")
    #add links to sample structure, unless prompted not to
    if not args.no_link:
        script_lines.append("")
        script_lines.append("#at this point we're happy, I believe. let's symlink this over to the sample structure")
        script_lines.append("cd ..")
        for present_sample in args.samples:
            script_lines.append("bash "+args.location+"/makelinks.sh "+present_sample+" mapping")
    #script prep done! write it out!
    with open(args.script, "w") as fid:
        #add line breaks
        fid.writelines([i+"\n" for i in script_lines])

if __name__ == "__main__":
    main()
