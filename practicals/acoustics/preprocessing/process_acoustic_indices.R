#' R script to batch process the calculation of acoustic indices from recordings for the
#' EcoEvoDataScience module. The directory structure needs to be structured as:
#'
#'        ── root
#'        │   ├── sites
#'        │   │   ├── site_name
#'        │   │   │   ├── Data
#'        │   │   │   │   ├── 20240802_054502.wav
#'        │   │   │   │   ├── 20240802_055002.wav
#'        │   ...
#'        ── outputs # created as needed
#'        ── script_files etc
#'
#' Each `site_name` directory is basically the contents of the data downloaded from the
#' song meters. The script is then expecting to be run in an array job and will use the
#' array index to pick up one of the site folders and process all the files in the
#' folder.

library(soundecology)

# Path handling
root_directory <- "/rds/general/users/dorme/acoustics_2026"
output_directory <- file.path(root_directory, "outputs")
if (!dir.exists(output_directory)) {
  dir.create(output_directory)
}

# Get the target site for this subjob
array_job <- as.integer(Sys.getenv("PBS_ARRAY_INDEX"))
sites <- sort(dir(file.path(root_directory, "sites")))
subjob_site <- sites[array_job]

# Get the path to the WAV file directory for this site
sites_directory <- file.path(root_directory, "sites", subjob_site, "Data")

# Run parallel processed calculation of ACI, NDSI and BI acoustic indices
multiple_sounds(
  directory = sites_directory,
  resultfile = file.path(
    root_directory,
    "outputs",
    paste0(subjob_site, "_ACI.csv")
  ),
  soundindex = "acoustic_complexity",
  min_freq = 1000,
  max_freq = 11000,
  no_cores = "max"
)

multiple_sounds(
  directory = sites_directory,
  resultfile = file.path(
    root_directory,
    "outputs",
    paste0(subjob_site, "_NDSI.csv")
  ),
  soundindex = "ndsi",
  no_cores = "max"
)

multiple_sounds(
  directory = sites_directory,
  resultfile = file.path(
    root_directory,
    "outputs",
    paste0(subjob_site, "_BI.csv")
  ),
  soundindex = "bioacoustic_index",
  no_cores = "max",
  min_freq = 1000,
  max_freq = 11000
)
