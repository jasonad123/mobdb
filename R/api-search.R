#' Search for feeds across the Mobility Database
#'
#' @description
#' Perform a text search across feed names, providers, and locations.
#' This is useful when you don't know the exact feed ID or want to
#' discover feeds based on keywords.
#'
#' @param query Character. Search query string. Searches across provider names,
#'   feed names, and locations.
#' @param data_type Character. Optional filter by data type: "gtfs" or "gtfs_rt".
#' @param country_code Character. Optional filter by two-letter ISO country code.
#' @param limit Integer. Maximum number of results (default: 50).
#'
#' @return A tibble of matching feeds with the same structure as [mobdb_feeds()].
#'
#' @examples
#' \dontrun{
#' # Search for transit agencies
#' bart <- mobdb_search("BART")
#' mta <- mobdb_search("MTA New York")
#'
#' # Search with filters
#' canadian_transit <- mobdb_search(
#'   "transit",
#'   country_code = "CA",
#'   data_type = "gtfs"
#' )
#' }
#'
#' @export
mobdb_search <- function(query,
                         data_type = NULL,
                         country_code = NULL,
                         limit = 50) {
  
  if (!is.character(query) || length(query) != 1 || nchar(query) == 0) {
    cli::cli_abort("{.arg query} must be a non-empty character string.")
  }
  
  # Validate data_type if provided
  if (!is.null(data_type)) {
    data_type <- match.arg(data_type, c("gtfs", "gtfs_rt"))
  }
  
  # Build query parameters
  query_params <- build_query(
    q = query,
    data_type = data_type,
    country_code = country_code,
    limit = limit
  )
  
  # Make request
  req <- mobdb_request("search") |>
    httr2::req_url_query(!!!query_params)
  
  resp <- httr2::req_perform(req)
  check_rate_limit(resp)
  
  mobdb_parse_response(resp)
}
