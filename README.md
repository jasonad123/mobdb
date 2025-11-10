# mobdb <img src="man/figures/logo.png" align="right" width="180" alt="logo" />

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/jasonad123/mobdb/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jasonad123/mobdb/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/jasonad123/mobdb/graph/badge.svg)](https://app.codecov.io/gh/jasonad123/mobdb)
<!-- badges: end -->

**mobdb** provides R functions to search and access transit feed data from the [Mobility Database](https://mobilitydatabase.org). The package wraps the Mobility Database Catalog API, enabling the discovery of GTFS (General Transit Feed Specification) Schedule, GTFS Realtime, and GBFS (General Bikeshare Feed Specification) feeds from organizations worldwide.

## Installation

You can install the development version of mobdb from GitHub:

```r
# Install using pak (recommended)
# install.packages("pak")
pak::pak("jasonad123/mobdb")

# Or using remotes
# install.packages("remotes")
remotes::install_github("jasonad123/mobdb")
```

## Authentication

To use the Mobility Database Catalog API, you need a refresh token:

1. Sign up at [mobilitydatabase.org](https://mobilitydatabase.org)
2. Navigate to your account details page to view your refresh token
3. Set your token in R:

```r
library(mobdb)

# For current session only
mobdb_set_key("your_refresh_token_here")

# To save permanently in .Renviron
mobdb_set_key("your_refresh_token_here", install = TRUE)
```

Alternatively, you can set the `MOBDB_REFRESH_TOKEN` environment variable in your `.Renviron` file.

## Usage

### Search for feeds

```r
# Search by provider name
bart_feeds <- feeds(provider = "BART")

# Filter feeds by location
on_feeds <- feeds(
  country_code = "CA",
  subdivision_name = "Ontario",
  data_type = "gtfs"
)

# Or search generically
toronto <- mobdb_search(provider = "toronto")

# Note: mobdb_search() has known issues with relevance ranking. 
# Use feeds() with filters for more precise results.

```

### Download GTFS Schedule feeds

The `download_feed()` function downloads GTFS Schedule feeds by feed ID or by searching for providers/locations.

```r
library(tidytransit)
library(gtfsio)

# Download by feed ID
stm_montreal <- download_feed("mdb-2126")

# Download by provider name (excludes GTFS-Flex feeds automatically)
bart_gtfs <- download_feed(provider = "BART")

# Use feed_name parameter when multiple feeds exist for a provider
dc_bus <- download_feed(provider = "WMATA", feed_name = "Bus")

# Download from agency source URL instead of MobilityData hosted version
kcm_gtfs <- download_feed(provider = "King County", use_source_url = TRUE)

# Filter by location
on_gtfs <- download_feed(
  country_code = "CA",
  subdivision_name = "Ontario"
)

# Export as GTFS zip file
pdx_gtfs <- download_feed("mdb-247")
export_gtfs(stm_montreal, "data/gtfs/trimet.zip")

# Check exported file contents
zip::zip_list("data/gtfs/trimet.zip")$filename
#> [1] "agency.txt"         "calendar.txt"       "calendar_dates.txt"
#> [4] "feed_info.txt"      "routes.txt"         "shapes.txt"
#> [7] "stops.txt"          "stop_times.txt"     "trips.txt"
```

**Note:** When multiple feeds match your search criteria, the function displays a table of options and prompts you to specify which feed to download using its feed ID.

```r
gtfs <- download_feed(provider = "San Francisco")
#> Searching for GTFS Schedule feeds...
#> ! Found 2 matching feeds:
#>
#> # A tibble: 2 × 4
#>   id     provider                                          feed_name status
#>   <chr>  <chr>                                             <chr>     <chr>
#> 1 mdb-62 San Francisco Bay Area Water Emergency Transp... ""        active
#> 2 mdb-50 San Francisco Municipal Transportation Agency ... ""        inactive
#>
#> Error: Multiple feeds found. Please specify which one to download.
#> Use `download_feed(feed_id = "mdb-XXX")` with one of the IDs above.
```

### Get feed details

```r
# Get detailed information about a specific feed
feed_info <- mobdb_get_feed("mdb-247")

# Get just the download URL
url <- mobdb_feed_url("mdb-247")

# Or extract URLs from multiple feeds (requires data_type for location filters)
feeds <- feeds(country_code = "US", data_type = "gtfs", limit = 10)
urls <- mobdb_extract_urls(feeds)
```

### Check feed quality before downloading

MobilityData validates all GTFS Schedule feeds through the canonical GTFS validator. You can check validation results before downloading:

```r
# Get validation report for a feed
datasets <- mobdb_datasets("mdb-482")  # Alexandria DASH
validation <- get_validation_report(datasets)
validation
#> # A tibble: 1 × 12
#>   dataset_id    feed_id total_error total_warning total_info html_report
#>   <chr>         <chr>         <int>         <int>      <int> <chr>
#> 1 mdb-482-2025… mdb-482           0            38          0 https://...

# View detailed validation report in browser
view_validation_report("mdb-482")

# Check feed quality, then download if clean
if (validation$total_error == 0) {
  gtfs <- download_feed("mdb-482")
}
```

### Access historical datasets

```r
# List all available versions for a feed
versions <- download_feed("mdb-53", latest = FALSE)  # BART
nrow(versions)
#> [1] 29

# Download a specific historical version
historical <- download_feed(dataset_id = "mdb-53-202507240047")

# Compare validation across versions
recent_versions <- versions[1:3, ]
sapply(1:3, function(i) {
  get_validation_report(recent_versions[i, ])$total_error
})
#> [1]   2 266   2
```

### Using with tidytransit

The package provides two functions for working with [tidytransit](https://github.com/r-transit/tidytransit):

- **`download_feed()`** - Download GTFS Schedule feeds with provider/location search (recommended)
- **`mobdb_read_gtfs()`** - More flexible reader that works with any GTFS feed type

```r
library(tidytransit)
library(dplyr)

# Download GTFS Schedule feed with search (recommended for most users)
gtfs <- download_feed(provider = "TriMet")

# Or use mobdb_read_gtfs() for more flexibility
gtfs <- mobdb_read_gtfs("mdb-247")

# Pass a data frame from feeds()
feeds <- feeds(provider = "TriMet", data_type = "gtfs")
gtfs <- mobdb_read_gtfs(feeds[1, ])

# Or manually extract URLs and use tidytransit directly
urls <- mobdb_extract_urls(feeds)
gtfs <- read_gtfs(urls[1])

# Now analyze with tidytransit
gtfs$routes
gtfs$stops
```

### Pagination

For large result sets, use pagination:

```r
# Get first 100 results
page1 <- feeds(limit = 100, offset = 0)

# Get next 100 results
page2 <- feeds(limit = 100, offset = 100)
```

## Related Packages

- [tidytransit](https://github.com/r-transit/tidytransit) - Read, validate, and analyze GTFS feeds
- [gtfstools](https://github.com/ipeaGIT/gtfstools) - Edit and analyze GTFS feeds
- [gtfsio](https://github.com/r-transit/gtfsio) - Read and write GTFS files

## License

MIT License

## Disclaimers

**Not Affiliated with MobilityData**: This package is an independent, community-developed project and is not officially affiliated with, endorsed by, or supported by MobilityData or the Mobility Database project. It is a third-party API wrapper created to facilitate R users' access to the Mobility Database.

**Work in Progress**: This package is under active development. While all functions have been tested against the live API and the package passes R CMD check, the API structure may change, and some features are still being refined. Use in production environments at your own discretion.

**Generative AI Assistance**: This code and documentation were developed with assistance from generative AI tools, including Claude and Claude Code. While all outputs have been reviewed and tested, users should validate results independently before use in production environments.
