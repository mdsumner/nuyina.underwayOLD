
#' Obtain and save the Nuyina underway
#'
#' Data is read from the AADC geoserver feed.
#'
#' We take a rough offset from the existing data and merge, it might make the query faster.
#'
#' We convert 'date_time_utc' to POSIXct here.
#'
#' We apply a weird fix to longitudes if they are negative for a bug that appeared in October 2023.
#'
#' @param init update existing data or initialize it (FALSE by default, data is appended)
#' @param filename name of file to create (or use default)
#'
#' @return status TRUE if success
#' @export
get_underway <- function(init = FALSE, filename = NULL) {
    clobber <- FALSE
    if (is.null(filename)) {
        clobber <- TRUE
        filename <- "data-raw/nuyina_underway.parquet"
    }
    dat <- NULL
    offset <- 0
    if (!init) {
        dat <- arrow::read_parquet(filename)
            offset <- dim(dat)[1L] - 1024

}
Sys.setenv("OGR_WFS_USE_STREAMING" = "YES")

uwy <- vapour::vapour_read_fields("WFS:https://data.aad.gov.au/geoserver/ows?service=wfs&version=2.0.0&request=GetCapabilities",
                 sql = sprintf("SELECT * FROM \"underway:nuyina_underway\" OFFSET %i", offset))

uwy <- tibble::as_tibble(uwy)
uwy$date_time_utc <- as.POSIXct(uwy$date_time_utc, "%Y/%m/%d %H:%M:%S", tz = "UTC")

## if this fails should we just do again with init = TRUE?
dat <- try(dplyr::bind_rows(dat, uwy))
if (inherits(dat, "try-error")) stop("appending failed, try with init = TRUE")

dat <- dplyr::arrange(dplyr::distinct(dat), "date_time_utc")
if (clobber) {
    file.remove("data-raw/nuyina_underway_0.parquet")
    file.copy(filename, "data-raw/nuyina_underway_0.parquet")
}
arrow::write_parquet(dat, filename, compression = "zstd")

TRUE
## we don't have voyage groupings in this data, so all "nuyina"

#uwy <- tail(uwy, 30 * 24 * 60)
#uwy <- uwy[seq(1, nrow(uwy), by = 4), ]
#uwy2 <- dplyr::arrange(uwy2, date_time_utc)
#try(trip::write_track_kml(rep("nuyina", nrow(uwy)), uwy$longitude, uwy$latitude, utc = uwy$date_time_utc, kml_file = "data-raw/nuyina.kmz"))
}
