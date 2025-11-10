# Filter feeds or datasets by validation quality

Filter feed or dataset results by validation quality thresholds. This is
a convenience wrapper around
[`get_validation_report()`](https://mobdb.pages.dev/reference/get_validation_report.md)
that returns the original data filtered to only include feeds/datasets
meeting your quality criteria.

**Note:** This function does *not* support GBFS validation reports at
this time as GBFS validation reports are located at a different endpoint
and have a different validation criteria.

## Usage

``` r
filter_by_validation(
  data,
  max_errors = NULL,
  max_warnings = NULL,
  max_info = NULL,
  require_validation = TRUE
)
```

## Arguments

- data:

  A tibble from [`feeds()`](https://mobdb.pages.dev/reference/feeds.md),
  [`mobdb_datasets()`](https://mobdb.pages.dev/reference/mobdb_datasets.md),
  or
  [`mobdb_search()`](https://mobdb.pages.dev/reference/mobdb_search.md).

- max_errors:

  Maximum number of validation errors allowed. Use `0` for error-free
  feeds. If `NULL` (default), no error filtering is applied.

- max_warnings:

  Maximum number of validation warnings allowed. If `NULL` (default), no
  warning filtering is applied.

- max_info:

  Maximum number of informational notices allowed. If `NULL` (default),
  no info filtering is applied.

- require_validation:

  Logical. If `TRUE` (default), exclude feeds/datasets that have no
  validation data. If `FALSE`, include them in results.

## Value

A filtered version of the input data frame containing only
feeds/datasets that meet the specified quality criteria.

## See also

[`get_validation_report()`](https://mobdb.pages.dev/reference/get_validation_report.md)
to inspect validation metrics,
[`view_validation_report()`](https://mobdb.pages.dev/reference/view_validation_report.md)
to view full validation reports

## Examples

``` r
if (FALSE) { # \dontrun{
# Find all California feeds with zero errors
ca_feeds <- feeds(
  country_code = "US",
  subdivision_name = "California",
  data_type = "gtfs"
)
clean_feeds <- filter_by_validation(ca_feeds, max_errors = 0)

# Find feeds with minimal issues
quality_feeds <- filter_by_validation(
  ca_feeds,
  max_errors = 0,
  max_warnings = 100
)

# Get historical BART datasets with improving quality
bart <- feeds(provider = "Bay Area Rapid Transit")
datasets <- mobdb_datasets(bart$id[1], latest = FALSE)
improving <- filter_by_validation(datasets, max_errors = 5, max_warnings = 3000)
} # }
```
