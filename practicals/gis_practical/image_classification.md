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

# Image classification

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

We already have the CEH Land Cover map, but we may be able to get a better local model
of land cover by classifying the Sentinel 2 data. Image classification is the process of
taking spectral data from an image and identifying particular spectral signatures
(combinations of values in the different bands) with a land cover category. You _can_
classify simple RGB images, but it is often better to use data with more spectral bands:
as we saw with the false colour infrared image, some bands are great at picking out
particular features.

## Unsupervised classification

Unsupervised classification tries to extract clusters of spectral signatures from the
data. There are many approaches, but the basic aim of the algorithms is to try and find
sets of points in the image that have similar spectral signatures.

Here we will use the base R `stats::kmeans` function to carry out k-means clustering on
the data. The `k` of the k-means is the number of clusters we want to identify, and here
we are letting the algorithm pick 10 random starting points from with the image spectra
and then iterating to try and find stable sets of clusters. It then repeats that process
with different starting choices and returns a classification across all of the runs.

```{code-cell} r
# We need to convert the raster data into a data frame giving the 
# spectral signature of each cell
values <- as.data.frame(s2_silwood_10m)
head(values)
```

```{code-cell} r
# Now we can run the clustering
n_cats <- 6
s2_kmeans <- kmeans(
  values, centers=n_cats, iter.max = 500, nstart = 5, algorithm="Lloyd"
)

# We can now take the cluster attribute from the output and put those values
# back into a 10m resolution raster
s2_kmeans_map <- rast(s2_silwood_10m, nlyr=1)
values(s2_kmeans_map) <- s2_kmeans$cluster
```

Now that we have the map, we can add labels and category names, as we did above for the
CEH dataset.

```{code-cell} r


labels <- data.frame(ID=1:n_cats, category=paste0("Category_", 1:n_cats))
#colours <- data.frame(ID=1:n_cats, colours=hcl.colors(n_cats, "Dark 2"))

colours <- data.frame(ID=1:n_cats, colours=carto_pal(n_cats, "Safe"))

levels(s2_kmeans_map) <- labels
coltab(s2_kmeans_map) <- colours

plot(s2_kmeans_map)
```

## Supervised classification

The classes from an unsupervised classification are a purely statistical construction:
they often do identify meaningful land cover types, but they need to be interpreted and
it is common to re-run the process with different numbers of classes, or to merge
classes that identify very similar regions.

The alternative of supervised classification avoids that by starting with a training
dataset of sites with known categories. The spectral signatures of those sites can then
be used to assign other sites to classes based on their similarity to the training data.
This does mean that you need to put together a training dataset in one of two ways:

* physically exploring the location with a GPS and assigning classes based on field data
  ("ground truthing"), or
* selecting points from the imagery that visually belong to a particular class
  ("digitization").

Here we use a training set drawn from inspecting the imagery, saved as a set of X and Y
point coordinates and the land cover category at that point. There are multiple sites
for each class, giving a distribution of signatures associated with each class.

```{code-cell} r
# Load the classification data and convert it to an SF point dataset
training_sites <- read.csv("data/S2_classification_data.csv")
training_sites <- st_as_sf(training_sites, coords=c("x","y"), crs="EPSG:27700")

# Plot the data over the top of an aerial image. This is a bit of a hack
# as it plots the vector data first to get the legend, then plots the aerial
# photo over the top and then the training sites _again_.
plot(training_sites, reset=FALSE)
plotRGB(silwood_aerial, add=TRUE)
plot(training_sites, add=TRUE)

# Show a table of the number of training sites for each category.
table(training_sites$category)
```

We can then extract the spectral signatures at each of those sites to give a spectral
training dataset to use in classification.

```{code-cell} r
# Extract a data frame of band values at each training site and add the
# category field to the dataset.
training_spectra <- extract(s2_silwood_10m, training_sites, ID=FALSE)
training_spectra$category <- training_sites$category
```

We will use a regression tree model using the `rpart::rpart` function to assign spectral
signatures to classes. A regression tree finds critical values in the different bands
that separate different classes and provides a simple decision tree based on the
training data that can then be used to classify the whole image.

```{code-cell} r
# Fit a regression tree of the land cover category as a function of the bands
s2_class_model <- rpart(
  category ~  B + G + R + NIR + RE5 + RE6 + RE7 + NNIR + SWIR1 + SWIR2,
  data = training_spectra, method = 'class', minsplit = 5
)

# Show the regression tree.
print(s2_class_model)
```

The model can then be used to predict values for all of the pixels. The resulting
raster has one layer for each land cover type that gives the probability that the pixel
is in that class.

```{code-cell} r
# Generate the predictions for the whole map
s2_class_probability <- predict(s2_silwood_10m, s2_class_model)

# Plot 3 of the probability layers
plot(s2_class_probability[[1:3]], nc=3)
```

We can convert it into a land cover map by assigning each pixel to the class where it
has the highest probability.

```{code-cell} r
# Find the layer with the highest probability. The index of that code gives the 
# associated land  cover type
s2_class_map <- which.max(s2_class_probability)

# Assign level labels to the index codes.
levels(s2_class_map) <- data.frame(id=1:7, class=names(s2_class_probability))
plot(s2_class_map, col=carto_pal(7, "Safe"))
```

It is good practice to partition your training dataset to then test the accuracy of the
classification - can your model successfully predict the classes of the data retained in
the test partition. There are a lot of approaches to this (k-fold cross validation is a
common one) but these are outside the scope of this practical.

:::{tip} Generating training data
:class: dropdown

Digitizing training data is one of those tasks where it may be easier to use a dedicated
GIS program like GIS. This is mostly because it is easier to zoom in on an image to
precisely place the training locations.

However, you can use R to create training datasets. The code below defines a function
that can be used to generate a training data frame and then extend it with training data
for different classes.

```{code-cell} r
:tags: [skip-execution]

pick_training_sites <- function(category, df = NULL) {
    #' Function to add training data locations by clicking on a displayed map.
    #' 
    #' The function returns a data frame with the X and Y coordinates of the clicked
    #' points and a category field giving the `category` label for with the points.
    #' Press 'Escape' to finish collecting points and return a dataframe of coordinates.
    #' The returned dataframe for one category can be passed back into the `df`
    #' argument to append sites for a new category to the existing data. 

    # Pick the points from a plotted GIS map
    xy <- draw("points", pch=4)
    # Convert the selected coordinates to a dataframe and add the category label
    new_data <- as.data.frame(crds(xy))
    new_data$category <- category

    # Return the new_data appended to any existing data
    return(rbind(df, new_data))
}

# Plot the image
plotRGB(silwood_aerial)

# Build up the training set by clicking on the image and then pressing
# "escape" to finish defining one class and to move onto the next category
df <- pick_training_sites("Urban")
df <- pick_training_sites("Grassland", df=df)
df <- pick_training_sites("Water", df=df)
df <- pick_training_sites("Silwood Lake", df=df)
df <- pick_training_sites("Bare Ground", df=df)
df <- pick_training_sites("Woodland", df=df)
df <- pick_training_sites("Road", df=df)

# Export the data
write.csv(df, "data/S2_classification_data.csv", row.names=FALSE)
```

:::

```{code-cell} r
:tags: [remove-cell]

# Dump the objects from this section
save_state()
```
