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
short_title: Simple GIS plots
---


# Plotting GIS data

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

```{hint}
These are very basic plotting tips for vector data, but are all we need for this
practical. 
```

## Plotting vector data

If you plot a vector dataset, then it will generate a panel for each vector attribute in
the dataset (up to a limit!).

```{code-cell} r
plot(nest_boxes)
```

If you want to plot just one of those attributes, then you can use `[]` subsets to do
so, and R will generate a key for it.

```{code-cell} r
plot(nest_boxes['SPlocation'], key.pos=4)
```

If you just want to plot the features geometry, then you can use `sf::st_geometry`. You
can use `add=TRUE` to overplot features and you can use extent to change the spatial
area being plotted. It can be tricky to set the area of the plot so that it will include
all features. One trick here is to get the extent (or bounding box) of the layers you
want to plot and then convert them to polygons using `sf::st_as_sfc` and then take the
spatial union(`sf::st_union`) of those boxes. Long-winded but reliable!

```{code-cell} r
# Get the plot extent as the union of the bounding boxes
plot_extent <- st_union(
  st_as_sfc(st_bbox(nest_boxes)),
  st_as_sfc(st_bbox(silmas_route))
)

# Plot the nest box points and overplot the Silmas route
plot(st_geometry(nest_boxes), col="forestgreen", extent=plot_extent)
plot(st_geometry(silmas_route), col="red", add=TRUE)
```

## Plotting raster data

If you plot a raster object, it will plot each band separately:

```{code-cell} r
# Plot the 3 bands of the silwood aerial image
names(silwood_aerial) <- c("Red", "Green", "Blue")
plot(silwood_aerial, nc=3)
```

If you instead want to combine image bands to create a three colour image, then the
`terra::plotRGB`  can be used to combine 3 bands to generate a colour composite image.
The `silwood_aerial` image contains the three RGB bands in the correct order, so we can
simply plot it:

```{code-cell} r
# Plot the silwood aerial data using the default settings
plotRGB(silwood_aerial)
```

If we want to do the same thing with the RGB data from the Sentinel 2 data then we need
to adjust the command to give the bands in the right order and also to set the maximum
scale of the values across the bands.

```{code-cell} r
# Plot the Sentinel data, setting the bands and scale
plotRGB(s2_silwood_10m, r=3, g=2, b=1, scale=0.80)
```

In fact, the L2A Sentinel 2 product provides a True Colour Image (TCI) that orders and
scale the RGB bands to give something closer to expected colour. This can be used with
the default settings.

```{code-cell} r
# Load the L2A TCI image for Silwood and plot using defaults.
s2_silwood_tci <- rast(
  "data/sentinel_2/R10m/silwood/T30UXC_20250711T110651_TCI_10m.tiff"
)
plotRGB(s2_silwood_tci)
```

Alternatively, you can set different bands as inputs to give a "false-colour image". One
common usage is a [false colour
infrared](https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel-2/false_color_infrared/)
image, which swaps from the `[R, G, B]` bands to `[NIR, R, G]`. This kind of imagery is
very good at pulling out differences between vegetation (bright red), water (dark) and
urban areas and bare ground (tan or grey).

```{code-cell} r
# Plot the Sentinel data, setting the bands and scale
plotRGB(s2_silwood_10m, r=4, g=3, b=2, scale=0.8)
```

<!-- 
NOTE - there are no changes to the data objects in this document so there is no 
code cell required to save changes to the data state.
-->
