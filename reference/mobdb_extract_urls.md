# Extract download URLs from feed results

Helper function to extract producer URLs from a tibble of feeds returned
by [`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md) or
[`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md).
This is useful when you want to get all the source URLs from a set of
search results.

## Usage

``` r
mobdb_extract_urls(feeds)
```

## Arguments

- feeds:

  A tibble returned by
  [`feeds()`](https://mobdb.jasonadle.dev/reference/feeds.md) or
  [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md).

## Value

A character vector of download URLs, with the same length as the input
tibble. Returns `NA` for feeds without a URL.

## Examples

``` r
# Create sample data matching feeds() output structure
sample_feeds <- tibble::tibble(
  id = c("mdb-1", "mdb-2"),
  provider = c("Agency A", "Agency B"),
  source_info = tibble::tibble(
    producer_url = c("https://example.com/feed1.zip", "https://example.com/feed2.zip"),
    authentication_type = c(0L, 0L)
  )
)

# Extract URLs from sample data
mobdb_extract_urls(sample_feeds)
#> [1] "https://example.com/feed1.zip" "https://example.com/feed2.zip"

if (FALSE) { # mobdb_can_run_examples()
# With real API data:
ca_gtfs <- feeds(subdivision_name = "California", data_type = "gtfs")
ca_urls <- mobdb_extract_urls(ca_gtfs)
}
```
