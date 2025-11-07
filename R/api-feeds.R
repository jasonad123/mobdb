#' List and filter feeds
#'
#' @description
#' Query the Mobility Database for transit/bikeshare feeds matching specified criteria.
#' Returns a tibble with feed metadata including download URLs.
#'
#' *This function was formerly called \code{mobdb_feeds()}.
#' All functions are identical to that function.*
#'
#' @param provider A string. Filter by provider/agency name (partial match).
#' @param country_code A string. Two-letter ISO country code
#'   (e.g., "US", "CA"). **Note:** Location filters (`country_code`,
#'   `subdivision_name`, `municipality`) require `data_type` to be specified.
#' @param subdivision_name A string. State, province, or region name.
#'   Requires `data_type` to be specified.
#' @param municipality A string. City or municipality name.
#'   Requires `data_type` to be specified.
#' @param data_type A string. Type of feed: "gtfs" (schedule),
#'   "gtfs_rt" (realtime), or "gbfs" (bike share). Required when using
#'   location filters.
#' @param status A string. Feed status: "active", "deprecated",
#'   "inactive", "development", or "future".
#' @param official A logical. If `TRUE`, only return official feeds.
#'   If `FALSE`, only return unofficial feeds. If `NULL` (default),
#'   return all feeds regardless of official status.
#' @param limit An integer. Maximum number of results to return (default: 100).
#' @param offset An integer. Number of results to skip for pagination
#'   (default: 0).
#'
#' @return A tibble containing feed information with columns including:
#'   * `id` - Unique feed identifier
#'   * `data_type` - Type of feed (gtfs, gtfs_rt, or gbfs)
#'   * `created_at` - Date and time feed was added to database
#'   * `external_ids` - External identifier information
#'   * `provider` - Transit agency/provider name
#'   * `feed_contact_email` - Contact email for the feed
#'   * `source_info` - Data frame containing:
#'     - `producer_url` - Direct download URL for the feed
#'     - `authentication_type` - Type of auth required (0 = none)
#'     - `authentication_info_url` - Human-readable page for authentication info
#'     - `api_key_parameter_name` - Name of the parameter to pass in the URL to provide the API key
#'     - `license_url` - License information
#'   * `created_at` - Feed creation timestamp
#'   * `status` - Feed status (active, inactive, deprecated)
#'   * `official` - Whether feed is official
#'   * `official_updated_at` - Date and time of last update
#'   * Additional metadata columns
#'
#' @examples
#' \dontrun{
#' # Get all active GTFS feeds in California
#' ca_feeds <- feeds(
#'   country_code = "US",
#'   subdivision_name = "California",
#'   data_type = "gtfs",
#'   status = "active"
#' )
#'
#' # Search for a specific provider
#' sf_muni <- feeds(provider = "San Francisco")
#'
#' # Get feeds with pagination
#' first_100 <- feeds(limit = 100, offset = 0)
#' next_100 <- feeds(limit = 100, offset = 100)
#' }
#' @export
feeds <- function(provider = NULL,
                  country_code = NULL,
                  subdivision_name = NULL,
                  municipality = NULL,
                  data_type = NULL,
                  status = NULL,
                  official = NULL,
                  limit = 100,
                  offset = 0) {

  # Validate data_type if provided
  if (!is.null(data_type)) {
    data_type <- match.arg(data_type, c("gtfs", "gtfs_rt", "gbfs"))
  }

  # Validate status if provided
  if (!is.null(status)) {
    status <- match.arg(status, c("active", "deprecated", "inactive", "development", "future"))
  }

  # Location filters require specific endpoints (data_type must be set)
  location_filters_used <- !is.null(country_code) ||
    !is.null(subdivision_name) ||
    !is.null(municipality)

  if (location_filters_used && is.null(data_type)) {
    cli::cli_abort(c(
      "Location filters require {.arg data_type} to be specified.",
      "i" = "The {.path /feeds} endpoint does not support filtering.",
      "i" = "Specify {.code data_type = \"gtfs\"}, {.code \"gtfs_rt\"},
              or {.code \"gbfs\"} to use location filters."
    ))
  }

  # Determine endpoint based on data_type
  # /feeds returns all types; use specific endpoints to filter by type
  endpoint <- if (!is.null(data_type)) {
    switch(data_type,
           "gtfs" = "gtfs_feeds",
           "gtfs_rt" = "gtfs_rt_feeds",
           "gbfs" = "gbfs_feeds",
           "feeds")
  } else {
    "feeds"
  }

  # Build query parameters (data_type not needed since endpoint filters it)
  query_params <- build_query(
    provider = provider,
    country_code = country_code,
    subdivision_name = subdivision_name,
    municipality = municipality,
    status = status,
    official = official,
    limit = limit,
    offset = offset
  )

  # Make request
  req <- mobdb_request(endpoint)

  if (length(query_params) > 0) {
    req <- httr2::req_url_query(req, !!!query_params)
  }

  resp <- httr2::req_perform(req)
  check_rate_limit(resp)

  result <- mobdb_parse_response(resp)

  # Post-filter for official status if needed (API may return NA values)
  if (!is.null(official) && nrow(result) > 0) {
    if (official) {
      # Keep only feeds where official is TRUE (exclude NA and FALSE)
      result <- result[!is.na(result$official) & result$official == TRUE, ]
    } else {
      # Keep only feeds where official is FALSE (exclude NA and TRUE)
      result <- result[!is.na(result$official) & result$official == FALSE, ]
    }
  }

  result
}

#' Get details for a specific feed
#'
#' @description
#' Retrieve detailed information about a single feed by its ID.
#'
#' @param feed_id A string. The unique identifier for the feed.
#'
#' @return A list containing detailed feed information.
#'
#' @examples
#' \dontrun{
#' # Get details for a specific feed
#' feed_details <- mobdb_get_feed("mdb-53")
#' }
#' @export
mobdb_get_feed <- function(feed_id) {
  if (!is.character(feed_id) || length(feed_id) != 1) {
    cli::cli_abort("{.arg feed_id} must be a single character string.")
  }

  req <- mobdb_request("feeds") |>
    httr2::req_url_path_append(feed_id)

  resp <- httr2::req_perform(req)
  check_rate_limit(resp)

  httr2::resp_body_json(resp)
}

#' Get download URL for a feed
#'
#' @description
#' Convenience function to quickly get the direct download URL for a feed.
#' This is useful for passing to tidytransit::read_gtfs() or similar
#' functions.
#'
#' @param feed_id A string. The unique identifier for the feed.
#'
#' @return A string. The direct download URL, or `NULL` if not available.
#'
#' @examples
#' \dontrun{
#' # Get download URL
#' url <- mobdb_feed_url("mdb-53")
#'
#' # Use with tidytransit
#' library(tidytransit)
#' gtfs <- read_gtfs(url)
#' }
#' @export
mobdb_feed_url <- function(feed_id) {
  feed <- mobdb_get_feed(feed_id)

  # Try different possible locations for the URL
  # Based on actual API: URL is in source_info$producer_url
  url <- feed$source_info$producer_url %||%
    feed$urls$direct_download %||%
    feed$direct_download_url %||%
    feed$url

  if (is.null(url)) {
    cli::cli_warn("No download URL found for feed {.val {feed_id}}.")
  }

  url
}
