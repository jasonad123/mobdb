# mobdb 0.1.3

## Major changes

* `mobdb_download_feed()` is now called `download_feed()`. This is a **breaking change** and requires users that uses this function to be updated to use the new function name.

* `mobdb_feeds()` is now called `feeds()`. This is a **breaking change** and requires all code that uses this function to be updated to use the new function name.

## Minor changes

* `download_feed()` now accepts the `official` parameter for filtering official vs unofficial feeds

* `feeds()` now accepts the `official` parameter for filtering official vs unofficial feeds

# mobdb 0.1.2

## Major changes
* `mobdb_download_feed()` now accepts data frames from `mobdb_feeds()` or `mobdb_search()`
* Soft deprecation of `mobdb_read_gtfs()` (still works; use `mobdb_download_feed()` for new code)

## Minor changes
* Fixed documentation examples to use valid feed IDs
* Enhanced `mobdb_search()` docs to explain API limitations
* Added comprehensive test suite

# mobdb 0.1.1

## Major changes
* Added `mobdb_download_feed()` for downloading GTFS Schedule feeds from MobilityData hosted URLs
* Enhanced `mobdb_download_feed()` to support provider/location search parameters
* Added automatic GTFS-Flex feed filtering with `exclude_flex` parameter (default: TRUE)
* Added `use_source_url` parameter to choose between MobilityData hosted or agency source URLs

## Minor changes
* Improved error messages to display feed details table when multiple feeds match search criteria
* Updated installation instructions to use `pak` instead of `remotes`

# mobdb 0.1.0

Initial release. Provides R access to the Mobility Database Catalog API for discovering and accessing GTFS transit feeds.

* Search and filter feeds with `mobdb_feeds()`
* Access historical datasets with `mobdb_datasets()`
* Direct integration with tidytransit via `mobdb_read_gtfs()`
* Secure authentication with `mobdb_set_key()`