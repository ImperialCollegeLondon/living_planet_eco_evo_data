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
short_title: Manipulating spatial data
---

# Manipulating spatial data

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

## Manipulating raster data

Even once you have raster datasets in the same resolution, it is common to want to
manipulate them to get multiple datasets into the same extent and resolution. This
section covers:

* upscaling and downscaling raster resolution,
* joining adjacent raster tiles into a single dataset,
* combining raster bands for datasets with the same extent and resolution, and
* cropping datasets to a smaller extent.

### Changing raster resolution

If you want to change the resolution or grid of an existing raster grid **without
changing the projection** then you there are a few options:

* If you want to change the grid resolution by a simple factor while keeping the same
  basic grid cell alignments and extent, then you can use the `terra::aggregate` and
  `terra::disagg` functions.

* If you need to change the grid to a raster resolution that is not a simple factor or
  need to move the cell boundaries to match another dataset, then you will need the
  `terra::resample` function. This functions much like `terra::project` without the
  coordinate transformation, and has the same methods for resampling onto the new grid.

Here, we will use disaggregation to resample the 20 metre resolution Sentinel 2 bands to
10 metre resolution. We will use `method=bilinear` which uses a simple linear model to
assign new cell values; the alternative `method=near` would simply duplicate the value
from the nearest coarser resolution cell into each of the smaller cells.

```{code-cell} r
s2_silwood_20m_at_10m <- disagg(s2_silwood_20m, fact=2, method="bilinear")
s2_nhm_20m_at_10m <- disagg(s2_nhm_20m, fact=2, method="bilinear")
```

We can use the `terra::res` function to show the resolutions of the two versions.

```{code-cell} r
print(res(s2_silwood_20m))
print(res(s2_silwood_20m_at_10m))
```

```{admonition} Stretch goal: projecting Sentinel 2 to 10m resolution
:class: tip

We could also have got the 20 metre resolution Sentinel 2 bands resampled to 10 metres
using  only the `terra::project` function. See if you can generate
`s2_silwood_20m_direct_to_10m` and `s2_nhm_20m_direct_to_10m` using only that function.
```

:::{tip} Show solution
:class: dropdown

```{code-cell} r
:tags: [skip-execution]

# It is actually very easy - we can just use the existing 10m CEH Land Cover Map
# datasets as the resampling template.
s2_silwood_20m_direct_to_10m <- project(
  s2_silwood_20m, silwood_lcm, method="cubic"
)
s2_nhm_20m_direct_to_10m <- project(
  s2_nhm_20m, nhm_lcm, method="cubic"
)
```

:::

### Mosaicing rasters

We can **mosaic** the two panes of Terrain 5 data for each site from two 5km panes into
a single rectangle of data. The two panes are side by side for Silwood and one above the
other for the NHM. The plot below shows the 5 x 5 km extent of the two panes. The figure
also shows the 3 x 3 km extent of the other data sources - as you can see it overlaps
the Terrain 5 panes for both sites, which is why we needed to load two panes.

```{code-cell} r
:tags: [remove-input]

options(repr.plot.height=4)

par(mfrow=c(1,2))

# Calculate the union of the extents of the two rasters
silwood_dtm_extent <- union(ext(silwood_dtm_SU96NE), ext(silwood_dtm_SU96NW ))

# Plot the extent of the first raster, but using the extent of both datasets
plot(ext(silwood_dtm_SU96NE), border="blue", ext=silwood_dtm_extent, main="Silwood")

# Get the middle coordinates of the raster and add a label. The `xFromCol` and 
# `yFromRow` functions extract the X and Y coordinates of cell centres from the 
# raster and `mean` then gives the centre of the raster image.
text(
  x=mean(xFromCol(silwood_dtm_SU96NE)), 
  y=mean(yFromRow(silwood_dtm_SU96NE)),
  labels="SU96NE", col="blue"
)

# Use `add=TRUE` to add the extent of the second raster and add the label
plot(ext(silwood_dtm_SU96NW), border="red", add=TRUE)
text(
  x=mean(xFromCol(silwood_dtm_SU96NW)), 
  y=mean(yFromRow(silwood_dtm_SU96NW)),
  labels="SU96NW", col="red"
)

# Finally add the extent of the other raster datasets 
plot(ext(silwood_aerial), border="black", add=TRUE)

# Repeat for the NHM datasets
nhm_dtm_extent <- union(ext(nhm_dtm_TQ27NE), ext(nhm_dtm_TQ28SE))

plot(ext(nhm_dtm_TQ27NE), border="blue", ext=nhm_dtm_extent, main="NHM")
text(
  x=mean(xFromCol(nhm_dtm_TQ27NE)), 
  y=mean(yFromRow(nhm_dtm_TQ27NE)),
  labels="TQ27NE", col="blue"
)
plot(ext(nhm_dtm_TQ28SE), border="red", add=TRUE)
text(
  x=mean(xFromCol(nhm_dtm_TQ28SE)), 
  y=mean(yFromRow(nhm_dtm_TQ28SE)),
  labels="TQ28SE", col="red"
)
plot(ext(nhm_aerial), border="black", add=TRUE)
```

:::{note} Show source code for plot
:class: dropdown

The plot above uses a few useful plotting tricks for spatial data:

* changing the spatial extent of the plot to include more than one dataset,
* adding mutiple layers to a spatial plot, and
* using coordinates to add text.

You do not need to know these details for the practical, but this might be something to
come back to and look at.

```{code-block} r

options(repr.plot.height=4)

par(mfrow=c(1,2))

# Calculate the union of the extents of the two rasters
silwood_dtm_extent <- union(ext(silwood_dtm_SU96NE), ext(silwood_dtm_SU96NW ))

# Plot the extent of the first raster, but using the extent of both datasets
plot(ext(silwood_dtm_SU96NE), border="blue", ext=silwood_dtm_extent, main="Silwood")

# Get the middle coordinates of the raster and add a label. The `xFromCol` and 
# `yFromRow` functions extract the X and Y coordinates of cell centres from the 
# raster and `mean` then gives the centre of the raster image.
text(
  x=mean(xFromCol(silwood_dtm_SU96NE)), 
  y=mean(yFromRow(silwood_dtm_SU96NE)),
  labels="SU96NE", col="blue"
)

# Use `add=TRUE` to add the extent of the second raster and add the label
plot(ext(silwood_dtm_SU96NW), border="red", add=TRUE)
text(
  x=mean(xFromCol(silwood_dtm_SU96NW)), 
  y=mean(yFromRow(silwood_dtm_SU96NW)),
  labels="SU96NW", col="red"
)

# Finally add the extent of the other raster datasets 
plot(ext(silwood_aerial), border="black", add=TRUE)

# Repeat for the NHM datasets
nhm_dtm_extent <- union(ext(nhm_dtm_TQ27NE), ext(nhm_dtm_TQ28SE))

plot(ext(nhm_dtm_TQ27NE), border="blue", ext=nhm_dtm_extent, main="NHM")
text(
  x=mean(xFromCol(nhm_dtm_TQ27NE)), 
  y=mean(yFromRow(nhm_dtm_TQ27NE)),
  labels="TQ27NE", col="blue"
)
plot(ext(nhm_dtm_TQ28SE), border="red", add=TRUE)
text(
  x=mean(xFromCol(nhm_dtm_TQ28SE)), 
  y=mean(yFromRow(nhm_dtm_TQ28SE)),
  labels="TQ28SE", col="red"
)
plot(ext(nhm_aerial), border="black", add=TRUE)
```

:::

We use the `terra::mosaic` function to combine these two panes into a single dataset for
each site. There is also the `terra::merge` function: this is used to combine aligned
raster datasets that are not simply neatly adjoining tiles. It also make life easier if
we update these datasets so they use the same raster layer name - they currently are
named by BNG grid pane.

```{code-cell} r
# Mosaic the two Terrain 5 panes into a single dataset
silwood_dtm <- mosaic(silwood_dtm_SU96NE, silwood_dtm_SU96NW)
nhm_dtm <- mosaic(nhm_dtm_TQ27NE, nhm_dtm_TQ28SE)

# Update the raster layer names
names(silwood_dtm) <- names(nhm_dtm) <- "Elevation"
```

We can check the extents to show what happened - the new Silwood terrain dataset now has
a 10km extent in the X dimension.

```{code-cell} r
print(ext(silwood_dtm_SU96NE))
print(ext(silwood_dtm_SU96NW))
print(ext(silwood_dtm))
```

### Combining raster bands

We can also combine rasters with the same resolution and grid to add more bands onto an
existing dataset. We can do this to create a new Sentinel 2 dataset that includes the
original 10 metre resolution bands and the 20 metre bands that we resampled to 10
metres. The `terra` package takes the standard `c()` function for combining R vectors
and lists and extends that to join raster layers by band.

```{code-cell} r
# Combine the S2 10m bands with the resampled 20 m bands.
s2_silwood_10m <- c(s2_silwood_10m, s2_silwood_20m_at_10m)
s2_nhm_10m <- c(s2_nhm_10m, s2_nhm_20m_at_10m)
```

### Cropping rasters

You can reduce the size of a raster dataset to a particular area of interest using the
`terra::crop` function. We will use this to extract the 3km area of interest from the
newly mosaiced datasets. All we need to provide is another dataset that has the required
extent.

```{code-cell} r
# Crop the mosaiced DTM data to the 3km area of interest.
silwood_dtm <- crop(silwood_dtm, silwood_aerial)
nhm_dtm <- crop(nhm_dtm, nhm_aerial)
```

We can again check the extents of the resulting grids to check that they match:

```{code-cell} r
# Crop the mosaiced DTM data to the 3km area of interest.
print(ext(silwood_dtm))
print(ext(silwood_aerial))
```

## Manipulating vector data

Vector data manipulation is generally either to merge two datasets or to crop data to a
smaller spatial extent.

### Merging vector data

Vector data is easier to merge in some ways: because the coordinates are recorded
as sets of point forming features, you don't have to worry about cell alignment or
resolution. However, to merge a set of spatial features:

* The two datasets have to have the same attributes: the data associated with each
  feature needs to match.
* The two datasets have to be in the same projection.

Provided these two things are true, then merging two vector datasets is basically the
same as binding together the rows of two data frames with the same structure. The `sf`
package provides a version of the `rbind` function that joins two `sf` objects, and we
can use this to combine the two VML panes for the sites.

```{code-cell} r
# Combine the road panes
silwood_VML_roads <- rbind(vml_su96ne_roads, vml_su96nw_roads)
nhm_VML_roads <- rbind(vml_tq28se_roads, vml_tq27ne_roads)

# Combine the water area panes
silwood_VML_water <- rbind(vml_su96ne_water, vml_su96nw_water)
nhm_VML_water <- rbind(vml_tq28se_water, vml_tq27ne_water)
```

If we plot the extents of the new combined data (grey) and the source panes (red and
blue) for Silwood, you can see that the panes are not neatly aligned with actual BNG
grid cell bounds used by the elevation data (dashed panes). Raster cells by definition
fall onto a neat grid, but vector features cross boundaries and it is common for
datasets to include features that fall outside the strict pane boundaries.

```{code-cell} r
# Merged data
plot(st_as_sfc(st_bbox(silwood_VML_roads)), border='grey', lwd=4)

# SU96NW panes of vector (solid) and raster (dashed) data
plot(st_as_sfc(st_bbox(vml_su96nw_roads)), border='blue', add=TRUE)
plot(st_as_sfc(st_bbox(silwood_dtm_SU96NW)), border='blue', add=TRUE, lty=2)

# SU96NE panes of vector (solid) and raster (dashed) data
plot(st_as_sfc(st_bbox(vml_su96ne_roads)), border='red', add=TRUE)
plot(st_as_sfc(st_bbox(silwood_dtm_SU96NE)), border='red', add=TRUE, lty=2)
```

### Cropping vector data

We can crop the VML data down to the study site using the `sf::st_crop` function. It is
usually faster and easier to reduce datasets to only the focal area you are working
with.

```{code-cell} r
# Crop the two vector datasets
silwood_VML_roads <- st_crop(silwood_VML_roads, silwood_aerial)
nhm_VML_roads <- st_crop(nhm_VML_roads, nhm_aerial)
silwood_VML_water <- st_crop(silwood_VML_water, silwood_aerial)
nhm_VML_water <- st_crop(nhm_VML_water, nhm_aerial)
```

We can now create a simple plot overlaying the vector roads and water over the top of
the digital elevations maps, again using `sf::st_geometry` to just show the geometries
of the vector features.

```{code-cell} r
par(mfrow=c(1, 2))

plot(silwood_dtm, col=grey.colors(20), main="Silwood")
plot(st_geometry(silwood_VML_roads), col="firebrick", add = TRUE)
plot(st_geometry(silwood_VML_water), col="cornflowerblue", border=NA, add = TRUE)

plot(nhm_dtm, col=grey.colors(20), main="NHM")
plot(st_geometry(nhm_VML_roads), col="firebrick", add = TRUE)
plot(st_geometry(nhm_VML_water), col="cornflowerblue", border=NA, add = TRUE)
```

<!-- 

### Vector operations

within, voronoi etc?

```{code-cell} r
within_25 <- st_within(nest_boxes, nest_boxes_25, sparse=FALSE)
n_within_25 <- colSums(within_25)
```
 -->

```{code-cell} r
:tags: [remove-cell]

# Dump the objects from this section
source("practical_data_state_functions.r")
save_state()
```
