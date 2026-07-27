# Download GTFS Schedule feeds

A convenience function for downloading GTFS Schedule feeds from the
Mobility Database. This is a "one-stop-shop" that can search for feeds
by provider/location and download them in a single call, or download a
specific feed by ID.

**Note:** This function is specifically designed for GTFS Schedule feeds
only. GTFS Realtime and GBFS feeds use a different data model and are
not supported by this function.

*This function was formerly called `mobdb_download_feed()`.*

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
  official = NULL,
  auth_args = NULL,
  export_path = NULL,
  raw = NULL,
  ...
)
```

## Arguments

- feed_id:

  A string or data frame. The unique identifier for the feed (e.g.,
  "mdb-2862"), or a single-row data frame from
  [`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md) or
  [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md).
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

  A logical. If `FALSE` (default), uses Mobility Database's
  hosted/archived URL which ensures you get the exact version in their
  database. If `TRUE`, uses the provider's direct source URL which may
  be more current but could differ from the hosted version.

- dataset_id:

  A string. Optional specific dataset ID for historical versions (e.g.,
  "mdb-53-202510250025"). If provided, downloads that specific dataset
  version instead of the latest. Cannot be used with
  `use_source_url = TRUE`. If `dataset_id` is provided without
  `feed_id`, the feed ID will be automatically extracted from the
  dataset ID format.

- latest:

  A logical. If `TRUE` (default), download the most recent dataset. If
  `FALSE`, returns information about all available datasets for the feed
  without downloading. Only works when `feed_id` is provided directly;
  cannot be used with search parameters like `provider` or
  `country_code`.

- status:

  A string. Feed status filter: "active" (default), "deprecated",
  "inactive", "development", or "future". Only used when searching by
  provider/location.

- official:

  A logical. If `NULL` (default), return all feeds regardless of
  official status when searching by provider/location. If `TRUE`, return
  official feeds and feeds with unknown official status (NA). If
  `FALSE`, only return feeds explicitly marked as unofficial.

- auth_args:

  A string. Some agencies require authentication to download feeds
  directly from their source URLs. Provide your API key/token in one of
  two formats:

  - Just the value: `"your_api_key_here"`

  - Parameter and value: `"apikey=your_api_key_here"`

  Also accepts a value stored in `.Renviron` (.e.g
  Sys.getenv("AGENCY_API_KEY") stored in the same formats) Only valid
  when `use_source_url = TRUE`. If a feed requires authentication,
  you'll receive an error message with a link to obtain credentials. The
  authentication method (URL parameter or HTTP header) is determined
  automatically from the feed's metadata.

- export_path:

  A string. Optional path to save the GTFS feed as a ZIP file (e.g.,
  "data/gtfs/feed.zip"). By default, saves the raw file exactly as
  downloaded. Set `raw = FALSE` to parse with tidytransit and re-export
  in GTFS-spec-compliant format (requires `tidytransit` and `gtfsio`).
  If `NULL` (default), the feed is not saved to disk.

- raw:

  A logical. Controls whether the file saved to `export_path` is the raw
  download (`TRUE`) or a parsed-and-re-exported version (`FALSE`).
  Defaults to `TRUE` when `export_path` is provided, `FALSE` otherwise.

- ...:

  Additional arguments passed to
  [`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html).

## Value

If `export_path` is provided with `raw = TRUE` (the default when
exporting), the file path (invisibly). If `latest = TRUE`, a `gtfs`
object as returned by
[`tidytransit::read_gtfs()`](https://r-transit.github.io/tidytransit/reference/read_gtfs.html).
If `latest = FALSE`, a tibble of all available datasets with their
metadata.

## See also

[`mobdb_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_datasets.md)
to list all available historical versions,
[`get_validation_report()`](https://mobdb.jasonadle.dev/reference/get_validation_report.md)
to check feed quality before downloading,
[`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md) to search
for feeds,
[`mobdb_read_gtfs()`](https://mobdb.jasonadle.dev/reference/mobdb_read_gtfs.md)
for more flexible GTFS reading

## Examples

``` r
if (FALSE) { # mobdb_can_run_examples() && mobdb_has_tidytransit()
# Download by feed ID
gtfs <- download_feed("mdb-2862")

# Download from search results
feeds <- feeds(provider = "TransLink", data_type = "gtfs")
gtfs <- download_feed(feeds[1, ])

# Search and download by provider name
gtfs <- download_feed(provider = "Arlington")

# Download using agency's source URL instead of Mobility Database
gtfs <- download_feed(provider = "TriMet", use_source_url = TRUE)

# See all available versions for a feed
versions <- download_feed("mdb-2862", latest = FALSE)

# Download a specific historical version (feed_id auto-extracted from dataset_id)
historical <- download_feed(dataset_id = "mdb-53-202507240047")

# Filter by location (may return multiple feeds requiring disambiguation,
# in which case refine with `provider` or `feed_name`)
try(download_feed(
  country_code = "US",
  subdivision_name = "California",
  municipality = "San Francisco"
))

# Save GTFS feed to disk (raw file, no parsing required)
path <- download_feed("mdb-247", export_path = tempfile(fileext = ".zip"))
}
```
