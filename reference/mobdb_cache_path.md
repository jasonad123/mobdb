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
# Show current cache path
mobdb_cache_path()
#> ℹ Current cache path: /home/runner/.cache/R/mobdb

# \donttest{
# Set for current session only
mobdb_cache_path(file.path(tempdir(), "mobdb_cache_example"))
#> ✔ Created cache directory: /tmp/RtmpiKKmQu/mobdb_cache_example
#> ✔ Cache path set to: /tmp/RtmpiKKmQu/mobdb_cache_example
# }

if (FALSE) { # \dontrun{
# Set permanently in .Renviron
mobdb_cache_path("~/my_mobdb_cache", install = TRUE)
} # }
```
