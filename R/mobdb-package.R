#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom tibble tibble as_tibble
#' @importFrom rlang .data abort warn inform %||%
#' @importFrom cli cli_abort cli_warn cli_inform
## usethis namespace: end
NULL

# Package environment for storing authentication tokens and state
mobdb_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  mobdb_env$base_url <- "https://api.mobilitydatabase.org/v1"
  mobdb_env$access_token <- NULL
  mobdb_env$refresh_token <- NULL
}

.onAttach <- function(libname, pkgname) {
  if (interactive() && is.null(mobdb_env$refresh_token)) {
    packageStartupMessage(
      "To use mobdb, set your API refresh token with:\n",
      "  mobdb_set_key(\"your_refresh_token\")\n",
      "Get your token at: https://mobilitydatabase.org"
    )
  }
}
