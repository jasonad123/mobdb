# Changelog

## mobdb 0.1.5

### Major changes

- **New!**
  [`feeds_bbox()`](https://mobdb.pages.dev/reference/feeds_bbox.md)
  function for discovering GTFS Schedule feeds by bounding box
- **New!** API responses are now cached. Used the following functions to
  manage the cache:
  - [`mobdb_cache_path()`](https://mobdb.pages.dev/reference/mobdb_cache_path.md) -
    configure cache location
  - [`mobdb_cache_info()`](https://mobdb.pages.dev/reference/mobdb_cache_info.md) -
    view cache status
  - [`mobdb_cache_list()`](https://mobdb.pages.dev/reference/mobdb_cache_list.md) -
    list cached files
  - [`mobdb_cache_clear()`](https://mobdb.pages.dev/reference/mobdb_cache_clear.md) -
    clear cache
- All API functions now support caching via `use_cache` parameter

### Minor changes

- **New!** Vignette: “Working with GTFS-Realtime and GBFS”
- [`feeds_bbox()`](https://mobdb.pages.dev/reference/feeds_bbox.md)
  supports both numeric vectors and sf bbox objects
- Added `sf` to Suggests for bbox object support

## mobdb 0.1.4

### Major changes

- [`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md)
  now supports downloading specific historical dataset versions via the
  `dataset_id` parameter
- **New!**
  [`get_validation_report()`](https://mobdb.pages.dev/reference/get_validation_report.md)
  function extracts MobilityData validation summaries to help assess
  feed quality before downloading
- **New!**
  [`view_validation_report()`](https://mobdb.pages.dev/reference/view_validation_report.md)
  function opens MobilityData validation reports in your browser
- **New!**
  [`filter_by_validation()`](https://mobdb.pages.dev/reference/filter_by_validation.md)
  function filters feeds/datasets by quality thresholds (max
  errors/warnings)

### Minor changes

- [`mobdb_extract_datasets()`](https://mobdb.pages.dev/reference/mobdb_extract_datasets.md)
  now includes `html_report` and `json_report` URLs in output
- `download_feed(latest = FALSE)` returns all available historical
  versions without downloading
- [`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md)
  now supports various parameters.
- **New!**
  [`mobdb_browse()`](https://mobdb.pages.dev/reference/mobdb_browse.md)
  function opens the Mobility Database in your browser

### Bug fixes

- [`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md)
  now validates feed status when searching by provider/location
- [`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md)
  correctly filters official feed status
- [`feeds()`](https://mobdb.pages.dev/reference/feeds.md) status
  validation now correctly accepts all five API statuses: “active”,
  “deprecated”, “inactive”, “development”, and “future”
- [`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md)
  now correctly performs searches

## mobdb 0.1.3

### Major changes

- `mobdb_download_feed()` is now called
  [`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md).
  This is a **breaking change** and requires users that uses this
  function to be updated to use the new function name.

- `mobdb_feeds()` is now called
  [`feeds()`](https://mobdb.pages.dev/reference/feeds.md). This is a
  **breaking change** and requires all code that uses this function to
  be updated to use the new function name.

### Minor changes

- [`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md)
  now accepts the `official` parameter for filtering official vs
  unofficial feeds

- [`feeds()`](https://mobdb.pages.dev/reference/feeds.md) now accepts
  the `official` parameter for filtering official vs unofficial feeds

## mobdb 0.1.2

### Major changes

- `mobdb_download_feed()` now accepts data frames from `mobdb_feeds()`
  or
  [`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md)
- Soft deprecation of
  [`mobdb_read_gtfs()`](https://mobdb.pages.dev/reference/mobdb_read_gtfs.md)
  (still works; use `mobdb_download_feed()` for new code)

### Minor changes

- Fixed documentation examples to use valid feed IDs
- Enhanced
  [`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md)
  docs to explain API limitations
- Added comprehensive test suite

## mobdb 0.1.1

### Major changes

- Added `mobdb_download_feed()` for downloading GTFS Schedule feeds from
  MobilityData hosted URLs
- Enhanced `mobdb_download_feed()` to support provider/location search
  parameters
- Added automatic GTFS-Flex feed filtering with `exclude_flex` parameter
  (default: TRUE)
- Added `use_source_url` parameter to choose between MobilityData hosted
  or agency source URLs

### Minor changes

- Improved error messages to display feed details table when multiple
  feeds match search criteria
- Updated installation instructions to use `pak` instead of `remotes`

## mobdb 0.1.0

Initial release. Provides R access to the Mobility Database Catalog API
for discovering and accessing GTFS transit feeds.

- Search and filter feeds with `mobdb_feeds()`
- Access historical datasets with
  [`mobdb_datasets()`](https://mobdb.pages.dev/reference/mobdb_datasets.md)
- Direct integration with tidytransit via
  [`mobdb_read_gtfs()`](https://mobdb.pages.dev/reference/mobdb_read_gtfs.md)
- Secure authentication with
  [`mobdb_set_key()`](https://mobdb.pages.dev/reference/mobdb_set_key.md)
