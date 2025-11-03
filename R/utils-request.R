#' Build a base request to the Mobility Database API
#'
#' @param endpoint Character. The API endpoint path (without leading slash).
#'
#' @return An `httr2_request` object.
#' @keywords internal
#' @noRd
mobdb_request <- function(endpoint) {
  httr2::request(mobdb_env$base_url) |>
    httr2::req_url_path_append(endpoint) |>
    httr2::req_auth_bearer_token(mobdb_token()) |>
    httr2::req_headers(Accept = "application/json") |>
    httr2::req_user_agent(mobdb_user_agent()) |>
    httr2::req_retry(
      max_tries = 3,
      max_seconds = 120
    ) |>
    httr2::req_error(body = mobdb_error_body)
}

#' Extract error message from API response
#'
#' @param resp An `httr2_response` object.
#'
#' @return Character. The error message.
#' @keywords internal
#' @noRd
mobdb_error_body <- function(resp) {
  body <- httr2::resp_body_json(resp)
  
  if (!is.null(body$detail)) {
    return(body$detail)
  }
  
  if (!is.null(body$message)) {
    return(body$message)
  }
  
  "An unknown error occurred"
}

#' Generate user agent string
#'
#' @return Character. User agent string identifying the package and version.
#' @keywords internal
#' @noRd
mobdb_user_agent <- function() {
  version <- utils::packageVersion("mobdb")
  paste0("mobdb/", version, " (R ", getRversion(), ")")
}

#' Parse API response to tibble
#'
#' @param resp An `httr2_response` object.
#' @param simplify Logical. Whether to simplify nested structures.
#'
#' @return A tibble.
#' @keywords internal
#' @noRd
mobdb_parse_response <- function(resp, simplify = TRUE) {
  body <- httr2::resp_body_json(resp, simplifyVector = simplify)
  
  # Handle different response structures
  if (is.data.frame(body)) {
    return(tibble::as_tibble(body))
  }
  
  # If response has a 'results' or 'data' field, extract it
  if (is.list(body)) {
    if (!is.null(body$results)) {
      return(tibble::as_tibble(body$results))
    }
    if (!is.null(body$data)) {
      return(tibble::as_tibble(body$data))
    }
    if (!is.null(body$feeds)) {
      return(tibble::as_tibble(body$feeds))
    }
  }
  
  # Otherwise return as-is, attempting to coerce to tibble
  tibble::as_tibble(body)
}

#' Check rate limiting and warn if approaching limits
#'
#' @param resp An `httr2_response` object.
#'
#' @keywords internal
#' @noRd
check_rate_limit <- function(resp) {
  headers <- httr2::resp_headers(resp)
  
  limit <- headers$`x-ratelimit-limit`
  remaining <- headers$`x-ratelimit-remaining`
  
  if (!is.null(limit) && !is.null(remaining)) {
    limit_num <- as.numeric(limit)
    remaining_num <- as.numeric(remaining)
    
    if (remaining_num / limit_num < 0.1) {
      cli::cli_warn(c(
        "!" = "Approaching rate limit: {remaining_num} of {limit_num} requests remaining.",
        "i" = "Consider spacing out your requests."
      ))
    }
  }
  
  invisible(NULL)
}

#' Build query parameters, removing NULL values
#'
#' @param ... Named arguments to use as query parameters.
#'
#' @return Named list of non-NULL parameters.
#' @keywords internal
#' @noRd
build_query <- function(...) {
  params <- list(...)
  params[!vapply(params, is.null, logical(1))]
}
