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
authors:
  - name: David Orme
short_title: In
---

# Spatial Methods in Ecological and Evolutionary Data Science

The Spatial Methods in Ecological and Evolutionary Data Science practical is one long
self-paced practical that provides an introduction to key spatial data handling and
analysis techniques. This practical uses [the R programming
language](https://cran.r-project,org) to load, manipulate and analyse spatial data. See
more here on [why we use R for GIS](./why_r_for_gis.md).

## Aims of the the practical

The practical aims to:

* Provide you with some high quality spatial datasets for the Silwood and NHM sites
  that provide additional information that you can use to develop your hypotheses in
  your coursework for the module.

* Run through most of the major GIS techniques that you will need to use to integrate
  raster and vector datasets in order to get to a final dataset addressing your
  hypotheses.

* Provide _simple_ plotting options using the basic R graphics commands. For more
  advanced mapping, see the ["Making maps with R"](https://r.geocompx.org/adv-map)
  chapter in "Geocomputation with R".

## How to use the practical

This practical is self-paced: work through it at your own speed and ask questions as
needed! It builds up and then saves a set of datasets that you can use in your
assessment, so you will need to:

1. Download the practical data bundle [ADD LINK] and save that in a directory.
1. Create a new R script file to run the practical analyses.
1. Copy example code from the practical into your script and run it from your script.
1. Check you understand what the code is doing - add extra comments, ask questions.
1. The practical contains exercises where you are asked to use the previous example to
  write and run your own code. Write your solution into your script file and again add
  comments for when you come back to it!
1. The practical contains solutions for all the exercises, but do try and solve them
  yourself.
1. At the end of the practical, you should have:

    * A set of GIS data files that allow you to add further environmental context to the
      outputs of the sensor data exercises.
    * A complete script that builds up those files from the original source data.

## Required packages

We will need to load the following packages. Remember to read [this guide on setting up
packages on your computer](../practical_requirements.md) before running these practicals
on your own machine.

```{code-cell} r
:tags: [remove-stderr]
library(terra)       # core raster GIS package
library(sf)          # core vector GIS package
library(rcartocolor) # plotting
library(rpart)
```

You will see a whole load of package loading messages about GDAL, GEOS, PROJ which are
not shown here. Don't worry about this - they are not errors, just R linking to some key
open source GIS toolkits.
