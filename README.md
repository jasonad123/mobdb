# mobdb <img src="man/figures/logo.png" align="right" width="180" alt="logo" />

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/jasonad123/mobdb/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jasonad123/mobdb/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

**mobdb** provides R functions to search and access transit feed data from the [Mobility Database](https://mobilitydatabase.org). The package wraps the Mobility Database Catalog API, enabling the discovery of GTFS (General Transit Feed Specification) Schedule, GTFS Realtime, and GBFS (General Bikeshare Feed Specification) feeds from transit agencies worldwide.

## Installation

You can install the development version of mobdb from GitHub:

```r
# Install using pak (recommended)
# install.packages("pak")
pak::pak("jasonad123/mobdb")

# Or using remotes
# install.packages("pak")
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

### Search for transit feeds

```r
# Search by provider name
bart_feeds <- mobdb_feeds(provider = "BART")

# Filter feeds by location
on_feeds <- mobdb_feeds(
  country_code = "CA",
  subdivision_name = "Ontario",
  data_type = "gtfs"
)

# Search for a specific provider
translink_yvr <- mobdb_feeds(provider = "TransLink Vancouver")

# Note: mobdb_search() uses the /search endpoint which has known issues
# with relevance ranking. Use mobdb_feeds() with filters for better results.
```

### Download feed from MobilityData

```r
library(gtfsio)

# Download latest MobilityData-hosted version of the feed 
stm_montreal <- mobdb_download_feed("mdb-2126")

# use export_gtfs() to export as GTFS zip file
export_gtfs (stm_montreal, "data/gtfs/gtfs.zip")

> zip::zip_list("data/gtfs/gtfs.zip")$filename
[1] "agency.txt"         "calendar.txt"       "calendar_dates.txt" "feed_info.txt"      "routes.txt"         "shapes.txt"        
[7] "stops.txt"          "stop_times.txt"     "trips.txt"  
```

### Get feed details

```r
# Get detailed information about a specific feed
feed_info <- mobdb_get_feed("mdb-53")

# Get just the download URL
url <- mobdb_feed_url("mdb-53")

# Or extract URLs from multiple feeds (requires data_type for location filters)
feeds <- mobdb_feeds(country_code = "US", data_type = "gtfs", limit = 10)
urls <- mobdb_extract_urls(feeds)
```

### Access historical datasets

```r
# Get the latest dataset for a feed (only works with GTFS schedule feeds)
latest <- mobdb_datasets("mdb-53", latest = TRUE)

# Get all historical versions
all_versions <- mobdb_datasets("mdb-53", latest = FALSE)
```

### Using with tidytransit

The package works with [tidytransit](https://github.com/r-transit/tidytransit) for GTFS analysis:

```r
library(tidytransit)
library(dplyr)

# Read by feed ID (simplest approach)
gtfs <- mobdb_read_gtfs("mdb-53")

# Or search and read in one pipeline
feeds <- mobdb_feeds(provider = "San Francisco", data_type = "gtfs")
gtfs <- mobdb_read_gtfs(feeds[1, ])  # Pass single-row data frame

# Or manually extract the URL using helper function
feeds <- mobdb_feeds(provider = "San Francisco", data_type = "gtfs")
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
page1 <- mobdb_feeds(limit = 100, offset = 0)

# Get next 100 results
page2 <- mobdb_feeds(limit = 100, offset = 100)
```

## Project Status

**What works:** Core API access (feeds, datasets, metadata), direct downloads, authentication, all filters. R CMD check: 0/0/0.

**Experimental:** tidytransit integration (`mobdb_read_gtfs()`) - implemented but needs more testing.

**Pipeline:** Unit tests with mocked responses, vignettes, batch downloads, caching, pkgdown site.

## API Endpoints

The package provides access to the following Mobility Database API endpoints:

- **Feeds** (`mobdb_feeds()`, `mobdb_get_feed()`) - Search and retrieve feed information
- **Search** (`mobdb_search()`) - Full-text search across feeds
- **Datasets** (`mobdb_datasets()`, `mobdb_get_dataset()`) - Access historical feed versions
- **Metadata** (`mobdb_metadata()`) - Get API version and status information

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