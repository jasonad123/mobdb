# mobdb 0.1.1

* Added `mobdb_download_feed()` for downloading GTFS Schedule feeds from MobilityData hosted URLs
* Enhanced `mobdb_download_feed()` to support provider/location search parameters
* Added automatic GTFS-Flex feed filtering with `exclude_flex` parameter (default: TRUE)
* Added `use_source_url` parameter to choose between MobilityData hosted or agency source URLs
* Improved error messages to display feed details table when multiple feeds match search criteria
* Updated installation instructions to use `pak` instead of `remotes`

# mobdb 0.1.0

Initial release. Provides R access to the Mobility Database Catalog API for discovering and accessing GTFS transit feeds.

* Search and filter feeds with `mobdb_feeds()`
* Access historical datasets with `mobdb_datasets()`
* Direct integration with tidytransit via `mobdb_read_gtfs()`
* Secure authentication with `mobdb_set_key()`
