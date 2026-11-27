#! /bin/bash
# This script sets up a new R environment for processing the acoustics data on the HPC.

# We will use conda to create a new environment with the required packages. If a user
# has not installed conda, they can do so by running the following commands:
# module load miniforge/3
# miniforge-setup

# Once conda is installed, we can activate the conda commands and then create a new
# environment with the required R and python base packages:
# -  birdnet_analyzer requires python 3.11 - 3.13
eval "$(~/miniforge3/bin/conda shell.bash hook)"
conda create -n acoustics python=3.13 r-base=4.6.1 -c conda-forge

# Install R packages - soundecology does not seem to be in a channel so use CRAN
# This is tedious on a Linux system with the default CRAN repos that only serve source
# installs for Linux, so use the PPM repos to get binary installs.
conda activate acoustics
Rscript -e "install.packages('soundecology', repo='https://packagemanager.posit.co/cran/latest/bin/linux/centos8-x86_64/4.6')"

# Install python tools:
conda install -n acoustics birdnet-analyzer birdnet
