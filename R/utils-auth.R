#' Set Mobility Database API refresh token
#'
#' @description
#' Store your Mobility Database API refresh token for use in subsequent API calls.
#' The refresh token is used to generate short-lived access tokens automatically.
#'
#' @param refresh_token Character. Your Mobility Database API refresh token.
#'   Obtain this by signing up at https://mobilitydatabase.org and navigating
#'   to your account details page.
#' @param install Logical. If `TRUE`, will set the token in `.Renviron` for use
#'   across sessions. If `FALSE` (default), token is only set for the current session.
#'
#' @return Invisibly returns `TRUE` if successful.
#'
#' @examples
#' \dontrun{
#' # Set token for current session
#' mobdb_set_key("your_refresh_token_here")
#'
#' # Set token permanently in .Renviron
#' mobdb_set_key("your_refresh_token_here", install = TRUE)
#' }
#'
#' @export
mobdb_set_key <- function(refresh_token, install = FALSE) {
  if (!is.character(refresh_token) || length(refresh_token) != 1) {
    cli::cli_abort("{.arg refresh_token} must be a single character string.")
  }
  
  if (nchar(refresh_token) == 0) {
    cli::cli_abort("{.arg refresh_token} cannot be empty.")
  }
  
  mobdb_env$refresh_token <- refresh_token
  mobdb_env$access_token <- NULL  # Clear any existing access token
  
  if (install) {
    set_renviron_key(refresh_token)
    cli::cli_inform(c(
      "v" = "Refresh token set and saved to {.file .Renviron}.",
      "i" = "Restart R for the change to take effect across sessions."
    ))
  } else {
    cli::cli_inform(c(
      "v" = "Refresh token set for current session.",
      "i" = "Use {.code install = TRUE} to save permanently."
    ))
  }
  
  invisible(TRUE)
}

#' Get current access token, refreshing if necessary
#'
#' @description
#' Internal function to retrieve or refresh the access token. Users typically
#' don't need to call this directly.
#'
#' @param force Logical. If `TRUE`, force refresh the access token even if
#'   one already exists.
#'
#' @return Character. The current valid access token.
#' @keywords internal
#' @noRd
mobdb_token <- function(force = FALSE) {
  # Check for refresh token
  if (is.null(mobdb_env$refresh_token)) {
    refresh_token <- Sys.getenv("MOBDB_REFRESH_TOKEN", "")
    if (nchar(refresh_token) > 0) {
      mobdb_env$refresh_token <- refresh_token
    } else {
      cli::cli_abort(c(
        "No refresh token found.",
        "i" = "Set your token with {.code mobdb_set_key()}.",
        "i" = "Get a token at {.url https://mobilitydatabase.org}."
      ))
    }
  }
  
  # Return existing access token if available and not forcing refresh
  if (!force && !is.null(mobdb_env$access_token)) {
    return(mobdb_env$access_token)
  }
  
  # Generate new access token
  mobdb_env$access_token <- generate_access_token(mobdb_env$refresh_token)
  mobdb_env$access_token
}

#' Generate access token from refresh token
#'
#' @param refresh_token Character. The refresh token.
#'
#' @return Character. A new access token.
#' @keywords internal
#' @noRd
generate_access_token <- function(refresh_token) {
  req <- httr2::request(mobdb_env$base_url) |>
    httr2::req_url_path_append("tokens") |>
    httr2::req_headers("Content-Type" = "application/json") |>
    httr2::req_body_json(list(refresh_token = refresh_token)) |>
    httr2::req_error(body = mobdb_error_body) |>
    httr2::req_retry(max_tries = 3)
  
  resp <- httr2::req_perform(req)
  body <- httr2::resp_body_json(resp)
  
  if (is.null(body$access_token)) {
    cli::cli_abort("Failed to generate access token. Check your refresh token.")
  }
  
  body$access_token
}

#' Set token in .Renviron
#'
#' @param token Character. The refresh token to store.
#'
#' @return Invisibly returns `TRUE`.
#' @keywords internal
#' @noRd
set_renviron_key <- function(token) {
  renviron_path <- file.path(Sys.getenv("HOME"), ".Renviron")
  
  if (file.exists(renviron_path)) {
    lines <- readLines(renviron_path)
    # Remove any existing MOBDB_REFRESH_TOKEN lines
    lines <- lines[!grepl("^MOBDB_REFRESH_TOKEN=", lines)]
  } else {
    lines <- character()
  }
  
  # Add new token
  lines <- c(lines, paste0("MOBDB_REFRESH_TOKEN=", token))
  
  writeLines(lines, renviron_path)
  invisible(TRUE)
}

#' Check if authentication is configured
#'
#' @description
#' Check whether a refresh token has been set for the current session or
#' is available in the environment.
#'
#' @return Logical. `TRUE` if a token is configured, `FALSE` otherwise.
#'
#' @examples
#' \dontrun{
#' mobdb_has_key()
#' }
#'
#' @export
mobdb_has_key <- function() {
  !is.null(mobdb_env$refresh_token) || 
    nchar(Sys.getenv("MOBDB_REFRESH_TOKEN", "")) > 0
}
