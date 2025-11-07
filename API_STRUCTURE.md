# API Response Structure Reference

This document describes the actual structure of responses from the Mobility Database API, based on real API testing.

## Feeds vs Search Endpoints

The API has two main discovery endpoints with different response structures:

### `feeds()` - Basic feed listing
- Returns core feed information
- Simpler structure, faster queries
- Good for filtering by specific criteria

### `mobdb_search()` - Enhanced search results
- Returns everything from feeds endpoint PLUS:
  - `locations` - Detailed geographical information
  - `latest_dataset` - Full dataset details with validation reports
- Better for exploration and quality checking
- Slower but more comprehensive

## Feed Object Structure (from feeds)

When you call `feeds()` or `mobdb_search()`, you get a tibble with these columns:

### Top-Level Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | character | Unique feed identifier (e.g., "mdb-195") |
| `data_type` | character | Feed type: "gtfs" or "gtfs_rt" |
| `provider` | character | Transit agency/provider name |
| `status` | character | "active", "deprecated", "inactive", "development", or "future" |
| `created_at` | character | ISO timestamp of when feed was added |
| `feed_contact_email` | character | Contact email (may be empty) |
| `official` | logical | Whether feed is officially maintained |
| `official_updated_at` | character | When official status was updated |
| `feed_name` | character | Optional feed name (often empty) |
| `note` | character | Optional notes (often empty) |

### Nested Data Structures

#### `source_info` (data frame)

This is where the download URL lives!

```r
feeds$source_info
```

Contains:
- `producer_url` - **The direct download URL** for the GTFS/GBFS file
- `authentication_type` - Integer (0 = no auth required, 1 = API key, 2 = header)
- `authentication_info_url` - URL with auth instructions (if needed)
- `api_key_parameter_name` - Parameter name for API key (if needed)
- `license_url` - License information URL

#### `external_ids` (list of data frames)

External identifiers from other systems:
```r
feeds$external_ids[[1]]
# external_id    source
# "195"         "mdb"
```

#### `redirects` (list)

URL redirects (usually empty list)

#### `related_links` (list)

Related URLs (usually empty list)

## Accessing Download URLs

### Method 1: Extract from search results

```r
feeds <- feeds(country_code = "US", limit = 5)

# Get first feed's URL
url <- feeds$source_info$producer_url[1]

# Get all URLs
urls <- feeds$source_info$producer_url
```

### Method 2: Use helper function

```r
feeds <- mobdb_search("transit")
urls <- mobdb_extract_urls(feeds)
```

### Method 3: Get specific feed URL

```r
url <- mobdb_feed_url("mdb-195")
```

### Method 4: Direct integration with tidytransit

```r
gtfs <- mobdb_read_gtfs("mdb-195")
# or
gtfs <- mobdb_read_gtfs(feeds[1, ])
```

## Example: Complete Workflow

```r
library(mobdb)
library(dplyr)

# Set up authentication
mobdb_set_key("your_refresh_token")

# Search for California transit
ca_feeds <- feeds(
  subdivision_name = "California",
  data_type = "gtfs",
  status = "active"
)

# View results
ca_feeds |>
  select(id, provider, status) |>
  print(n = 20)

# Get download URLs
ca_feeds |>
  mutate(url = mobdb_extract_urls(ca_feeds)) |>
  select(provider, url)

# Filter for specific provider
sf_muni <- ca_feeds |>
  filter(grepl("San Francisco", provider, ignore.case = TRUE))

# Download with tidytransit
if (nrow(sf_muni) > 0) {
  library(tidytransit)
  gtfs <- mobdb_read_gtfs(sf_muni[1, ])
  
  # Analyze
  gtfs$routes
  gtfs$stops
}
```

## Dataset Object Structure

When you call `mobdb_datasets()`:

| Field | Type | Description |
|-------|------|-------------|
| `id` | character | Unique dataset identifier |
| `feed_id` | character | Associated feed ID |
| `downloaded_at` | character | When this version was captured |
| `hash` | character | Hash of the dataset file |
| `download_url` | character | URL for this specific version |

## Search Results Structure (from mobdb_search)

Search results include all fields from feeds PLUS additional nested data:

### Additional Fields in Search Results

#### `locations` (list of data frames)

Each feed can have multiple locations:

```r
results <- mobdb_search("transit")

# Access locations for first result
results$locations[[1]]
#   country_code country       subdivision_name municipality
#   "US"         "United States" "California"   "Los Angeles"

# Use helper to extract all locations
locations <- mobdb_extract_locations(results)
```

#### `latest_dataset` (data frame)

Complete information about the most recent validated dataset:

```r
results$latest_dataset
```

Contains:
- `id` - Dataset identifier  
- `hosted_url` - URL to download validated GTFS (preferred over producer_url)
- `downloaded_at` - Capture timestamp
- `hash` - File hash
- `service_date_range_start` - First date of service
- `service_date_range_end` - Last date of service
- `agency_timezone` - Timezone of the agency
- `validation_report` - Nested validation results:
  - `features` - List of GTFS features used
  - `total_error` - Count of validation errors
  - `total_warning` - Count of warnings
  - `total_info` - Count of info messages
  - `unique_error_count` - Unique error types
  - `unique_warning_count` - Unique warning types

**Important:** The `hosted_url` from latest_dataset is a validated, hosted copy of the feed. 
This is often more reliable than the original `producer_url`.

```r
# Extract dataset information
datasets <- mobdb_extract_datasets(results)

# Filter for feeds with no validation errors
clean_feeds <- datasets |> filter(total_error == 0)

# Use hosted URLs for downloading
results$latest_dataset$hosted_url[1]
```

## Helper Functions for Search Results

### Extract URLs

```r
results <- mobdb_search("California")

# Get producer URLs (original source)
urls <- mobdb_extract_urls(results)

# Or get validated hosted URLs (recommended)
hosted_urls <- results$latest_dataset$hosted_url
```

### Extract Locations

```r
# Unnest locations (one row per feed-location pair)
locations <- mobdb_extract_locations(results, unnest = TRUE)

# Or get summary (one row per feed with combined locations)
location_summary <- mobdb_extract_locations(results, unnest = FALSE)
```

### Extract Dataset Info

```r
# Get dataset details with validation status
datasets <- mobdb_extract_datasets(results)

# Find feeds with no errors
perfect_feeds <- datasets |> 
  filter(total_error == 0, total_warning == 0)

# Check service date coverage
datasets |>
  filter(service_date_range_end >= Sys.Date())
```

## Dataset Object Structure (from mobdb_datasets)

## Common Patterns

### Filter active GTFS feeds

```r
active_gtfs <- feeds(
  data_type = "gtfs",
  status = "active"
)
```

### Search and filter

```r
results <- mobdb_search("metro") |>
  filter(status == "active") |>
  filter(data_type == "gtfs")
```

### Get URLs for batch download

```r
feeds <- feeds(country_code = "US", limit = 100)
urls <- mobdb_extract_urls(feeds)

# Download all (be respectful of rate limits!)
for (url in urls[!is.na(urls)]) {
  # Your download logic here
}
```

## Notes

- The `source_info` field is a data frame, not a simple list
- Most feeds have `authentication_type = 0` (no auth required)
- URLs in `source_info$producer_url` can be direct GTFS zip files or GBFS JSON endpoints
- Not all feeds have all fields populated
- Empty strings and empty lists are common for optional fields
