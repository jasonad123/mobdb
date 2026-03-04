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
  [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md).

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
  [`mobdb_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_datasets.md),
  not from search results

## See also

[`get_validation_report()`](https://mobdb.jasonadle.dev/reference/get_validation_report.md)
to get full validation details with report URLs,
[`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md)
to search for feeds,
[`mobdb_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_datasets.md)
to get dataset information directly

## Examples

``` r
# Create sample data matching mobdb_search() output with latest_dataset
sample_results <- tibble::tibble(
  id = "mdb-1",
  provider = "Sample Agency",
  latest_dataset = tibble::tibble(
    id = "mdb-1-202501010000",
    hosted_url = "https://example.com/dataset.zip",
    downloaded_at = "2025-01-01T00:00:00Z",
    hash = "abc123",
    service_date_range_start = "2025-01-01",
    service_date_range_end = "2025-12-31",
    agency_timezone = "America/Los_Angeles",
    validation_report = tibble::tibble(
      total_error = 0L,
      total_warning = 5L,
      total_info = 10L,
      url_html = "https://example.com/report.html",
      url_json = "https://example.com/report.json"
    )
  )
)

# Extract dataset information
mobdb_extract_datasets(sample_results)
#> # A tibble: 1 × 14
#>   feed_id provider      dataset_id         hosted_url        downloaded_at hash 
#>   <chr>   <chr>         <chr>              <chr>             <chr>         <chr>
#> 1 mdb-1   Sample Agency mdb-1-202501010000 https://example.… 2025-01-01T0… abc1…
#> # ℹ 8 more variables: service_date_range_start <chr>,
#> #   service_date_range_end <chr>, agency_timezone <chr>, total_error <int>,
#> #   total_warning <int>, total_info <int>, html_report <chr>, json_report <chr>

if (FALSE) { # mobdb_can_run_examples()
# With real API data:
results <- mobdb_search("transit")
datasets <- mobdb_extract_datasets(results)
}
```
