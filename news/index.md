# Changelog

## mobdb 1.0.0

Setting the state for an initial CRAN release and bugfixes.

### Major changes

- First stable release prepared for CRAN submission
- Comprehensive documentation and vignettes

### Minor changes

- Refined API response caching system
- Improved error messages and user feedback
- **New!** `raw=` argument added to
  [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  and
  [`download_best_feed()`](https://mobdb.jasonadle.dev/reference/download_best_feed.md) -
  download raw ZIP files without parsing or processing

### Bug fixes

- Various stability improvements from pre-release testing
- Feed download functions like
  [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  should now consistently have GTFS spec-compliant dates and times.

## mobdb 0.1.8

### Major changes

- **New!**
  [`download_best_feed()`](https://mobdb.jasonadle.dev/reference/download_best_feed.md)
  function for intelligent, one-shot downloading of GTFS Schedule feeds
  - Automatically ranks feeds by status, official designation,
    validation quality, and service date coverage
  - Prompts for user selection when multiple equally-ranked feeds exist
    (in interactive mode)
  - Falls back to historical datasets when current feed is marked
    “future” or “inactive”
  - Like
    [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md),
    only works with GTFS Schedule feeds

### Minor changes

- **New!** `export_path=` argument added to
  [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  and
  [`download_best_feed()`](https://mobdb.jasonadle.dev/reference/download_best_feed.md).
  This argument wraps
  [`export_gtfs()`](https://r-transit.github.io/gtfsio/reference/export_gtfs.html)
  from `gtfsio` to save GTFS Schedule files as a ZIP file locally.
  Perfect for workflows that need a local ZIP file and not a tidygtfs
  object, like analysis in [R5r](https://ipeagit.github.io/r5r/)
- *FYI:* Documentation for this package has now been moved to a new
  domain - <https://mobdb.jasonadle.dev> - you should be redirected
  automatically and we’ll keep it up on the old domain for a period of
  time.

### Bug fixes

None.

## mobdb 0.1.7

### Major changes

None.

### Minor changes

None.

### Bug fixes

- The `status` parameter in
  [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  should now work correctly.

## mobdb 0.1.6

### Major changes

- **New!**
  [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  now supports direct download of feeds that require API authentication
  through the `auth_args` parameter

## mobdb 0.1.5

### Major changes

- **New!**
  [`feeds_bbox()`](https://mobdb.jasonadle.dev/reference/feeds_bbox.md)
  function for discovering GTFS Schedule feeds by bounding box
- **New!** API responses are now cached. Used the following functions to
  manage the cache:
  - [`mobdb_cache_path()`](https://mobdb.jasonadle.dev/reference/mobdb_cache_path.md) -
    configure cache location
  - [`mobdb_cache_info()`](https://mobdb.jasonadle.dev/reference/mobdb_cache_info.md) -
    view cache status
  - [`mobdb_cache_list()`](https://mobdb.jasonadle.dev/reference/mobdb_cache_list.md) -
    list cached files
  - [`mobdb_cache_clear()`](https://mobdb.jasonadle.dev/reference/mobdb_cache_clear.md) -
    clear cache
- All API functions now support caching via `use_cache` parameter

### Minor changes

- **New!** Vignette: “Working with GTFS-Realtime and GBFS”
- [`feeds_bbox()`](https://mobdb.jasonadle.dev/reference/feeds_bbox.md)
  supports both numeric vectors and sf bbox objects
- Added `sf` to Suggests for bbox object support

## mobdb 0.1.4

### Major changes

- [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  now supports downloading specific historical dataset versions via the
  `dataset_id` parameter
- **New!**
  [`get_validation_report()`](https://mobdb.jasonadle.dev/reference/get_validation_report.md)
  function extracts MobilityData validation summaries to help assess
  feed quality before downloading
- **New!**
  [`view_validation_report()`](https://mobdb.jasonadle.dev/reference/view_validation_report.md)
  function opens MobilityData validation reports in your browser
- **New!**
  [`filter_by_validation()`](https://mobdb.jasonadle.dev/reference/filter_by_validation.md)
  function filters feeds/datasets by quality thresholds (max
  errors/warnings)

### Minor changes

- [`mobdb_extract_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_extract_datasets.md)
  now includes `html_report` and `json_report` URLs in output
- `download_feed(latest = FALSE)` returns all available historical
  versions without downloading
- [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md)
  now supports various parameters.
- **New!**
  [`mobdb_browse()`](https://mobdb.jasonadle.dev/reference/mobdb_browse.md)
  function opens the Mobility Database in your browser

### Bug fixes

- [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  now validates feed status when searching by provider/location
- [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  correctly filters official feed status
- [`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md) status
  validation now correctly accepts all five API statuses: “active”,
  “deprecated”, “inactive”, “development”, and “future”
- [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md)
  now correctly performs searches

## mobdb 0.1.3

### Major changes

- `mobdb_download_feed()` is now called
  [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md).
  This is a **breaking change** and requires users that uses this
  function to be updated to use the new function name.

- `mobdb_feeds()` is now called
  [`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md). This is a
  **breaking change** and requires all code that uses this function to
  be updated to use the new function name.

### Minor changes

- [`download_feed()`](https://mobdb.jasonadle.dev/reference/download_feed.md)
  now accepts the `official` parameter for filtering official vs
  unofficial feeds

- [`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md) now
  accepts the `official` parameter for filtering official vs unofficial
  feeds

## mobdb 0.1.2

### Major changes

- `mobdb_download_feed()` now accepts data frames from `mobdb_feeds()`
  or
  [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md)
- Soft deprecation of
  [`mobdb_read_gtfs()`](https://mobdb.jasonadle.dev/reference/mobdb_read_gtfs.md)
  (still works; use `mobdb_download_feed()` for new code)

### Minor changes

- Fixed documentation examples to use valid feed IDs
- Enhanced
  [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md)
  docs to explain API limitations
- Added comprehensive test suite

## mobdb 0.1.1

### Major changes

- Added `mobdb_download_feed()` for downloading GTFS Schedule feeds from
  Mobility Database hosted URLs
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
  [`mobdb_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_datasets.md)
- Direct integration with tidytransit via
  [`mobdb_read_gtfs()`](https://mobdb.jasonadle.dev/reference/mobdb_read_gtfs.md)
- Secure authentication with
  [`mobdb_set_key()`](https://mobdb.jasonadle.dev/reference/mobdb_set_key.md)
