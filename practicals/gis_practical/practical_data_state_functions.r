#' These functions are used to save the data state at then end of each
#' practical and then load it again at the start of a subsequent practical.
#' This is needed because raster datasets are not properly serialised by
#' save()



save_state <- function() {
    if (!dir.exists("build_data")) {
        dir.create("build_data")
    }

    only_write_once <- c("silwood_aerial", "nhm_aerial")
    object_names <- ls(envir = .GlobalEnv)
    non_raster <- character()

    for (this_object_name in object_names) {
        object <- get(this_object_name)
        if (inherits(object, "SpatRaster")) {
            out_name <- sprintf("build_data/%s.tiff", this_object_name)

            if (this_object_name %in% only_write_once && file.exists(out_name)) {
                next()
            }

            terra::writeRaster(object, "build_data/tmp.tiff", overwrite = TRUE)
            file.rename(
                from = "build_data/tmp.tiff",
                to = sprintf("build_data/%s.tiff", this_object_name)
            )
        } else {
            non_raster <- c(non_raster, this_object_name)
        }
    }

    save(list = non_raster, file = "build_data/build_data.Rdata")
}

load_state <- function() {
    load("build_data/build_data.Rdata", envir = .GlobalEnv)

    tiff_files <- dir(path = "build_data", pattern = "*.tiff$", full.names = TRUE)

    for (each_tiff in tiff_files) {
        assign(
            x = sub(".tiff$", "", basename(each_tiff)),
            value = terra::rast(each_tiff),
            envir = .GlobalEnv
        )
    }
}
