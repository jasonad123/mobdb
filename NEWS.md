# mobdb 0.1.1

* Added `mobdb_download_feed()` for downloading feeds from MobilityData hosted URLs
* Updated installation instructions to use `pak` instead of `remotes`

# mobdb 0.1.0

Initial release. Provides R access to the Mobility Database Catalog API for discovering and accessing GTFS transit feeds.

* Search and filter feeds with `mobdb_feeds()`
* Access historical datasets with `mobdb_datasets()`
* Direct integration with tidytransit via `mobdb_read_gtfs()`
* Secure authentication with `mobdb_set_key()`
