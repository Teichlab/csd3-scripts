Various scripts for `ktp27` survival on CSD3. A clone exists at `/rfs/project/rfs-iCNyzSAaucw/ktp27/csd3-scripts`.

### Proper Python scripts (with `--help` and everything)

- `pyranger.py` generates `sbatch`able wrappers for running Cellranger on various CSCI data. `getfastq.sh` is used to pull in the requisite fastqs, `stashimage.sh` copies over provided Visium HD images into `sample_images` on RFS, `makelinks.sh` creates links to mapping folder from `libraries` on RFS.
- `pysub` is a wrapper for preparing things for `sbatch`, it's detailed in [HPC intro](https://github.com/Teichlab/hpc-intro/blob/main/jobs.md). Uses `postjob_sacct.sh` to generate reports with info.

### RDS sequencing fastq management

- `getfastq.sh` takes a library ID and retrieves all existing fastqs for it, copying them one pool-flowcell combination at a time and using `crukci_to_illumina.py` to rename them to an Illumina-compatible nomenclature (as needed by e.g. Cellranger). This is done one pool-flowcell at a time because the CRUK renaming script is built for that, the `S` counter is incremented between each one (starting at 2, to leave 1 for the staging files from the current renaming).
- `regenerate_library_fastqs.sh` takes a library ID and checks on all its CRAMs, submitting `cramfastq.sh` jobs to turn them back to fastqs if absent.
- `remove_regenerated_library_fastqs.sh` takes a library ID and checks on all its CRAMs, removing any fastqs regenerated via `regenerate_library_fastqs.sh`. These are differentiated from primary CRUK fastqs (which are left intact) by the presence of an `.fqsuccess` file left behind by `cramfastq.sh`.
- `cramfastq.sh` takes a CRAM file name (assumed to be in the same folder) and converts it back to fastqs, making an informed decision on I1/I2 generation based on the formatting of the `BC:` tag. Upon success, leaves behind a `.fqsuccess` file.
- `crukci_to_illumina.py` is a local (slightly outdated) copy of [the official CRUK-to-Illumina renaming script](https://genomicshelp.cruk.cam.ac.uk/tools/crukci_to_illumina.py), which renames all `.fq.gz` files present within `.` from CRUK to Illumina nomenclature.

### RFS folder management

- `add_publication_info.sh` takes a library ID and the name of a file with publication information, and appends its contents to `publications.tsv` in the RFS library folder. The publication information is to be a four-column TSV containing an identifying author, manuscript title, repository where the data is deposited (e.g. ArrayExpress/EGA, not the actual accession), and the manuscript/preprint DOI if possible (if not, state "in progress")
- `makelinks.sh` takes a library ID and the name of the subfolder in the library structure to link the current folder to, and then creates a symlink to `.` within the specified subfolder for the library.
- `rmlink.sh` takes a library ID and the name of the subfolder in the library structure and undoes the action of `makelinks.sh`, removing the existing symlink to `.` within the specified subfolder of the library.
- `stashimage.sh` takes a library ID and the path to an image, and rsyncs it to the library's subfolder within `sample_images` on RFS if not already present. The RFS path has spaces replaced with underscores. Yields the RFS path as output, for easy use within `pyranger`.

### RCS interaction

- `pull_rcs.sh` accepts the full path to a file on RCS, and submits an rsync of it being copied to `.` as a `nohup &` process that will persist in the background after logging out of the head node.
- `tarball.sh` accepts the path to a subdirectory within a user folder in RDS `sharedData`, and mirrors it in a `.tar.gz` state to `sharedData_CSCI_tarballs`. Best ran within a screen due to possible long run times.

### Job-related

- `postjob_sacct.sh` is used by `pysub` to append usage stats to the stdout of a job. Accepts the job ID on input.
- `slurm_partition_scan.sh` is a script written by Theo Nelson to monitor load across the various CSD3 partitions, as detailed within [HPC intro](https://github.com/Teichlab/hpc-intro/blob/main/jobs.md).
