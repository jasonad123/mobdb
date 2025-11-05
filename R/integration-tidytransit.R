#' Read GTFS feed directly from Mobility Database
#'
#' @description
#' Convenience wrapper that fetches a feed's download URL from the Mobility
#' Database and passes it to [tidytransit::read_gtfs()]. Requires the tidytransit
#' package to be installed.
#'
#' @param feed_id Character. The unique identifier for the feed, or a data frame
#'   with a single row from [mobdb_feeds()] or [mobdb_search()].
#' @param dataset_id Character. Optional specific dataset ID. If `NULL` (default),
#'   uses the current/latest feed URL.
#' @param ... Additional arguments passed to [tidytransit::read_gtfs()].
#'
#' @return A `gtfs` object as returned by [tidytransit::read_gtfs()].
#'
#' @examples
#' \dontrun{
#' # Read latest feed by ID
#' gtfs <- mobdb_read_gtfs("mdb-123")
#'
#' # Read from search results
#' sf_muni <- mobdb_search("SF Muni") |> slice(1)
#' gtfs <- mobdb_read_gtfs(sf_muni)
#'
#' # Read specific historical dataset
#' gtfs_historical <- mobdb_read_gtfs("mdb-123", dataset_id = "dataset-456")
#' }
#'
#' @export
mobdb_read_gtfs <- function(feed_id, dataset_id = NULL, ...) {
  if (!requireNamespace("tidytransit", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg tidytransit} package is required to use this function.",
      "i" = "Install it with {.code install.packages('tidytransit')}."
    ))
  }
  
  # Handle data frame input
  if (is.data.frame(feed_id)) {
    if (nrow(feed_id) != 1) {
      cli::cli_abort("{.arg feed_id} data frame must have exactly one row.")
    }
    
    # Try to extract URL directly if available from actual API structure
    if ("source_info" %in% names(feed_id) && 
        is.data.frame(feed_id$source_info) &&
        "producer_url" %in% names(feed_id$source_info)) {
      url <- feed_id$source_info$producer_url[1]
    } else if ("urls.direct_download" %in% names(feed_id)) {
      url <- feed_id$urls.direct_download
    } else if ("id" %in% names(feed_id)) {
      feed_id <- feed_id$id
      url <- mobdb_feed_url(feed_id)
    } else {
      cli::cli_abort("Cannot extract feed ID or URL from provided data frame.")
    }
  } else {
    # Get URL based on feed_id or dataset_id
    if (!is.null(dataset_id)) {
      dataset <- mobdb_get_dataset(dataset_id)
      url <- dataset$download_url %||% dataset$hosted_url
      
      if (is.null(url)) {
        cli::cli_abort("No download URL found for dataset {.val {dataset_id}}.")
      }
    } else {
      url <- mobdb_feed_url(feed_id)
    }
  }
  
  if (is.null(url)) {
    cli::cli_abort("Could not determine download URL.")
  }
  
  cli::cli_inform("Downloading GTFS feed from: {.url {url}}")
  
  tidytransit::read_gtfs(url, ...)
}

#' Download GTFS Schedule feed (one-stop-shop)
#'
#' @description
#' A convenience function for downloading GTFS Schedule feeds. This is a
#' "one-stop-shop" that can search for feeds by provider/location and download
#' them in a single call, or download a specific feed by ID.
#'
#' **Note:** This function is specifically designed for GTFS Schedule feeds only.
#' GTFS Realtime feeds use a different data model (streaming endpoints rather
#' than downloadable archives) and are not supported by this function.
#'
#' @param feed_id Character. The unique identifier for the feed (e.g., "mdb-2862").
#'   If provided, all other search parameters are ignored.
#' @param provider Character. Filter by provider/agency name (partial match).
#'   Use this to search for feeds without knowing the feed_id.
#' @param country_code Character. Two-letter ISO country code (e.g., "US", "CA").
#' @param subdivision_name Character. State, province, or region name.
#' @param municipality Character. City or municipality name.
#' @param exclude_flex Logical. If `TRUE` (default), automatically exclude feeds
#'   with "flex" in the feed name (case-insensitive). GTFS-Flex feeds have different
#'   schemas and may not work with standard GTFS tools.
#' @param feed_name Character. Optional filter for feed name. If provided, only
#'   feeds whose `feed_name` contains this string (case-insensitive) will be
#'   considered. Use `NULL` (default) to skip this filter.
#' @param use_source_url Logical. If `FALSE` (default), uses MobilityData's
#'   hosted/archived URL which ensures you get the exact version in their database.
#'   If `TRUE`, uses the provider's direct source URL which may be more current
#'   but could differ from MobilityData's archived version.
#' @param latest Logical. If `TRUE` (default), download the most recent dataset.
#'   If `FALSE`, returns information about all available datasets for the feed.
#' @param status Character. Feed status filter: "active" (default), "inactive",
#'   or "deprecated". Only used when searching by provider/location.
#' @param ... Additional arguments passed to [tidytransit::read_gtfs()].
#'
#' @return If `latest = TRUE`, a `gtfs` object as returned by [tidytransit::read_gtfs()].
#'   If `latest = FALSE`, a tibble of all available datasets with their metadata.
#'
#' @examples
#' \dontrun{
#' # Download by feed ID
#' gtfs <- mobdb_download_feed("mdb-2862")
#'
#' # Search and download by provider name (excludes Flex automatically)
#' gtfs <- mobdb_download_feed(provider = "Arlington")
#'
#' # Download using agency's source URL instead of MobilityData hosted
#' gtfs <- mobdb_download_feed(provider = "San Francisco", use_source_url = TRUE)
#'
#' # Include Flex feeds in search
#' gtfs <- mobdb_download_feed(provider = "Arlington", exclude_flex = FALSE)
#'
#' # Filter by location
#' gtfs <- mobdb_download_feed(
#'   country_code = "US",
#'   subdivision_name = "California",
#'   municipality = "San Francisco"
#' )
#'
#' # See all available versions for a feed
#' versions <- mobdb_download_feed("mdb-2862", latest = FALSE)
#' }
#'
#' @export
mobdb_download_feed <- function(feed_id = NULL,
                                 provider = NULL,
                                 country_code = NULL,
                                 subdivision_name = NULL,
                                 municipality = NULL,
                                 exclude_flex = TRUE,
                                 feed_name = NULL,
                                 use_source_url = FALSE,
                                 latest = TRUE,
                                 status = "active",
                                 ...) {
  if (!requireNamespace("tidytransit", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg tidytransit} package is required to use this function.",
      "i" = "Install it with {.code install.packages('tidytransit')}."
    ))
  }

  # Determine if we need to search for feeds
  search_params_provided <- !is.null(provider) || !is.null(country_code) ||
    !is.null(subdivision_name) || !is.null(municipality)

  # Case 1: feed_id provided directly
  if (!is.null(feed_id)) {
    if (search_params_provided) {
      cli::cli_warn(c(
        "Both {.arg feed_id} and search parameters provided.",
        "i" = "Ignoring search parameters and using {.arg feed_id} directly."
      ))
    }

    selected_feed_id <- feed_id

  # Case 2: Search for feed using provider/location filters
  } else if (search_params_provided) {
    cli::cli_inform("Searching for GTFS Schedule feeds...")

    # Query feeds with provided filters
    feeds <- mobdb_feeds(
      provider = provider,
      country_code = country_code,
      subdivision_name = subdivision_name,
      municipality = municipality,
      data_type = "gtfs",  # GTFS Schedule only
      status = status,
      limit = 100
    )

    if (nrow(feeds) == 0) {
      cli::cli_abort(c(
        "No GTFS Schedule feeds found matching your criteria.",
        "i" = "Try broadening your search parameters."
      ))
    }

    # Apply feed_name filters
    original_count <- nrow(feeds)

    # Exclude Flex feeds if requested
    if (exclude_flex) {
      feeds <- feeds[!grepl("flex", feeds$feed_name, ignore.case = TRUE), ]

      if (nrow(feeds) == 0) {
        cli::cli_abort(c(
          "All {original_count} feed{?s} found {?was/were} GTFS-Flex feed{?s}.",
          "i" = "Set {.code exclude_flex = FALSE} to include Flex feeds."
        ))
      }

      if (nrow(feeds) < original_count) {
        cli::cli_inform("Excluded {original_count - nrow(feeds)} Flex feed{?s}.")
      }
    }

    # Apply custom feed_name filter if provided
    if (!is.null(feed_name)) {
      feeds <- feeds[grepl(feed_name, feeds$feed_name, ignore.case = TRUE), ]

      if (nrow(feeds) == 0) {
        cli::cli_abort(c(
          "No feeds found with {.val {feed_name}} in feed name.",
          "i" = "Remove or adjust the {.arg feed_name} filter."
        ))
      }
    }

    # Handle multiple feeds
    if (nrow(feeds) > 1) {
      # Display feed details in a readable format
      cli::cli_inform(c(
        "!" = "Found {nrow(feeds)} matching feeds:",
        " " = ""
      ))

      # Print a clean table of options
      feed_summary <- feeds[, c("id", "provider", "feed_name", "status")]
      print(feed_summary)

      cli::cli_abort(c(
        "x" = "Multiple feeds found. Please specify which one to download.",
        "i" = "Use {.code mobdb_download_feed(feed_id = \"mdb-XXX\")} with one of the IDs above.",
        "i" = "Or refine your search with the {.arg provider} or {.arg feed_name} parameters."
      ))
    }

    selected_feed_id <- feeds$id[1]
    cli::cli_inform("Found feed: {.val {feeds$provider[1]}} - {.val {feeds$feed_name[1]}} ({.val {selected_feed_id}})")

  # Case 3: No feed_id or search parameters
  } else {
    cli::cli_abort(c(
      "Must provide either {.arg feed_id} or search parameters.",
      "i" = "Specify {.arg feed_id} directly, or use {.arg provider}/{.arg country_code}/etc. to search."
    ))
  }

  # Get dataset(s) for the feed
  datasets <- mobdb_datasets(selected_feed_id, latest = latest)

  if (!latest) {
    # Return all datasets for user to choose from
    return(datasets)
  }

  # Get the hosted URL from the latest dataset
  if (nrow(datasets) == 0) {
    cli::cli_abort("No datasets found for feed {.val {selected_feed_id}}.")
  }

  # Choose URL source
  if (use_source_url) {
    # Get source URL from feed details
    feed_details <- mobdb_get_feed(selected_feed_id)
    url <- feed_details$source_info$producer_url

    if (is.null(url) || is.na(url)) {
      cli::cli_abort(c(
        "No source URL found for feed {.val {selected_feed_id}}.",
        "i" = "Try setting {.code use_source_url = FALSE} to use MobilityData's hosted URL."
      ))
    }

    cli::cli_inform("Downloading from agency source: {.url {url}}")
  } else {
    # Use MobilityData hosted URL
    url <- datasets$hosted_url[1]

    if (is.null(url) || is.na(url)) {
      cli::cli_abort(c(
        "No hosted URL found for feed {.val {selected_feed_id}}.",
        "i" = "Try setting {.code use_source_url = TRUE} to use the agency's source URL."
      ))
    }

    cli::cli_inform("Downloading from MobilityData: {.url {url}}")
  }

  tidytransit::read_gtfs(url, ...)
}
