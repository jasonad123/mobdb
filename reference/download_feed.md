# Download GTFS Schedule feed

A convenience function for downloading GTFS Schedule feeds from the
Mobility Database. This is a "one-stop-shop" that can search for feeds
by provider/location and download them in a single call, or download a
specific feed by ID.

**Note:** This function is specifically designed for GTFS Schedule feeds
only. GTFS Realtime and GBFS feeds use a different data model and are
not supported by this function.

*This function was formerly called `mobdb_download_feed()`. All
functions are identical to that function.*

## Usage

``` r
download_feed(
  feed_id = NULL,
  provider = NULL,
  country_code = NULL,
  subdivision_name = NULL,
  municipality = NULL,
  exclude_flex = TRUE,
  feed_name = NULL,
  use_source_url = FALSE,
  dataset_id = NULL,
  latest = TRUE,
  status = "active",
  official = TRUE,
  ...
)
```

## Arguments

- feed_id:

  A string or data frame. The unique identifier for the feed (e.g.,
  "mdb-2862"), or a single-row data frame from
  [`feeds()`](https://jasonad123.github.io/mobdb/reference/feeds.md) or
  [`mobdb_search()`](https://jasonad123.github.io/mobdb/reference/mobdb_search.md).
  If a data frame is provided, the feed ID will be extracted
  automatically. If provided, all other search parameters are ignored.

- provider:

  A string. Filter by provider/agency name (partial match). Use this to
  search for feeds without knowing the feed_id.

- country_code:

  A string. Two-letter ISO country code (e.g., "US", "CA").

- subdivision_name:

  A string. State, province, or region name.

- municipality:

  A string. City or municipality name.

- exclude_flex:

  A logical. If `TRUE` (default), automatically exclude feeds with
  "flex" in the feed name (case-insensitive). GTFS-Flex feeds are an
  extension of the GTFS Schedule specification and may contain files
  that have unique schemas that may not work with standard GTFS tools.

- feed_name:

  A string. Optional filter for feed name. If provided, only feeds whose
  `feed_name` contains this string (case-insensitive) will be
  considered. Use `NULL` (default) to skip this filter.

- use_source_url:

  A logical. If `FALSE` (default), uses MobilityData's hosted/archived
  URL which ensures you get the exact version in their database. If
  `TRUE`, uses the provider's direct source URL which may be more
  current but could differ from MobilityData's version.

- dataset_id:

  A string. Optional specific dataset ID for historical versions (e.g.,
  "mdb-53-202510250025"). If provided, downloads that specific dataset
  version instead of the latest. Cannot be used with
  `use_source_url = TRUE`.

- latest:

  A logical. If `TRUE` (default), download the most recent dataset. If
  `FALSE`, returns information about all available datasets for the feed
  without downloading.

- status:

  A string. Feed status filter: "active" (default), "deprecated",
  "inactive", "development", or "future". Only used when searching by
  provider/location.

- official:

  A logical. If `TRUE` (default), only return official feeds when
  searching by provider/location. If `FALSE`, only return unofficial
  feeds. If `NULL`, return all feeds regardless of official status.

- ...:

  Additional arguments passed to
  [`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html).

## Value

If `latest = TRUE`, a `gtfs` object as returned by
[`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html).
If `latest = FALSE`, a tibble of all available datasets with their
metadata.

## See also

[`mobdb_datasets()`](https://jasonad123.github.io/mobdb/reference/mobdb_datasets.md)
to list all available historical versions,
[`get_validation_report()`](https://jasonad123.github.io/mobdb/reference/get_validation_report.md)
to check feed quality before downloading,
[`feeds()`](https://jasonad123.github.io/mobdb/reference/feeds.md) to
search for feeds,
[`mobdb_read_gtfs()`](https://jasonad123.github.io/mobdb/reference/mobdb_read_gtfs.md)
for more flexible GTFS reading

## Examples

``` r
if (FALSE) { # \dontrun{
# Download by feed ID
gtfs <- download_feed("mdb-2862")

# Download from search results
feeds <- feeds(provider = "TransLink")
gtfs <- download_feed(feeds[36, ])

# Search and download by provider name (excludes Flex automatically)
gtfs <- download_feed(provider = "Arlington")

# Download using agency's source URL instead of MobilityData hosted
gtfs <- download_feed(provider = "TriMet", use_source_url = TRUE)

# Include Flex feeds in search
gtfs <- download_feed(provider = "Arlington", exclude_flex = FALSE)

# Filter by location
gtfs <- download_feed(
  country_code = "US",
  subdivision_name = "California",
  municipality = "San Francisco"
)

# Search and download all feeds, including unofficial ones
gtfs <- download_feed(provider = "TTC", official = NULL)

# See all available versions for a feed
versions <- download_feed("mdb-2862", latest = FALSE)

# Download a specific historical version
historical <- download_feed("mdb-53", dataset_id = "mdb-53-202507240047")
} # }
```
