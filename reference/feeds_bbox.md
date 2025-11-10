# Find GTFS Schedule feeds by location

Discover GTFS Schedule feeds whose geographic coverage overlaps with or
is contained within a specified bounding box. This function is designed
for feed discovery based on geographic location.

**Important:** This function only works with GTFS Schedule feeds because
bounding box data is derived from the feed's latest dataset.

## Usage

``` r
feeds_bbox(
  bbox,
  filter_method = "completely_enclosed",
  provider = NULL,
  country_code = NULL,
  subdivision_name = NULL,
  municipality = NULL,
  status = NULL,
  official = NULL,
  limit = 100,
  offset = 0,
  use_cache = TRUE
)
```

## Arguments

- bbox:

  A numeric vector of length 4 specifying the bounding box as
  `c(min_lon, min_lat, max_lon, max_lat)` in WGS84 coordinates
  (EPSG:4326). Alternatively, an `sf` bbox object can be provided if
  `sf` is installed.

- filter_method:

  A string. Method for filtering feeds by bounding box:

  - `"completely_enclosed"` (default) - Feeds whose coverage is fully
    inside the specified bounding box

  - `"partially_enclosed"` - Feeds whose coverage overlaps with the box

  - `"disjoint"` - Feeds whose coverage is completely outside the box

- provider:

  A string. Filter by provider/agency name (partial match).

- country_code:

  A string. Two-letter ISO country code (e.g., "US", "CA").

- subdivision_name:

  A string. State, province, or region name.

- municipality:

  A string. City or municipality name.

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

A tibble containing GTFS Schedule feed information with columns
including:

- `id` - Unique feed identifier

- `data_type` - Always "gtfs" for this function

- `provider` - Transit agency/provider name

- `status` - Feed status

- `source_info` - Data frame containing download URLs and auth info

- `latest_dataset` - Information about the most recent dataset including
  bounding box coordinates

- Additional metadata columns

## Examples

``` r
if (FALSE) { # \dontrun{
# Find feeds in the San Francisco Bay Area
# Bounding box: c(min_lon, min_lat, max_lon, max_lat)
bay_area_feeds <- feeds_bbox(
  bbox = c(-122.5, 37.2, -121.8, 38.0),
  filter_method = "partially_enclosed"
)

# Find feeds completely within Los Angeles County
la_feeds <- feeds_bbox(
  bbox = c(-118.9, 33.7, -118.0, 34.8),
  filter_method = "completely_enclosed",
  status = "active"
)

# Use with sf package (if installed)
library(sf)
# Create bbox from sf object
bbox_sf <- st_bbox(c(xmin = -122.5, ymin = 37.2,
                     xmax = -121.8, ymax = 38.0),
                   crs = 4326)
feeds <- feeds_bbox(bbox = bbox_sf)
} # }
```
