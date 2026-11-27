#!/bin/bash

# Run birdnet identification by site. The upper limit on the
# number of subjobs set in the -J directive needs to match the number of site
# directories in the root data directory used in the called R script.

# Because
# `soundecology::multiple_sounds` supports parallelisation, this requests the maximum 16
# CPUs for the small24 queue.

#PBS -lselect=1:ncpus=16:mem=128gb
#PBS -lwalltime=24:00:00
#PBS -J 1-13
#PBS -j oe
#PBS -o /rds/general/users/dorme/acoustics_2026/outputs/birdnet_^array_index^.out

# Activate the conda environment containing the configured R environment
eval "$(~/miniforge3/bin/conda shell.bash hook)"
conda activate r_acoustics

# Echo the R version and start time
R --version
echo -e "In PBS.SH and running"
date

# Run the birdnet R script
Rscript --vanilla /rds/general/users/dorme/acoustics_2026/process_birdnet.R

# Echo the end time and deactivate the conda environment
date
conda deactivate
