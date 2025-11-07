# View validation report in browser

Opens the MobilityData validation report for a feed or dataset in your
default web browser. The report shows detailed validation results from
the canonical GTFS validator.

## Usage

``` r
view_validation_report(data, format = "html")
```

## Arguments

- data:

  One of:

  - A single-row tibble from
    [`mobdb_datasets()`](https://jasonad123.github.io/mobdb/reference/mobdb_datasets.md)
    or
    [`mobdb_search()`](https://jasonad123.github.io/mobdb/reference/mobdb_search.md)

  - A character string feed_id (e.g., "mdb-482")

  - A character string dataset_id (e.g., "mdb-482-202511010126")

- format:

  Character. Report format: "html" (default) or "json".

## Value

Invisibly returns the URL that was opened.

## See also

[`get_validation_report()`](https://jasonad123.github.io/mobdb/reference/get_validation_report.md)
to extract validation data as a tibble,
[`filter_by_validation()`](https://jasonad123.github.io/mobdb/reference/filter_by_validation.md)
to filter by quality thresholds,
[`mobdb_datasets()`](https://jasonad123.github.io/mobdb/reference/mobdb_datasets.md)
to get dataset information with validation reports

## Examples

``` r
if (FALSE) { # \dontrun{
# View validation report for Alexandria DASH
view_validation_report("mdb-482")

# View report from dataset results
datasets <- mobdb_datasets("mdb-482")
view_validation_report(datasets)

# View JSON report instead
view_validation_report("mdb-482", format = "json")
} # }
```
