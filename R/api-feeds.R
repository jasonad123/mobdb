#' List and filter GTFS Schedule, GTFS-RT, and GBFS feeds
#'
#' @description
#' Query the Mobility Database for transit/bikeshare feeds matching specified criteria.
#' Returns a tibble with feed metadata including download URLs.
#'
#' *This function was formerly called \code{mobdb_feeds()}.*
#'
#' @param provider A string. Filter by provider/agency name (partial match).
#' @param country_code A string. Two-letter ISO country code
#'   (e.g., "US", "CA"). **Note:** Location filters (`country_code`,
#'   `subdivision_name`, `municipality`) require `data_type` to be specified.
#' @param subdivision_name A string. State, province, or region name.
#'   Requires `data_type` to be specified.
#' @param municipality A string. City, municipality, or jurisdiction name.
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
#' @param use_cache A logical. If `TRUE` (default), use cached results if available.
#'   If `FALSE`, always fetch fresh data from the API. Cached data expires after 1 hour.
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
                  offset = 0,
                  use_cache = TRUE) {

  # Check cache first
  if (use_cache) {
    cache_key <- generate_cache_key(
      provider = provider,
      country_code = country_code,
      subdivision_name = subdivision_name,
      municipality = municipality,
      data_type = data_type,
      status = status,
      official = official,
      limit = limit,
      offset = offset,
      prefix = "feeds"
    )
    cached <- read_from_cache(cache_key, max_age = get_cache_ttl("feeds"))
    if (!is.null(cached)) return(cached)
  }

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

  # Write to cache
  if (use_cache) {
    write_to_cache(result, cache_key)
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
#' Convenience function to quickly get the direct download or source URL for a feed.
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
#' 
#' @export
mobdb_feed_url <- function(feed_id) {
  feed <- mobdb_get_feed(feed_id)

  # Try different possible locations for the URL
  # Based on actual API: URL is in source_info$producer_url
  url <- feed$source_info$producer_url

  if (is.null(url)) {
    cli::cli_warn("No download URL found for feed {.val {feed_id}}.")
  }

  url
}

#' Get `authentication_type` for a feed
#'
#' @description
#' Internal function for getting the `authentication_type` for API authentication purposes
#' This is then used by `auth_args=` parameters in `download_feed()` and similar functions
#' to enable direct download of feeds requiring an API key or similar
#' 
#' @param feed_id A string. The unique identifier for the feed.
#'
#' @return An integer. 
#' - 0 or `NULL` means the feed does not require authentication
#' - 1 means the authentication requires an API key, which should be passed as value of the parameter api_key_parameter_name in the URL. 
#' - 2 means the authentication requires an HTTP header, which should be passed as the value of the header api_key_parameter_name in the HTTP request. 
#' 
#' When not provided, the authentication type is assumed to be 0.
#'
#' @noRd
mobdb_authentication_type <- function(feed_id) {
  feed <- mobdb_get_feed(feed_id)

  # Based on actual API: URL is in source_info$authentication_type
  result <- feed$source_info$authentication_type

  result
}


#' Get `api_key_parameter_name` for a feed
#'
#' @description
#' Internal function for getting the `api_key_parameter_name` for API authentication purposes
#' This is then used by `auth_args=` parameters in `download_feed()` and similar functions
#'
#' @param feed_id A string. The unique identifier for the feed.
#'
#' @return A string. Defines the name of the parameter to pass in the URL to provide the API key or `NULL` if not available.
#'
#' @noRd
mobdb_api_key_parameter_name <- function(feed_id) {
  feed <- mobdb_get_feed(feed_id)

  # Based on actual API: URL is in source_info$producer_url
  result <- feed$source_info$api_key_parameter_name

  result
}


#' Get `authentication_info_url` for a feed
#'
#' @description
#' Internal function for getting the `authentication_info_url` for API authentication purposes
#' This is then used by `auth_args=` parameters in `download_feed()` and similar functions
#' This function returns a URL that describes the how API auth credentials are created
#'
#' *NOTE:* Per the Mobility Database API, authentication_info_url is required if `authentication_type` is 1 or 2
#' so this function will warn if this is the case
#'
#' @param feed_id A string. The unique identifier for the feed.
#'
#' @return A string. Defines the authentication info URL
#'
#' @noRd
mobdb_authentication_info_url <- function(feed_id) {
  feed <- mobdb_get_feed(feed_id)

  # Try different possible locations for the URL
  # Based on actual API: URL is in source_info$producer_url
  url <- feed$source_info$authentication_info_url

  auth_type <- mobdb_authentication_type(feed_id)

  if (is.null(url) && auth_type > 0) {
    cli::cli_warn("No authentication info URL found for feed {.val {feed_id}}.")
    cli::cli_warn("Contact the agency directly for more information on how to access their API.")
  }

  url
}


#' Parse auth_args parameter
#'
#' @description
#' Internal helper to parse auth_args parameter, which can be provided as:
#' - "value" - just the API key/token value
#' - "param_name=value" - explicit parameter name and value
#'
#' @param auth_args A string. The authentication argument(s)
#' @param expected_param_name A string. The expected parameter name from API
#'
#' @return A string. The API key/token value
#'
#' @noRd
parse_auth_args <- function(auth_args, expected_param_name = NULL) {
  if (is.null(auth_args) || is.na(auth_args)) {
    return(NULL)
  }

  # Check if auth_args contains "=" (explicit param=value format)
  if (grepl("=", auth_args, fixed = TRUE)) {
    parts <- strsplit(auth_args, "=", fixed = TRUE)[[1]]
    if (length(parts) != 2) {
      cli::cli_abort(c(
        "Invalid {.arg auth_args} format: {.val {auth_args}}",
        "i" = "Expected format: {.code param_name=value} or just {.code value}"
      ))
    }

    param_name <- parts[1]
    value <- parts[2]

    # Validate that provided param name matches expected (if expected is known)
    if (!is.null(expected_param_name) && !is.na(expected_param_name)) {
      if (param_name != expected_param_name) {
        cli::cli_warn(c(
          "Provided parameter name {.val {param_name}} does not match expected {.val {expected_param_name}}",
          "i" = "Using provided parameter name anyway"
        ))
      }
    }

    return(value)
  } else {
    # auth_args is just the value
    return(auth_args)
  }
}


#' Build authenticated URL for feed download
#'
#' @description
#' Internal function to construct an authenticated download URL or httr2 request
#' based on the feed's authentication requirements
#'
#' @param url A string. The base URL to download from
#' @param auth_type An integer. Authentication type (0=none, 1=URL param, 2=HTTP header)
#' @param auth_param_name A string. Name of the authentication parameter/header
#' @param auth_value A string. The API key/token value
#'
#' @return A string (for auth_type=1) or httr2 request object (for auth_type=2)
#'
#' @noRd
build_authenticated_request <- function(url, auth_type, auth_param_name, auth_value) {
  # Type 0: No authentication needed
  if (is.null(auth_type) || is.na(auth_type) || auth_type == 0) {
    return(url)
  }

  # Type 1: URL query parameter authentication
  if (auth_type == 1) {
    if (is.null(auth_param_name) || is.na(auth_param_name)) {
      cli::cli_abort(c(
        "Authentication type 1 requires {.field api_key_parameter_name}",
        "i" = "This information is missing from the API response"
      ))
    }

    # Check if URL already has query parameters
    separator <- if (grepl("?", url, fixed = TRUE)) "&" else "?"

    # Build authenticated URL with query parameter
    authenticated_url <- paste0(url, separator, auth_param_name, "=", auth_value)
    return(authenticated_url)
  }

  # Type 2: HTTP header authentication
  if (auth_type == 2) {
    if (is.null(auth_param_name) || is.na(auth_param_name)) {
      cli::cli_abort(c(
        "Authentication type 2 requires {.field api_key_parameter_name}",
        "i" = "This information is missing from the API response"
      ))
    }

    # Return httr2 request with authentication header
    # Note: This will be used by tidytransit::read_gtfs() which accepts httr2 requests
    req <- httr2::request(url) |>
      httr2::req_headers(!!auth_param_name := auth_value)

    return(req)
  }

  # Unknown authentication type
  cli::cli_abort(c(
    "Unknown authentication type: {.val {auth_type}}",
    "i" = "Expected 0, 1, or 2"
  ))
}


