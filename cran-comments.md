## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* Local: macOS 15.7.3, R 4.5.2
* GitHub Actions: Ubuntu-latest, R release; Windows-latest, R Release
* R-hub: Windows Server 2022, R-devel
* R-hub: Ubuntu 22.04, R-devel

## Notes

* Examples that require API authentication or internet access are wrapped
  with `@examplesIf mobdb_can_run_examples()` which checks for both
  internet connectivity and API key availability.

* Vignettes are set to `eval = FALSE` to avoid API calls during CRAN checks.

* Tests use httptest2 for mocking HTTP responses, with `skip_on_cran()`
  for tests that require live API access.

## Downstream dependencies

There are currently no known downstream dependencies for this package.