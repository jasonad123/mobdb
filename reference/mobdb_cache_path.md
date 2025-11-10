# Set or show mobdb cache directory

Configure the directory where mobdb caches API responses. By default,
mobdb uses `tools::R_user_dir("mobdb", "cache")`.

## Usage

``` r
mobdb_cache_path(path = NULL, install = FALSE, overwrite = FALSE)
```

## Arguments

- path:

  Optional. Directory path for cache. If NULL (default), shows current
  cache path without changing it.

- install:

  Logical. If TRUE, adds MOBDB_CACHE_PATH to .Renviron for persistence
  across R sessions. Default: FALSE

- overwrite:

  Logical. If TRUE, overwrites existing MOBDB_CACHE_PATH in .Renviron.
  Default: FALSE

## Value

Character string with cache path (invisibly)

## Examples

``` r
if (FALSE) { # \dontrun{
# Show current cache path
mobdb_cache_path()

# Set for current session only
mobdb_cache_path("~/my_mobdb_cache")

# Set permanently in .Renviron
mobdb_cache_path("~/my_mobdb_cache", install = TRUE)
} # }
```
