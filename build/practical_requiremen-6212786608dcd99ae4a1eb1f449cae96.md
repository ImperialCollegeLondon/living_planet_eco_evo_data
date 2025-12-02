---
jupytext:
  formats: md:myst
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.13
    jupytext_version: 1.11.5
kernelspec:
  display_name: R
  language: R
  name: ir
short_title: Requirements
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

## Spatial methods practical

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

## Microclimate practical

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
