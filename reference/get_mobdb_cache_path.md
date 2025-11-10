# Get mobdb cache directory path

Returns the cache directory path, checking environment variables and
options before falling back to the default R user directory.

## Usage

``` r
get_mobdb_cache_path()
```

## Value

Character string with cache directory path

## Details

Priority order:

1.  MOBDB_CACHE_PATH environment variable

2.  mobdb.cache_path R option

3.  tools::R_user_dir("mobdb", "cache") (default)
