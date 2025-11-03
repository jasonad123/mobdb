# mobdb

<!-- badges: start -->
<!-- badges: end -->

**mobdb** provides R functions to search and access transit feed data from the [Mobility Database](https://mobilitydatabase.org). The package wraps the Mobility Database API v1, enabling programmatic discovery of GTFS (General Transit Feed Specification) and GTFS Realtime feeds from transit agencies worldwide.

## Installation

You can install the development version of mobdb from GitHub:

```r
# install.packages("remotes")
remotes::install_github("jasonad123/mobdb")
```

## Authentication

To use the Mobility Database API, you need a refresh token:

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
# Search by keywords
bart_feeds <- mobdb_search("BART")

# Filter feeds by location
ca_feeds <- mobdb_feeds(
  country_code = "US",
  subdivision_name = "California",
  data_type = "gtfs"
)

# Search for a specific provider
sf_muni <- mobdb_feeds(provider = "San Francisco Municipal")
```

### Get feed details

```r
# Get detailed information about a specific feed
feed_info <- mobdb_get_feed("mdb-123")

# Get just the download URL
url <- mobdb_feed_url("mdb-123")

# Or extract URLs from multiple feeds
feeds <- mobdb_feeds(country_code = "US", limit = 10)
urls <- mobdb_extract_urls(feeds)
```

### Access historical datasets

```r
# Get the latest dataset for a feed
latest <- mobdb_datasets("mdb-123", latest = TRUE)

# Get all historical versions
all_versions <- mobdb_datasets("mdb-123", latest = FALSE)
```

### Integration with tidytransit

The package integrates with [tidytransit](https://github.com/r-transit/tidytransit) for GTFS analysis:

```r
library(tidytransit)
library(dplyr)

# Search and read in one pipeline
gtfs <- mobdb_search("SF Muni") 
  slice(1) %>%
  mobdb_read_gtfs()

# Or by feed ID
gtfs <- mobdb_read_gtfs("mdb-123")

# Or manually extract the URL
feeds <- mobdb_feeds(provider = "SF Muni")
url <- feeds$source_info$producer_url[1]  # Download URL is here
gtfs <- read_gtfs(url)

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

Generative AI Assistance: This code and documentation were developed with assistance from generative AI tools, including Claude and Claude Code. While all outputs have been reviewed and tested, users should validate results independently before use in production environments.