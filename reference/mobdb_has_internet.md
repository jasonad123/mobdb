# Check if internet connection is available

Tests whether internet connectivity is available for API calls. Used
internally to control example execution on CRAN.

## Usage

``` r
mobdb_has_internet()
```

## Value

Logical. `TRUE` if internet is available, `FALSE` otherwise.

## Examples

``` r
mobdb_has_internet()
#> Warning: URL 'https://api.mobilitydatabase.org/?apiKey=***REDACTED_API_KEY***&mode=login&tid=_59033768865&redirect_uri=https://iap.googleapis.com/v1beta1/gcip/resources/288F4075118BE963:handleRedirect&state=***REDACTED_JWT_TOKEN*** [... truncated]
#> [1] FALSE
```
