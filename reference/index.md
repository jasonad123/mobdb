# Package index

## Get started

Essential functions to begin using mobdb

- [`mobdb_has_key()`](https://mobdb.pages.dev/reference/mobdb_has_key.md)
  : Check if Mobility Database API token is configured
- [`mobdb_set_key()`](https://mobdb.pages.dev/reference/mobdb_set_key.md)
  : Set Mobility Database API refresh token
- [`mobdb_browse()`](https://mobdb.pages.dev/reference/mobdb_browse.md)
  : Load the Mobility Database in browser

## Discover feeds

Search and explore available transit feeds

- [`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md)
  **\[experimental\]** : Search for feeds across the Mobility Database
- [`feeds()`](https://mobdb.pages.dev/reference/feeds.md) : List and
  filter GTFS Schedule, GTFS-RT, and GBFS feeds
- [`feeds_bbox()`](https://mobdb.pages.dev/reference/feeds_bbox.md) :
  Find GTFS Schedule feeds by location

## Download feeds

Download feeds for analysis

- [`download_feed()`](https://mobdb.pages.dev/reference/download_feed.md)
  : Download GTFS Schedule feeds
- [`mobdb_read_gtfs()`](https://mobdb.pages.dev/reference/mobdb_read_gtfs.md)
  **\[superseded\]** : Read GTFS feed directly from Mobility Database

## Assess feed quality

Evaluate feed quality using MobilityData validation reports

- [`filter_by_validation()`](https://mobdb.pages.dev/reference/filter_by_validation.md)
  : Filter feeds or datasets by validation quality
- [`get_validation_report()`](https://mobdb.pages.dev/reference/get_validation_report.md)
  : Get GTFS-Schedule validation report for feeds or datasets
- [`view_validation_report()`](https://mobdb.pages.dev/reference/view_validation_report.md)
  : View GTFS-Schedule validation report in browser

## Historical datasets

Access and explore historical feed versions

- [`mobdb_datasets()`](https://mobdb.pages.dev/reference/mobdb_datasets.md)
  : Get datasets for a feed
- [`mobdb_get_dataset()`](https://mobdb.pages.dev/reference/mobdb_get_dataset.md)
  : Get details for a specific dataset

## Work with feed metadata

Extract and manipulate feed information

- [`mobdb_extract_datasets()`](https://mobdb.pages.dev/reference/mobdb_extract_datasets.md)
  : Extract latest dataset information from search results
- [`mobdb_extract_locations()`](https://mobdb.pages.dev/reference/mobdb_extract_locations.md)
  : Extract location information from search results
- [`mobdb_extract_urls()`](https://mobdb.pages.dev/reference/mobdb_extract_urls.md)
  : Extract download URLs from feed results
- [`mobdb_get_feed()`](https://mobdb.pages.dev/reference/mobdb_get_feed.md)
  : Get details for a specific feed
- [`mobdb_feed_url()`](https://mobdb.pages.dev/reference/mobdb_feed_url.md)
  : Get download URL for a feed

## Utilities

- [`mobdb_cache_clear()`](https://mobdb.pages.dev/reference/mobdb_cache_clear.md)
  : Clear mobdb cache
- [`mobdb_cache_info()`](https://mobdb.pages.dev/reference/mobdb_cache_info.md)
  : Show cache information
- [`mobdb_cache_list()`](https://mobdb.pages.dev/reference/mobdb_cache_list.md)
  : List cached files
- [`mobdb_cache_path()`](https://mobdb.pages.dev/reference/mobdb_cache_path.md)
  : Set or show mobdb cache directory
