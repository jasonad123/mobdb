# Show cache information

Displays information about the mobdb cache including location, number of
files, and total size.

## Usage

``` r
mobdb_cache_info()
```

## Value

List with cache information (invisibly):

- path:

  Cache directory path

- files:

  Number of cached files

- size_mb:

  Total size in megabytes

- exists:

  Whether cache directory exists

## Examples

``` r
# Show cache info
mobdb_cache_info()
#> 
#> ── mobdb Cache Information ──
#> 
#> ℹ Path: /home/runner/.cache/R/mobdb
#> ℹ Files: 0
#> ℹ Size: 0 MB
#> ℹ Exists: FALSE
```
