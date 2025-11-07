# Get datasets for a feed

Retrieve information about available datasets (historical versions) for
a specific feed. Each dataset represents a snapshot of the feed at a
particular point in time.

## Usage

``` r
mobdb_datasets(feed_id, latest = TRUE)
```

## Arguments

- feed_id:

  A string. The unique identifier for the feed.

- latest:

  A logical. If `TRUE` (default), return only the most recent dataset.
  If `FALSE`, return all available datasets.

## Value

A tibble containing dataset information including:

- `id` - Dataset identifier

- `feed_id` - Associated feed ID

- `downloaded_at` - Timestamp when dataset was captured

- `hash` - Hash of the dataset file

- `download_url` - URL to download this specific dataset version

- Additional metadata columns

## See also

[`download_feed()`](https://jasonad123.github.io/mobdb/reference/download_feed.md)
to download specific historical versions,
[`get_validation_report()`](https://jasonad123.github.io/mobdb/reference/get_validation_report.md)
to extract validation data from datasets,
[`mobdb_get_dataset()`](https://jasonad123.github.io/mobdb/reference/mobdb_get_dataset.md)
to get details for a specific dataset

## Examples

``` r
if (FALSE) { # \dontrun{
# Get latest dataset for a feed (GTFS schedule feeds only)
latest <- mobdb_datasets("mdb-53")

# Get all historical datasets
all_versions <- mobdb_datasets("mdb-53", latest = FALSE)
} # }
```
