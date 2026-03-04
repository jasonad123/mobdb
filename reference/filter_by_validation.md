# Filter feeds or datasets by validation quality

Filter feed or dataset results by validation quality thresholds. This is
a convenience wrapper around
[`get_validation_report()`](https://mobdb.jasonadle.dev/reference/get_validation_report.md)
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

  A tibble from
  [`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md),
  [`mobdb_datasets()`](https://mobdb.jasonadle.dev/reference/mobdb_datasets.md),
  or
  [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md).

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

[`get_validation_report()`](https://mobdb.jasonadle.dev/reference/get_validation_report.md)
to inspect validation metrics,
[`view_validation_report()`](https://mobdb.jasonadle.dev/reference/view_validation_report.md)
to view full validation reports

## Examples

``` r
# Create sample data with validation information (search results structure)
sample_data <- tibble::tibble(
  id = c("mdb-1", "mdb-2", "mdb-3"),
  provider = c("Agency A", "Agency B", "Agency C"),
  latest_dataset = tibble::tibble(
    id = c("mdb-1-202501", "mdb-2-202501", "mdb-3-202501"),
    validation_report = tibble::tibble(
      total_error = c(0L, 5L, 100L),
      total_warning = c(10L, 50L, 500L),
      total_info = c(5L, 10L, 20L)
    )
  )
)

# Filter to feeds with zero errors
filter_by_validation(sample_data, max_errors = 0)
#> Filtered to 1 of 3 items matching quality criteria.
#> # A tibble: 1 × 3
#>   id    provider latest_dataset$id $validation_report$total_er…¹ $$total_warning
#>   <chr> <chr>    <chr>                                     <int>           <int>
#> 1 mdb-1 Agency A mdb-1-202501                                  0              10
#> # ℹ abbreviated name: ¹​$validation_report$total_error
#> # ℹ 1 more variable: latest_dataset$validation_report$total_info <int>

# Filter with multiple criteria
filter_by_validation(sample_data, max_errors = 10, max_warnings = 100)
#> Filtered to 2 of 3 items matching quality criteria.
#> # A tibble: 2 × 3
#>   id    provider latest_dataset$id $validation_report$total_er…¹ $$total_warning
#>   <chr> <chr>    <chr>                                     <int>           <int>
#> 1 mdb-1 Agency A mdb-1-202501                                  0              10
#> 2 mdb-2 Agency B mdb-2-202501                                  5              50
#> # ℹ abbreviated name: ¹​$validation_report$total_error
#> # ℹ 1 more variable: latest_dataset$validation_report$total_info <int>

if (FALSE) { # mobdb_can_run_examples()
# With real API data:
ca_feeds <- feeds(
  country_code = "US",
  subdivision_name = "California",
  data_type = "gtfs"
)
clean_feeds <- filter_by_validation(ca_feeds, max_errors = 0)
}
```
