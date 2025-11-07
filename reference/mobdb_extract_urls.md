# Extract download URLs from feed results

Helper function to extract producer URLs from a tibble of feeds returned
by [`feeds()`](https://jasonad123.github.io/mobdb/reference/feeds.md) or
[`mobdb_search()`](https://jasonad123.github.io/mobdb/reference/mobdb_search.md).
This is useful when you want to get all the source URLs from a set of
search results.

## Usage

``` r
mobdb_extract_urls(feeds)
```

## Arguments

- feeds:

  A tibble returned by
  [`feeds()`](https://jasonad123.github.io/mobdb/reference/feeds.md) or
  [`mobdb_search()`](https://jasonad123.github.io/mobdb/reference/mobdb_search.md).

## Value

A character vector of download URLs, with the same length as the input
tibble. Returns `NA` for feeds without a URL.

## Examples

``` r
if (FALSE) { # \dontrun{
# Search for feeds and get their URLs
feeds <- mobdb_search("California")
urls <- mobdb_extract_urls(feeds)

# Filter and get URLs
ca_gtfs <- feeds(subdivision_name = "California", data_type = "gtfs")
ca_urls <- mobdb_extract_urls(ca_gtfs)
} # }
```
