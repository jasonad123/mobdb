## R CMD check results

0 errors | 0 warnings | 0 notes

## Resubmission

This is a resubmission addressing a CRAN "Additional issues" NOTE reported
against 1.0.1 (checking for new files in some other directories, on the
r-devel Fedora `--run-donttest` flavor):

* The `\donttest{}` example for `mobdb_cache_path()` called
  `mobdb_cache_path("~/my_mobdb_cache")`, which creates the given directory.
  Because `\donttest{}` examples are executed by that check flavor, this left
  a `my_mobdb_cache` directory behind in the checking user's home directory.
  The example now uses a path under `tempdir()` instead, so nothing persists
  outside the session temp directory.

## Test environments

* Local: macOS 15.7.7 and Windows 11 25H2, R 4.6.1
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

* A maintainer running `R CMD check` locally with API credentials configured
  may see a NOTE about long-running examples (`download_feed()`,
  `gtfs_to_spec_format()`), since `@examplesIf mobdb_can_run_examples()`
  allows those examples to execute live API calls in that environment. On
  CRAN's build servers, no API key is configured, so these examples are
  skipped entirely and this NOTE will not occur.
