# Get GTFS-Schedule validation report for feeds or datasets

Extract validation report summary from feed/dataset results. The
Mobility Database runs all GTFS Schedule feeds through the canonical
GTFS validator, and this function surfaces that validation data to help
assess feed quality before downloading.

**Note:** This function does *not* support GBFS validation reports at
this time as GBFS validation reports are located at a different endpoint
and have a different validation criteria.

## Usage

``` r
get_validation_report(data)
```

## Arguments

- data:

  A tibble from
  [`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md),
  [`mobdb_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_datasets.md),
  or
  [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md).

## Value

A tibble with validation summary information:

- `feed_id` or `dataset_id` - Identifier

- `provider` - Provider name (if available)

- `total_error` - Number of validation errors

- `total_warning` - Number of validation warnings

- `total_info` - Number of informational notices

- `html_report` - URL to full HTML validation report

- `json_report` - URL to JSON validation report

## See also

[`filter_by_validation()`](https://mobdb.jasonadle.dev/reference/filter_by_validation.md)
to filter by quality thresholds,
[`view_validation_report()`](https://mobdb.jasonadle.dev/reference/view_validation_report.md)
to open full HTML/JSON reports in browser,
[`mobdb_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_datasets.md)
to get dataset information with validation data,
[`mobdb_extract_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_extract_datasets.md)
to extract validation from search results

## Examples

``` r
# Create sample dataset data with validation_report
sample_datasets <- tibble::tibble(
  id = "mdb-1-202501010000",
  feed_id = "mdb-1",
  validation_report = tibble::tibble(
    total_error = 0L,
    total_warning = 5L,
    total_info = 10L,
    unique_error_count = 0L,
    unique_warning_count = 3L,
    unique_info_count = 5L,
    url_html = "https://example.com/report.html",
    url_json = "https://example.com/report.json",
    validated_at = "2025-01-01T00:00:00Z",
    validator_version = "5.0.0"
  )
)

# Extract validation report
get_validation_report(sample_datasets)
#> # A tibble: 1 × 12
#>   dataset_id     feed_id total_error total_warning total_info unique_error_count
#>   <chr>          <chr>         <int>         <int>      <int>              <int>
#> 1 mdb-1-2025010… mdb-1             0             5         10                  0
#> # ℹ 6 more variables: unique_warning_count <int>, unique_info_count <int>,
#> #   html_report <chr>, json_report <chr>, validated_at <chr>,
#> #   validator_version <chr>

if (FALSE) { # mobdb_can_run_examples()
# With real API data:
bart_feeds <- feeds(provider = "Bay Area Rapid Transit")
datasets <- mobdb_datasets(bart_feeds$id[1])
validation <- get_validation_report(datasets)
}
```
