#' Read GTFS feed directly from Mobility Database
#'
#' @description
#' `r lifecycle::badge('superseded')`
#'
#' **Note:** This function is superseded by [download_feed()], which provides
#' the same functionality plus integrated search, Flex filtering, and more control
#' over data sources. New code should use [download_feed()] instead.
#'
#' Convenience wrapper that fetches a feed's download URL from the Mobility
#' Database and passes it to [tidytransit::read_gtfs()]. Requires the `tidytransit`
#' package.
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

#' Download GTFS Schedule feeds
#'
#' @description
#' A convenience function for downloading GTFS Schedule feeds from the Mobility Database.
#' This is a "one-stop-shop" that can search for feeds by provider/location and download
#' them in a single call, or download a specific feed by ID.
#'
#' **Note:** This function is specifically designed for GTFS Schedule feeds only.
#' GTFS Realtime and GBFS feeds use a different data model and are not supported by this function.
#'
#' *This function was formerly called \code{mobdb_download_feed()}.*
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
#' @param auth_args A string. Some agencies require authentication to download
#'   feeds directly from their source URLs. Provide your API key/token in one of
#'   two formats:
#'   - Just the value: `"your_api_key_here"`
#'   - Parameter and value: `"apikey=your_api_key_here"`
#'
#'   Also accepts a value stored in `.Renviron` (.e.g Sys.getenv("AGENCY_API_KEY") stored in the same formats)
#'   Only valid when `use_source_url = TRUE`. If a feed requires authentication, you'll receive an error message with a link to obtain credentials.
#'   The authentication method (URL parameter or HTTP header) is determined
#'   automatically from the feed's metadata.
#' @param export_path A string. Optional path to save the GTFS feed as a ZIP file
#'   (e.g., "data/gtfs/feed.zip"). If provided, the feed will be exported using
#'   [gtfsio::export_gtfs()] after downloading. Requires the `gtfsio` package.
#'   If `NULL` (default), the feed is not saved to disk.
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
#' # Search and download by provider name
#' gtfs <- download_feed(provider = "Arlington")
#'
#' # Download using agency's source URL instead of MobilityData
#' gtfs <- download_feed(provider = "TriMet", use_source_url = TRUE)
#'
#' # Download from agency requiring API authentication
#' gtfs <- download_feed(
#'   provider = "WMATA",
#'   feed_name = "Rail",
#'   use_source_url = TRUE,
#'   auth_args = "your_wmata_api_key"
#' )
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
#' # Download and save as ZIP file
#' gtfs <- download_feed("mdb-247", export_path = "data/gtfs/trimet.zip")
#'
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
                          auth_args = NULL,
                          export_path = NULL,
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

  if (!is.null(auth_args) && !use_source_url) {
    cli::cli_abort(c(
      "Cannot use {.arg auth_args} with {.arg use_source_url = FALSE}.",
      "i" = "auth_args are only required when downloading directly from certain agencies"
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
  # TODO add interactive response - if single feed but inactive, ask to download
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

  # Choose URL source and prepare request
  if (use_source_url) {
    # Get source URL from feed details
    feed_details <- mobdb_get_feed(selected_feed_id)
    url <- feed_details$source_info$producer_url
    auth_type <- mobdb_authentication_type(selected_feed_id)
    auth_param_name <- mobdb_api_key_parameter_name(selected_feed_id)
    auth_info_url <- mobdb_authentication_info_url(selected_feed_id)

    if (is.null(url) || is.na(url)) {
      cli::cli_abort(c(
        "No source URL found for feed {.val {selected_feed_id}}.",
        "i" = "Try setting {.code use_source_url = FALSE} to use MobilityData's hosted URL."
      ))
    }

    # Check if authentication is required
    if (!is.null(auth_type) && !is.na(auth_type) && auth_type > 0) {
      if (is.null(auth_args) || is.na(auth_args) || auth_args == "") {
        cli::cli_abort(c(
          "{.val {selected_feed_id}} requires API credentials to download from source.",
          "i" = "Visit {.url {auth_info_url}} to learn how to get API credentials.",
          "i" = "Then set {.code auth_args} with your API credentials.",
          "i" = "The API key parameter is: {.val {auth_param_name}}",
          "i" = "Or set {.code use_source_url = FALSE} to download the MobilityData hosted version."
        ))
      }

      # Parse auth_args and build authenticated request
      auth_value <- parse_auth_args(auth_args, auth_param_name)

      # Double-check that we got a valid auth value after parsing
      if (is.null(auth_value) || is.na(auth_value) || auth_value == "") {
        cli::cli_abort(c(
          "{.val {selected_feed_id}} requires API credentials to download from source.",
          "x" = "The provided {.arg auth_args} is empty or invalid.",
          "i" = "If using {.code Sys.getenv()}, make sure the environment variable is set in your {.file .Renviron} file.",
          "i" = "Visit {.url {auth_info_url}} to learn how to get API credentials.",
          "i" = "The API key parameter is: {.val {auth_param_name}}",
          "i" = "Or set {.code use_source_url = FALSE} to download the MobilityData hosted version."
        ))
      }

      # Build authenticated URL or request object
      request <- build_authenticated_request(url, auth_type, auth_param_name, auth_value)

      # Inform user based on auth type
      if (auth_type == 1) {
        cli::cli_inform("Downloading from agency source with URL parameter authentication")
      } else if (auth_type == 2) {
        cli::cli_inform("Downloading from agency source with HTTP header authentication")
      }
    } else {
      # No authentication needed
      request <- url
      cli::cli_inform("Downloading from agency source: {.url {url}}")
    }
  } else {
    # Use MobilityData hosted URL (no authentication needed)
    url <- datasets$hosted_url[1]

    if (is.null(url) || is.na(url)) {
      cli::cli_abort(c(
        "No hosted URL found for feed {.val {selected_feed_id}}.",
        "i" = "Try setting {.code use_source_url = TRUE} to use the agency's source URL."
      ))
    }

    request <- url
    cli::cli_inform("Downloading from MobilityData: {.url {url}}")
  }

  # Download and parse GTFS feed
  # Note: tidytransit::read_gtfs() only accepts URL strings or local file paths
  # It does NOT support httr2 request objects, so for HTTP header auth we need to
  # download to a temp file first
  if (inherits(request, "httr2_request")) {
    # For HTTP header authentication, download to temp file first
    temp_file <- tempfile(fileext = ".zip")

    cli::cli_inform("Downloading feed to temporary file...")
    resp <- httr2::req_perform(request, path = temp_file)

    # Read from the downloaded file
    gtfs <- tidytransit::read_gtfs(temp_file, ...)

    # Clean up temp file
    on.exit(unlink(temp_file), add = TRUE)
  } else {
    # For URL strings (no auth or URL param auth), validate before passing to tidytransit
    # Download to temp file first to check if it's actually a ZIP and provide better errors
    temp_file <- tempfile(fileext = ".zip")
    on.exit(unlink(temp_file), add = TRUE)

    gtfs <- tryCatch({
      # Download the file first
      req <- httr2::request(request)
      resp <- httr2::req_perform(req, path = temp_file)

      # Check if it's actually a ZIP file by reading magic bytes
      if (file.exists(temp_file) && file.size(temp_file) > 4) {
        con <- file(temp_file, "rb")
        magic_bytes <- readBin(con, "raw", n = 4)
        close(con)

        # ZIP files start with PK\x03\x04 (0x504B0304)
        is_zip <- magic_bytes[1] == 0x50 && magic_bytes[2] == 0x4B &&
          magic_bytes[3] == 0x03 && magic_bytes[4] == 0x04

        if (!is_zip) {
          # Not a ZIP file - probably an error response
          # Try to read as text to show user what the error is
          error_content <- readLines(temp_file, n = 20, warn = FALSE)
          error_preview <- paste(head(error_content, 5), collapse = "\n")

          cli::cli_abort(c(
            "The server did not return a valid GTFS ZIP file.",
            "x" = "Received {resp_content_type(resp)} instead of application/zip",
            "i" = "This usually means authentication failed or the URL is incorrect.",
            "i" = "Response preview: {.code {error_preview}}",
            if (!is.null(auth_args) && auth_args != "") {
              c("i" = "Check that your API key is valid and has the correct permissions.")
            } else {
              c("i" = "Try using {.code use_source_url = FALSE} to download from MobilityData instead.")
            }
          ))
        }
      }

      # It's a valid ZIP, pass to tidytransit
      tidytransit::read_gtfs(temp_file, ...)

    }, error = function(e) {
      # If it's already our custom error, re-throw it
      if (grepl("did not return a valid GTFS ZIP", conditionMessage(e))) {
        stop(e)
      }

      # Otherwise, add context to the error
      cli::cli_abort(c(
        "Failed to download or read GTFS feed.",
        "x" = conditionMessage(e),
        "i" = "URL: {.url {request}}",
        if (use_source_url && !is.null(auth_args) && auth_args != "") {
          c("i" = "Check that your API key is valid.")
        } else if (use_source_url) {
          c("i" = "This feed may require authentication. Check the feed details.")
        } else {
          c("i" = "Try using {.code use_source_url = TRUE} with proper authentication.")
        }
      ))
    })
  }

  # Export to ZIP file if export_path is provided
  if (!is.null(export_path)) {
    if (!requireNamespace("gtfsio", quietly = TRUE)) {
      cli::cli_abort(c(
        "The {.pkg gtfsio} package is required to export GTFS feeds.",
        "i" = "Install it with {.code install.packages('gtfsio')}."
      ))
    }

    # Create directory if it doesn't exist
    export_dir <- dirname(export_path)
    if (!dir.exists(export_dir)) {
      dir.create(export_dir, recursive = TRUE)
    }

    cli::cli_inform("Exporting GTFS feed to: {.file {export_path}}")
    gtfsio::export_gtfs(gtfs, export_path)
    cli::cli_inform("Successfully exported GTFS feed.")
  }

  gtfs
}

#' Download the best GTFS Schedule feed with smart selection
#'
#' @description
#' `r lifecycle::badge('experimental')`
#'
#' A higher-level wrapper around [download_feed()] that automagically selects
#' the best GTFS Schedule feed when multiple options exist. This function:
#'
#' * Searches for feeds using provider name or location
#' * Automatically ranks feeds by status, official designation, and validation quality
#' * Prompts for user selection when multiple equally-ranked feeds exist (in interactive mode)
#' * Falls back to historical datasets when current feed is marked "future" or "inactive"
#' * Only works with GTFS Schedule feeds (not GTFS-RT or GBFS)
#'
#' This is designed for common use cases where you just want the best, most recent feed
#' without needing to specify exact feed IDs or handle multiple results manually.
#'
#' @param provider Provider/agency name (partial match).
#' @param country_code ISO 2-letter country code (requires `subdivision_name`).
#' @param subdivision_name State/province/region name (requires `country_code`).
#' @param municipality City name.
#' @param feed_name Feed name filter (case-insensitive substring match).
#' @param prefer_official Logical. If `TRUE` (default), prefer feeds marked as official.
#' @param prefer_active Logical. If `TRUE` (default), prefer feeds with status "active"
#'   over "future", "development", "deprecated", or "inactive".
#' @param max_validation_errors Integer. Maximum number of validation errors allowed.
#'   Feeds exceeding this threshold are filtered out. If `NULL` (default), no filtering.
#' @param interactive Logical. If `TRUE`, prompt user to select when multiple equally-ranked
#'   feeds exist. If `FALSE`, automatically select the first highest-ranked feed with a
#'   warning. If `NULL` (default), uses `getOption("mobdb.interactive")` or falls back to
#'   `interactive()` to detect if running in an interactive R session.
#' @param exclude_flex Logical. If `TRUE` (default), exclude GTFS-Flex feeds.
#' @param use_source_url Logical. Download from agency's source URL (`TRUE`) or
#'   MobilityData's hosted URL (`FALSE`, default).
#' @param auth_args Authentication arguments if required (see [download_feed()]).
#' @param export_path A string. Optional path to save the GTFS feed as a ZIP file
#'   (e.g., "data/gtfs/feed.zip"). If provided, the feed will be exported using
#'   [gtfsio::export_gtfs()] after downloading. Requires the `gtfsio` package.
#'   If `NULL` (default), the feed is not saved to disk.
#' @param ... Additional arguments passed to [tidytransit::read_gtfs()].
#'
#' @return A `gtfs` object from tidytransit, or `NULL` if user cancels selection.
#'
#' @section Selection Algorithm:
#' When multiple feeds match the search criteria, feeds are ranked by:
#'
#' 1. **Status** (if `prefer_active = TRUE`): active > future > development > inactive > deprecated
#' 2. **Official designation** (if `prefer_official = TRUE`): official > unclassified > unofficial
#' 3. **Validation quality**: Feeds with fewer errors score higher
#' 4. **Service date coverage**: Feeds covering today's date score higher
#' 5. **Recency**: More recently added feeds get a tiebreaker boost
#'
#' If multiple feeds have the same score and `interactive = TRUE`, you'll be prompted to choose.
#'
#' @section Status Handling:
#' The function handles different feed statuses as follows:
#'
#' * **"active"**: Preferred status. Feed should be used in public trip planners.
#' * **"future"** or **"inactive"**: Automatically searches for historical datasets with
#'   service dates covering today. "future" feeds are not yet active; "inactive" feeds
#'   haven't been recently updated and may provide outdated information.
#' * **"deprecated"**: Explicitly deprecated and should not be used. Warns user to search
#'   for a replacement feed.
#' * **"development"**: For development purposes only, should not be used in production.
#'
#' @section GTFS Schedule Only:
#' Like [download_feed()], this function only works with GTFS Schedule feeds.
#' For GTFS-RT or GBFS feeds, use [mobdb_read_gtfs()] or fetch URLs with [mobdb_get_feed()].
#'
#' @examples
#' \dontrun{
#' # Simple one-shot download by provider name
#' bart_feed <- download_best_feed(provider = "Bay Area Rapid Transit")
#'
#' # Download with quality filtering
#' clean_feed <- download_best_feed(
#'   provider = "Capital Metro",
#'   max_validation_errors = 0
#' )
#'
#' # Download by location
#' ontario_feed <- download_best_feed(
#'   country_code = "CA",
#'   subdivision_name = "Ontario"
#' )
#'
#' # Non-interactive mode (for scripts)
#' options(mobdb.interactive = FALSE)
#' feed <- download_best_feed(provider = "WMATA")
#'
#' # Download and save as ZIP file
#' feed <- download_best_feed(provider = "TriMet", export_path = "data/gtfs/trimet.zip")
#' }
#'
#' @seealso
#' [download_feed()] for precise control,
#' [feeds()] to explore available feeds before downloading,
#' [mobdb_search()] for full-text search with validation data
#'
#' @export
download_best_feed <- function(provider = NULL,
                             country_code = NULL,
                             subdivision_name = NULL,
                             municipality = NULL,
                             feed_name = NULL,
                             prefer_official = TRUE,
                             prefer_active = TRUE,
                             max_validation_errors = NULL,
                             interactive = NULL,
                             exclude_flex = TRUE,
                             use_source_url = FALSE,
                             auth_args = NULL,
                             export_path = NULL,
                               ...) {
  if (!requireNamespace("tidytransit", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg tidytransit} package is required to use this function.",
      "i" = "Install it with {.code install.packages('tidytransit')}."
    ))
  }

  # Determine interactive mode
  if (is.null(interactive)) {
    interactive <- getOption("mobdb.interactive", base::interactive())
  }

  # Check that at least one search parameter is provided
  if (is.null(provider) && is.null(country_code) && is.null(subdivision_name) &&
        is.null(municipality)) {
      cli::cli_abort(c(
      "At least one search parameter must be provided.",
      "i" = "Use {.arg provider}, {.arg country_code} + {.arg subdivision_name}, or {.arg municipality}."
    ))
  }

  # Search for feeds
  cli::cli_inform("Searching for GTFS Schedule feeds...")

  # Use mobdb_search() if provider is specified (to get validation data)
  # Otherwise use feeds() for location-based search
  if (!is.null(provider)) {
    results <- mobdb_search(query = provider, data_type = "gtfs")

    # Filter to only feeds where provider field actually matches
    # mobdb_search() does full-text search which can return unrelated results
    if (nrow(results) > 0 && "provider" %in% names(results)) {
      results <- results[grepl(provider, results$provider, ignore.case = TRUE), ]
    }
  } else {
    results <- feeds(
      country_code = country_code,
      subdivision_name = subdivision_name,
      municipality = municipality,
      data_type = "gtfs"
    )
  }

  # Check results after filtering
  if (nrow(results) == 0) {
    cli::cli_abort(c(
      "No GTFS Schedule feeds found matching your search criteria.",
      "i" = "Try broadening your search or check the spelling."
    ))
  }

  # Apply exclude_flex filter
  if (exclude_flex && "feed_name" %in% names(results)) {
    original_count <- nrow(results)
    results <- results[!grepl("flex", results$feed_name, ignore.case = TRUE), ]

    if (nrow(results) < original_count) {
      cli::cli_inform("Excluded {original_count - nrow(results)} GTFS-Flex feed(s).")
    }

    if (nrow(results) == 0) {
      cli::cli_abort(c(
        "All feeds were filtered out as GTFS-Flex feeds.",
        "i" = "Set {.code exclude_flex = FALSE} to include them."
      ))
    }
  }

  # Apply feed_name filter if specified
  if (!is.null(feed_name) && "feed_name" %in% names(results)) {
    original_count <- nrow(results)
    results <- results[grepl(feed_name, results$feed_name, ignore.case = TRUE), ]

    if (nrow(results) == 0) {
      cli::cli_abort(c(
        "No feeds found matching {.arg feed_name} = {.val {feed_name}}.",
        "i" = "{original_count} feed(s) were found before applying this filter."
      ))
    }

    if (nrow(results) < original_count) {
      cli::cli_inform("Filtered to {nrow(results)} feed(s) matching {.val {feed_name}}.")
    }
  }

  cli::cli_inform("Found {nrow(results)} GTFS Schedule feed(s).")

  # Select best feed
  selected <- select_best_feed(
    results,
    prefer_official = prefer_official,
    prefer_active = prefer_active,
    max_validation_errors = max_validation_errors
  )

  if (is.null(selected) || nrow(selected) == 0) {
    cli::cli_abort("No suitable feeds found after applying quality filters.")
  }

  # Handle multiple equally-ranked feeds
  if (nrow(selected) > 1) {
    if (interactive) {
      selected <- prompt_feed_selection(selected)

      if (is.null(selected)) {
        # User cancelled
        return(invisible(NULL))
      }
    } else {
      # Non-interactive: select first and warn
      runner_ups <- selected[-1, ]
      selected <- selected[1, ]

      cli::cli_warn(c(
        "Multiple equally-ranked feeds found. Automatically selected:",
        "v" = "{.val {selected$id}} - {selected$provider}",
        "i" = "Other options: {paste(runner_ups$id, collapse = ', ')}",
        "i" = "Use {.code interactive = TRUE} or specify {.arg feed_name} for precise selection."
      ))
    }
  }

  # Check feed status and handle special cases
  dataset_id <- NULL

  if (selected$status == "deprecated") {
    # Deprecated feeds are being replaced by a different feed_id
    cli::cli_warn(c(
      "!" = "Selected feed has status {.val deprecated}.",
      "i" = "This feed is being replaced by a different feed.",
      "i" = "Try searching again or check the Mobility Database for the replacement feed."
    ))
  } else if (selected$status %in% c("future", "inactive")) {
    # Future/inactive feeds may have historical datasets with current service dates
    cli::cli_inform(c(
      "!" = "Selected feed has status {.val {selected$status}}.",
      "i" = "Searching for historical dataset with current service dates..."
    ))

    dataset_id <- find_active_dataset(selected$id)

    if (!is.null(dataset_id)) {
      cli::cli_inform(c(
        "v" = "Found active historical dataset: {.val {dataset_id}}",
        "i" = "Downloading this version instead of the current feed."
      ))
    } else {
      cli::cli_warn(c(
        "!" = "No historical dataset found with current service dates.",
        "i" = "Proceeding with the current feed, but it may have {selected$status} service dates."
      ))
    }
  }

  # Download the selected feed
  cli::cli_inform("Downloading: {.val {selected$id}} - {selected$provider}")

  download_feed(
    feed_id = selected$id,
    dataset_id = dataset_id,
    use_source_url = use_source_url,
    auth_args = auth_args,
    export_path = export_path,
    ...
  )
}

# Internal helper: Select best feed from multiple results
# Returns a single-row tibble or NULL
select_best_feed <- function(feeds, prefer_official = TRUE, prefer_active = TRUE,
                          max_validation_errors = NULL) {
  if (nrow(feeds) == 0) {
    return(NULL)
  }

  if (nrow(feeds) == 1) {
    return(feeds)
  }

  # Filter by validation errors if threshold specified
  if (!is.null(max_validation_errors)) {
    feeds_with_validation <- feeds[sapply(seq_len(nrow(feeds)), function(i) {
      row <- feeds[i, ]
      if ("latest_dataset" %in% names(row) &&
            !is.null(row$latest_dataset) &&
            is.data.frame(row$latest_dataset)) {
        ld <- row$latest_dataset
        if ("validation_report" %in% names(ld) && is.data.frame(ld$validation_report)) {
          vr <- ld$validation_report
          if ("total_error" %in% names(vr) && !is.na(vr$total_error)) {
            return(vr$total_error <= max_validation_errors)
          }
        }
      }
      TRUE  # Include feeds without validation data
    }), ]

    if (nrow(feeds_with_validation) == 0) {
      cli::cli_warn(c(
        "No feeds found with {.field total_error} <= {max_validation_errors}.",
        "i" = "Proceeding with all {nrow(feeds)} feed(s) found."
      ))
    } else {
      feeds <- feeds_with_validation
    }
  }

  # Score each feed
  scores <- sapply(seq_len(nrow(feeds)), function(i) {
    score_feed_quality(feeds[i, ], prefer_official, prefer_active)
  })

  # Select feed with highest score
  max_score <- max(scores)
  ties <- which(scores == max_score)

  if (length(ties) > 1) {
    # Multiple feeds with same score - return all for interactive selection
    return(feeds[ties, ])
  }

  feeds[ties[1], ]
}

# Internal helper: Prompt user to select from multiple feeds
# Returns a single-row tibble or NULL if user quits
prompt_feed_selection <- function(feeds) {
  if (nrow(feeds) == 0) {
    return(NULL)
  }

  if (nrow(feeds) == 1) {
    return(feeds)
  }

  cli::cli_inform(c(
    "i" = "Multiple GTFS Schedule feeds found. Please select one:"
  ))

  # Display options
  for (i in seq_len(nrow(feeds))) {
    feed_summary <- format_feed_summary(feeds[i, ], include_validation = TRUE)
    cli::cli_inform(paste0("  ", i, ". ", feed_summary))
  }

  cli::cli_inform("")

  # Get user input
  while (TRUE) {
    choice <- readline(prompt = paste0("Enter selection (1-", nrow(feeds), ") or 'q' to quit: "))

    # Handle quit
    if (tolower(trimws(choice)) == "q") {
      cli::cli_inform("Selection cancelled.")
      return(NULL)
    }

    # Try to parse as integer
    choice_num <- suppressWarnings(as.integer(choice))

    if (!is.na(choice_num) && choice_num >= 1 && choice_num <= nrow(feeds)) {
      selected_feed <- feeds[choice_num, ]
      cli::cli_inform(c(
        "v" = "Selected: {.val {selected_feed$id}} ({selected_feed$provider})"
      ))
      return(selected_feed)
    }

    cli::cli_warn("Invalid selection. Please enter a number between 1 and {nrow(feeds)}, or 'q' to quit.")
  }
}

# Internal helper: Find active dataset for a feed
# Returns dataset_id or NULL
find_active_dataset <- function(feed_id) {
  datasets <- mobdb_datasets(feed_id, latest = FALSE)

  if (nrow(datasets) == 0) {
    return(NULL)
  }

  # Filter to datasets with service dates covering today
  today <- Sys.Date()

  active_datasets <- datasets[sapply(seq_len(nrow(datasets)), function(i) {
    row <- datasets[i, ]
    if ("service_date_range_start" %in% names(row) &&
          "service_date_range_end" %in% names(row)) {
      start_date <- as.Date(row$service_date_range_start)
      end_date <- as.Date(row$service_date_range_end)

      if (!is.na(start_date) && !is.na(end_date)) {
        return(start_date <= today && end_date >= today)
      }
    }
    FALSE
  }), ]

  if (nrow(active_datasets) == 0) {
    return(NULL)
  }

  # Return most recent active dataset
  active_datasets <- active_datasets[order(as.POSIXct(active_datasets$downloaded_at), decreasing = TRUE), ]
  active_datasets$id[1]
}
