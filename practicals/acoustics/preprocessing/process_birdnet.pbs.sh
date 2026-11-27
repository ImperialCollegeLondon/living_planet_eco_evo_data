#!/bin/bash

# Run birdnet identification by site. The upper limit on the
# number of subjobs set in the -J directive needs to match the number of site
# directories in the root data directory used in the called python script. Note that
# this uses Pythonic 0-based indexing to iterate over sites.

#PBS -lselect=1:ncpus=16:mem=128gb
#PBS -lwalltime=24:00:00
#PBS -J 0-12
#PBS -j oe
#PBS -o /rds/general/users/dorme/acoustics_2026/outputs/birdnet_^array_index^.out

# Activate the conda environment containing the configured R environment
eval "$(~/miniforge3/bin/conda shell.bash hook)"
conda activate acoustics

# Echo the R version and start time
R --version
echo -e "In PBS.SH and running"
date

# Run the birdnet R script
python /rds/general/users/dorme/acoustics_2026/process_birdnet.py

# Echo the end time and deactivate the conda acoustics environment
date
conda deactivate
