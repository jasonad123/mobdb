# Extract latest dataset information from search results

Helper function to extract dataset details from search results. The
search endpoint includes a `latest_dataset` field with comprehensive
information about the most recent dataset, including validation results.

## Usage

``` r
mobdb_extract_datasets(results)
```

## Arguments

- results:

  A tibble returned by
  [`mobdb_search()`](https://jasonad123.github.io/mobdb/reference/mobdb_search.md).

## Value

A tibble with one row per feed, containing key dataset information:

- `id` - Feed ID

- `dataset_id` - Latest dataset ID

- `hosted_url` - URL to download the latest validated dataset

- `downloaded_at` - When the dataset was captured

- `hash` - Dataset file hash

- `service_date_range_start` - Start of service dates

- `service_date_range_end` - End of service dates

- `total_error` - Number of validation errors (if available)

- `total_warning` - Number of validation warnings (if available)

- Note: Report URLs (html_report, json_report) are only available when
  using
  [`mobdb_datasets()`](https://jasonad123.github.io/mobdb/reference/mobdb_datasets.md),
  not from search results

## See also

[`get_validation_report()`](https://jasonad123.github.io/mobdb/reference/get_validation_report.md)
to get full validation details with report URLs,
[`mobdb_search()`](https://jasonad123.github.io/mobdb/reference/mobdb_search.md)
to search for feeds,
[`mobdb_datasets()`](https://jasonad123.github.io/mobdb/reference/mobdb_datasets.md)
to get dataset information directly

## Examples

``` r
if (FALSE) { # \dontrun{
# Search for feeds
results <- mobdb_search("transit")

# Get dataset info with validation status
datasets <- mobdb_extract_datasets(results)

# Filter for feeds with no errors
clean_feeds <- datasets |> filter(total_error == 0)
} # }
```
