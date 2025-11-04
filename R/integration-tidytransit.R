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

#' Download GTFS feed from MobilityData hosted URL
#'
#' @description
#' Downloads the latest GTFS feed using MobilityData's hosted/archived URL
#' rather than the provider's source URL. This ensures you're getting the
#' exact version stored in MobilityData's database with validated metadata.
#'
#' @param feed_id Character. The unique identifier for the feed (e.g., "mdb-2862").
#' @param latest Logical. If `TRUE` (default), download the most recent dataset.
#'   If `FALSE`, returns information about all available datasets.
#' @param ... Additional arguments passed to [tidytransit::read_gtfs()].
#'
#' @return If `latest = TRUE`, a `gtfs` object as returned by [tidytransit::read_gtfs()].
#'   If `latest = FALSE`, a tibble of all available datasets with their metadata.
#'
#' @examples
#' \dontrun{
#' # Download latest MobilityData-hosted version
#' gtfs <- mobdb_download_feed("mdb-2862")
#'
#' # See all available versions
#' versions <- mobdb_download_feed("mdb-2862", latest = FALSE)
#' }
#'
#' @export
mobdb_download_feed <- function(feed_id, latest = TRUE, ...) {
  if (!requireNamespace("tidytransit", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg tidytransit} package is required to use this function.",
      "i" = "Install it with {.code install.packages('tidytransit')}."
    ))
  }

  # Get dataset(s) for the feed
  datasets <- mobdb_datasets(feed_id, latest = latest)

  if (!latest) {
    # Return all datasets for user to choose from
    return(datasets)
  }

  # Get the hosted URL from the latest dataset
  if (nrow(datasets) == 0) {
    cli::cli_abort("No datasets found for feed {.val {feed_id}}.")
  }

  url <- datasets$hosted_url[1]

  if (is.null(url) || is.na(url)) {
    cli::cli_abort("No hosted URL found for feed {.val {feed_id}}.")
  }

  cli::cli_inform("Downloading GTFS feed from MobilityData: {.url {url}}")

  tidytransit::read_gtfs(url, ...)
}
