---
authors:
- name: David Orme
jupytext:
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.18.1
---

# Bulk processing acoustic data

Acoustic recorders generate a _huge_ amount of data and processing it all can be a
significant computing task. As an example, the recorders deployed in the field for this
module in 2026 generated:

* XXXX `.WAV` files across 13 sampled sites
* XXXX GB of data
* XXXX hours of recordings

Processing all of that data takes a lot of time. We could divide and conquer by giving
you all a subset of files to process, but its really to big a task to coordinate. We
could also just leave it running on a single computer for ages, but the best answer here
is to use Imperial's [High Performance Computing (HPC)
services](https://www.imperial.ac.uk/computational-methods/hpc/).

This is an advanced topic, but the information below describes how we used the HPC to
generate the species identification files from the audio files for this year.

## Data collection and transfer

The recorders were retrieved and downloaded during November before they ran out of
storage and power and the files were all transferred onto the file storage used for the
HPC. The data are arranged as site-by-site folders of WAV files.

## Computing setup

The HPC uses the [`conda`](https://docs.conda.io/en/latest/index.html) package
management tool, so first we need to use `conda` to define a virtual environment
containing all of the code needed. The file below shows the commands used to do this.

::::{admonition} Virtual environment setup
:class: dropdown

:::{literalinclude} HPC_setup.sh
:::

::::

## Running tasks on the HPC

We need to run two bulk processing tasks:

* calculating acoustic indices for all of the files, and
* identifying bird calls in all of the files using Birdnet.

Running each of these tasks on the HPC requires two files:

* A job submission script, written as a `bash` shell script, that tells the HPC what
  resources are needed to run the job and then sets the job running.
* The actual job script, which contains all of the code needed to complete the tasks.

Because there are a very large number of files and the processing is identical for each
site file, we can run these tasks as _array jobs_. By doing this, we can run the folders
in parallel: the HPC will submit the same task multiple times and we can use a subjob
index number to select a different site folders for each run.

## Processing acoustic indices

The processing for the acoustic indices is basically identical to the example code used
in the practical with the Monkswood and Parsonage Down files. We use the
`soundecology::multiple_sounds` function and each subjob runs it on a single site
directory.

::::{admonition} Acoustic index job submission script
:class: dropdown

:::{literalinclude} process_acoustic_indices.pbs.sh
:::

::::

::::{admonition} Acoustic index job script

:::{literalinclude} process_acoustic_indices.R
:::

::::

