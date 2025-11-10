# List and filter GTFS Schedule, GTFS-RT, and GBFS feeds

Query the Mobility Database for transit/bikeshare feeds matching
specified criteria. Returns a tibble with feed metadata including
download URLs.

*This function was formerly called `mobdb_feeds()`.*

## Usage

``` r
feeds(
  provider = NULL,
  country_code = NULL,
  subdivision_name = NULL,
  municipality = NULL,
  data_type = NULL,
  status = NULL,
  official = NULL,
  limit = 100,
  offset = 0,
  use_cache = TRUE
)
```

## Arguments

- provider:

  A string. Filter by provider/agency name (partial match).

- country_code:

  A string. Two-letter ISO country code (e.g., "US", "CA"). **Note:**
  Location filters (`country_code`, `subdivision_name`, `municipality`)
  require `data_type` to be specified.

- subdivision_name:

  A string. State, province, or region name. Requires `data_type` to be
  specified.

- municipality:

  A string. City, municipality, or jurisdiction name. Requires
  `data_type` to be specified.

- data_type:

  A string. Type of feed: "gtfs" (schedule), "gtfs_rt" (realtime), or
  "gbfs" (bike share). Required when using location filters.

- status:

  A string. Feed status: "active", "deprecated", "inactive",
  "development", or "future".

- official:

  A logical. If `TRUE`, only return official feeds. If `FALSE`, only
  return unofficial feeds. If `NULL` (default), return all feeds
  regardless of official status.

- limit:

  An integer. Maximum number of results to return (default: 100).

- offset:

  An integer. Number of results to skip for pagination (default: 0).

- use_cache:

  A logical. If `TRUE` (default), use cached results if available. If
  `FALSE`, always fetch fresh data from the API. Cached data expires
  after 1 hour.

## Value

A tibble containing feed information with columns including:

- `id` - Unique feed identifier

- `data_type` - Type of feed (gtfs, gtfs_rt, or gbfs)

- `created_at` - Date and time feed was added to database

- `external_ids` - External identifier information

- `provider` - Transit agency/provider name

- `feed_contact_email` - Contact email for the feed

- `source_info` - Data frame containing:

  - `producer_url` - Direct download URL for the feed

  - `authentication_type` - Type of auth required (0 = none)

  - `authentication_info_url` - Human-readable page for authentication
    info

  - `api_key_parameter_name` - Name of the parameter to pass in the URL
    to provide the API key

  - `license_url` - License information

- `created_at` - Feed creation timestamp

- `status` - Feed status (active, inactive, deprecated)

- `official` - Whether feed is official

- `official_updated_at` - Date and time of last update

- Additional metadata columns

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all active GTFS feeds in California
ca_feeds <- feeds(
  country_code = "US",
  subdivision_name = "California",
  data_type = "gtfs",
  status = "active"
)

# Search for a specific provider
sf_muni <- feeds(provider = "San Francisco")

# Get feeds with pagination
first_100 <- feeds(limit = 100, offset = 0)
next_100 <- feeds(limit = 100, offset = 100)
} # }
```
