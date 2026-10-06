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
short_title: BirdNET
---

# Species identification using BirdNET

This practical uses the [BirdNET acoustic classification
model](https://birdnet-web.tucmi.de/) to identify bird species present in the datasets
from their calls.

```{code-cell} R
# Load packages
library(birdnetR)
library(stringr)
library(tidyr)
library(lubridate)
library(hms)
library(dplyr)
library(vegan)
```

## Setting up the model

The package requires the `birdnetR` package but this is a simple wrapper around
the main `birdnet` package, which is written in Python. When you first try and create a
classificition model, the package should automatically setup the required Python
environment. This can take some time and you will see output about downloading Python
packages and the model data.

```{code-cell} R
# Initialise a BirdNET model
model <- birdnet_model_tflite("v2.4")
```

## Running the classifier

The main function is `birdnetR::predict_species_from_audio_file()`, which generates a
dataframe of call data and species identifications from a single audio file.
Unfortunately there is no built in function to handle a set of files, so it useful to
create a small function that processes a file and then adds the filename to the data
frame. This allows us to combine the dataframes later and keep a record of which call
came from which file.

```{code-cell} R
run_one_file <- function(file){
  #' A wrapper function to process a file and add the filename into the call
  #' prediction dataframe.
  preds <- predict_species_from_audio_file(model, file)

  # Add filename as a new column
  preds$file <- basename(file)

  return(preds)
}
```

We can now run the classifier on the Monkswood and Parsonage acoustic files. Here we are
using `lapply` to run the same function (`run_one_file`) on each filename. This returns
a list of prediction data frames and we can the use `do.call` to run `rbind` on all of
the dataframes in the list.

```{code-cell} R
# First run Monkswood
monkswood_files <- list.files(
    "../data/acoustics/Monkswood_dawn",
    pattern = "\\.wav$",
    full.names = TRUE
)

# Loop through each WAV file and run predictions
monkswood_predicts <- lapply(monkswood_files, run_one_file)
# Combine into one dataframe
monkswood_predicts <- do.call(rbind, monkswood_predicts)
monkswood_predicts$site <- "monkswood"

parsonage_files <- list.files(
    "../data/acoustics/Parsonage_dawn",
    pattern = "\\.wav$",
    full.names = TRUE
)

# Loop through each WAV file and run predictions
parsonage_predicts <- lapply(parsonage_files, run_one_file)
# Combine into one dataframe
parsonage_predicts <- do.call(rbind, parsonage_predicts)
parsonage_predicts$site <- "parsonage"
```

## Building the dataset

We can now combine the two sets of predictions into a single dataframe and extract the
time. The time data here is tricky:

* We are not interested in the date and time, but just the time itself, to look at when
  birds are singing during the diel cycle. So we use the `hms()` function to get a pure
  time value rather than a date time.
* We need to extract the time components from the file name. The code here uses regular
  expressions to extract the data. You can look at a [detailed
  breakdown](https://regex101.com/r/gYuXBU/2) of the regular expression, but the basic
  explanation is that the code looks for three adjacent groups of characters, each of
  which containd exactly two digits (`([0-9]{2})`). Those three groups must have an
  underscore before them (a 'lookbehind' pattern: `(?<=_)`) and be followed by the
  `.wav` file extension (a `lookahead` pattern: `(?=.wav)`). Each of the three groups
  can be extracted to grab the three time components.

  There are certainly easier ways of getting at this data, but once you start working in
  data science, it is _really_ worth understanding the power of regular expressions and
  their ability to parse structure text for you.

```{code-cell} R
# Output the predictions
predictions <- rbind(monkswood_predicts, parsonage_predicts)

# Extract the time components
regex <- "(?<=_)([0-9]{2})([0-9]{2})([0-9]{2})(?=.wav)"
hour <- str_extract(predictions$file, regex, group = 1)
minute <- str_extract(predictions$file, regex, group = 2)
second <- str_extract(predictions$file, regex, group = 3)

# Generate a timestamp in a column
predictions$time <- hms(
    hour=as.numeric(hour), minute=as.numeric(minute), second=as.numeric(second)
)

write.csv(predictions, "outputs/birdnet_predictions.csv")
```

## Exploring the predictions

The first thing to note is that the full set of predictions includes chunks of audio
where no call was detected and also call detections with low call identification
confidence:

```{code-cell} R
head(predictions)
```

We can drop the audio with no calls or low confidence:

```{code-cell} R
predictions <- drop_na(predictions)
predictions <- subset(predictions, confidence > 0.7)
```

### Overall species calling counts

First, we can look at which species are reliably detected and how commonly they call
across the two sites.

```{code-cell} R
# Calculate number of calls per species per site
call_counts <- predictions %>%
  group_by(site) %>%
  count(common_name, sort=TRUE)

# Plot call counts by species, stacking by site.
ggplot(call_counts, aes(fill=site, y=n, x=reorder(common_name, n))) +
  geom_bar(position="stack", stat="identity")+
  coord_flip() +# Changes the axes
  labs(y = "Frequency")+
  labs(x = "Species")
```

### Species community matrix

We can use the call counts to build a community matrix for the two sites. This basically
rearranges the data into a site by species matrix, filling in zeros for species that are
absent from a site. It is easier to see the results by using `t()` to transpose the
community matrix:

```{code-cell} R
call_counts_matrix <- xtabs(n ~ site + common_name, call_counts)

# Show a transposed species by site matrix
t(call_counts_matrix)
```

We can visualise presence absence by converting that matrix back into a data frame:

```{code-cell} R
presence_absence <- as.data.frame(call_counts_matrix)
presence_absence$present <- ifelse(presence_absence$Freq > 0, "present", "absent")

# Create the plot, where green is present and red is absent
ggplot(presence_absence, aes(x = site, y = common_name, fill = present)) +
  geom_tile(color = "white") +
  scale_fill_manual(values = c("red3", "limegreen")) +
  theme_classic() +
  theme(axis.text.y = element_text(size = 6),
        axis.text.x = element_text(angle = 0, hjust = 0.5, size = 12),
        legend.position = "none", panel.grid = element_blank()) +
  labs(x = "Site", y = "Species") +
  theme(axis.title = element_text(size = 14),
        strip.text = element_text(size = 12))
```

### Species diversity indices

We can calculate species diversity indices using the `vegan` package to look at
differences between sites. Note that here we are assuming that call count is a
reasonable proxy for the number of individuals of species at the sites.

```{code-cell} R
# Calculate diversity and species number in each site from the community matrix
site_diversity <- data.frame(
    site = rownames(call_counts_matrix),
    shannon_diversity = diversity(call_counts_matrix),
    n_species = specnumber(call_counts_matrix)
)

site_diversity
```

### Temporal patterns

We can group calls by the time of the recording (not the actual time of the call itself)
in order to look at temporal trends of call activity through the dawn chorus:

```{code-cell} R
# The summarise command creates a new activity field containing the count of calls
# within site and time groupings
activity_data <- predictions %>%
  group_by(site, time) %>%
  summarise(activity = n(), .groups = 'drop')
```

We can then visualise the call activity through time:

```{code-cell} R
activity_plot <- ggplot(
    activity_data, aes(x = time, y = activity, colour=site, group=site)
  ) +
  geom_point() +
  geom_smooth() +
  labs(y = "Activity") +
  labs(x = "Time")

activity_plot
```
