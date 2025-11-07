#' Read GTFS feed directly from Mobility Database
#'
#' @description
#' `r lifecycle::badge('superseded')`
#'
#' **Note:** This function is superseded by [download_feed()], which provides
#' the same functionality plus integrated search, Flex filtering, and more control
#' over data sources. New code should use [download_feed()] instead. This function
#' may be deprecated in the future once [download_feed()] supports historical datasets.
#'
#' Convenience wrapper that fetches a feed's download URL from the Mobility
#' Database and passes it to [tidytransit::read_gtfs()]. Requires the tidytransit
#' package to be installed.
#'
#' @param feed_id A string. The unique identifier for the feed, or a data frame
#'   with a single row from [feeds()] or [mobdb_search()].
#' @param dataset_id A string. Optional specific dataset ID. If `NULL` (default),
#'   uses the current/latest feed URL.
#' @param ... Additional arguments passed to [tidytransit::read_gtfs()].
#'
#' @return A `gtfs` object as returned by [tidytransit::read_gtfs()].
#'
#' @examples
#' \dontrun{
#' # Read latest feed by ID (Bay Area Rapid Transit)
#' gtfs <- mobdb_read_gtfs("mdb-53")
#'
#' # Read from search results
#' feeds <- feeds(provider = "TransLink", data_type = "gtfs")
#' gtfs <- mobdb_read_gtfs(feeds[1, ])
#'
#' # Read specific historical dataset
#' gtfs_historical <- mobdb_read_gtfs("mdb-53", dataset_id = "mdb-53-202510250025")
#' }
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

#' Download GTFS Schedule feed
#'
#' @description
#' A convenience function for downloading GTFS Schedule feeds from the Mobility Database.
#' This is a "one-stop-shop" that can search for feeds by provider/location and download
#' them in a single call, or download a specific feed by ID.
#'
#' **Note:** This function is specifically designed for GTFS Schedule feeds only.
#' GTFS Realtime and GBFS feeds use a different data model and are not supported by this function.
#'
#' *This function was formerly called \code{mobdb_download_feed()}.
#' All functions are identical to that function.*
#'
#' @param feed_id A string or data frame. The unique identifier for the feed
#'   (e.g., "mdb-2862"), or a single-row data frame from [feeds()] or
#'   [mobdb_search()]. If a data frame is provided, the feed ID will be extracted
#'   automatically. If provided, all other search parameters are ignored.
#' @param provider A string. Filter by provider/agency name (partial match).
#'   Use this to search for feeds without knowing the feed_id.
#' @param country_code A string. Two-letter ISO country code (e.g., "US", "CA").
#' @param subdivision_name A string. State, province, or region name.
#' @param municipality A string. City or municipality name.
#' @param exclude_flex A logical. If `TRUE` (default), automatically exclude feeds
#'   with "flex" in the feed name (case-insensitive). GTFS-Flex feeds are an extension of
#'   the GTFS Schedule specification and may contain files that have unique schemas
#'   that may not work with standard GTFS tools.
#' @param feed_name A string. Optional filter for feed name. If provided, only
#'   feeds whose `feed_name` contains this string (case-insensitive) will be
#'   considered. Use `NULL` (default) to skip this filter.
#' @param use_source_url A logical. If `FALSE` (default), uses MobilityData's
#'   hosted/archived URL which ensures you get the exact version in their database.
#'   If `TRUE`, uses the provider's direct source URL which may be more current
#'   but could differ from MobilityData's version.
#' @param dataset_id A string. Optional specific dataset ID for historical versions
#'   (e.g., "mdb-53-202510250025"). If provided, downloads that specific dataset
#'   version instead of the latest. Cannot be used with `use_source_url = TRUE`.
#'   If `dataset_id` is provided without `feed_id`, the feed ID will be automatically
#'   extracted from the dataset ID format.
#' @param latest A logical. If `TRUE` (default), download the most recent dataset.
#'   If `FALSE`, returns information about all available datasets for the feed
#'   without downloading. Only works when `feed_id` is provided directly; cannot
#'   be used with search parameters like `provider` or `country_code`.
#' @param status A string. Feed status filter: "active" (default), "deprecated",
#'   "inactive", "development", or "future". Only used when searching by provider/location.
#' @param official A logical. If `TRUE` (default), return official feeds and feeds
#'   with unknown official status (NA) when searching by provider/location.
#'   If `FALSE`, only return feeds explicitly marked as unofficial.
#'   If `NULL`, return all feeds regardless of official status.
#' @param ... Additional arguments passed to [tidytransit::read_gtfs()].
#'
#' @return If `latest = TRUE`, a `gtfs` object as returned by [tidytransit::read_gtfs()].
#'   If `latest = FALSE`, a tibble of all available datasets with their metadata.
#'
#' @examples
#' \dontrun{
#' # Download by feed ID
#' gtfs <- download_feed("mdb-2862")
#'
#' # Download from search results
#' feeds <- feeds(provider = "TransLink")
#' gtfs <- download_feed(feeds[36, ])
#'
#' # Search and download by provider name (excludes Flex automatically)
#' gtfs <- download_feed(provider = "Arlington")
#'
#' # Download using agency's source URL instead of MobilityData hosted
#' gtfs <- download_feed(provider = "TriMet", use_source_url = TRUE)
#'
#' # Include Flex feeds in search
#' gtfs <- download_feed(provider = "Arlington", exclude_flex = FALSE)
#'
#' # Filter by location
#' gtfs <- download_feed(
#'   country_code = "US",
#'   subdivision_name = "California",
#'   municipality = "San Francisco"
#' )
#'
#' # Search and download all feeds, including unofficial ones
#' gtfs <- download_feed(provider = "TTC", official = NULL)
#'
#' # See all available versions for a feed
#' versions <- download_feed("mdb-2862", latest = FALSE)
#'
#' # Download a specific historical version (feed_id auto-extracted from dataset_id)
#' historical <- download_feed(dataset_id = "mdb-53-202507240047")
#'
#' # Or specify both explicitly
#' historical <- download_feed("mdb-53", dataset_id = "mdb-53-202507240047")
#' }
#' @seealso
#' [mobdb_datasets()] to list all available historical versions,
#' [get_validation_report()] to check feed quality before downloading,
#' [feeds()] to search for feeds,
#' [mobdb_read_gtfs()] for more flexible GTFS reading
#'
#' @export
download_feed <- function(feed_id = NULL,
                          provider = NULL,
                          country_code = NULL,
                          subdivision_name = NULL,
                          municipality = NULL,
                          exclude_flex = TRUE,
                          feed_name = NULL,
                          use_source_url = FALSE,
                          dataset_id = NULL,
                          latest = TRUE,
                          status = "active",
                          official = NULL,
                          ...) {
  if (!requireNamespace("tidytransit", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg tidytransit} package is required to use this function.",
      "i" = "Install it with {.code install.packages('tidytransit')}."
    ))
  }

  # Validate parameter combinations
  if (!is.null(dataset_id) && use_source_url) {
    cli::cli_abort(c(
      "Cannot use {.arg dataset_id} with {.arg use_source_url = TRUE}.",
      "i" = "Historical datasets are only available from MobilityData's hosted URLs.",
      "i" = "Set {.code use_source_url = FALSE} to download a specific dataset version."
    ))
  }

  # Check if search parameters are being used with latest = FALSE
  search_params_check <- !is.null(provider) || !is.null(country_code) ||
    !is.null(subdivision_name) || !is.null(municipality)

  if (search_params_check && !latest) {
    cli::cli_abort(c(
      "{.arg latest = FALSE} cannot be used with search parameters.",
      "x" = "The {.arg latest} parameter only works when specifying {.arg feed_id} directly.",
      "i" = "First find the feed ID you want, then use {.code download_feed(feed_id = \"mdb-XXX\", latest = FALSE)}."
    ))
  }

  if (!is.null(dataset_id) && !latest) {
    cli::cli_warn(c(
      "Both {.arg dataset_id} and {.arg latest = FALSE} provided.",
      "i" = "Ignoring {.arg latest} parameter since {.arg dataset_id} is specified."
    ))
  }

  # Handle data frame input (extract feed_id from feed data)
  if (is.data.frame(feed_id)) {
    if (nrow(feed_id) != 1) {
      cli::cli_abort(c(
        "{.arg feed_id} data frame must have exactly one row.",
        "i" = "Use {.code feed_df[1, ]} to select the first feed."
      ))
    }

    if (!"id" %in% names(feed_id)) {
      cli::cli_abort(c(
        "{.arg feed_id} data frame must have an {.field id} column.",
        "i" = "Pass a data frame from {.fn feeds} or {.fn mobdb_search}."
      ))
    }

    extracted_id <- feed_id$id[1]
    cli::cli_inform("Extracted feed ID: {.val {extracted_id}}")
    feed_id <- extracted_id
  }

  # Determine if we need to search for feeds
  search_params_provided <- !is.null(provider) || !is.null(country_code) ||
    !is.null(subdivision_name) || !is.null(municipality)

  # Extract feed_id from dataset_id if dataset_id provided but feed_id is not
  # Format: mdb-NNN-TIMESTAMP (e.g., "mdb-482-202402080041")
  # Feed ID is everything before the second delimiter
  if (is.null(feed_id) && !is.null(dataset_id)) {
    parts <- strsplit(dataset_id, "-")[[1]]
    if (length(parts) >= 3 && parts[1] == "mdb") {
      feed_id <- paste(parts[1:2], collapse = "-")
      cli::cli_inform("Extracted feed ID from dataset: {.val {feed_id}}")
    } else {
      cli::cli_abort(c(
        "Invalid {.arg dataset_id} format: {.val {dataset_id}}",
        "i" = "Expected format: {.code mdb-NNN-TIMESTAMP} (e.g., {.code mdb-482-202402080041})",
        "i" = "Or provide {.arg feed_id} separately."
      ))
    }
  }

  # Case 1: feed_id provided directly (or extracted from dataset_id)
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
    # Note: When official=TRUE, we pass NULL to API and post-filter ourselves
    # This is because the API filters out NA values, but we want to include them
    api_official_param <- if (!is.null(official) && official) NULL else official

    feeds <- feeds(
      provider = provider,
      country_code = country_code,
      subdivision_name = subdivision_name,
      municipality = municipality,
      data_type = "gtfs",  # GTFS Schedule only
      status = status,
      official = api_official_param,
      limit = 100
    )

    # Post-filter for official status if needed
    if (!is.null(official)) {
      if (official) {
        # Keep feeds where official is TRUE or NA (NA = not yet classified)
        # Only exclude feeds explicitly marked as FALSE
        feeds <- feeds[is.na(feeds$official) | feeds$official == TRUE, ]
      } else {
        # Keep only feeds where official is explicitly FALSE
        # Exclude TRUE and NA
        feeds <- feeds[!is.na(feeds$official) & feeds$official == FALSE, ]
      }
    }

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
        "i" = "Use {.code download_feed(feed_id = \"mdb-XXX\")} with one of the IDs above.",
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

  # Validate feed status if search was performed with status filter
  if (search_params_provided && !is.null(status)) {
    feed_details <- mobdb_get_feed(selected_feed_id)
    actual_status <- feed_details$status

    if (!is.null(actual_status) && actual_status != status) {
      cli::cli_abort(c(
        "Feed {.val {selected_feed_id}} has status {.val {actual_status}}, not {.val {status}}.",
        "i" = "The feed's status may have changed since being indexed.",
        "i" = "Set {.code status = \"{actual_status}\"} to download anyway, or choose a different feed."
      ))
    }
  }

  # Get dataset(s) for the feed
  if (!is.null(dataset_id)) {
    # Get specific dataset by ID
    dataset <- mobdb_get_dataset(dataset_id)

    # Convert to tibble format matching mobdb_datasets output
    datasets <- tibble::tibble(
      id = dataset$id,
      feed_id = dataset$feed_id,
      hosted_url = dataset$hosted_url,
      downloaded_at = dataset$downloaded_at,
      hash = dataset$hash
    )

    cli::cli_inform("Using historical dataset: {.val {dataset_id}}")
  } else {
    datasets <- mobdb_datasets(selected_feed_id, latest = latest)

    if (!latest) {
      # Return all datasets for user to choose from
      return(datasets)
    }
  }

  # Get the hosted URL from the dataset
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
