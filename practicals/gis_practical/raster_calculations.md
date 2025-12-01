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



# Raster calculations

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

A layer in a continuous raster dataset is basically just a large numeric matrix. This
means you can use raster layers in equations to calulate new composite indices that
emphasize different parts of the spectral signal. There are a very large number of
remote sensing indices and the [Sentinel-Hub scripts
site](https://custom-scripts.sentinel-hub.com/custom-scripts/sentinel/sentinel-2/)
provides formulae for a wide range of options. Here we will look at two simple
vegetation indices.

### NDVI

The normalised difference vegetation index (NDVI) is defined as:

$$
NDVI = \frac{\text{NIR} - \text{RED}}{\text{NIR} + \text{RED}}
$$

where NIR is band data for the near infrared and RED is band data in the red spectrum,
which are Sentinel 2 bands B8 and B4. The index returns values from -1 (water) through 0
(rock and bare ground) to 1 (rainforest). See [the Sentinel-Hub NDVI script page for
more details](https://custom-scripts.sentinel-hub.com/sentinel-2/ndvi/).

```{code-cell} r
# Calculate the NDVI index for the two sites
ndvi_nhm <- (
  s2_nhm_10m[["NIR"]] - s2_nhm_10m[["R"]]) / 
  (s2_nhm_10m[["NIR"]] + s2_nhm_10m[["R"]]
)
ndvi_silwood <- (
  s2_silwood_10m[["NIR"]] - s2_silwood_10m[["R"]]) / 
  (s2_silwood_10m[["NIR"]] + s2_silwood_10m[["R"]]
)
# Rename the single band 
names(ndvi_silwood) <- names(ndvi_nhm) <- "NDVI"

# Plot the NDVI index data
par(mfrow=c(1, 2))
plot(ndvi_silwood)
plot(ndvi_nhm)
```

### EVI

The enhanced vegetation index (EVI) is very similar but includes scaling factors and
uses the Blue band (Sentinel B2) to improve how well the index captures vegetation. The
scale again extends from -1 to 1. See [the Sentinel-Hub EVI script page for
more details](https://custom-scripts.sentinel-hub.com/sentinel-2/evi/).

$$
EVI = 2.5 \cdot \left( \frac{\text{NIR} - \text{RED}}
  {\text{NIR} + 6 \cdot \text{RED} - 7.5 \cdot \text{BLUE} + 1} \right)
$$

```{code-cell} r
# Calculate the EVI index for the two sites
evi_nhm <- 2.5 * 
  (s2_nhm_10m[["NIR"]] - s2_nhm_10m[["R"]]) / 
  (s2_nhm_10m[["NIR"]] + 
    6 * s2_nhm_10m[["R"]] - 
    7.5 * s2_nhm_10m[["B"]] + 1)
  
evi_silwood <- 2.5 * 
  (s2_silwood_10m[["NIR"]] - s2_silwood_10m[["R"]]) / 
  (s2_silwood_10m[["NIR"]] + 
    6 * s2_silwood_10m[["R"]] - 
    7.5 * s2_silwood_10m[["B"]] + 1)

# Rename the single band 
names(evi_silwood) <- names(evi_nhm) <- "EVI"
```

There is an issue with the EVI data for the NHM site: there are some anomalous high
values in the satellite data that lead to extreme EVI values. You can see these local
issues as hotspots if you try plotting these bands (e.g. `plot(s2_nhm_10m[["NIR"]])`).
We can fix that problem by setting extreme values to `NA` - this is another useful
method for manipulating raster data.

```{code-cell} r
# Remove anomalous EVI values
evi_nhm[evi_nhm > 1] <- NA
evi_nhm[evi_nhm < -1] <- NA
```

Now we can plot the EVI maps.

```{code-cell} r
# Plot the EVI index data
par(mfrow=c(1, 2))
plot(evi_silwood)
plot(evi_nhm)
```

```{code-cell} r
:tags: [remove-cell]

# Dump the objects from this section
save_state()
```
