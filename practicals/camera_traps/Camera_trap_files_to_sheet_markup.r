# =================================================================================================
# CAMERA TRAP FILES TO SHEET
#
# Fill in the two lines below, then run the whole script
# This Script renames and copies camera trap video files from a raw input folder,
# and fills in the Random Encounter and Staying Time (REST)
# model data template with the resulting file list.

# =================================================================================================
# Expected input folder structure:
#
# INPUT_FOLDER/
# ├── PLOT_X/
# │   ├── IMG_0001.AVI
# │   └── IMG_0002.AVI
# └── PLOT_Y/
#     ├── IMG_0001.AVI
#     └── IMG_0002.AVI
#
# - One subfolder per plot; the folder name is used as the plot ID
# - Videos sit directly inside each plot folder (no deeper nesting)
# - File names can repeat across plots

inDir <- "/Volumes/Silwood_Bat_data/Silwood_camera_trap/Fractal_Plots_REST" # <<< FILL IN: path to the folder of raw camera trap files for this survey round >>>
survey_round <- "SUMMER_2026" # <<< FILL IN: e.g. "SUMMER_2026" >>>

if (!nzchar(inDir)) {
  stop("Set inDir at the top of the script before running.")
}
if (!dir.exists(inDir)) {
  stop("inDir does not exist: ", inDir)
}
if (!nzchar(survey_round)) {
  stop("Set survey_round at the top of the script before running.")
}

# ---- everything below is automatic ------------------------------------------------------------

outDir <- paste0(inDir, "_renamed")
file_formats <- c("avi", "mp4") # jpg picks up the _QV.JPG thumbnails alongside their videos
template_output_path <- file.path(
  outDir,
  paste0("RAD_data_", survey_round, ".xlsx")
)

# ---- Renaming and copying video's  ------------------------------------------------------------

stations <- list.dirs(inDir, full.names = TRUE, recursive = FALSE)
stations <- stations[!basename(stations) %in% c(".dtrash", ".mysql.digikam")]

file_table <- do.call(
  rbind,
  lapply(stations, function(stn_dir) {
    files <- list.files(
      stn_dir,
      full.names = TRUE,
      recursive = FALSE,
      pattern = paste0("\\.(", paste(file_formats, collapse = "|"), ")$"),
      ignore.case = TRUE
    )
    if (length(files) == 0) {
      return(NULL)
    }
    data.frame(
      Station = basename(stn_dir),
      FilePath = files,
      FileName = basename(files),
      DateTimeOriginal = file.info(files)$mtime, # true capture time isn't embedded in these videos; file mtime is the only reliable source
      stringsAsFactors = FALSE
    )
  })
)

file_table <- file_table[
  order(file_table$Station, file_table$DateTimeOriginal),
]

# number files sequentially within each station+minute, matching camtrapR's imageRename() convention
minute_group <- format(file_table$DateTimeOriginal, "%Y-%m-%d %H:%M")
file_table$minute.append <- ave(
  seq_len(nrow(file_table)),
  file_table$Station,
  minute_group,
  FUN = seq_along
)

file_table$DateTime_for_filename <- format(
  file_table$DateTimeOriginal,
  "%Y-%m-%d__%H-%M-%S"
)
file_table$filename_new <- paste0(
  file_table$Station,
  "__",
  file_table$DateTime_for_filename,
  "(",
  file_table$minute.append,
  ").",
  tools::file_ext(file_table$FileName)
)
file_table$outDirStation <- file.path(outDir, file_table$Station)
file_table$outPath <- file.path(
  file_table$outDirStation,
  file_table$filename_new
)

# --- inspect before copying anything ---
head(file_table[, c("Station", "FileName", "DateTimeOriginal", "filename_new")])
range(file_table$DateTimeOriginal) # sanity-check for clock errors like the 2022 outlier

# --- copy ---
invisible(lapply(
  unique(file_table$outDirStation),
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))
file_table$copy_success <- file.copy(
  file_table$FilePath,
  file_table$outPath,
  overwrite = FALSE,
  copy.date = TRUE
)

write.csv(
  file_table,
  file.path(outDir, "renaming_table.csv"),
  row.names = FALSE
)
all(file_table$copy_success)

# ---- Fill the camera trap data template   ------------------------------------------------------------

library(openxlsx)

# only video clips get a detection_data row (the _QV.JPG thumbnails are companions, not separate detections)
video_rows <- file_table[
  toupper(tools::file_ext(file_table$filename_new)) %in% c("AVI", "MP4"),
]
video_rows <- video_rows[
  order(video_rows$Station, video_rows$DateTimeOriginal),
]

# template is built from scratch -- Summary/Locations get just their column headers (no dropdown
# lists or station data), and detection_data also keeps its first five description rows above the
# actual column headers. No separate template file is needed.
wb <- createWorkbook()

addWorksheet(wb, "Summary")
writeData(
  wb,
  "Summary",
  c(
    "SAFE Project ID",
    "Access status",
    "Title",
    "Description",
    "Embargo date",
    "Author name",
    "Author email",
    "Author affiliation",
    "Author ORCID",
    "Worksheet name",
    "Worksheet title",
    "Worksheet description",
    "Worksheet external file",
    "External file",
    "External file description",
    "Keywords",
    "Publication DOI",
    "Permit type",
    "Permit authority",
    "Permit number",
    "Funding body",
    "Funding type",
    "Funding reference",
    "Funding link",
    "Start date",
    "End date",
    "North",
    "South",
    "East",
    "West"
  ),
  colNames = FALSE
)

addWorksheet(wb, "Locations")
writeData(
  wb,
  "Locations",
  matrix(c("Station", "Latitude", "Longitude", "Type"), nrow = 1),
  colNames = FALSE
)

addWorksheet(wb, "Taxa")
writeData(
  wb,
  "Taxa",
  matrix(c("Common_Name", "Latin_Name"), nrow = 1),
  colNames = FALSE
)


addWorksheet(wb, "detection_data")
detection_header_rows <- rbind(
  c(
    "field_type",
    "ID",
    "ID",
    "Time",
    "ID",
    "Taxa",
    "Numeric",
    "Numeric",
    "Categorical"
  ),
  c(
    "description",
    "File name",
    "Camera station ID",
    "Date and time of detection",
    "Survey round",
    "Species detected",
    "Number of passes through the focal area in this clip",
    "Staying time inside the focal area",
    "Is the animal still in the frame at the end of the video?"
  ),
  c(
    "levels",
    NA,
    NA,
    NA,
    NA,
    NA,
    NA,
    NA,
    "1 =animal still in frame at clip end,0 = animal has left the frame"
  ),
  c("units", NA, NA, NA, NA, NA, NA, "seconds", NA),
  c("method", NA, NA, NA, NA, NA, NA, NA, NA),
  c(
    "field_name",
    "Filename",
    "Station",
    "DateTime",
    "Term",
    "Species",
    "Nfocal",
    "Stay",
    "Cens"
  )
)
writeData(wb, "detection_data", detection_header_rows, colNames = FALSE)

writeData(
  wb,
  sheet = "detection_data",
  x = rep(survey_round, nrow(video_rows)),
  startCol = 5,
  startRow = 7,
  colNames = FALSE
) # SurveyRound (Term)
writeData(
  wb,
  sheet = "detection_data",
  x = video_rows$filename_new,
  startCol = 2,
  startRow = 7,
  colNames = FALSE
) # Filename
writeData(
  wb,
  sheet = "detection_data",
  x = video_rows$Station,
  startCol = 3,
  startRow = 7,
  colNames = FALSE
) # Station
writeData(
  wb,
  sheet = "detection_data",
  x = video_rows$DateTimeOriginal,
  startCol = 4,
  startRow = 7,
  colNames = FALSE
) # DateTime

saveWorkbook(wb, template_output_path, overwrite = TRUE)

cat("Done. Filled template saved to:\n", template_output_path, "\n")
