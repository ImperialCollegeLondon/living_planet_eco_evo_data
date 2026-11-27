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


::::{admonition} Virtual environment setup
:class: dropdown

:::{literalinclude} process_acoustic_indices.R
:::

::::



