---
authors:
- name: Tijmen de Lorm
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
short_title: Camera trap analysis
---

# Using camera traps to estimate species densities without individual recognition

This webpage provides one long self-paced practical that provides instructions to
estimate the densities of terrestrial mammals using camera trap data, as part of the
Ecological and Evolutionary Data Science. This practical uses [the R programming
language](https://cran.r-project.org).

## Aims of the the practical

The practical aims to:

- Introduce you to how to process camera trap data
- Give hands-on practice in identifying animals from camera trap videos
- Give hands-on practice in shared, consistent data-entry
- Introduce the REST Model, the logic behind it, and how to apply it to get animal
  densities for Silwood Park

## How to use the practical

This practical is self-paced: work through it at your own speed and ask questions as
needed! It builds up and then saves a set of datasets that you can use in your
assessment.

1. Create a new R script file to run the practical analyses.
2. Copy example code from the practical into your script and run it from your script.
3. Check you understand what the code is doing - add extra comments, ask questions.

## Required packages

Before you start this practical, it is important to download and install
[Xcode Command Line
Tools](https://developer.apple.com/documentation/xcode/command-line-tools)
(for macOS users) or
[Rtools](https://cran.r-project.org/bin/windows/Rtools/) (for Windows
users). For windows users, check what appropriate version of Rtools is,
and download and install it. For mac users, the easiest way to install
this is by opening the terminal app, copy-pasting
`xcode-select --install`, and pressing enter. Follow the instruction to
install the software.

**We will need to download and load following packages :**

```{code-cell} r
:tags: [remove-stderr]

# # used to read the Excel datasheet
# install.packages("readxl")
# # used to wrangle data
# install.packages("dplyr")
# # used for plotting
# install.packages("ggplot2")
# # Used to install the ctrest package from github
# install.packages("pak")
# pak::pak("YoshihiroNakashima/ctrest@v1.0")

library(ctrest)
library(dplyr)
library(ggplot2)
library(readxl)
```

## Datasets

We will use the camera trap data from the camera traps you set up in Silwood. We need to
identify the species for each detection.

We have already collected the camera traps and structured the data properly[^1]. You can
find it in
[Box](https://imperialcollegelondon.box.com/s/wbhvsjolrfrtdm2v8xwq75ljy3u85ttv), in the
folder:

`Silwood_Park_Sensor_Data/CameraTraps/2026`

The folders are ordered by plot. As you can see, the filenames contain the plot, date
and time of the detection, such as:

`PLOT113__2026-07-20__11-29-46(1).AVI`

When we collected the camera traps, we used the R package camtrapR to automatically read
the date and time of each file, and rename them accordingly. This results in file names
that make downstream data analysis much easier, instead of just being named, for
example, "IMG_001.AVI", which camera traps default to.

We then read in all the filenames and put them in a dataframe that will allow analysis
using the Random Encounter and Staying Time (REST) model, which you can find in the 2026
camera trap folder (`REST_data_WINTER_2026.csv`).

## The REST model

We use the [REST
model](https://besjournals.onlinelibrary.wiley.com/doi/10.1111/2041-210x.70248) to
estimate the density of different animal species, in terms of individuals per km². The
REST model assumes that animals move randomly with respect to the camera, so that the
total time animals spend in front of the camera depends on how many animals there are.
REST measures that time, and uses it to work out how many animals must be around to
produce it. For each species, the model needs four pieces of information:

1. **Passes.** The number of times animals entered the *focal area* (the triangles we
   set up in front of each video) in each video.
1. **Staying time.** How long each animal spent inside the focal area. Some animals are
   still in view when the video ends, so their staying times are *censored*, and the
   model accounts for this.
1. **Effort.** The number of days the camera was operating.
1. **Activity level.** The proportion of the day the species is active, estimated from
   the times of day of the detections. A nocturnal animal is only available to be
   detected for part of each 24 hours, which affects the density estimate.

Conceptually, the estimate combines these like this:

> density ≈ (passes × mean staying time) / (focal area × effort × proportion of time active)

The key advantage is that **individual animals do not need to be recognised**, on which
capture-recapture models rely. While this is feasible for some species with clear
individual markings (think of leopards or tigers), it is pretty tricky for species in
which individual recognition is not reliable (foxes or rabbits).

## Identifying species in the videos

The datasheet in the Box folder contains the relevant variables we need for each video.
Open the Excel workbook and look at all the column names and descriptions in the
`detection_datasheet`.

We will share this datasheet to log all animal identifications. As a group, ID all
videos, taking note of all parameters necessary for the REST models in the relevant
columns. A few house rules:

- If a video contains more than one individual, insert a new row, copy paste the
  context, and use one row per individual. So, let's say, a video contains two roe deer,
  one roe deer spends 10 seconds in the focal area, and one spends 5 seconds in the
  focal area, and both leave the camera's field of view before the end of the video:
- For the species naming conventions, refer to the *Taxa* sheet. Since we are all using
  the same sheet, it is especially important to be consistent with species names! If you
  find a species that isn't on the list yet, you can add it to the *Taxa* sheet.
- Try to identify species to species level. When that is impossible, try to be as
  specific as possible.

When you have finished ID'ing all species from your station, let a GTA know. When all
groups are finished, we can start analysing the data.

## Loading and inspecting the data

Download and save the workbook on your computer. Then load the datasheet into R. In the
following code block, change the path to wherever you have saved the datasheet:

```{code-cell} r
rest_data <- "../data/CameraTraps/REST_data_SUMMER_2026.xlsx"

detection_data <- readxl::read_xlsx(
    rest_data,
    sheet = "detection_data",
    skip = 5
)
station_data <- readxl::read_xlsx(
    rest_data,
    sheet = "Locations"
)

head(detection_data)
```

```{code-cell} r
head(station_data)
```

When you have loaded the data, let's inspect it.

Check if people used the same species names consistently, and look for any typos:

```{code-cell} r
# Check species names
unique(detection_data$Species)
```

If the names are consistent, you can proceed. If not, you can change
names in R:

```{code-cell} r
detection_data$Species[
    detection_data$Species == "INCORRECT_SPECIES_NAME"
] <- "CORRECT_SPECIES_NAME"
```

Now we can look at some patterns in the data. Let's order species by number of
detections.

```{code-cell} r
species_detections <- detection_data %>%
    count(Species) %>%
    arrange(desc(n))

print(species_detections)
```

```{tip} Tasks

After the hashtags, annotate the code with what each line does.

- What is the mammal species richness?
- Which species has the most detections?
- What does NA mean in this context?
```

## Formatting the data for REST

The REST model requires a specific data input, in which species pass- and
staying-time-counts are aggregated per station. The ctrest package has a function that
does this automatically.

```{code-cell} r
station_data_rest <- format_station_data(
    detection_data = detection_data,
    station_data = station_data,
    col_name_station = "Station",
    col_name_species = "Species",
    col_name_y = "Nfocal",
    model = "REST"
)

head(station_data_rest)
```

Look at the resultant dataframe. What do the columns in `station_data_rest` mean?

To estimate density, the model needs to know how long each station was active for. We do
this using the `add_effort` function, which computes the number of days the camera was
active for based on the first and last detection.

```{code-cell} r
station_effort_rest <- add_effort(
    detection_data = detection_data,
    station_data_formatted = station_data_rest,
    col_name_station = "Station",
    col_name_datetime = "DateTime",
    col_name_term = "Term", # The sampling campaign, called "Term" in the detection data
    plot = TRUE # automatically plots sampling effort
)
```

Investigate the plot. Is sampling effort consistent between stations? What could be
causing differences?

```{code-cell} r
stay_data <- format_stay(
    detection_data = detection_data,
    station_data = station_data,
    col_name_station = "Station",
    col_name_species = "Species",
    col_name_stay = "Stay",
    col_name_cens = "Cens"
)

head(stay_data)
```

The REST model builds an activity curve from the times of day at which a species is
detected. If one fox spends an hour moving back and forth in front of a camera at 2 am,
it produces many detections at 2 am, and the curve would overstate how active foxes are
at that hour. To avoid this, `format_activity()` treats detections of the same species
at the same station as independent only when they are separated by a cut-off time
(`indep_time`). The cut-off is somewhat arbitrary and is usually set to 30 minutes.

```{tip} Tasks
What are the risks of setting `indep_time` too short, and too long?
```

```{code-cell} r
activity_data <- format_activity(
    detection_data = detection_data,
    col_name_station = "Station",
    col_name_species = "Species",
    col_name_datetime = "DateTime",
    indep_time = 30 # minimum minutes between independent detections
)

head(activity_data)
```

We can compare the number of rows before and after `format_activity()` to see how many
observations have been removed:

```{code-cell} r
nrow(detection_data)
```

```{code-cell} r
nrow(activity_data)
```

The function above has also converted detection timestamps from datetimes to the angular
unit of radians. This might seem a bit odd, but datetimes express a point in linear time
and the REST model looks at species activity through the daily cycle. Radians are here
used to express time of day: midnight = $0$ = $2\pi$, 06:00 = $\pi/2$, 12:00 = $\pi$ and
18:00 = $3\pi/2$.

## Running the REST model

Now the data is in the format that the REST model functions expect, so we can run it.

A few variables of interest:

- `formula_stay`: if you suspect the time an animal spends in front of
  the camera is affected by variables in your dataset, you can include
  them here. For example, maybe prey animals move faster through
  exposed areas.
- `formula_density`: if the stations have covariables that you think
  have an impact on species density, you can include them here. For
  example, if you expect a species to be affected by canopy cover, you
  could include that in the model.
- `focal_area`: how big is the triangle we set up in front of the
  camera?
- `target_species`: this function only runs it for one species. We can
  start with `roe_deer`, but feel free to look at other species.

```{code-cell} r
result_rest <- bayes_rest(
    formula_stay = Stay ~ 1,
    formula_density = ~1, # density model (no LHS)
    # formula_enter = ~1, # required argument; ignored for REST
    station_effort_data = station_effort_rest,
    stay_data = stay_data,
    activity_data = activity_data,
    # random_effect_stay = NULL,
    activity_estimation = "mixture", # "kernel" or "mixture"
    bw_adj = 1.0, # bandwidth adjustment for kernel estimation
    stay_family = "lognormal", # from bayes_stay_selection output
    focal_area = 3.125, # focal area in m²
    iter = 5000,
    warmup = 1000,
    chains = 3,
    thin = 2,
    model = "REST",
    all_comb = FALSE, # TRUE = compare all density covariate subsets
    target_species = "roe_deer"
)

print(result_rest)
```

The model output contains a lot of information, mostly related to how good the model
fits the data we fed it. Most important is whether the Rhat value is below 1.1 – this is
a measure of how well the Bayesian model fit the data.

The value we are most interested in is the density. This gives you the model's estimate
of the number of individuals of your species per km². Silwood Park is approximately 0.8
km². Does the estimate of the number of roe deer seem realistic? Does it align with what
you have seen on campus?

The REST model also considers when each species is active. To do this, it fits an
activity curve that we can manually inspect as well. Look at the plot, when does roe
deer activity peak?

```{code-cell} r
colnames(result_rest$activity_curve)[4] <- "lower"
colnames(result_rest$activity_curve)[6] <- "upper"

ggplot(result_rest$activity_curve, aes(x = x)) +
    geom_ribbon(
        aes(ymin = lower, ymax = upper),
        fill = "steelblue",
        alpha = 0.3
    ) +
    geom_line(aes(y = mean), colour = "steelblue") +
    scale_x_continuous(
        name = "Time of day",
        breaks = c(0, pi / 2, pi, 3 * pi / 2, 2 * pi),
        labels = c("00:00", "06:00", "12:00", "18:00", "24:00")
    ) +
    ylab("Activity density") +
    theme_bw()
```

## Multi-species model

We can also fit one model for multiple species. The benefit of this method is that the
model can borrow strength from well sampled species for poorly sampled species -- it
uses information it 'learns' from common species, such as roe deer, and uses them for
species with fewer detections, such as foxes. (This code may take a few minutes to run)

```{code-cell} r
result_multi <- bayes_rest_multi(
    formula_stay = Stay ~ 1,
    formula_density = ~1,
    formula_enter = ~1,
    station_effort_data = station_effort_rest,
    stay_data = stay_data,
    activity_data = activity_data,
    activity_estimation = "mixture",
    stay_family = "lognormal",
    C = 10,
    focal_area = 3.125,
    iter = 1000,
    warmup = 1000,
    chains = 4,
    thin = 4,
    model = "REST",
    target_species = c("rabbit", "roe_deer", "muntjac", "fox", "badger")
)

print(result_multi)
```

## Comparing density estimates to raw detections

Let's compare the densities of species to the raw number of detections of species we
looked at earlier in the practical. First, we extract the density estimates from the
model output and combine them with the detection counts:

```{code-cell} r
# Find the posterior summary table in the model output
est <- Filter(
    function(x) is.data.frame(x) && any(grepl("^density\\[", x$Variable)),
    result_multi
)[[1]]

# Keep the density estimate for each species
density_est <- est %>%
    filter(grepl("^density\\[", Variable)) %>%
    select(Species, mean, lower, upper)

# Combine with the number of detections per species, and express
# both as a share of the total
comparison <- species_detections %>%
    filter(Species %in% density_est$Species) %>%
    inner_join(density_est, by = "Species") %>%
    mutate(
        prop_detections = n / sum(n),
        prop_density = mean / sum(mean)
    )

print(comparison)
```

Now plot the share of detections against the share of estimated density. The dashed line
shows where the two would be identical:

```{code-cell} r
ggplot(
    comparison,
    aes(x = prop_detections, y = prop_density, label = Species)
) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    geom_point(size = 3) +
    geom_text(vjust = -0.8) +
    labs(
        x = "Share of detections",
        y = "Share of estimated density"
    ) +
    theme_bw()
```

```{tip} Tasks
Does the ratio between species' densities differ from the ratio between species' number
of detections? Which species fall above or below the dashed line? What could be causing
that?

Think about what type of questions you can answer with these data. What kind of
covariables can you include in models for density and staying time? What could impact
species' activity patterns?
```

[^1]: You can see the [pre-processing details](./preprocessing.md): we basically just
    give the image files unique names and generate the template for collecting detection
    data.
