---
authors:
- name: Vivienne Groner
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
short_title: Microclimate
---

# Microclimate sensor data analysis in R

This tutorial is designed for ecologists and environmental scientists with basic R
skills. You will learn how to analyze microclimate data collected with an EasyLog USB
datalogger, focusing on loading, cleaning, and exploring, environmental time series
data.

By the end of this tutorial, you will be able to:

* Load a single EasyLog sensor CSV file
* Clean your dataset and check for data quality issues
* Identify and flag potential outliers using different methods
* Visualize microclimate trends over time
* Perform basic statistical summaries
* Export cleaned data for further analysis

At the end, an optional extension shows how to compare data from multiple sensors and
add habitat classification data.

The skills and methods you learn here apply broadly to other environmental
datasets.

## Load required libraries

You will use several R packages that simplify data manipulation, date handling,
and plotting:

```{code-cell} r
:tags: [remove-stderr]

library(ggplot2)
library(dplyr)
library(janitor)     # for cleaning column names and general tidying
library(patchwork)   # for combining plots
```

## Set up file paths

In this practical, we expect to find the sensor data and habitat classification data in
the directories described in the [practical requirements](../practical_requirements.md)
notes.

More generally, storing file paths in variables makes your code easier to update and
maintain. If you move your data later, you only need to change the code in one place.

```{code-cell} r
# Define the full paths to the folder containing your sensor data and to the
# metadata file
sensor_data_folder <- "../data/Microclimate/2025"
sensor_metadata_file <- "../data/SensorSites/2025/sensor_sites_2025.csv"

# Get the paths to all of the TXT files containing climate data from this year.
# We will use just one file in the main practical, and use all of the files only in
# the optional extension at the end.
microclimate_files <- dir(
  path=sensor_data_folder, pattern="*.txt",
  recursive = TRUE, full.names = TRUE
)

# Check what files we found
print(microclimate_files)

# Start with the first logger. Change this index to work with a different logger.
logger_file <- microclimate_files[1]

if (is.na(logger_file)) {
  stop("No sensor TXT files were found. Check the sensor_data_folder path.")
}

print(logger_file)
```

## Read sensor data

Sensor data often contain inconsistencies such as mixed date formats or data types,
which can cause issues during analysis. The format of the output files from the EasyLog
sensors is also odd - there is the serial number field that only uses the first row.
However, the main data is always in the first five columns. We can use the code below to
compile the data into a data frame.

```{code-cell} r
# Load one TXT file, handling Windows file encoding
logger_data <- read.csv(logger_file, encoding = "latin1")

# EasyLog's first column name contains the sensor ID. R converts a hyphen to a dot,
# so convert that dot back to a hyphen.
sensor_id <- sub(".", "-", names(logger_data)[1], fixed = TRUE)

# Keep the five measurement columns and give them consistent names
logger_data <- logger_data[, 1:5]
names(logger_data) <- c(
  "observation_id", "datetime", "temperature", "humidity", "dewpoint"
)

logger_data$sensor_id <- sensor_id

# Convert text fields to the types required for analysis
logger_data$datetime <- as.POSIXct(logger_data$datetime)
logger_data$temperature <- suppressWarnings(as.numeric(logger_data$temperature))
logger_data$humidity <- suppressWarnings(as.numeric(logger_data$humidity))
logger_data$dewpoint <- suppressWarnings(as.numeric(logger_data$dewpoint))
```

We should now be able to preview the data

```{code-cell} r
print(head(logger_data))
print(tail(logger_data))
```

## First inspection of the data

Before doing any statistics, inspect the raw data and check the time range and missing
values.

```{code-cell} r
summary(logger_data[c("temperature", "humidity", "dewpoint")])

data.frame(
  variable = c("datetime", "temperature", "humidity", "dewpoint"),
  missing = c(
    sum(is.na(logger_data$datetime)),
    sum(is.na(logger_data$temperature)),
    sum(is.na(logger_data$humidity)),
    sum(is.na(logger_data$dewpoint))
  )
)

range(logger_data$datetime, na.rm = TRUE)
```

Plot temperature over time:

```{code-cell} r
ggplot(logger_data, aes(x = datetime, y = temperature)) +
  geom_line(color = "steelblue") +
  geom_point(alpha = 0.25) +
  labs(
    title = paste("Temperature over time:", sensor_id),
    x = "Datetime",
    y = "Temperature (°C)"
  ) +
  theme_minimal()
```

If you see values far outside the main cluster, they might be outliers or errors.
However, remember: **not all extreme values are mistakes**, a sudden heat spike could be
real. Always think carefully before you remove any points from your data set.

### Quick detour: Comparison to station data

Go online to explore historic weather data:

* [UK Met office WOW](https://wow.metoffice.gov.uk/)
* [Time and Date historic weather](https://www.timeanddate.com/weather/@2656992/historic)

Look for temperature time series covering your measurement period. Compare:

* Are the daily patterns similar?
* Is the temperature range realistic for the time of year?
* Were any extreme values recorded?

If you find differences between your data and the station observations data,
what could be possible reasons?

## Identifying outliers

There are several ways to identify outliers. The table below summarizes three
common methods with their pros and cons.

You already did the visual inspection;
Z-score and Interquartile Range (IQR) method are described in more detail below.

Do you expect to get the same outliers with different methods?

<!-- rumdl-disable MD069 -->

:::{list-table}
:header-rows: 1

* * Method
  * How It Works
  * Pros
  * Cons
* * Visual
  * Use boxplots or scatterplots to spot unusual points visually.
  * Quick, intuitive, and easy to spot obvious anomalies.
  * Not systematic; subjective; may miss subtle outliers.
* * Z-score
  * Calculate how many standard deviations a value is from the mean.
  * Fast to compute; effective for bell-shaped (normal) data.
  * Misleading for skewed data or when extreme values distort mean and SD.
* * Inter-quartile range (IQR)
  * Flags points outside 1.5×IQR below Q1 or above Q3 percentiles.
  * Robust to skewed data; less influenced by extreme values.
  * May label valid extreme values as outliers, especially with small sample sizes.

:::

<!-- rumdl-enable MD069 -->

### Z-score method for outlier detection

The Z-score measures how far each value is from the mean, in units of standard
deviations:

$$
Z = \frac{\text{value} - \text{mean}}{\text{standard deviation}}
$$

* A Z-score of 0 = exactly the mean.
* A Z-score of +2 = two standard deviations above the mean.
* A Z-score of –3 = three standard deviations below the mean.

For normally distributed data, 99.7% of values lie within ±3 standard deviations.
Values beyond this range are flagged as potential outliers.

```{code-cell} r
logger_data_Z <- logger_data %>%
  mutate(
    temperature_Z = (
      (temperature - mean(temperature, na.rm = TRUE))
      / sd(temperature, na.rm = TRUE)
    ),
    temp_outlier_Z = abs(temperature_Z) > 3
  )

# Check what that added
print(head(logger_data_Z))
```

### Interquartile Range (IQR) Method for Outlier Detection

The IQR method focuses on the spread of the middle 50% of the data. It calculates the
difference between the 25th percentile ($Q_1$) and the 75th percentile ($Q_3$), called
the interquartile range (IQR). Values falling below $Q_1 - 1.5 \times IQR$ or above
$Q_3 + 1.5 \times IQR$ are considered potential outliers.

```{code-cell} r
# Use the IQR method to flag temperature outliers
logger_data_IQR <- logger_data %>%
  mutate(
    temp_Q1 = quantile(temperature, 0.25, na.rm = TRUE),
    temp_Q3 = quantile(temperature, 0.75, na.rm = TRUE),
    temp_IQR = temp_Q3 - temp_Q1,
    temp_outlier_IQR = if_else(
      temperature < (temp_Q1 - 1.5 * temp_IQR) | temperature > (temp_Q3 + 1.5 * temp_IQR),
      TRUE, FALSE, missing = FALSE
    ),
  )

# Check what that added
print(head(logger_data_IQR))
```

## Visualize temperature over time with outliers highlighted

```{code-cell} r
:tags: [remove-cell]

options(repr.plot.width=12, repr.plot.height=10)
```

```{code-cell} r
# Plot using IQR outlier flags
p1 <- ggplot(
  logger_data_IQR,
  aes(x = datetime, y = temperature, color = temp_outlier_IQR)
) +
  geom_point() +
  geom_line() +
  scale_color_manual(values = c("black", "red")) +
  labs(
    title = "Temperature over Time (IQR Outliers)",
    x = "Datetime",
    y = "Temperature (°C)",
    color = "Outlier"
  ) +
  theme_minimal()

# Plot using Z-score outlier flags
p2 <- ggplot(
  logger_data_Z,
  aes(x = datetime, y = temperature, color = temp_outlier_Z)
) +
  geom_point() +
  geom_line() +
  scale_color_manual(values = c("black", "blue")) +
  labs(
    title = "Temperature over Time (Z-score Outliers)",
    x = "Datetime",
    y = "Temperature (°C)",
    color = "Outlier"
  ) +
  theme_minimal()

# Combine plots side-by-side
p1 + p2 + plot_layout(ncol = 1)
```

## Clean and summarize the logger data

Choose one of the outlier methods and make a cleaned copy. Here we keep the IQR flags
for inspection, but remove only IQR-flagged temperatures and missing values before
calculating descriptive statistics.

```{code-cell} r
clean_data <- logger_data_IQR %>%
  filter(!temp_outlier_IQR, !is.na(temperature))

clean_summary <- clean_data %>%
  summarize(
    observations = n(),
    start = min(datetime, na.rm = TRUE),
    end = max(datetime, na.rm = TRUE),
    mean_temperature = mean(temperature, na.rm = TRUE),
    minimum_temperature = min(temperature, na.rm = TRUE),
    maximum_temperature = max(temperature, na.rm = TRUE),
    mean_humidity = mean(humidity, na.rm = TRUE)
  )

print(clean_summary)
```

This gives you a robust starting point for further analysis. For example, calculate
the mean temperature for each hour of the day:

```{code-cell} r
diurnal_data <- clean_data %>%
  mutate(hour = format(datetime, "%H")) %>%
  group_by(hour) %>%
  summarize(
    mean_temperature = mean(temperature, na.rm = TRUE),
    mean_humidity = mean(humidity, na.rm = TRUE),
    .groups = "drop"
  )

ggplot(diurnal_data, aes(x = hour, y = mean_temperature, group = 1)) +
  geom_line(color = "steelblue") +
  geom_point() +
  labs(
    title = paste("Average diurnal temperature:", sensor_id),
    x = "Hour",
    y = "Mean temperature (°C)"
  ) +
  theme_minimal()
```

## Export the cleaned logger data

```{code-cell} r
clean_file <- file.path(sensor_data_folder, paste0(sensor_id, "_cleaned.csv"))
write.csv(clean_data, clean_file, row.names = FALSE)
print(clean_file)
```

## Optional extension 1: compare multiple loggers

Once you have completed the single-logger workflow, extend the analysis to every
logger. This is deliberately kept after the core analysis so that you can debug each
step with a single dataset first.

### Read and combine logger files

```{code-cell} r
all_data <- NULL

for (each_file in microclimate_files) {
  data <- read.csv(each_file, encoding = "latin1")

  sensor_id_each <- sub(".", "-", names(data)[1], fixed = TRUE)
  data <- data[, 1:5]
  names(data) <- c(
    "observation_id", "datetime", "temperature", "humidity", "dewpoint"
  )

  data$sensor_id <- sensor_id_each
  all_data <- rbind(all_data, data)
}

all_data$datetime <- as.POSIXct(all_data$datetime)
all_data$temperature <- suppressWarnings(as.numeric(all_data$temperature))
all_data$humidity <- suppressWarnings(as.numeric(all_data$humidity))
all_data$dewpoint <- suppressWarnings(as.numeric(all_data$dewpoint))
all_data$sensor_id <- factor(all_data$sensor_id)

print(head(all_data))
```

### Compare logger distributions and time series

```{code-cell} r
ggplot(all_data, aes(x = sensor_id, y = temperature)) +
  geom_boxplot() +
  labs(
    title = "Temperature distribution per sensor",
    x = "Sensor ID",
    y = "Temperature (°C)"
  ) +
  theme_minimal()

ggplot(all_data, aes(x = datetime, y = temperature, color = sensor_id)) +
  geom_line(alpha = 0.6) +
  labs(
    title = "Temperature over time by sensor",
    x = "Datetime",
    y = "Temperature (°C)",
    color = "Sensor ID"
  ) +
  theme_minimal()
```

### Flag outliers for every logger

Outlier calculations should be performed separately for each logger because each logger
can have a different baseline, bias, and range.

```{code-cell} r
all_data_IQR <- all_data %>%
  group_by(sensor_id) %>%
  mutate(
    temp_Q1 = quantile(temperature, 0.25, na.rm = TRUE),
    temp_Q3 = quantile(temperature, 0.75, na.rm = TRUE),
    temp_IQR = temp_Q3 - temp_Q1,
    temp_outlier_IQR = if_else(
      temperature < (temp_Q1 - 1.5 * temp_IQR)
        | temperature > (temp_Q3 + 1.5 * temp_IQR),
      TRUE, FALSE, missing = FALSE
    )
  ) %>%
  ungroup()

ggplot(
  all_data_IQR,
  aes(x = datetime, y = temperature, color = temp_outlier_IQR)
) +
  geom_point() +
  facet_wrap(~sensor_id) +
  scale_color_manual(values = c("black", "red")) +
  labs(
    title = "IQR temperature outliers by logger",
    x = "Datetime",
    y = "Temperature (°C)",
    color = "Outlier"
  ) +
  theme_minimal()
```

### Add habitat metadata

```{code-cell} r
metadata <- read.csv(sensor_metadata_file, as.is = TRUE)
metadata$site <- ifelse(
  metadata$long_Sensor_location > -0.5,
  "NHM",
  "Silwood"
)

habitat_classification <- metadata[, c("Logger_SerialNumber", "Habitat", "site")]
names(habitat_classification) <- c("sensor_id", "habitat", "site")
habitat_classification$site <- factor(habitat_classification$site)
habitat_classification$habitat <- factor(habitat_classification$habitat)

summary_data <- all_data_IQR %>%
  filter(!temp_outlier_IQR, !is.na(temperature)) %>%
  group_by(sensor_id) %>%
  summarize(
    max_temperature = max(temperature),
    mean_temperature = mean(temperature),
    .groups = "drop"
  ) %>%
  left_join(habitat_classification, by = "sensor_id")

print(summary_data)
```

### Compare habitats statistically

ANOVA (Analysis of Variance) is a statistical method used to test whether the
means of a continuous variable differ significantly across two or more groups.

Test whether the max temperature is predicted by location. What do you expect?

```{code-cell} r
anova_model <- lm(max_temperature ~ habitat, data = summary_data)
summary(anova_model)
```

```{code-cell} r
ggplot(summary_data, aes(x = habitat, y = max_temperature)) +
  geom_boxplot(fill = "lightblue", alpha = 0.6) +
  geom_jitter(width = 0.1, size = 2, alpha = 0.7) +
  labs(
    title = "Maximum Temperature by Habitat Type",
    x = "Habitat Type",
    y = "Max Temperature (°C)"
  ) +
  theme_minimal()
```

### Export the combined data set

```{code-cell} r
write.csv(
  all_data_IQR,
  file.path(sensor_data_folder, "all_sensor_data_2025.csv"),
  row.names = FALSE
)
```

## Optional extension 2: Explore other variables and relationships

Now that you are familiar with the dataset, go explore other variables,
statistics, or relatioships, for example:

* Plotting humidity vs. habitat type
* Looking at the diurnal cycle (average daily patterns)
* Comparing spatial variation between sensors

## Reflection Tasks

### 1. Descriptive statistics paragraph

Write a short summary of:

* Your dataset (number of sensors, time range, variables measured)
* Any unusual patterns or outliers
* How your measurements compare with official weather station data

### 2. Interpretation of modelling results

In ~300 words, explain:

* What your ANOVA shows
* Whether this result supports your hypothesis

:::{important} Key takeaway

Data cleaning and exploratory analysis are not just “pre-work”, they are
essential steps in understanding your data set, spotting problems, and making
sure your conclusions are valid.

:::
