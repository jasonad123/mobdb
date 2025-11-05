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

### Download GTFS Schedule feeds

The `mobdb_download_feed()` function downloads GTFS Schedule feeds by feed ID or by searching for providers/locations.

```r
library(tidytransit)
library(gtfsio)

# Download by feed ID
stm_montreal <- mobdb_download_feed("mdb-2126")

# Download by provider name (excludes GTFS-Flex feeds automatically)
bart_gtfs <- mobdb_download_feed(provider = "BART")

# Use feed_name parameter when multiple feeds exist for a provider
dc_bus <- mobdb_download_feed(provider = "WMATA", feed_name = "Bus")

# Download from agency source URL instead of MobilityData hosted version
gtfs <- mobdb_download_feed(provider = "SFMTA", use_source_url = TRUE)

# Filter by location
on_gtfs <- mobdb_download_feed(
  country_code = "CA",
  subdivision_name = "Ontario"
)

# Export as GTFS zip file
export_gtfs(stm_montreal, "data/gtfs/stm_montreal.zip")

> zip::zip_list("data/gtfs/stm_montreal.zip")$filename
[1] "agency.txt"         "calendar.txt"       "calendar_dates.txt" "feed_info.txt"      "routes.txt"         "shapes.txt"
[7] "stops.txt"          "stop_times.txt"     "trips.txt"
```

**Note:** When multiple feeds match your search criteria, the function displays a table of options and prompts you to specify which feed to download using its feed ID.

```r
> gtfs <- mobdb_download_feed(provider = "San Francisco")
Searching for GTFS Schedule feeds...
! Found 2 matching feeds:
  
# A tibble: 2 × 4
  id     provider                                                               feed_name status
  <chr>  <chr>                                                                  <chr>     <chr> 
1 mdb-62 San Francisco Bay Area Water Emergency Transportation Authority (WETA) ""        active
2 mdb-50 San Francisco Municipal Transportation Agency (SFMTA, Muni)            ""        inact…
Error in `mobdb_download_feed()`:
Multiple feeds found. Please specify which one to download.
Use `mobdb_download_feed(feed_id = "mdb-XXX")` with one of the IDs above.
Or refine your search with the `provider` or `feed_name` parameters.

```

### Get feed details

```r
# Get detailed information about a specific feed
feed_info <- mobdb_get_feed("mdb-247")

# Get just the download URL
url <- mobdb_feed_url("mdb-247")

# Or extract URLs from multiple feeds (requires data_type for location filters)
feeds <- mobdb_feeds(country_code = "US", data_type = "gtfs", limit = 10)
urls <- mobdb_extract_urls(feeds)
```

### Access historical datasets

```r
# Get the latest dataset for a feed (only works with GTFS schedule feeds)
latest <- mobdb_datasets("mdb-247", latest = TRUE)

# Get all historical versions
all_versions <- mobdb_datasets("mdb-247", latest = FALSE)
```

### Using with tidytransit

The package provides two functions for working with [tidytransit](https://github.com/r-transit/tidytransit):

- **`mobdb_download_feed()`** - Download GTFS Schedule feeds with provider/location search (recommended)
- **`mobdb_read_gtfs()`** - More flexible reader that works with any GTFS feed type

```r
library(tidytransit)
library(dplyr)

# Download GTFS Schedule feed with search (recommended for most users)
gtfs <- mobdb_download_feed(provider = "TriMet")

# Or use mobdb_read_gtfs() for more flexibility
gtfs <- mobdb_read_gtfs("mdb-247")

# Pass a data frame from mobdb_feeds()
feeds <- mobdb_feeds(provider = "TriMet", data_type = "gtfs")
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