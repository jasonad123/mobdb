# Set Mobility Database API refresh token

Store your Mobility Database API refresh token for use in subsequent API
calls. The refresh token is used to generate short-lived access tokens
automatically.

## Usage

``` r
mobdb_set_key(refresh_token, install = FALSE)
```

## Arguments

- refresh_token:

  A string. Your Mobility Database API refresh token. Obtain this by
  signing up at https://mobilitydatabase.org and navigating to your
  account details page.

- install:

  A logical. If `TRUE`, will set the token in `.Renviron` for use across
  sessions. If `FALSE` (default), token is only set for the current
  session.

## Value

Invisibly returns `TRUE` if successful.

## Examples

``` r
if (FALSE) { # \dontrun{
# Set token for current session
mobdb_set_key("your_refresh_token_here")

# Set token permanently in .Renviron
mobdb_set_key("your_refresh_token_here", install = TRUE)
} # }
```
