---
authors:
- name: Tijmen de Lorm
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
short_title: Camera trap pre-processing
---

# GTA instructions camera trap practical

Before the students start the practical, a GTA should collect and properly process all
the camera trap data.

## Instructions for collecting and processing the camera trap data

* The students did take note of the deployment info through Epicollect but as a backup,
  you should take note of which camera comes from which plot as you collect them, instead
  of relying on the deployment forms.

* Once you have collected all of the cameras, sort them locally into folders – either on
  your computer or an external hard drive. This will make it easier to rename files
  quickly.

* The folders should be structured as follows, with each plot having its own folder, and
  the folder being named after the plot, for example:

``` text
INPUT_FOLDER/
  └── PLOT_221/
    └──  IMG_0001.AVI
    └── IMG_0002.AVI
  └── PLOT_231/
    └── IMG_0001.AVI
    └── IMG_0002.AVI
```

The script
[`Camera_trap_files_to_sheet_markup.r`](./Camera_trap_files_to_sheet_markup.r) will take
your folder structure and rename the files so they contain time, plot and date. This
script will also will produce two things:

* A copy of the entire camera trap dataset with proper names
* A REST datasheet, the template that they will fill with camera trap identifications
  during the practical.

When you run the script, make sure to give it the correct path and the name of the
sampling campaign (structured as SEASONYEAR, e.g. WINTER2026).

Upload the full dataset and REST datasheet to the CameraTraps folder, in the subfolder
of the correct year.
