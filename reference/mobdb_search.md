# Search for feeds across the Mobility Database

**\[experimental\]**

Perform a text search across feed names, providers, and locations.

**Note:** Search is performed on English words and is case insensitive.
Word order is not relevant for matching. For example
`New York City Transit` will be parsed as `new & york & city & transit`

The endpoint used has known issues with relevance ranking. For better
results when searching by provider name, consider using
[`feeds()`](https://mobdb.pages.dev/reference/feeds.md) with the
`provider` parameter.

## Usage

``` r
mobdb_search(
  query,
  feed_id = NULL,
  data_type = NULL,
  official = NULL,
  status = NULL,
  gtfs_feature = NULL,
  gbfs_version = NULL,
  limit = 50,
  offset = 0
)
```

## Arguments

- query:

  A string. Search query string. Searches across provider names, feed
  names, and locations.

- feed_id:

  A string. The unique identifier for the feed (e.g. "mdb-696",
  "mdb-1707", "gbfs-lime_vancouver_bc"). When provided, searches only
  for this specific feed and all other filter parameters must be
  omitted.

- data_type:

  A string. Optional filter by data type: "gtfs", "gtfs_rt", or "gbfs".

- official:

  A logical. If `TRUE`, only return official feeds when searching by
  provider/location. If `FALSE`, only return unofficial feeds. If `NULL`
  (default), return all feeds regardless of official status.

- status:

  A string. Feed status filter: "active", "deprecated", "inactive",
  "development", or "future".

- gtfs_feature:

  A character vector. Filter feeds by their GTFS features. Only valid
  for GTFS Schedule feeds. [GTFS features definitions are defined
  here.](https://gtfs.org/getting-started/features/overview/)

- gbfs_version:

  A character vector. Comma-separated list of GBFS versions to filter
  by. Only valid for GBFS feeds. [GBFS version notes are defined
  here](https://github.com/MobilityData/gbfs/blob/master/README.md)

- limit:

  An integer. Maximum number of results (default: 50).

- offset:

  An integer. Number of results to skip for pagination (default: 0).

## Value

A tibble of matching feeds. Note that search results include additional
fields compared to
[`feeds()`](https://mobdb.pages.dev/reference/feeds.md):

- `locations` - List of data frames with geographical information

- `latest_dataset` - Data frame with most recent dataset details and
  validation

- Core fields (`id`, `provider`, `data_type`, `status`, `source_info`)
  are the same

## Examples

``` r
if (FALSE) { # \dontrun{
# Search for transit agencies (Note: results may not be well-ranked)
results <- mobdb_search("transit")

# Better approach: use feeds() with provider filter
bart <- feeds(provider = "BART")
mta <- feeds(provider = "MTA New York")

# Search with filters
gtfs_feeds <- mobdb_search(
  "transit",
  data_type = "gtfs",
  official = TRUE
)

# Search with pagination
first_50 <- mobdb_search("train", limit = 50, offset = 0)
next_50 <- mobdb_search("train", limit = 50, offset = 50)

# Search for official GTFS feeds only
official_feeds <- mobdb_search("metro", official = TRUE, data_type = "gtfs")

# Note: For location-specific searches (state/province/city), use feeds() instead:
ontario_transit <- feeds(
  provider = "transit",
  country_code = "CA",
  subdivision_name = "Ontario",
  data_type = "gtfs"
)
} # }
```
