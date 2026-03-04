# Condition Helper Functions for Examples
#
# These functions are used with @examplesIf to control conditional
# execution of examples on CRAN and in different environments.

#' Check if internet connection is available
#'
#' Tests whether internet connectivity is available for API calls.
#' Used internally to control example execution on CRAN.
#'
#' @return Logical. `TRUE` if internet is available, `FALSE` otherwise.
#' @importFrom curl nslookup
#' @keywords internal
#' @export
#' @examples
#' mobdb_has_internet()
mobdb_has_internet <- function() {
  !is.null(curl::nslookup("api.mobilitydatabase.org", error = FALSE))
}

#' Check if mobdb examples can run
#'
#' Tests whether both internet connectivity and an API key are available.
#' Used to control example execution on CRAN.
#'
#' @return Logical. `TRUE` if examples can run, `FALSE` otherwise.
#' @keywords internal
#' @export
#' @examples
#' mobdb_can_run_examples()
mobdb_can_run_examples <- function() {
  mobdb_has_internet() && mobdb_has_key()
}

#' Check if tidytransit package is available
#'
#' Tests whether the tidytransit package is installed.
#' Used to control example execution for functions that require tidytransit.
#'
#' @return Logical. `TRUE` if tidytransit is available, `FALSE` otherwise.
#' @keywords internal
#' @export
#' @examples
#' mobdb_has_tidytransit()
mobdb_has_tidytransit <- function() {
  requireNamespace("tidytransit", quietly = TRUE)
}
