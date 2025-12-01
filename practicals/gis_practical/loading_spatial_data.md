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
short_title: Loading spatial data
---


# Loading spatial data

```{code-cell} r
:tags: [remove-stderr]
library(terra)       # core raster GIS package
library(sf)          # core vector GIS package
library(rcartocolor) # plotting
library(rpart)
```

We will be using a number of different datasets in both vector and raster format, at a
range of resolutions. They are not all in the same projection and so we will need to
supply coordinate system details. These can be very complex, but fortunately the [EPSG
database](https://epsg.io/) now provides a set of consistent codes that can be use to
specify coordinate systems.

We will first load the location data for three field datasets, all of which GPS point
location data using the WGS84 projection ([EPSG:4326](https://epsg.io/4326)) with units
in degrees:

* The sensor deployment locations (16 sites across both the NHM and Silwood).
* The blue tit nest box sites at Silwood (222 sites)
* The woodland survey data sites.

We will then load a set of additional data files in a wide range of formats. The
following datasets are all downloaded from the [Edina
Digimap](https://digimap.edina.ac.uk/) system. This is a UK national GIS resource for
higher education, which you should be able to use for any UK based GIS whilst you are at
the college using your college credentials. All of these datasets use the the OSGB36 /
British National Grid projected coordinate system
([`EPSG:27700`](https://epsg.io/27700)), with units in metres.

* Aerial photography: RGB raster data at 25cm resolution with a single 3 x 3 km pane each
  of the two sites.
* The Ordnance Survey (OS) Terrain 5 digital elevation dataset: raster data at 5m
  resolution with 2 pairs of 5 x 5 km panes for each site.
* The CEH LandCover Map 2024: a raster land cover classification map with a single 3 x 3
  km pane for each site.
* The OS VectorMap Local dataset: two 5 x 5 km panes of vector data for each site.

There are then two final datasets:

* Satellite data from the Sentinel 2 L2A product at a range of resolutions, using the
  [Universal Transverse Mercator
  system](https://en.wikipedia.org/wiki/Universal_Transverse_Mercator_coordinate_system).
  This projection uses multiple zones for different parts of the planet and the UK data
  is in UTM zone 30N ([EPSG code `EPSG:32630`](https://epsg.io/32630)), with units of
  meters.
  
* The GPS route for Silwood Christmas (Silmas) fun run and walking route. This is again
  in WGS84 projection.

The sections below show how to load each dataset.

## Sensor locations

The sensor stations at Silwood and the NHM are recorded as  a CSV file, providing
station data including the latitude and longitude of each site. This file is directly
downloaded from the Epicollect5 project. This is vector point data: precise locations
from GPS associated with additional site data.

* The data is first loaded as a simple CSV file.

* We then need to convert the data to an `sf` (simple features) object. This is very
  like a normal R data frame, but contains an additional `geometry` field that contains
  the vector data geometries and the coordinate system. This is done using the
  `sf::st_sf` function to set the CSV fields that contain the point coordinates.

```{code-cell} r
# Load the data from the CSV file
sensor_locations <- read.csv("data/SensorSites/form-1__setup.csv")

# Convert to an sf object by setting the fields containing X and Y data and set 
# the projection of the dataset
sensor_locations <- st_as_sf(
  sensor_locations, 
  coords=c("long_Sensor_location","lat_Sensor_location"),
  crs="EPSG:4326"
)
```

## Nest boxes

The locations of the Silwood blue tit nest boxes were also recorded using GPS. This is a
long-term dataset and these data have already been processed into specific GIS format:
the widely used [shapefile format](https://en.wikipedia.org/wiki/Shapefile). The
`sf::st_read` function is used to read existing GIS format files directly into an `sf`
object.

```{code-cell} r
nest_boxes <- st_read("data/NestBoxes/NestBoxes.shp")
```

As you can see from the output above, loading a GIS file using `sf::stread` produces
quite a lot of information. This practical handout will generally hide that to keep the
page size down. We can also look at what an `sf` object looks like if you print it out:
very like a dataframe with some extra header data.

```{code-cell} r
print(head(nest_boxes))
```

```{admonition} Shapefile - not one file!
:class: danger

Confusingly, a **shapefile dataset is not a single file** - a shapefile dataset consists
of a set of related files with the same shared file name and a range of file type
suffixes (`.shp`, `.dbf`, `.shx` and `.prj` are the core subfiles but other suffixes are
common). You **must keep all of these files together**, or the dataset will not load 
correctly.
```

## Woodland survey

The Silwood woodland survey transect points: another CSV file providing latitude and
longitude of transect locations.

TODO

## Aerial photography

These raster datasets provide 3km by 3km panes of 25cm resolution [aerial photography
imagery](https://digimap.edina.ac.uk/aerial) for the two sites. These files are provided
as GeoTIFF data files - these are essentially just [standard TIFF
image](https://en.wikipedia.org/wiki/TIFF) files but contain metadata that provides the
spatial context of each pixel in the image and the projection information.

Raster data can be loaded using the `terra::rast` function.

```{code-cell} r
nhm_aerial <- rast('data/aerial/nhm_aerial.tiff')
silwood_aerial <- rast('data/aerial/silwood_aerial.tiff')
```

Printing out one of those fhiles shows the spatial information of the raster and then a
table showing the names of the bands in the raster and their range. These files contain
three band to provide RGB imagery.

```{code-cell} r
print(nhm_aerial)
```

## OS Terrain 5

These raster datasets provide continuous elevation data at 5m
resolution from the [Ordnance Survey Terrain 5 Digital Terrain Map (DTM)
dataset](https://www.ordnancesurvey.co.uk/products/os-terrain-5). Each site has
two adjoining panes of data.

```{admonition} Aside: coordinates in the British National Grid
:class: tip

The odd file names come from the British National Grid mapping system. The code `SU96NE`
indicates the north east quadrant of a 10 x 10 km cell that is found 9 cells east and 6
cells north within the 100 x 100 km `SU` cell. The `SU` cell itself is one of 25 cells
within the 500 x 500 km `S` cell. You can add more digits to give more resolution. An 8
digit grid reference has a 10 metre precision: the Hamilton building is at `SU 9469
6871` and the NHM Wildlife Garden is at `TQ 2656 7899`.

See [here for more details](<https://digimap.edina.ac.uk/help/our-maps-and-data/bng/>).
```

These files are `ASC` format files - a very simple text based format that contains the
cell coordinates but _not_ the projection metadata, so we need to add that information.

```{code-cell} r
# Load the DTM data from ASC format files
silwood_dtm_SU96NE <- rast("data/dtm_5m/SU96NE.asc")
silwood_dtm_SU96NW <- rast("data/dtm_5m/SU96NW.asc")
nhm_dtm_TQ27NE <- rast("data/dtm_5m/TQ27NE.asc")
nhm_dtm_TQ28SE <- rast("data/dtm_5m/TQ28SE.asc")
```

If we look at one of those datasets, you can see that the cell coordinates, resolution
and overall dataset size have been set but that the `coord. ref` attribute is empty.

```{code-cell} r
# Look at the object data
silwood_dtm_SU96NE
```

We need to set the projection manually using the `terra::crs` function and then check
that the attribute has been set.

```{code-cell} r
# Set the projection information for the DTM datasets
crs(silwood_dtm_SU96NE) <- crs(silwood_dtm_SU96NW) <- "EPSG:27700"
crs(nhm_dtm_TQ27NE) <- crs(nhm_dtm_TQ28SE) <- "EPSG:27700"

# Print the modified dataset
silwood_dtm_SU96NE
```

## CEH Land Cover

The Centre for Ecology and Hydrology produces a UK wide land cover map at 10 metre
resolution. The datasets here are taken from the most recent [Land Cover Map
2024](https://catalogue.ceh.ac.uk/documents/5af9e97d-9f33-495d-8323-e57734388533).

The land cover categories are assigned using a classification of multi-band spectral
data from satellites onto the spectral signatures of known training sites. Each cell is
assigned to the category with training signatures that most closely match the spectral
signature of the cell.

```{code-cell} r
# Load the land cover map datasets
silwood_LCM <- rast("data/lcm_2024/Silwood_LCM2024.tiff")
nhm_LCM <- rast("data/lcm_2024/NHM_LCM2024.tiff")

# Look at the raster details
print(silwood_LCM)
```

The LCM2024 files contain **two raster bands**. The first band is a numeric code
giving the land cover category. The second band give the probability of the cell having
that land cover type, based on the underlying classification. As loaded, these values
are just numeric, so if we plot the data, we will get two continuous colour legends:

```{code-cell} r
plot(silwood_LCM)
```

We can add category labels and better category colours to make the data easier to use.
The labels and some colours are defined in a separate CSV file:

```{code-cell} r
lcm_info <- read.csv("data/lcm_2024/LCM2024_info.csv")

# Set the band names, the category code labels and the colour tables
levels(nhm_LCM) <- lcm_info[c("value", "label")]
coltab(nhm_LCM) <- lcm_info[c("value", "color")]
names(nhm_LCM) <- c("LandCover", "Certainty")

coltab(silwood_LCM) <- lcm_info[c("value", "color")]
levels(silwood_LCM) <- lcm_info[c("value", "label")]
names(silwood_LCM) <- c("LandCover", "Certainty")
```

Now we can now plot maps that have actual category labels:

```{code-cell} r
par(mfrow=c(1,2))
plot(silwood_LCM["LandCover"])
plot(nhm_LCM["LandCover"])
```

And look at the frequencies of the different categories using the `terra::freq` function:

```{code-cell} r
nhm_freq <- freq(nhm_LCM["LandCover"])
silwood_freq <- freq(silwood_LCM["LandCover"])

# Join the two datasets, including all categories
merge(
  nhm_freq, silwood_freq, 
  by="value", all=TRUE, suffixes = c(".nhm", ".silwood")
)
```

We can also use the data within raster layers with other non-spatial data exploration
techniques. For example, we can look at the distribution of cell certainties associated
with each category. We use `terra::droplevels` here to remove unused levels within each scene.

```{code-cell} r
par(mar = c(4, 12, 1, 1))

# Plot cell assignment certainties as a function of land cover category
boxplot(
  silwood_LCM["Certainty"], 
  droplevels(silwood_LCM["LandCover"]), 
  las = 1, ylab = "", horizontal=TRUE, main="Silwood", xlab="Certainty"
)
boxplot(
  nhm_LCM["Certainty"], 
  droplevels(nhm_LCM["LandCover"]), 
  las = 1, ylab = "", horizontal=TRUE, main="NHM", xlab="Certainty"
)
```

## OS VectorMap Local

The [Ordnance Survey VectorMap
Local](https://www.ordnancesurvey.co.uk/products/os-vectormap-local) dataset provides
very high precision vector data on spatial features in the UK. These files are saved in
the [GeoPackage file format (`.gpkg`)](https://en.wikipedia.org/wiki/GeoPackage). As
with the Terrain 5 data, the data from Edina Digimap consists of two 5 x 5 km panes for
each site.

A GeoPackage file can contain multiple vector datasets in a single file: these are
usually called "layers" and so you will typically load one layer at a time. The code
below uses the `sf::st_layers` command to show the available layers within one of the
VML datasets.

```{code-cell} r
print(st_layers("data/VML/vml-su96ne.gpkg"))
```

We can then use the `sf::st_read` function to read specific different layers for each
site.

```{code-cell} r
:tags: [remove-output]

# Load the two panes of VML road centrelines for each site.
vml_tq28se_roads <- st_read(
  dsn = "data/VML/vml-tq28se.gpkg", layer = "Road_Centreline"
)
vml_tq27ne_roads <- st_read(
  dsn = "data/VML/vml-tq27ne.gpkg", layer = "Road_Centreline"
)
vml_su96ne_roads <- st_read(
  dsn = "data/VML/vml-su96ne.gpkg", layer = "Road_Centreline"
)
vml_su96nw_roads <- st_read(
  dsn = "data/VML/vml-su96nw.gpkg", layer = "Road_Centreline"
)

# Do the same for water bodies
vml_tq28se_water <- st_read(
  dsn = "data/VML/vml-tq28se.gpkg", layer = "Water_Area"
)
vml_tq27ne_water <- st_read(
  dsn = "data/VML/vml-tq27ne.gpkg", layer = "Water_Area"
)
vml_su96ne_water <- st_read(
  dsn = "data/VML/vml-su96ne.gpkg", layer = "Water_Area"
)
vml_su96nw_water <- st_read(
  dsn = "data/VML/vml-su96nw.gpkg", layer = "Water_Area"
)
```

## Sentinel 2 data

The Sentinel 2 satellite mission collects spectral data from [13
bands](https://custom-scripts.sentinel-hub.com/sentinel-2/bands/) across the visible,
near infra-red and infra-red at resolutions from 10m to 60m. See the [Copernicus
Sentinel 2 data wiki](https://sentiwiki.copernicus.eu/web/sentinel-2) for more
information about the mission and data processing.

The `sentinel_2` folder contains data from a single (relatively cloud free!) scene from
the [Sentinel 2 Level 2A data
product](https://sentiwiki.copernicus.eu/web/s2-products#S2Products-Level-2AProductsS2-Products-L2Atrue)
that was downloaded using the [Copernicus data
browser](https://browser.dataspace.copernicus.eu/). The L2A data product has been
processed to remove atmospheric effects to give modelled surface reflectance values for
each band and also to add some extra calculated layers, such as true colour images (more
on this later!).

A single scene of L2A data covers roughly 110 x 110 km and contains about 1 GB of data,
so has been cropped down to the two study sites (see [below](#cropping-rasters)). The
code below loads the four 10m resolution bands into a single raster for each site by
providing a vector of file names to the `terra::rast` function. It also rescales the
data: remote sensing data is often stored as integer data to save file space and needs
converting to actual values, in this case by dividing by 10000.

```{code-cell} r
# Load the four 10m resolution Sentinel 2 bands for Silwood
s2_silwood_10m <- rast(
    c(
        "data/sentinel_2/R10m/silwood/T30UXC_20250711T110651_B02_10m.tiff",
        "data/sentinel_2/R10m/silwood/T30UXC_20250711T110651_B03_10m.tiff",
        "data/sentinel_2/R10m/silwood/T30UXC_20250711T110651_B04_10m.tiff",
        "data/sentinel_2/R10m/silwood/T30UXC_20250711T110651_B08_10m.tiff"
    ),
)  / 10000

# Name the bands 
names(s2_silwood_10m) <- c("B", "G", "R", "NIR")

# Do the same for the NHM
s2_nhm_10m <- rast(
    c(
        "data/sentinel_2/R10m/nhm/T30UXC_20250711T110651_B02_10m.tiff",
        "data/sentinel_2/R10m/nhm/T30UXC_20250711T110651_B03_10m.tiff",
        "data/sentinel_2/R10m/nhm/T30UXC_20250711T110651_B04_10m.tiff",
        "data/sentinel_2/R10m/nhm/T30UXC_20250711T110651_B08_10m.tiff"
    ),
) / 10000
names(s2_nhm_10m) <- c("B", "G", "R", "NIR")

# Show the resulting object structure
print(s2_silwood_10m)
```

```{admonition} Exercise

The Sentinel 2 dataset directory also includes the band data sampled at 20m and 60m
resolution. The 60m bands are largely aimed at detecting water vapour and clouds, but
the 20 metre bands include red edge, narrow near infrared and short wave infrared data
that can be useful. Use the code above as a template to load Bands 5, 6, 7, 8A, 11 and
12 from the 20 meter directories for each site. Note that the 20m directory also 
contains downsampled data from the 10 metre bands.

The resulting objects should be called `s2_silwood_20m` and `s2_nhm_20m` and the bands 
should be named `RE5`, `RE6`, `RE7`, `NNIR`, `SWIR1` and `SWIR2`.
```

:::{tip} Show solution
:class: dropdown

```{code-cell} r

# Load the six 20m resolution Sentinel 2 bands for Silwood
s2_silwood_20m <- rast(
    c(
        "data/sentinel_2/R20m/silwood/T30UXC_20250711T110651_B05_20m.tiff",
        "data/sentinel_2/R20m/silwood/T30UXC_20250711T110651_B06_20m.tiff",
        "data/sentinel_2/R20m/silwood/T30UXC_20250711T110651_B07_20m.tiff",
        "data/sentinel_2/R20m/silwood/T30UXC_20250711T110651_B8A_20m.tiff",
        "data/sentinel_2/R20m/silwood/T30UXC_20250711T110651_B11_20m.tiff",
        "data/sentinel_2/R20m/silwood/T30UXC_20250711T110651_B12_20m.tiff"
    ),
) / 10000

# Name the bands 
names(s2_silwood_20m) <- c("RE5", "RE6", "RE7", "NNIR", "SWIR1", "SWIR2")

# Load the seven 20m resolution Sentinel 2 bands for the NHM
s2_nhm_20m <- rast(
    c(
        "data/sentinel_2/R20m/nhm/T30UXC_20250711T110651_B05_20m.tiff",
        "data/sentinel_2/R20m/nhm/T30UXC_20250711T110651_B06_20m.tiff",
        "data/sentinel_2/R20m/nhm/T30UXC_20250711T110651_B07_20m.tiff",
        "data/sentinel_2/R20m/nhm/T30UXC_20250711T110651_B8A_20m.tiff",
        "data/sentinel_2/R20m/nhm/T30UXC_20250711T110651_B11_20m.tiff",
        "data/sentinel_2/R20m/nhm/T30UXC_20250711T110651_B12_20m.tiff"
    ),
) / 10000

# Name the bands 
names(s2_nhm_20m) <- c("RE5", "RE6", "RE7", "NNIR", "SWIR1", "SWIR2")
```

:::

## Silmas walk/run route

The last dataset is a [GPS Exchange Format (GPX)
file](https://en.wikipedia.org/wiki/GPS_Exchange_Format) containing the course of the
Silmas fun run and walking route. The GPX format is a commonly used format to record
routes and points from GPS devices. Again, the format holds multiple layers:

```{code-cell} r
print(st_layers("data/Silmas_Fun_Run.gpx"))
```

With GPX files, there are a fixed number of layers. They are not all used in this file:
we have a single linear feature in `tracks` layer, which is the Silmas route, and then
the 425 point features in the `track_points` layer, which are the points along
along that route. We will load the  `tracks` layer:

```{code-cell} r
silmas_route <- st_read(
  dsn="data/Silmas_Fun_Run.gpx", layer="tracks"
)
```

```{code-cell} r
:tags: [remove-cell]

# Dump the objects from this section
source("practical_data_state_functions.r")
save_state()
```
