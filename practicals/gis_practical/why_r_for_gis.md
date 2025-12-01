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
---

# Why use R for GIS

There are a number of really good reasons for using R for the GIS in this module:

* It is an open-source, cross-platform and free program.
* It provides a powerful set of GIS data tools and packages extend this GIS
  functionality into a well estabished ecosystem of R packages for ecological and
  evolutionary analysis, including species distribution modelling, population genetics
  and many other areas.
* Writing spatial analyses as R scripts provides a clear reproducible research record.
* It integrates easily with the use of R in the other practicals.

There are disadvantages to using R as a GIS platform:

* Principally, although it can create very high quality spatial graphics, it is not a
  GIS data visualiser and explorer program. It is not as easy to zoom and pan around
  spatial datasets in R or to alter the way in which a set of layers overlay each other.
* It can also be difficult to find the exact set of commands you need to get the result
  you are after (although this can also be true of other systems)!

If you end up using GIS more widely in your research project, you may find it useful to
look at other GIS programs for exploring and visualising data:

* The most well known is probably the ESRI ArcGIS package: Imperial College London does
  have a [licensing agreement for
  ArcGIS](https://www.imperial.ac.uk/admin-services/ict/self-service/computers-printing/devices-and-software/get-software/get-software-for-students/arcgis/)
  but it is Windows only software and is expensive to use.
* The [QGIS program](https://qgis.org/) is an open source and cross platform
  alternative to ArcGIS and is very worth exploring.
