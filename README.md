# mobdb <img src="man/figures/logo.png" align="right" width="180" alt="logo" />

<!-- badges: start -->
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R-CMD-check](https://github.com/jasonad123/mobdb/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jasonad123/mobdb/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/jasonad123/mobdb/graph/badge.svg)](https://app.codecov.io/gh/jasonad123/mobdb)
[![mobdb status badge](https://jasonad123.r-universe.dev/mobdb/badges/version)](https://jasonad123.r-universe.dev/mobdb)
<!-- badges: end -->

**mobdb** provides R functions to search and access transit feed data from the [Mobility Database](https://mobilitydatabase.org). The package wraps the Mobility Database Catalog API, enabling the discovery of GTFS (General Transit Feed Specification) Schedule, GTFS Realtime, and GBFS (General Bikeshare Feed Specification) feeds from organizations worldwide.
 
## Setup

### Installation

Install from [r-universe](https://jasonad123.r-universe.dev/mobdb):

```r
# Install from r-universe
install.packages('mobdb', repos = c('https://jasonad123.r-universe.dev', 'https://cloud.r-project.org'))
```

Development versions of `mobdb` are available from GitHub:

```r
# Install using pak (recommended)
# install.packages("pak")
pak::pak("jasonad123/mobdb")

# Or using remotes
# install.packages("remotes")
remotes::install_github("jasonad123/mobdb")
```

### Authentication

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

## Getting started

### Search for feeds

```r
library(mobdb)

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
library(mobdb)
library(tidytransit)

# Download by feed ID
stm_montreal <- download_feed("mdb-2126")

# Or by provider name (excludes GTFS-Flex feeds automatically)
bart_gtfs <- download_feed(provider = "BART")

# Use feed_name parameter when multiple feeds exist for a provider
dc_bus <- download_feed(provider = "WMATA", feed_name = "Bus")

# Download from agency source URL instead of Mobility Database hosted version
kcm_gtfs <- download_feed(provider = "King County", use_source_url = TRUE)

# Filter by location
on_gtfs <- download_feed(
  country_code = "CA",
  subdivision_name = "Ontario"
)

# Export as a zip file 
pdx_gtfs <- download_feed("mdb-247", export_path = file.path("data/gtfs/trimet.zip"))

# Check exported file contents
zip::zip_list("data/gtfs/trimet.zip")$filename
#> [1] "feed_info.txt"           "stops.txt"               "agency.txt"              "calendar.txt"   
#> [5] "calendar_dates.txt"      "fare_attributes.txt"     "fare_leg_rules.txt"      "fare_media.txt" 
#> [7] "fare_products.txt"       "fare_rules.txt"          "fare_transfer_rules.txt" "rider_categories.txt"
#> [13] "routes.txt"              "route_directions.txt"    "shapes.txt"              "stop_features.txt"
#> [17] "stop_times.txt"          "transfers.txt"           "trips.txt"               "linked_datasets.txt" 

```

**Note:** When multiple feeds share the same name or search criteria, `download_feed()` displays a `tibble` of options and prompts you to specify which feed to download using its feed ID or using more qualifiers.

```r
gtfs <- download_feed(provider = "WMATA")
#> Searching for GTFS Schedule feeds...
#> ! Found 2 matching feeds:
#>
#> # A tibble: 2 × 4
#> A tibble: 2 × 4
#>  id       provider                                               feed_name status
#>  <chr>    <chr>                                                  <chr>     <chr> 
#> 1 mdb-1846 Washington Metropolitan Area Transit Authority (WMATA) Bus       active
#> 2 mdb-1847 Washington Metropolitan Area Transit Authority (WMATA) Rail      active
#>
#> Error in `download_feed()`:
#> ✖ Multiple feeds found. Please specify which one to download.
#> ℹ Use `download_feed(feed_id = "mdb-XXX")` with one of the IDs above.
#> ℹ Or refine your search with the `provider` or `feed_name` parameters.
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

### Using with other R transit packages

When downloading GTFS Schedule feeds, `mobdb` provides outputs that are compatible with [tidytransit](https://github.com/r-transit/tidytransit) and other R transit packages.

## More information

For more details on how to use more advanced functionality of `mobdb`, have a look at the following vignettes:

* [Intro to mobdb for and use with GTFS Schedule feeds](https://mobdb.jasonadle.dev/articles/mobdb.html)
* [GTFs-Realtime and GBFS usage (within what's possible with R)](https://mobdb.jasonadle.dev/articles/gbfs-and-gtfs-rt.html)

## Related packages

- [tidytransit](https://github.com/r-transit/tidytransit) - Read, validate, and analyze GTFS feeds
- [gtfstools](https://github.com/ipea/gtfstools) - Edit and analyze GTFS feeds
- [gtfsio](https://github.com/r-transit/gtfsio) - Read and write GTFS files

## License

MIT License

## Disclaimers

**Not affiliated with MobilityData**: This package is an independent, community-developed project and is not officially affiliated with, endorsed by, or supported by MobilityData or the Mobility Database project. It is a third-party API wrapper created to facilitate R users' access to the Mobility Database.

**Work in progress**: This package is under active development. While all functions have been tested against the live API and the package passes R CMD check, the API structure may change, and some features are still being refined. Use in production environments at your own discretion.

**Generative AI assistance**: This code and documentation were developed with assistance from generative AI tools, including Claude and Claude Code. While all outputs have been reviewed and tested, users should validate results independently before use in production environments.
