#! /bin/bash
# This script sets up a new R environment for processing the acoustics data on the HPC.

# We will use conda to create a new environment with the required packages. If a user
# has not installed conda, they can do so by running the following commands:
# module load miniforge/3
# miniforge-setup

# Once conda is installed, we can activate the conda commands and then create a new
# environment with the required packages.
eval "$(~/miniforge3/bin/conda shell.bash hook)"
conda create -n r_acoustics r-base=4.6.1 -c conda-forge

# We need the following packages:
# Install packages from the R channel
conda install -c r soundecology
