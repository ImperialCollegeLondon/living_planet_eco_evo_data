---
authors:
- name: Jenna Lawson
jupytext:
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.18.1
kernelspec:
  name: uvr-ecoevodata
  display_name: R (ecoevodata)
  language: R
short_title: Acoustic analysis
---

# Analysis of acoustic data in R

This section of the module introduces techniques for analysing ecological acoustic data
using R.

The practicals include:

* Loading and [visualising ecological acoustic data](./visualisation.md) as
  spectrograms.
* Calculating [ecological acoustic indices](./acoustic_indices.md) from acoustic data
  and comparing values through time and between sites.
* Using [acoustic classifiers](./birdnet.md) such as BirdNET to identify species from
  acoustic data for use in looking at species diversity and activity patterns.

## Practical data

The data processing parts of the practicals use two smaller datasets of example data.
These are sets of acoustic data recorded as a series of WAV format files made at dawn in
two locations:

* [Monks Wood](https://www.google.com/maps/@52.4009072,-0.2470383,3701m/data=!3m1!1e3) -
  a woodland National Nature Reserve in Cambridgeshire.
* [Parsonage Down](https://www.google.com/maps/@51.1701538,-1.9267329,1388m) - a chalk
  downland National Nature Reserve in Wiltshire.

We use these because the acoustic data collected for this practical is huge and it is
impractical to try and process it all during the module. We have preprocessed the field
data - using the same techniques as we use on the two smaller datasets - so that the
complete set of field data outputs are available for the practical and coursework.

The [pre-processing details](preprocessing/preprocessing.md) are available if you want
to look at them. It is more complex - although mostly because we run the processing on
our HPC system - but it might be of use if you end up using acoustic data in your
project!
