
#' Obtain and save the Nuyina underway
#'
#' Data is read from the AADC geoserver feed.
#'
#' We take a rough offset from the existing data and merge, it might make the query faster.
#'
#' We convert 'datetime' to POSIXct here.
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
#name changed to datetime and doesn't need parsing (but maybe that's version-specific)
if (!inherits(uwy$datetime, "POSIXct")) {
 uwy$datetime <- as.POSIXct(uwy$datetime, "%Y/%m/%d %H:%M:%S", tz = "UTC")
}
## if this fails should we just do again with init = TRUE?
dat <- try(dplyr::bind_rows(dat, uwy))
if (inherits(dat, "try-error")) stop("appending failed, try with init = TRUE")

bad <- abs(dat$longitude) < .1 & abs(dat$latitude) < .1  ## FIXME
#dat$longitude <- abs(dat$longitude)  ## FIXME when geoserver feed is fixed
if (any(bad)) dat <- dat[!bad, ]
dat <- dplyr::arrange(dplyr::distinct(dat, .data$datetime, .data$longitude, .data$latitude, .keep_all = TRUE), .data$datetime)

if (clobber) {
    file.remove("data-raw/nuyina_underway_0.parquet")
    file.copy(filename, "data-raw/nuyina_underway_0.parquet")
}
arrow::write_parquet(dat, filename, compression = "zstd")

TRUE
}
