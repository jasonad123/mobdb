# Download the best GTFS Schedule feed with smart selection

**\[experimental\]**

A higher-level wrapper around
[`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
that automagically selects the best GTFS Schedule feed when multiple
options exist. This function:

- Searches for feeds using provider name or location

- Automatically ranks feeds by status, official designation, and
  validation quality

- Prompts for user selection when multiple equally-ranked feeds exist
  (in interactive mode)

- Falls back to historical datasets when current feed is marked "future"
  or "inactive"

- Only works with GTFS Schedule feeds (not GTFS-RT or GBFS)

This is designed for common use cases where you just want the best, most
recent feed without needing to specify exact feed IDs or handle multiple
results manually.

## Usage

``` r
download_best_feed(
  provider = NULL,
  country_code = NULL,
  subdivision_name = NULL,
  municipality = NULL,
  feed_name = NULL,
  prefer_official = TRUE,
  prefer_active = TRUE,
  max_validation_errors = NULL,
  interactive = NULL,
  exclude_flex = TRUE,
  use_source_url = FALSE,
  auth_args = NULL,
  export_path = NULL,
  ...
)
```

## Arguments

- provider:

  Provider/agency name (partial match).

- country_code:

  ISO 2-letter country code (requires `subdivision_name`).

- subdivision_name:

  State/province/region name (requires `country_code`).

- municipality:

  City name.

- feed_name:

  Feed name filter (case-insensitive substring match).

- prefer_official:

  Logical. If `TRUE` (default), prefer feeds marked as official.

- prefer_active:

  Logical. If `TRUE` (default), prefer feeds with status "active" over
  "future", "development", "deprecated", or "inactive".

- max_validation_errors:

  Integer. Maximum number of validation errors allowed. Feeds exceeding
  this threshold are filtered out. If `NULL` (default), no filtering.

- interactive:

  Logical. If `TRUE`, prompt user to select when multiple equally-ranked
  feeds exist. If `FALSE`, automatically select the first highest-ranked
  feed with a warning. If `NULL` (default), uses
  `getOption("mobdb.interactive")` or falls back to
  [`interactive()`](https://rdrr.io/r/base/interactive.html) to detect
  if running in an interactive R session.

- exclude_flex:

  Logical. If `TRUE` (default), exclude GTFS-Flex feeds.

- use_source_url:

  Logical. Download from agency's source URL (`TRUE`) or MobilityData's
  hosted URL (`FALSE`, default).

- auth_args:

  Authentication arguments if required (see
  [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)).

- export_path:

  A string. Optional path to save the GTFS feed as a ZIP file (e.g.,
  "data/gtfs/feed.zip"). If provided, the feed will be exported using
  [`gtfsio::export_gtfs()`](https://r-transit.github.io/gtfsio/reference/export_gtfs.html)
  after downloading. Requires the `gtfsio` package. If `NULL` (default),
  the feed is not saved to disk.

- ...:

  Additional arguments passed to
  [`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html).

## Value

A `gtfs` object from tidytransit, or `NULL` if user cancels selection.

## Selection Algorithm

When multiple feeds match the search criteria, feeds are ranked by:

1.  **Status** (if `prefer_active = TRUE`): active \> future \>
    development \> inactive \> deprecated

2.  **Official designation** (if `prefer_official = TRUE`): official \>
    unclassified \> unofficial

3.  **Validation quality**: Feeds with fewer errors score higher

4.  **Service date coverage**: Feeds covering today's date score higher

5.  **Recency**: More recently added feeds get a tiebreaker boost

If multiple feeds have the same score and `interactive = TRUE`, you'll
be prompted to choose.

## Status Handling

The function handles different feed statuses as follows:

- **"active"**: Preferred status. Feed should be used in public trip
  planners.

- **"future"** or **"inactive"**: Automatically searches for historical
  datasets with service dates covering today. "future" feeds are not yet
  active; "inactive" feeds haven't been recently updated and may provide
  outdated information.

- **"deprecated"**: Explicitly deprecated and should not be used. Warns
  user to search for a replacement feed.

- **"development"**: For development purposes only, should not be used
  in production.

## GTFS Schedule Only

Like
[`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md),
this function only works with GTFS Schedule feeds. For GTFS-RT or GBFS
feeds, use
[`mobdb_read_gtfs()`](https://mobdb.jasonadle.dev/reference/mobdb_read_gtfs.md)
or fetch URLs with
[`mobdb_get_feed()`](https://mobdb.jasonadle.dev/reference/mobdb_get_feed.md).

## See also

[`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
for precise control,
[`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md) to explore
available feeds before downloading,
[`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md)
for full-text search with validation data

## Examples

``` r
if (FALSE) { # \dontrun{
# Simple one-shot download by provider name
bart_feed <- download_best_feed(provider = "Bay Area Rapid Transit")

# Download with quality filtering
clean_feed <- download_best_feed(
  provider = "Capital Metro",
  max_validation_errors = 0
)

# Download by location
ontario_feed <- download_best_feed(
  country_code = "CA",
  subdivision_name = "Ontario"
)

# Non-interactive mode (for scripts)
options(mobdb.interactive = FALSE)
feed <- download_best_feed(provider = "WMATA")

# Download and save as ZIP file
feed <- download_best_feed(provider = "TriMet", export_path = "data/gtfs/trimet.zip")
} # }
```
