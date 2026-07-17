## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* Local: macOS 15.7.7, R 4.6.1
* GitHub Actions: Ubuntu-latest, R-release; Ubuntu-latest, R-devel; Windows-latest, R-release
* R-universe (via GitHub Actions): R-devel (Linux, Windows, macOS); R-release (Linux, Windows, macOS), R-old (Linux, Windows, macOS)

## Notes

* Examples that require API authentication or internet access are wrapped
  with `@examplesIf mobdb_can_run_examples()` which checks for both
  internet connectivity and API key availability.

* Vignettes are set to `eval = FALSE` to avoid API calls during CRAN checks.

* Tests requiring live API access are guarded with
  `skip_if_not(mobdb_has_key())`, so they skip (rather than fail) on CRAN,
  where no API key is configured. A small number of tests also use
  `skip_on_cran()` directly.