
<!-- README.md is generated from README.Rmd. Please edit that file -->

# nuyina.underway

<!-- badges: start -->

[![R-CMD-check](https://github.com/mdsumner/nuyina.underway/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mdsumner/nuyina.underway/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The way this works has changed. 


The goal is to get the Nuyina underway feed. File is
saved at this URL in Parquet:

    https://github.com/mdsumner/uwy.new/releases/download/v0.0.1/nuyina_underway.parquet

For an up to the minute update, read the entire stream with

``` r
get_underway <- function(x) {
    ## read the bulk
    d <- arrow::read_parquet("https://github.com/mdsumner/uwy.new/releases/download/v0.0.1/nuyina_underway.parquet")
    ## read the rest
    d1 <- tibble::as_tibble(vapour::vapour_read_fields("WFS:https://data.aad.gov.au/geoserver/ows?service=wfs&version=2.0.0&request=GetCapabilities",
                                                       sql = sprintf("SELECT * FROM \"underway:nuyina_underway\" WHERE datetime > '%s'", 
                                                                     format(max(d$datetime, "%Y-%m-%dT%H:%M:%SZ")))))
    
    
    dplyr::bind_rows(d, d1)
    
}




d <- get_underway()
```


## Code of Conduct

Please note that the nuyina.underway project is released with a
[Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
