---
jupytext:
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.18.1
kernelspec:
  display_name: R
  language: R
  name: ir
---

# Required packages and data

If you are running these practicals on your own laptop then you will need to install
quite a few packages to get the code to run. The following sections give the core
packages required and then practical specific packages.

## Practical directory setup

Because these practicals link up and share data, it is best to set up a shared `data`
folder and then create folders for each practical:

* Create a directory for the practicals (e.g. `eco_evo_data_science`).
* Within that directory, create the following directories:

  * `data`: this will contains subfolders containing the different types of sensor
    data and other datasets for use in the module.
  * `spatial_methods`: This directory will be used for the [Spatial
    Methods](./gis_practical/gis_practical.md) practical
  * `microclimate`: This directory will be used for the
    [Microclimate](./microclimate/microclimate_sensor_analysis_EasyLog.md) practical
  * `bioinformatics`: This directory will be used for the
    [Bioinformatics](./bioinformatics/bioinformatics.md) practical.

## Practical requirements

The sections below give the R packages and datasets required for each practical. If you
are familiar with using virtual environments, you may want to look at the final section
on managing the packages for the module using `uvr`.

### Acoustics methods practicals

You will need to install the following packages:

```r
# Core acoustics packages
install.packages('tuneR')
install.packages('seewave')
install.packages('soundecology')
```

### Spatial methods practical

You will need to install the following packages:

```r
# Core GIS package
install.packages('terra')
install.packages('sf')
```

You will also need to download the practical data bundle:

* Download the SpatialMethods directory in the [Box site for the
  module](https://imperialcollegelondon.app.box.com/folder/353759097415) into the `data`
  directory.
* Download the SensorSites directory in the [Box site for the
  module](https://imperialcollegelondon.app.box.com/folder/353759097415) into the `data`
  directory.

### Microclimate practical

You will need to install the following packages:

```r
install.packages(openxlsx2)   # for opening excel files
install.packages(tidyverse)   # for data manipulation and plotting
install.packages(janitor)     # for cleaning column names and general tidying
install.packages(patchwork)
```

You will also need to download the practical data bundle:

* Download the Microclimate directory in the [Box site for the
  module](https://imperialcollegelondon.app.box.com/folder/353759097415) into the `data`
  directory.
* Download the SensorSites directory in the [Box site for the
  module](https://imperialcollegelondon.app.box.com/folder/353759097415) into the `data`
  directory.

## Managing R project libraries

One of the biggest problems with managing a large R project is keeping track of the
versions of R and packages used for the analysis. This is particularly true if you are
working in a big collaborative project - your code can fall apart _very_ fast if people
are using different versions - but it is also vital for scientific reproduceability.
There are a number of tools for different aspects of managing R versions and packages,
but a recent one that covers basically all the ground with one tool is
[`uvr`](https://nbafrank.github.io/uvr/).

Before going any further:

* This is a more advanced code management topic. You do not need to do this and can run
  these practicals using your existing installation of R (either through R Studio or
  not) and your existing R library.
* The `uvr` package is new (first commit in March 2026) and is still in development
  (version 0.4.6) but it is used to develop and build these practicals.

If you want to try it out:

1. Install `uvr`

2. Download `uvr.toml`

3. Run `uvr sync`
