# Clear mobdb cache

Removes cached files from the cache directory. Can remove all files or
only those older than a specified number of days.

## Usage

``` r
mobdb_cache_clear(older_than = NULL)
```

## Arguments

- older_than:

  Optional. Remove only files older than this many days. If NULL
  (default), removes all cached files.

## Examples

``` r
if (FALSE) { # \dontrun{
# Clear all cache
mobdb_cache_clear()

# Clear only files older than 7 days
mobdb_cache_clear(older_than = 7)
} # }
```
