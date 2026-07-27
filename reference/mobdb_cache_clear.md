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

## Value

Invisibly returns NULL. Called for its side effect of removing cached
files (and, if requested via older_than, only those older than the given
number of days)

## Examples

``` r
# \donttest{
# Clear all cache
mobdb_cache_clear()
#> ℹ No cache directory found

# Clear only files older than 7 days
mobdb_cache_clear(older_than = 7)
#> ℹ No cache directory found
# }
```
