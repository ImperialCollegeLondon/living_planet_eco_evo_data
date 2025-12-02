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
short_title: Saving GIS files
---


# Saving GIS files

```{code-cell} r
:tags: [remove-stderr]
library(terra)       # core raster GIS package
library(sf)          # core vector GIS package
library(rcartocolor) # plotting
library(rpart)
```

```{code-cell} r
:tags: [remove-cell]

# Dump the objects from this section
source("practical_data_state_functions.r")
load_state()
```

```{code-cell} r
:tags: [remove-cell]

# Remove any existing data output folder rather than have to stick a load of 
# overwrite=TRUE arguments in the student facing text.
if (dir.exists("spatial_method_practical_outputs")) {
  unlink("spatial_method_practical_outputs", recursive=TRUE)
}
```

We have created a lot of new dataset during this practical, which we should save for
future use. The first thing to do is create a new directory to save the data files in:

```{code-cell} r
# Create an output directory
dir.create("spatial_method_practical_outputs")
setwd("spatial_method_practical_outputs")
```

## Saving raster data

We can write raster data out using the `terra::writeRaster` function. This
function writes all the bands in the dataset out to a single file. The function uses the
file suffix of the file name you provide to set the output format: there are lots of
formats, but GeoTIFF is widely used and a good general choice.

```{code-cell} r
# Save the NDVI and EVI data
writeRaster(ndvi_silwood, "NDVI_Silwood.tiff")
writeRaster(ndvi_nhm, "NDVI_NHM.tiff")

writeRaster(evi_silwood, "EVI_Silwood.tiff")
writeRaster(evi_nhm, "EVI_NHM.tiff")

# Save the multiband Sentinel 2 data
writeRaster(s2_silwood_10m, "Sentinel2_Silwood.tiff")
writeRaster(s2_nhm_10m, "Sentinel2_NHM.tiff")
```

## Saving vector data

The `sf_st::write` function is used to write vector data to file. Again, the file format
is inferred from the output file name. This `sf_st::write` function is slightly more
complex because file formats work in slightly different ways. The function has three
main arguments:

* `obj`: The `sf` object you want to write to a file.
* `dsn`: The _data source name_ that usually gives a filename that the data will be
  written to.
* `layer`: A _layer name_ within the data source that the data will be saved under. Not
  all formats support multiple layers (e.g. shapefiles), so you do not always need to
  provide a layer name.

There are many, _many_ vector file formats - see the help file on `sf::st_drivers()` and
the output

```{code-cell} R
st_drivers()$name
```

The GeoPackage format is generally more convenient because it is a single file and can
hold multiple layers.  The code below saves the four processed VML subsets to a single
GeoPackage file.

```{code-cell} R
# Save the VML to GPKG
st_write(silwood_VML_roads, dsn="OS_VML_Silwood_NHM.gpkg", layer="silwood_VML_roads")
st_write(nhm_VML_roads, dsn="OS_VML_Silwood_NHM.gpkg", layer="nhm_VML_roads")
st_write(silwood_VML_water, dsn="OS_VML_Silwood_NHM.gpkg", layer="silwood_VML_water")
st_write(nhm_VML_water, dsn="OS_VML_Silwood_NHM.gpkg", layer="nhm_VML_water")

```

Although the Shapefile format is more widely known, the inconvience of having multiple
files is high and often leads to problems with incomplete datasets. It also has some odd
constraints - as you can see in the output below, there is a limit to the length of
attribute table field names in shapefiles.

```{code-cell} R
# Save the sensors as shapefile
st_write(sensor_locations, dsn="sensor_locations.shp")
```

```{code-cell} r
:tags: [remove-cell]

# Dump the objects from this section
source("practical_data_state_functions.r")
save_state()
```
