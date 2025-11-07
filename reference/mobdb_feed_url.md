# Get download URL for a feed

Convenience function to quickly get the direct download URL for a feed.
This is useful for passing to tidytransit::read_gtfs() or similar
functions.

## Usage

``` r
mobdb_feed_url(feed_id)
```

## Arguments

- feed_id:

  A string. The unique identifier for the feed.

## Value

A string. The direct download URL, or `NULL` if not available.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get download URL
url <- mobdb_feed_url("mdb-53")

# Use with tidytransit
library(tidytransit)
gtfs <- read_gtfs(url)
} # }
```
