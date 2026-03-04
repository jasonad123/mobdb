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
  [`mobdb_search()`](https://mobdb.jasonadle.dev/reference/mobdb_search.md).

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
# Create sample data matching mobdb_search() output structure
sample_results <- tibble::tibble(
  id = c("mdb-1", "mdb-2"),
  provider = c("Agency A", "Agency B"),
  locations = list(
    data.frame(
      country_code = "US",
      country = "United States",
      subdivision_name = "California",
      municipality = "San Francisco"
    ),
    data.frame(
      country_code = "CA",
      country = "Canada",
      subdivision_name = "British Columbia",
      municipality = "Vancouver"
    )
  )
)

# Extract and unnest locations
mobdb_extract_locations(sample_results)
#> # A tibble: 2 × 6
#>   id    provider country_code country       subdivision_name municipality 
#>   <chr> <chr>    <chr>        <chr>         <chr>            <chr>        
#> 1 mdb-1 Agency A US           United States California       San Francisco
#> 2 mdb-2 Agency B CA           Canada        British Columbia Vancouver    

# Get summary without unnesting
mobdb_extract_locations(sample_results, unnest = FALSE)
#> # A tibble: 2 × 4
#>   id    provider locations    location_summary               
#>   <chr> <chr>    <list>       <chr>                          
#> 1 mdb-1 Agency A <df [1 × 4]> San Francisco, California, US  
#> 2 mdb-2 Agency B <df [1 × 4]> Vancouver, British Columbia, CA

if (FALSE) { # mobdb_can_run_examples()
# With real API data:
results <- mobdb_search("California")
locations <- mobdb_extract_locations(results)
}
```
