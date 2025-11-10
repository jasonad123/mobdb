# Generate cache key from parameters

Creates a unique cache key by hashing the provided parameters.

## Usage

``` r
generate_cache_key(..., prefix = "mobdb")
```

## Arguments

- ...:

  Parameters to include in cache key

- prefix:

  Character prefix for cache key (default: "mobdb")

## Value

Character string with cache key (filename)
