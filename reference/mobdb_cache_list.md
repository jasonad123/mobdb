# List cached files

Returns a tibble with information about all cached files, including file
name, size, modification time, and age.

## Usage

``` r
mobdb_cache_list()
```

## Value

Tibble with columns:

- file:

  File name

- size_mb:

  File size in megabytes

- modified:

  Last modification time

- age_hours:

  Age in hours

## Examples

``` r
# List all cached files
mobdb_cache_list()
#> ! Cache directory does not exist: /home/runner/.cache/R/mobdb
#> # A tibble: 0 × 0
```
