# Read GTFS feed directly from Mobility Database

**\[superseded\]**

**Note:** This function is superseded by
[`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md),
which provides the same functionality plus integrated search, Flex
filtering, and more control over data sources. New code should use
[`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md)
instead. This function may be deprecated in the future once
[`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md)
supports historical datasets.

Convenience wrapper that fetches a feed's download URL from the Mobility
Database and passes it to
[`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html).
Requires the tidytransit package to be installed.

## Usage

``` r
mobdb_read_gtfs(feed_id, dataset_id = NULL, ...)
```

## Arguments

- feed_id:

  A string. The unique identifier for the feed, or a data frame with a
  single row from
  [`feeds()`](https://mobdb.pages.dev/reference/feeds.md) or
  [`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md).

- dataset_id:

  A string. Optional specific dataset ID. If `NULL` (default), uses the
  current/latest feed URL.

- ...:

  Additional arguments passed to
  [`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html).

## Value

A `gtfs` object as returned by
[`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html).

## Examples

``` r
if (FALSE) { # \dontrun{
# Read latest feed by ID (Bay Area Rapid Transit)
gtfs <- mobdb_read_gtfs("mdb-53")

# Read from search results
feeds <- feeds(provider = "TransLink", data_type = "gtfs")
gtfs <- mobdb_read_gtfs(feeds[1, ])

# Read specific historical dataset
gtfs_historical <- mobdb_read_gtfs("mdb-53", dataset_id = "mdb-53-202510250025")
} # }
```
