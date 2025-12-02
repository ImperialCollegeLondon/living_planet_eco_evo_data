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
short_title: Raster calculations
---

# Sampling from raster datasets

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

A common need in spatial analysis is to get raster values from locations: for example,
what are the EVI values at the nest box locations, or what are the heights of the sensor
location sites. We can do this using the `terra::extract` function, which takes a raster
and a vector dataset and returns the cell values under the vector features.

## Point features

With point features this is very easy - you get the values under each point.

```{code-cell} r
# Extract the EVI values under the nest boxes
nest_box_evi <- extract(evi_silwood, nest_boxes)
hist(nest_box_evi$EVI)
```

It is a little more difficult for the sensors because the heights are in two different
datasets, so we need to use extract twice and then combine the results. The
`terra::extract` function returns a row with NA if there is no data for a site, so we
can merge the data simply by joining the two datasets together and dropping the NA rows.

```{code-cell} r
# Extract the heights at the two sites
sensor_elevations_silwood <- extract(silwood_dtm, sensor_locations)
sensor_elevations_nhm <- extract(nhm_dtm, sensor_locations)

# Combine the values from the two rasters and drop to the combined data
sensor_elevations <- na.omit(rbind(sensor_elevations_silwood, sensor_elevations_nhm))

# Show the data
head(sensor_elevations)
```

## Line features

You might also want to know what the values under a line feature are: either because you
want a distribution of those values, or possible because you want a sequence of values
_along_ the feature. These two things are different - we'll look at them using the
Silmas walk/run route.

If we just use extract with the line features, then `terra::extract` returns the values
of all of the cells that the line touches. The values are not in sequence along the line
feature - they are just all the values it touches. We can see the cells that are being
selected by **rasterising** the route.

```{code-cell} r
# Extract the heights under the Silmas route
silmas_heights <- extract(silwood_dtm, silmas_route, xy=TRUE)

par(mfrow=c(1,2))
# Convert the Silmas route into a raster to show the sampled cells
silmas_route_raster <- rasterize(silmas_route, silwood_dtm)
plot(silwood_dtm, col=grey.colors(20))
plot(silmas_route_raster, col="red", add=TRUE, legend=FALSE)

# Show the height distribution of all the cells that the route crosses
hist(silmas_heights$Elevation, xlab = "Elevation of Silmas route cells (m)", main="")
```

If you want to get a _sequence of values along a linear feature_ then you need to
extract the values in order. To do this, you need to convert the linear feature to
points by **casting** it to the simpler feature type. This gives us a warning that
basically just says that it is assigning the attributes for the whole linear feature to
each and every point, and that might not be sensible. If the points are very spaced out,
you can use `sf::st_segmentize` to interpolate more points along the feature.

```{code-cell} r
silmas_points <- st_cast(silmas_route, "POINT")
```

We can now use `terra::extract` on the points to get the heights in sequence. We can
also use Pythagoras' theorem to get the cumulative distance along the route from the
coordinates.

```{code-cell} r
# Get the height of each GPS point along the route
silmas_heights <- extract(silwood_dtm, silmas_points)

# Get the coordinates of the points and use Pythagoras to ge the distance.
coords <- as.data.frame(st_coordinates(silmas_points))
coords$distance <- c(0, sqrt(diff(coords$X)**2 + diff(coords$Y)**2))
coords$total_distance <- cumsum(coords$distance)
coords$height <-silmas_heights$Elevation

# Plot the height profile of the Silmas walk
plot(height~ total_distance, data=coords, type="l")
```

## Polygon features

It is extremely common to want to get a distribution or summary statistic of raster
values within a polygon feature: for example, what is the average elevation within 50
metres of each of the sensor locations? The first thing to do is to get polygons that
form a 50m radius circle around each sensor locations using the `sf::st_buffer`
function.

```{code-cell} r
# Get 50m radius polygons around the sensor points
sensor_locations_50 <- st_buffer(sensor_locations, 50)
```

You can use `sf::st_buffer` with any features to get polygons extending out from the
feature, and you can in fact use negative distances to get polygons _within_ existing
polygons. We can then use the polygon features with `terra::extract` to get a data frame
of the values from the digital elevation map associated with each sensor location. We
again need to join the results from the two sites together and drop any NA rows.

```{code-cell} r
# Get the values within the 50m buffer for each sensor location, 
silwood_sensor_heights <- extract(silwood_dtm, sensor_locations_50)
nhm_sensor_heights <- extract(nhm_dtm, sensor_locations_50)
sensor_heights <- na.omit(rbind(silwood_sensor_heights, nhm_sensor_heights))

# How many values per site?
table(sensor_heights$ID)

# Height variation between sensors
boxplot(Elevation ~ ID, data= sensor_heights)
```

We can also extract data from categorical rasters:

```{code-cell} r
# Get the values within the 50m buffer for each sensor location, 
silwood_sensor_LCM <- extract(silwood_LCM, sensor_locations_50)
nhm_sensor_LCM <- extract(nhm_LCM, sensor_locations_50)
sensor_LCM <- na.omit(rbind(silwood_sensor_LCM, nhm_sensor_LCM))

# Land cover class counts within 50m of each sensor.
xtabs(~ LandCover + ID, data= sensor_LCM, drop.unused.levels=TRUE)
```

````{admonition} Side note

As a sidenote, the standard way this works is to use the `terra::rasterize` function to
find all of the raster cells where the cell centre falls within a polygon feature, but
you can optionally choose to also include any cells that the cell boundary touches,
using the `touches=TRUE` setting. The plot below shows the two alternatives for a single
sensor polygon:

```{code-cell} r
:tags: [hide-input]
# Create an extent around a single sensor
zoom_to_site_one <- ext(c(493835,  493955, 169200, 169330))

# Rasterize using the two methods
cell_touches_false <- rasterize(sensor_locations_50[1,], silwood_dtm)
cell_touches_true <- rasterize(sensor_locations_50[1,], silwood_dtm, touches=TRUE)

# Plot side by side as DTM overplotted with rasterized polygon and polygon border
par(mfrow=c(1,2))

plot(
  silwood_dtm, ext=zoom_to_site_one, legend=FALSE, 
  col=gray.colors(20), main="touches=FALSE"
)
plot(cell_touches_false, add=TRUE, legend=FALSE, col="firebrick")
plot(st_geometry(sensor_locations_50[1,]), col=NA, add=TRUE)

plot(
  silwood_dtm, ext=zoom_to_site_one, legend=FALSE, 
  col=gray.colors(20), main="touches=TRUE"
)
plot(cell_touches_true, add=TRUE, legend=FALSE, col="firebrick")
plot(st_geometry(sensor_locations_50[1,]), col=NA, add=TRUE)

```

````

## Zonal statistics

You can also sample from a raster dataset using another raster dataset. In practice,
this is what is happening when you extract data from a vector feature - the different
features get converted into raster layers in order to identify which cells to extract.
But if you already have a categorical raster, you can simply use the `terra::zonal`
function to extract the values under each raster cateogory.

```{code-cell} r
# Extract the EVI values for each LCM raster cell
evi_by_LCM <- zonal(evi_silwood, silwood_LCM, wide=FALSE)
head(evi_by_LCM)
```

We can then visualise the range of EVI values by land cover class:

```{code-cell} r
par(mar = c(4,12,1,1))
plot(EVI ~ as.factor(LandCover), data=evi_by_LCM, horizontal=TRUE, las=1, xlab="")
```
