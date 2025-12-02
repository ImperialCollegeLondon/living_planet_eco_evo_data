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
short_title: Reprojecting data
---


# Reprojecting spatial data

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

We now have a large number of different datasets, but they are not all in the same GIS
projection. We cannot use the datasets together until they use the same coordinate
system. We will use the "OSGB 1936 / British National Grid" (or BNG) projection for all
of the rest of the practical. It is a projected coordinate system, which means we can
use metres to measure distances, and it is also the standard mapping system for the UK.

## Reprojecting vector datasets

It is relatively easy to reproject vector datasets: all of the features in a vector
dataset are built up from pairs of point. Reprojection is therefore just a matter of
recalculating the coordinates in the new projection - the underlying equation might be
complex but we are just moving points between two systems.

We can show the current range of coordinates for a dataset by looking at the **extent**
of the data before.

```{code-cell} r
# Show the extent of the sensor locations in the current WGS84 projection
ext(sensor_locations)
```

The `sf::st_transform` function can then be used to transform data from one projection
to another.

```{code-cell} r
# Convert the WGS84 vector datasets to BNG
sensor_locations <- st_transform(sensor_locations, crs="EPSG:27700")
nest_boxes <- st_transform(nest_boxes, crs="EPSG:27700")
silmas_route <- st_transform(silmas_route, crs="EPSG:27700")

# Show the new extent
ext(sensor_locations)
```

## Reprojecting raster datasets

This is more involved than reprojecting vector data. You have a series of raster cell
values in one projection and then want to insert representative values into a set of
cells on a different projection. The borders of those new cells could have all sorts of
odd relationships to the current ones.

We can show the issue by superimposing two grids:

* A 200 m resolution grid using the extent of the BNG projection datasets for Silwood
  (red cells).
* A very similar 200m grid taken from the extent of the Sentinel 2 data in the UTM30N
  projection for the same site and then reprojected into the BNG (grey cells)

```{code-cell} r
# Create a BNG raster at 200m resolution for the study site
ext(silwood_aerial)
```

:::{note} Plot source
:class: dropdown

In case you are interested in how this plot was created.

```{code-cell} r
# Create a BNG raster at 200m resolution for the study site
grid_BNG <- rast(ext(silwood_aerial), res = 200, crs = "EPSG:27700")
# Convert to an sf polygon dataset of grid cells
grid_BNG <- st_as_sf(as.polygons(grid_BNG))

# Create a UTM30N raster at 200 m resolution for the study site
grid_UTM30N <- rast(ext(s2_silwood_10m), res = 200, crs = "EPSG:32630")
# Convert to an sf polygon dataset _and_ then transform to BNG
grid_UTM30N <- st_as_sf(as.polygons(grid_UTM30N))
grid_UTM30N_in_BNG <- st_transform(grid_UTM30N, "EPSG:27700")

# Plot the two sets of grid cells over each other
plot(st_geometry(grid_UTM30N_in_BNG), reset=FALSE, border="grey")
plot(st_geometry(grid_BNG), border='red', add=TRUE)

# Add coordinates on the axes
axis(1)
axis(2)
```

As you can see, even when the resolutions are the same, there is no neat one-to-one
relationship between the two sets of cells: the axes of the two grids are not exactly
parallel and the coordinates of the cell boundaries are not the same.

The `terra::project` function both **converts the coordinates** from one projection to
another and **resamples the data** from one grid to another. There are various methods
to carry out resampling - see the `method` details in `?project` but they basically fall
into two groups:

* Most are interpolations methods for getting a representative **continuous value** for
  each cell from the data in the original raster grid. They range from simple `average`
  values of intersecting cells, to more complex polynomials and splines (e.g `cubic`)
  that use a moving window of a neighbourhood of cells to construct an estimate for the
  new cell.

* Other approaches select a single value from the source grid: the `near` method takes
  the value from the source raster cell closest to the centre of the new cell, and the
  `mode` value takes the modal value of the set of overlapping cells. Both of these
  approaches are intended for use with categorical raster data, where it makes no sense
  to interpolate values between category codes.

To use the `terra::project` function, you need to provide a raster with the target
resolution and projection to use as a template. To reproject the Sentinel 2 data, we can
simply use the Land Cover map datasets, which are also have a 10m resolution and have
been cropped to the study area.

```{code-cell} r
s2_silwood_10m <- project(s2_silwood_10m, silwood_LCM, method="cubic")
s2_nhm_10m <- project(s2_nhm_10m, nhm_LCM, method="cubic")
```

```{admonition} Exercise

Repeat this reprojection for the 20 metre resolution Sentinel 2 datasets that you 
created earlier (`s2_silwood_20m` and `s2_nhm_20m`). 

You should reproject the data to the same 20 metre resolution. We do not have an
existing BNG raster dataset at this resolution, so you will need to make one.

```

:::{tip} Show solution
:class: dropdown

```{code-cell} r

# Make 20 metre resolution templates for the study sites
silwood_template_20m <- rast(ext(silwood_aerial), res=20, crs="EPSG:27700")
nhm_template_20m <- rast(ext(nhm_aerial), res=20, crs="EPSG:27700")

# Reproject S2 20m bands into BNG
s2_silwood_20m <- project(s2_silwood_20m, silwood_template_20m, method="cubic")
s2_nhm_20m <- project(s2_nhm_20m, nhm_template_20m, method="cubic")
```

:::

```{code-cell} r
:tags: [remove-cell]
# Remove template rasters
rm(silwood_template_20m, nhm_template_20m)

# Dump the objects from this section
save_state()
```
