# Get validation report for feeds or datasets

Extract validation report summary from feed/dataset results.
MobilityData runs all GTFS Schedule feeds through the canonical GTFS
validator, and this function surfaces that validation data to help
assess feed quality before downloading.

## Usage

``` r
get_validation_report(data)
```

## Arguments

- data:

  A tibble from [`feeds()`](https://mobdb.pages.dev/reference/feeds.md),
  [`mobdb_datasets()`](https://mobdb.pages.dev/reference/mobdb_datasets.md),
  or
  [`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md).

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

[`filter_by_validation()`](https://mobdb.pages.dev/reference/filter_by_validation.md)
to filter by quality thresholds,
[`view_validation_report()`](https://mobdb.pages.dev/reference/view_validation_report.md)
to open full HTML/JSON reports in browser,
[`mobdb_datasets()`](https://mobdb.pages.dev/reference/mobdb_datasets.md)
to get dataset information with validation data,
[`mobdb_extract_datasets()`](https://mobdb.pages.dev/reference/mobdb_extract_datasets.md)
to extract validation from search results

## Examples

``` r
if (FALSE) { # \dontrun{
# Get validation report for feeds from search
bart_feeds <- feeds(provider = "Bay Area Rapid Transit")
datasets <- mobdb_datasets(bart_feeds$id[1])
validation <- get_validation_report(datasets)
print(validation)

# Check TransLink Vancouver's validation (has known warnings)
# Per TransLink's GTFS page "We pass our data through Google's Transit Feed
# Validator at the error level, but the data may have warnings left unfixed
# in order to conform to TransLink's business rules, such as duplicate stops
# with no distance between them."
vancouver <- feeds(provider = "TransLink", country_code = "CA", data_type = "gtfs")
vancouver_datasets <- mobdb_datasets(vancouver$id[1])
validation <- get_validation_report(vancouver_datasets)
# Shows: 100,076 errors, 14,322,543 warnings
} # }
```
