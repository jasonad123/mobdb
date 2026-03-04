# Check if mobdb examples can run

Tests whether both internet connectivity and an API key are available.
Used to control example execution on CRAN.

## Usage

``` r
mobdb_can_run_examples()
```

## Value

Logical. `TRUE` if examples can run, `FALSE` otherwise.

## Examples

``` r
mobdb_can_run_examples()
#> Warning: URL 'https://api.mobilitydatabase.org/?apiKey=***REDACTED_API_KEY***&mode=login&tid=_59033768865&redirect_uri=https://iap.googleapis.com/v1beta1/gcip/resources/288F4075118BE963:handleRedirect&state=***REDACTED_JWT_TOKEN*** [... truncated]
#> [1] FALSE
```
