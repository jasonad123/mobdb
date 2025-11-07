#' Load the Mobility Database in browser
#'
#' @description
#' Opens the Mobility Database in your default web browser.
#' You'll need to log in or sign up on the website to get an
#' API key to use this package.
#'
#' @return Invisibly returns the URL that was opened.
#'
#'
#' @export
mobdb_browse <- function() {
  url <- "https://mobilitydatabase.org"
  cli::cli_inform("Opening Mobility Database in browser: {.url {url}}")
  utils::browseURL(url)

  invisible(url)
}