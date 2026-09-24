---
authors:
- name: Jenna Lawson
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
short_title: Acoustic Indices
---

# Calculating Acoustic Indices in R

This practical introduces acoustic indices: values measured from an acoustic
recording that have been designed to capture the acoustic environment along ecologically
interesting axes. Again can start by cleaning up your R environment and loading the
[required packages](../practical_requirements.md).

```{code-cell} r
# Clear your global environment
rm(list = ls())

#load packages
library(tuneR)
library(seewave)
library(stringr)
library(ggplot2)
library(patchwork)
library(soundecology)
```

## Acoustic indices

We will use R to compare three acoustic indices. We will start by using the first file
from Monkswood to compare the three indices:

```{code-cell} r
audio <- readWave('../data/Acoustics/Monkswood_dawn/20240802_054502.wav')
print(audio)
```

:::{admonition} Mono not stereo

Note that the input audio is a mono, not a stereo file. You will see that the outputs
below include fields for both left and right channels. With stereo inputs, both fields
would be populated but with mono inputs, only the "left" channel has real values and the
right channel fields will be `NA`.

:::

### Acoustic Complexity Index

The acoustic complexity index is calculated using `soundecology::acoustic_complexity()`.
See the function help for more details, but the basic idea is that biotic sounds tend to
be more variable than human generated sounds.[^1]

[^1]: The functions in the `soundecology` package print out quite a lot of processing
      information to the command line, and do not have a `quiet` option. The
      `suppressMessages()` function can be used to mute messages from noisy packages.

```{code-cell} r
# Calculate the ACI
aci_value <- acoustic_complexity(audio, min_freq = 1000, max_freq = 11000)
```

The return value is not just a single number - it is a complex object containing
different parts of the calculation for the index - but the `AciTotAll_left` slot
holds the actual ACI value:

```{code-cell} r
str(aci_value)
```

### Normalized Difference Soundscape Index

Again, see the help on `soundecology::ndsi()` for details but the Normalized Difference
Soundscape Index (NDSI) calculates an index as a ratio of indices of human-generated
(anthrophony) to biological (biophony) acoustic.

```{code-cell} r
# Calculate the NDSI
ndsi_value <- ndsi(audio)
```

Again, the return value is more complex than just a single number and includes the
values of the separate biophony and anthrophony indices:

```{code-cell} r
str(ndsi_value)
```

The NDSI value is then a normalised ratio of those two component.

```{code-cell} r
round(
    (ndsi_value$biophony_left - ndsi_value$anthrophony_left) /
    (ndsi_value$biophony_left + ndsi_value$anthrophony_left),
3)
```

### Bioacoustics Index

The bioacoustics index quantifies the amount of biophony in the signal: see
`soundecology::bioacoustic_index()` for details.

```{code-cell} r
# Calculate the BI
bi_value <- bioacoustic_index(audio, min_freq = 1000, max_freq = 11000)
```

This one actually does only return one value per channel:

```{code-cell} r
str(bi_value)
```

## Parallel processing

Loading all of the individual WAV files and processing each one in turn is:

1. Annoyingly complex, because you have to set up vectors to store results and then
   create a `for` loop to iterate over files and store results. [^2]

2. Slow, because the files are processed one after the other ("in series").

[^2]: You _could_ load all the data into a list and use `lapply`, but WAV files are
      quite big so the memory usage does not scale well to large folders. The `apply()`
      family functions can also be hard to read and debug.

Fortunately, the `soundecology::multiple_sounds` function provides parallel processing
of sound inputs in a directory and outputs the results to a CSV file. The three commands
below run ACI, NDSI and BI for all files in the Monkswood dataset, using all the cores
on your machine except for one (it is usually a good idea not to lock up all of your
cores).

```{code-cell} r
# Calculate acoustic_complexity using all but one core
multiple_sounds(
  directory = "../data/Acoustics/Monkswood_dawn",
  resultfile = "outputs/monkswood_aci.csv",
  soundindex = "acoustic_complexity",
  min_freq = 1000,
  max_freq = 11000,
  no_cores = -1
)
```

```{code-cell} r
multiple_sounds(
  directory = "../data/Acoustics/Monkswood_dawn",
  resultfile = "outputs/monkswood_ndsi.csv",
  soundindex = "ndsi",
  no_cores = -1
)
```

```{code-cell} r
multiple_sounds(
  directory = "../data/Acoustics/Monkswood_dawn",
  resultfile = "outputs/monkswood_bi.csv",
  soundindex = "bioacoustic_index",
  min_freq = 1000,
  max_freq = 11000,
  no_cores = -1
)
```

## Assembling data

We now have three CSV files, one for each acoustic index, each of which contains a lot
extra information that we do not need:

```{code-cell} r
monkswood_bi <- read.csv("outputs/monkswood_bi.csv")
str(monkswood_bi)
```

```{code-cell} r
monkswood_ndsi <- read.csv("outputs/monkswood_ndsi.csv")
str(monkswood_ndsi)
```

```{code-cell} r
monkswood_aci <- read.csv("outputs/monkswood_aci.csv")
str(monkswood_aci)
```

The code below just simplifies these datarames to the information we want: it selects
the file name and index value that is saved as `LEFT_CHANNEL`, and renames the fields
with the index name.

```{code-cell} r
monkswood_bi <- subset(monkswood_bi, select=c("FILENAME", "LEFT_CHANNEL"))
names(monkswood_bi) <- c("file", "bi")

monkswood_ndsi <- subset(monkswood_ndsi, select=c("FILENAME", "LEFT_CHANNEL"))
names(monkswood_ndsi) <- c("file", "ndsi")

monkswood_aci <- subset(monkswood_aci, select=c("FILENAME", "LEFT_CHANNEL"))
names(monkswood_aci) <- c("file", "aci")
```

We can now use `merge` to combine those files into a single dataframe: the function
orders the inputs on the shared `file` field name and then combines the columns. We
_could_ use `cbind` to just join them together but that unsafely assumes that the
results are written out in the same order.

```{code-cell} r
monkswood_indices <- merge(merge(monkswood_bi,monkswood_ndsi), monkswood_aci)
```

Last, we can add a site label and then extract timestamps from the file name:

```{code-cell} r
monkswood_indices$site <- "Monkswood"
monkswood_indices$datetime<-as.POSIXct(
  monkswood_indices$file, format = '%Y%m%d_%H%M%S.wav', tz = 'UTC'
)
monkswood_indices$date <- as.Date(monkswood_indices$datetime)
monkswood_indices$time <- format(monkswood_indices$datetime, format = "%H:%M")

head(monkswood_indices)
```

## Visualising time series

The code below plots time series of each index using `ggplot2` and the `patchwork`
package for combining plots. We start by defining a theme - feel free to modify it to
your own version!

```{code-cell} r
theme_new <- function(base_size = 17, base_family = "Helvetica"){
  theme_classic(base_size = base_size, base_family = base_family) %+replace%
    theme(
      #line = element_line(colour="black"),
      #text = element_text(colour="black"),
      axis.text.x=element_text(colour = "black", size=17),
      axis.text.y=element_text(colour = "black", size=17),
      axis.title=element_text(size=21,face="bold"),
      legend.position = 'top', legend.direction = "horizontal",
      #strip.text = element_text(size=21),
      axis.line = element_line(colour = "black", linewidth = 1, linetype = "solid"),
      legend.key=element_rect(colour=NA, fill =NA),
      panel.grid = element_blank(),
      #panel.border = element_rect(fill = NA, colour = "black", size=0),
      #panel.background = element_rect(fill = "white", colour = "black"),
      #strip.background = element_rect(fill = NA)
    )
}
```

Next we can generate a plot object for each index. Here we use a useful `ggplot2` trick
that allows us to set a list of common `ggplot2` elements we want to apply to each plot
and recycle them. The resulting code is shorter and easier to update. The `group = 1`
syntax is required to tell `ggplot` that all the observations are in the same group and
so the lines should be drawn between all points.

```{code-cell} r
# Define shared ggplot elements
lineplot_elements <- list(
  geom_line(),
  scale_x_discrete(breaks=c("05:45","06:45","07:45", "08:45", "09:45")),
  labs(x = "Time"),
  theme_new()
)

ACI <- ggplot(monkswood_indices, aes(x=time, y=aci , group=1)) +
      labs(y = "ACI") +
      lineplot_elements

NDSI <- ggplot(monkswood_indices, aes(x=time, y=ndsi , group=1)) +
      labs(y = "NDSI") +
      lineplot_elements

BI <- ggplot(monkswood_indices, aes(x=time, y=bi , group=1)) +
      labs(y = "BI") +
      lineplot_elements
```

We can then use the `/` operator from `patchwork` to stack the plots and the
`plot_layout` to remove the duplicated axes:

```{code-cell} r
# Combine the three plots vertically
combined_plot <- ACI / BI / NDSI + plot_layout(axis_titles = "collect")
combined_plot
```

## Comparing sites

The next steps are to compare the acoustic indices from Monkswood to the values for the
Parsonage site.

:::{tip}
Use the recipe above to generate a dataframe `parsonage_indices` containing the acoustic
indices for the Parsonage site.
:::

:::{note} Show solution
:class: dropdown

The code below runs the acoustic processing for the Parsonage data:

```{code-cell} r
# Calculate indices
multiple_sounds(
  directory = "../data/Acoustics/Parsonage_dawn",
  resultfile = "outputs/parsonage_aci.csv",
  soundindex = "acoustic_complexity",
  min_freq = 1000,
  max_freq = 11000,
  no_cores = -1
)
multiple_sounds(
  directory = "../data/Acoustics/Parsonage_dawn",
  resultfile = "outputs/parsonage_ndsi.csv",
  soundindex = "ndsi",
  no_cores = -1
)
multiple_sounds(
  directory = "../data/Acoustics/Parsonage_dawn",
  resultfile = "outputs/parsonage_bi.csv",
  soundindex = "bioacoustic_index",
  min_freq = 1000,
  max_freq = 11000,
  no_cores = -1
)
```

Then the following code is used to combine the outputs into a single `parsonage_indices`
dataframe with the same structure as the `monkswood_indices` dataframe

```{code-cell} r
# Load and combine data
parsonage_bi <- read.csv("outputs/parsonage_bi.csv")
parsonage_ndsi <- read.csv("outputs/parsonage_ndsi.csv")
parsonage_aci <- read.csv("outputs/parsonage_aci.csv")

parsonage_bi <- subset(parsonage_bi, select=c("FILENAME", "LEFT_CHANNEL"))
names(parsonage_bi) <- c("file", "bi")
parsonage_ndsi <- subset(parsonage_ndsi, select=c("FILENAME", "LEFT_CHANNEL"))
names(parsonage_ndsi) <- c("file", "ndsi")
parsonage_aci <- subset(parsonage_aci, select=c("FILENAME", "LEFT_CHANNEL"))
names(parsonage_aci) <- c("file", "aci")
parsonage_indices <- merge(merge(parsonage_bi,parsonage_ndsi), parsonage_aci)

# Add extra data to dataframe
parsonage_indices$site <- "Parsonage"
parsonage_indices$datetime<-as.POSIXct(
  parsonage_indices$file, format = '%Y%m%d_%H%M%S.wav', tz = 'UTC'
)
parsonage_indices$date <- as.Date(parsonage_indices$datetime)
parsonage_indices$time <- format(parsonage_indices$datetime, format = "%H:%M")
```

:::

Once you have created `parsonage_indices`, we can combine the sites into a single
dataframe.

```{code-cell} r
combined_indices <- rbind(monkswood_indices, parsonage_indices)
```

We can then generate plots comparing the two sites through the time series.

```{code-cell} r
ACI <- ggplot(
    combined_indices,
    aes(x = time, y = aci, colour=site, group=site)
  ) +
  labs(y = "ACI") +
  lineplot_elements


NDSI <- ggplot(
    combined_indices,
    aes(x = time, y = ndsi, colour=site, group=site)
  ) +
  labs(y = "NDSI") +
  lineplot_elements

BI <- ggplot(
    combined_indices,
    aes(x = time, y = bi, colour=site, group=site)
  ) +
  labs(y = "BI")+
  lineplot_elements

# Vertically stack the plots, collect the legends and place them above the plot and
# collect the shared X axis labels.
combined_plot <- (ACI / BI / NDSI) +
  plot_layout(guides = "collect", axis_titles = "collect") &
  theme(legend.position = "top")

combined_plot
```

## Statistical comparisons

It doesn't look like there is any obvious temporal patterns in the acoustic indices
above but the two sites do seem to have different average values. We can use boxplots to
compare the average index values between sites:

```{code-cell} r
:tags: [remove-cell]

# Setting graphics size
options(repr.plot.height=4, repr.plot.width=10)
```

```{code-cell} r
# Shared boxplot ggplot2 elements
boxplot_elements <- list(
  geom_boxplot(),
  theme_new(),
  labs(title = "", x = "Site")
)


# Plots for ACI, BI, and NDSI
aci_boxplot <-   ggplot(
    data = combined_indices,
    aes(x = site, y = aci)
  ) +
  labs(y= "ACI Score") +
  boxplot_elements

bi_boxplot <-   ggplot(
    data = combined_indices,
    aes(x = site, y = bi)
  ) +
  labs(y= "BI Score") +
  boxplot_elements

ndsi_boxplot <-   ggplot(
    data = combined_indices,
    aes(x = site, y = ndsi)
  ) +
  labs(y= "NDSI Score") +
  boxplot_elements

# Combine the plots side by side
combined_boxplot <- (aci_boxplot + bi_boxplot + ndsi_boxplot)
combined_boxplot
```

We can use statistical tests to see if there is a significant difference between sites.
The code below uses a two sample Wilcoxon test. This is the non-parametric alternative
to a T test for comparing continuous data from two categories and we are using it here
because there are lots of outliers and fairly big differences in variance between the
two sites.

```{code-cell} r
wilcox.test(aci ~ site, data = combined_indices)
```

```{code-cell} r
wilcox.test(bi ~ site, data = combined_indices)
```

```{code-cell} r
wilcox.test(ndsi ~ site, data = combined_indices)
```
