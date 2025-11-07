# Extract location information from search results

Helper function to extract and unnest location information from search
results. The `locations` field in search results is a list of data
frames; this function flattens it into a more usable format.

## Usage

``` r
mobdb_extract_locations(results, unnest = TRUE)
```

## Arguments

- results:

  A tibble returned by
  [`mobdb_search()`](https://jasonad123.github.io/mobdb/reference/mobdb_search.md).

- unnest:

  Logical. If `TRUE` (default), unnest locations so each feed-location
  combination gets its own row. If `FALSE`, return a summary of
  locations per feed.

## Value

A tibble with location information. If `unnest = TRUE`, each row
represents a feed-location pair. If `unnest = FALSE`, returns one row
per feed with concatenated location strings.

## Examples

``` r
if (FALSE) { # \dontrun{
# Search for feeds
results <- mobdb_search("California")

# Get unnested locations (multiple rows per feed if multiple locations)
locations <- mobdb_extract_locations(results)

# Get summary (one row per feed)
location_summary <- mobdb_extract_locations(results, unnest = FALSE)
} # }
```
