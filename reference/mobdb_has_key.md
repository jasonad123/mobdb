# Check if Mobility Database API token is configured

Check whether a refresh token has been set for the current session or is
available in the environment.

## Usage

``` r
mobdb_has_key()
```

## Value

Logical. `TRUE` if a token is configured, `FALSE` otherwise.

## Examples

``` r
# Check if API token is configured
mobdb_has_key()
#> [1] FALSE
```
