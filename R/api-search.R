#' Search for feeds across the Mobility Database
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' 
#' Perform a text search across feed names, providers, and locations.
#'
#' **Note:** Search is performed on English words and is case insensitive.
#' Word order is not relevant for matching. For example `New York City Transit` will
#' be parsed as `new & york & city & transit`
#'
#' The endpoint used has known issues with relevance ranking.
#' For better results when searching by provider name,
#' consider using [feeds()] with the `provider` parameter.
#'
#' @param query A string. Search query string. Searches across provider names,
#'   feed names, and locations.
#' @param feed_id A string. The unique identifier for the feed (e.g. "mdb-696",
#'   "mdb-1707", "gbfs-lime_vancouver_bc"). When provided, searches only for
#'   this specific feed and all other filter parameters must be omitted.
#' @param data_type A string. Optional filter by data type: "gtfs", "gtfs_rt",
#'   or "gbfs".
#' @param official A logical. If `TRUE`, only return official feeds when
#'   searching by provider/location. If `FALSE`, only return unofficial feeds.
#'   If `NULL` (default), return all feeds regardless of official status.
#' @param status A string. Feed status filter: "active", "deprecated",
#'   "inactive", "development", or "future".
#' @param gtfs_feature A character vector. Filter feeds by their GTFS features. Only valid
#'   for GTFS Schedule feeds.
#'   [GTFS features definitions are defined here.](https://gtfs.org/getting-started/features/overview/)
#' @param gbfs_version A character vector. Comma-separated list of GBFS versions to filter by.
#'   Only valid for GBFS feeds. [GBFS version notes are defined here](https://github.com/MobilityData/gbfs/blob/master/README.md)
#' @param limit An integer. Maximum number of results (default: 50).
#' @param offset An integer. Number of results to skip for pagination (default: 0).
#'
#' @return A tibble of matching feeds. Note that search results include additional
#'   fields compared to [feeds()]:
#'   * `locations` - List of data frames with geographical information
#'   * `latest_dataset` - Data frame with most recent dataset details and validation
#'   * Core fields (`id`, `provider`, `data_type`, `status`, `source_info`) are the same
#'
#' @examples
#' \dontrun{
#' # Search for transit agencies (Note: results may not be well-ranked)
#' results <- mobdb_search("transit")
#'
#' # Better approach: use feeds() with provider filter
#' bart <- feeds(provider = "BART")
#' mta <- feeds(provider = "MTA New York")
#'
#' # Search with filters
#' gtfs_feeds <- mobdb_search(
#'   "transit",
#'   data_type = "gtfs",
#'   official = TRUE
#' )
#'
#' # Search with pagination
#' first_50 <- mobdb_search("train", limit = 50, offset = 0)
#' next_50 <- mobdb_search("train", limit = 50, offset = 50)
#'
#' # Search for official GTFS feeds only
#' official_feeds <- mobdb_search("metro", official = TRUE, data_type = "gtfs")
#'
#' # Note: For location-specific searches (state/province/city), use feeds() instead:
#' ontario_transit <- feeds(
#'   provider = "transit",
#'   country_code = "CA",
#'   subdivision_name = "Ontario",
#'   data_type = "gtfs"
#' )
#' }
#' @export
mobdb_search <- function(query,
                         feed_id = NULL,
                         data_type = NULL,
                         official = NULL,
                         status = NULL,
                         gtfs_feature = NULL,
                         gbfs_version = NULL,
                         limit = 50,
                         offset = 0) {


  if (!is.character(query) || length(query) != 1 || nchar(query) == 0) {
    cli::cli_abort("{.arg query} must be a non-empty character string.")
  }

  # Validate feed_id exclusivity
  if (!is.null(feed_id)) {
    other_params <- c(data_type, official, status, gtfs_feature, gbfs_version)
    if (any(!vapply(other_params, is.null, logical(1)))) {
      cli::cli_abort(c(
        "When {.arg feed_id} is provided, all other filter parameters are ignored.",
        "i" = "Remove other parameters or omit {.arg feed_id} to use filters."
      ))
    }
  }

  # Validate data_type if provided
  if (!is.null(data_type)) {
    data_type <- match.arg(data_type, c("gtfs", "gtfs_rt", "gbfs"))
  }

  # Validate status if provided
  if (!is.null(status)) {
    status <- match.arg(status, c("active", "deprecated", "inactive", "development", "future"))
  }

  # Validate gtfs_feature (GTFS only)
  if (!is.null(gtfs_feature) && !is.null(data_type) && data_type != "gtfs") {
    cli::cli_abort(c(
      "{.arg gtfs_feature} can only be used with GTFS Schedule feeds.",
      "i" = "Set {.code data_type = \"gtfs\"} to use this parameter."
    ))
  }

  # Validate gbfs_version (GBFS only)
  if (!is.null(gbfs_version) && !is.null(data_type) && data_type != "gbfs") {
    cli::cli_abort(c(
      "{.arg gbfs_version} can only be used with GBFS feeds.",
      "i" = "Set {.code data_type = \"gbfs\"} to use this parameter."
    ))
  }

  # Build query parameters
  query_params <- build_query(
    search_query = query,
    feed_id = feed_id,
    data_type = data_type,
    is_official = official,
    status = status,
    feature = gtfs_feature,
    version = gbfs_version,
    limit = limit,
    offset = offset
  )

  # Make request
  req <- mobdb_request("search") |>
    httr2::req_url_query(!!!query_params)

  resp <- httr2::req_perform(req)
  check_rate_limit(resp)

  mobdb_parse_response(resp)



}
