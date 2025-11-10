#' Get GBFS feed URL
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' A convenience function for retrieving GBFS auto-discovery feed
#' URLs from the Mobility Database. This can search for feeds by provider
#' or location and return the source URL in a single call,
#' or retrieve the URL for a specific feed by system ID.
#'
#' **Note:** Unlike GTFS feeds which are downloadable ZIP archives, GBFS feeds
#' are live JSON endpoints. This function returns the URL that can be used to
#' access the GBFS feed data directly. GBFS system IDs use a different format
#' than GTFS feed IDs (e.g., "lyft_nyc" or "Mobibikes_CA_Vancouver" instead of
#' "mdb-123").
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system (e.g., "lyft_nyc", "Mobibikes_CA_Vancouver"), or a single-row
#'   data frame from [feeds()] or [mobdb_search()]. If a data frame is
#'   provided, the system ID will be extracted automatically. If provided, all
#'   other search parameters are ignored.
#' @param provider Character. Filter by provider/agency name (partial match).
#'   Use this to search for feeds without knowing the system_id.
#' @param country_code Character. Two-letter ISO country code (e.g., "US", "CA").
#' @param subdivision_name Character. State, province, or region name.
#' @param municipality Character. City or municipality name.
#' @param feed_name Character. Optional filter for feed name. Note that GBFS
#'   feeds typically do not have a `feed_name` field, so this parameter may not
#'   be effective for GBFS. Use `NULL` (default) to skip this filter.
#' @param version Character. Optional GBFS version filter (e.g., "2.3", "3.0").
#'   Uses semantic versioning comparison.
#' @param status Character. Feed status filter: "active" (default), "deprecated",
#'   "inactive", "development", or "future".
#'
#' @return A character string containing the GBFS feed URL.
#'
#' @examples
#' \dontrun{
#' # Get URL by system ID
#' url <- download_gbfs("gbfs-bcycle_lametro")
#'
#' # Get URL from search results
#' feeds <- feeds(data_type = "gbfs", limit = 10)
#' url <- download_gbfs(feeds[1, ])
#'
#' # Search and get URL by provider name
#' url <- download_gbfs(provider = "Metro Bike Share")
#'
#' # Filter by location (may return multiple - add provider to narrow down)
#' url <- download_gbfs(
#'   country_code = "US",
#'   subdivision_name = "California",
#'   provider = "Bay Wheels"
#' )
#' }
#'
#' @export
download_gbfs <- function(system_id = NULL,
                                 provider = NULL,
                                 country_code = NULL,
                                 subdivision_name = NULL,
                                 municipality = NULL,
                                 feed_name = NULL,
                                 version = NULL,
                                 status = "active") {

  # Handle data frame input (extract system_id from feed data)
  if (is.data.frame(system_id)) {
    if (nrow(system_id) != 1) {
      cli::cli_abort(c(
        "{.arg system_id} data frame must have exactly one row.",
        "i" = "Use {.code feed_df[1, ]} to select the first feed."
      ))
    }

    if (!"id" %in% names(system_id)) {
      cli::cli_abort(c(
        "{.arg system_id} data frame must have an {.field id} column.",
        "i" = "Pass a data frame from {.fn feeds} or {.fn mobdb_search}."
      ))
    }

    extracted_id <- system_id$id[1]
    cli::cli_inform("Extracted system ID: {.val {extracted_id}}")
    system_id <- extracted_id
  }

  # Determine if we need to search for feeds
  search_params_provided <- !is.null(provider) || !is.null(country_code) ||
    !is.null(subdivision_name) || !is.null(municipality)

  # Case 1: system_id provided directly
  if (!is.null(system_id)) {
    if (search_params_provided) {
      cli::cli_warn(c(
        "Both {.arg system_id} and search parameters provided.",
        "i" = "Ignoring search parameters and using {.arg system_id} directly."
      ))
    }

    selected_system_id <- system_id

  # Case 2: Search for feed using provider/location filters
  } else if (search_params_provided) {
    cli::cli_inform("Searching for GBFS feeds...")

    # Query feeds with provided filters
    feeds <- feeds(
      provider = provider,
      country_code = country_code,
      subdivision_name = subdivision_name,
      municipality = municipality,
      data_type = "gbfs",
      status = status,
      limit = 100
    )

    if (nrow(feeds) == 0) {
      cli::cli_abort(c(
        "No GBFS feeds found matching your criteria.",
        "i" = "Try broadening your search parameters."
      ))
    }

    # Apply custom feed_name filter if provided (if feed_name column exists)
    if (!is.null(feed_name) && "feed_name" %in% names(feeds)) {
      feeds <- feeds[grepl(feed_name, feeds$feed_name, ignore.case = TRUE), ]

      if (nrow(feeds) == 0) {
        cli::cli_abort(c(
          "No feeds found with {.val {feed_name}} in feed name.",
          "i" = "Remove or adjust the {.arg feed_name} filter."
        ))
      }
    } else if (!is.null(feed_name) && !"feed_name" %in% names(feeds)) {
      cli::cli_warn(c(
        "!" = "GBFS feeds do not have a {.field feed_name} column.",
        "i" = "Ignoring the {.arg feed_name} filter."
      ))
    }

    # Handle multiple feeds
    if (nrow(feeds) > 1) {
      # Display feed details in a readable format
      cli::cli_inform(c(
        "!" = "Found {nrow(feeds)} matching feeds:",
        " " = ""
      ))

      # Print a clean table of options
      cols_to_show <- c("id", "provider")
      if ("status" %in% names(feeds)) cols_to_show <- c(cols_to_show, "status")
      feed_summary <- feeds[, cols_to_show]
      print(feed_summary)

      cli::cli_abort(c(
        "x" = "Multiple feeds found. Please specify which one to use.",
        "i" = paste0(
          "Use {.code download_gbfs(system_id = ...)} ",
          "with one of the IDs above."
        ),
        "i" = "Or refine your search with {.arg provider} or {.arg feed_name}."
      ))
    }

    selected_system_id <- feeds$id[1]
    cli::cli_inform(
      "Found feed: {.val {feeds$provider[1]}} ({.val {selected_system_id}})"
    )

  # Case 3: No system_id or search parameters
  } else {
    cli::cli_abort(c(
      "Must provide either {.arg system_id} or search parameters.",
      "i" = paste0(
        "Specify {.arg system_id} directly, or use ",
        "{.arg provider}/{.arg country_code}/etc. to search."
      )
    ))
  }

  # Get feed details to retrieve the source URL
  feed_details <- mobdb_get_feed(selected_system_id)

  # Extract the producer URL from source_info
  url <- feed_details$source_info$producer_url

  if (is.null(url) || is.na(url)) {
    cli::cli_abort(c(
      "No source URL found for feed {.val {selected_system_id}}.",
      "i" = "The feed may not have a valid GBFS endpoint configured."
    ))
  }

  cli::cli_inform("GBFS feed URL: {.url {url}}")

  invisible(url)
}

#' Get GBFS station information
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Fetches station information from a GBFS feed and returns it as a data frame.
#' This includes station locations, names, capacities, and other metadata.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or
#'   [mobdb_search()]. Can also be a GBFS auto-discovery URL.
#' @param ... Additional parameters passed to [download_gbfs()] when
#'   searching for feeds (e.g., provider, country_code, etc.).
#'
#' @return A tibble containing station information with columns such as
#'   station_id, name, lat, lon, capacity, etc. The exact columns depend on
#'   the GBFS version and what the provider includes.
#'
#' @examples
#' \dontrun{
#' # Get Citi Bike station information
#' stations <- mobdb_get_gbfs_stations(provider = "Citi Bike")
#'
#' # Get stations by system ID
#' stations <- mobdb_get_gbfs_stations("gbfs-bcycle_lametro")
#'
#' # Get stations from search results
#' feeds <- feeds(data_type = "gbfs", limit = 10)
#' stations <- mobdb_get_gbfs_stations(feeds[1, ])
#' }
#'
#' @export
get_gbfs_stations <- function(system_id = NULL, ...) {
  # Get the GBFS auto-discovery URL
  if (is.character(system_id) && grepl("^https?://", system_id)) {
    # Already a URL
    gbfs_url <- system_id
  } else {
    # Get URL using download_gbfs
    gbfs_url <- download_gbfs(system_id = system_id, ...)
  }

  # Fetch the auto-discovery feed
  cli::cli_inform("Fetching GBFS auto-discovery feed...")
  gbfs_data <- jsonlite::fromJSON(gbfs_url, flatten = TRUE)

  # Find the station_information feed URL
  if (!"data" %in% names(gbfs_data)) {
    cli::cli_abort("Invalid GBFS feed: missing {.field data} field.")
  }

  # Try to find feeds in different language codes
  lang_codes <- names(gbfs_data$data)
  feeds <- NULL

  for (lang in lang_codes) {
    if ("feeds" %in% names(gbfs_data$data[[lang]])) {
      feeds <- gbfs_data$data[[lang]]$feeds
      break
    }
  }

  if (is.null(feeds)) {
    cli::cli_abort("Could not find feeds list in GBFS auto-discovery feed.")
  }

  # Find station_information URL
  if (is.data.frame(feeds)) {
    # Feeds is already a data frame (from flatten = TRUE)
    station_feed_idx <- which(feeds$name == "station_information")
    if (length(station_feed_idx) == 0) {
      cli::cli_abort(c(
        "Station information feed not found.",
        "i" = paste0(
          "This GBFS feed may not include station data ",
          "(e.g., free-floating bikes)."
        )
      ))
    }
    station_url <- feeds$url[station_feed_idx[1]]
  } else {
    # Feeds is a list
    station_feed_idx <- which(sapply(feeds, function(x) {
      "name" %in% names(x) && x$name == "station_information"
    }))
    if (length(station_feed_idx) == 0) {
      cli::cli_abort(c(
        "Station information feed not found.",
        "i" = paste0(
          "This GBFS feed may not include station data ",
          "(e.g., free-floating bikes)."
        )
      ))
    }
    station_url <- feeds[[station_feed_idx[1]]]$url
  }

  # Fetch station information
  cli::cli_inform("Fetching station information from {.url {station_url}}")
  station_data <- jsonlite::fromJSON(station_url, flatten = TRUE)

  if (!"data" %in% names(station_data) ||
      !"stations" %in% names(station_data$data)) {
    cli::cli_abort("Invalid station information feed structure.")
  }

  stations_df <- tibble::as_tibble(station_data$data$stations)

  cli::cli_inform("Retrieved {nrow(stations_df)} station{?s}.")

  stations_df
}

#' Get GBFS station status
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Fetches real-time station status from a GBFS feed and returns it as a
#' data frame. This includes current availability of bikes and docks,
#' station operational status, and last update times.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or
#'   [mobdb_search()]. Can also be a GBFS auto-discovery URL.
#' @param ... Additional parameters passed to [download_gbfs()] when
#'   searching for feeds (e.g., provider, country_code, etc.).
#'
#' @return A tibble containing real-time station status with columns such as
#'   station_id, num_bikes_available, num_docks_available, is_renting,
#'   is_returning, is_installed, last_reported, etc. The exact columns depend
#'   on the GBFS version and what the provider includes.
#'
#' @examples
#' \dontrun{
#' # Get Citi Bike station status
#' status <- mobdb_get_gbfs_station_status(provider = "Citi Bike")
#'
#' # Get status by system ID
#' status <- mobdb_get_gbfs_station_status("gbfs-bcycle_lametro")
#'
#' # Get status from search results
#' feeds <- feeds(data_type = "gbfs", limit = 10)
#' status <- mobdb_get_gbfs_station_status(feeds[1, ])
#'
#' # Join with station information for full details
#' stations <- mobdb_get_gbfs_stations(provider = "Citi Bike")
#' status <- mobdb_get_gbfs_station_status(provider = "Citi Bike")
#' full_data <- dplyr::left_join(stations, status, by = "station_id")
#' }
#'
#' @export
get_gbfs_station_status <- function(system_id = NULL, ...) {
  # Get the GBFS auto-discovery URL
  if (is.character(system_id) && grepl("^https?://", system_id)) {
    # Already a URL
    gbfs_url <- system_id
  } else {
    # Get URL using download_gbfs
    gbfs_url <- download_gbfs(system_id = system_id, ...)
  }

  # Fetch the auto-discovery feed
  cli::cli_inform("Fetching GBFS auto-discovery feed...")
  gbfs_data <- jsonlite::fromJSON(gbfs_url, flatten = TRUE)

  # Find the station_status feed URL
  if (!"data" %in% names(gbfs_data)) {
    cli::cli_abort("Invalid GBFS feed: missing {.field data} field.")
  }

  # Try to find feeds in different language codes
  lang_codes <- names(gbfs_data$data)
  feeds <- NULL

  for (lang in lang_codes) {
    if ("feeds" %in% names(gbfs_data$data[[lang]])) {
      feeds <- gbfs_data$data[[lang]]$feeds
      break
    }
  }

  if (is.null(feeds)) {
    cli::cli_abort("Could not find feeds list in GBFS auto-discovery feed.")
  }

  # Find station_status URL
  if (is.data.frame(feeds)) {
    # Feeds is already a data frame (from flatten = TRUE)
    status_feed_idx <- which(feeds$name == "station_status")
    if (length(status_feed_idx) == 0) {
      cli::cli_abort(c(
        "Station status feed not found.",
        "i" = paste0(
          "This GBFS feed may not include station data ",
          "(e.g., free-floating bikes)."
        )
      ))
    }
    status_url <- feeds$url[status_feed_idx[1]]
  } else {
    # Feeds is a list
    status_feed_idx <- which(sapply(feeds, function(x) {
      "name" %in% names(x) && x$name == "station_status"
    }))
    if (length(status_feed_idx) == 0) {
      cli::cli_abort(c(
        "Station status feed not found.",
        "i" = paste0(
          "This GBFS feed may not include station data ",
          "(e.g., free-floating bikes)."
        )
      ))
    }
    status_url <- feeds[[status_feed_idx[1]]]$url
  }

  # Fetch station status
  cli::cli_inform("Fetching station status from {.url {status_url}}")
  status_data <- jsonlite::fromJSON(status_url, flatten = TRUE)

  if (!"data" %in% names(status_data) ||
      !"stations" %in% names(status_data$data)) {
    cli::cli_abort("Invalid station status feed structure.")
  }

  status_df <- tibble::as_tibble(status_data$data$stations)

  cli::cli_inform("Retrieved status for {nrow(status_df)} station{?s}.")

  status_df
}

#' Get GBFS system information
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Fetches system information from a GBFS feed. This includes metadata about
#' the system such as name, operator, timezone, language, and URLs.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or
#'   [mobdb_search()]. Can also be a GBFS auto-discovery URL.
#' @param ... Additional parameters passed to [download_gbfs()] when
#'   searching for feeds (e.g., provider, country_code, etc.).
#'
#' @return A list containing system information fields such as system_id,
#'   name, operator, timezone, language, url, purchase_url, start_date, etc.
#'
#' @examples
#' \dontrun{
#' # Get Citi Bike system information
#' info <- mobdb_get_gbfs_system_information(provider = "Citi Bike")
#'
#' # Get by system ID
#' info <- mobdb_get_gbfs_system_information("gbfs-bcycle_lametro")
#' }
#'
#' @export
get_gbfs_system_information <- function(system_id = NULL, ...) {
  feed_data <- get_gbfs_feed_data(system_id, "system_information", ...)
  cli::cli_inform("Retrieved system information.")
  feed_data$data
}

#' Get GBFS vehicle types
#'
#' @description
#' Fetches information about vehicle types available in the system (bikes,
#' scooters, etc.) including their capabilities and features.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or
#'   [mobdb_search()]. Can also be a GBFS auto-discovery URL.
#' @param ... Additional parameters passed to [download_gbfs()] when
#'   searching for feeds (e.g., provider, country_code, etc.).
#'
#' @return A tibble containing vehicle type information with columns such as
#'   vehicle_type_id, form_factor, propulsion_type, max_range_meters, name.
#'
#' @examples
#' \dontrun{
#' # Get Citi Bike vehicle types
#' types <- mobdb_get_gbfs_vehicle_types(provider = "Citi Bike")
#' }
#'
#' @export
get_gbfs_vehicle_types <- function(system_id = NULL, ...) {
  feed_data <- get_gbfs_feed_data(system_id, "vehicle_types", ...)

  if (!"vehicle_types" %in% names(feed_data$data)) {
    cli::cli_abort("Vehicle types data not found in feed.")
  }

  types_df <- tibble::as_tibble(feed_data$data$vehicle_types)
  cli::cli_inform("Retrieved {nrow(types_df)} vehicle type{?s}.")
  types_df
}

#' Get GBFS system regions
#'
#' @description
#' Fetches geographic regions that the system operates in.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or
#'   [mobdb_search()]. Can also be a GBFS auto-discovery URL.
#' @param ... Additional parameters passed to [download_gbfs()] when
#'   searching for feeds (e.g., provider, country_code, etc.).
#'
#' @return A tibble containing region information with columns such as
#'   region_id and name.
#'
#' @examples
#' \dontrun{
#' # Get Citi Bike regions
#' regions <- mobdb_get_gbfs_system_regions(provider = "Citi Bike")
#' }
#'
#' @export
get_gbfs_system_regions <- function(system_id = NULL, ...) {
  feed_data <- get_gbfs_feed_data(system_id, "system_regions", ...)

  if (!"regions" %in% names(feed_data$data)) {
    cli::cli_abort("Regions data not found in feed.")
  }

  regions_df <- tibble::as_tibble(feed_data$data$regions)
  cli::cli_inform("Retrieved {nrow(regions_df)} region{?s}.")
  regions_df
}

#' Get GBFS system pricing plans
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Fetches pricing plan information for the system.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or
#'   [mobdb_search()]. Can also be a GBFS auto-discovery URL.
#' @param ... Additional parameters passed to [download_gbfs()] when
#'   searching for feeds (e.g., provider, country_code, etc.).
#'
#' @return A tibble containing pricing plan information with columns such as
#'   plan_id, name, currency, price, description, is_taxable.
#'
#' @examples
#' \dontrun{
#' # Get Citi Bike pricing plans
#' pricing <- mobdb_get_gbfs_system_pricing_plans(provider = "Citi Bike")
#' }
#'
#' @export
get_gbfs_system_pricing_plans <- function(system_id = NULL, ...) {
  feed_data <- get_gbfs_feed_data(system_id, "system_pricing_plans", ...)

  if (!"plans" %in% names(feed_data$data)) {
    cli::cli_abort("Pricing plans data not found in feed.")
  }

  plans_df <- tibble::as_tibble(feed_data$data$plans)
  cli::cli_inform("Retrieved {nrow(plans_df)} pricing plan{?s}.")
  plans_df
}

#' Get GBFS system calendar
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Fetches system calendar information showing service availability dates.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or
#'   [mobdb_search()]. Can also be a GBFS auto-discovery URL.
#' @param ... Additional parameters passed to [download_gbfs()] when
#'   searching for feeds (e.g., provider, country_code, etc.).
#'
#' @return A tibble containing calendar information with columns such as
#'   start_month, start_day, end_month, end_day.
#'
#' @examples
#' \dontrun{
#' # Get Citi Bike calendar
#' calendar <- mobdb_get_gbfs_system_calendar(provider = "Citi Bike")
#' }
#'
#' @export
get_gbfs_system_calendar <- function(system_id = NULL, ...) {
  feed_data <- get_gbfs_feed_data(system_id, "system_calendar", ...)

  if (!"calendars" %in% names(feed_data$data)) {
    cli::cli_abort("Calendar data not found in feed.")
  }

  calendar_df <- tibble::as_tibble(feed_data$data$calendars)
  cli::cli_inform("Retrieved {nrow(calendar_df)} calendar entr{?y/ies}.")
  calendar_df
}

# Helper function to reduce code duplication
get_gbfs_feed_data <- function(system_id, feed_name, ...) {
  # Get the GBFS auto-discovery URL
  if (is.character(system_id) && grepl("^https?://", system_id)) {
    gbfs_url <- system_id
  } else {
    gbfs_url <- download_gbfs(system_id = system_id, ...)
  }

  # Fetch the auto-discovery feed
  cli::cli_inform("Fetching GBFS auto-discovery feed...")
  gbfs_data <- jsonlite::fromJSON(gbfs_url, flatten = TRUE)

  if (!"data" %in% names(gbfs_data)) {
    cli::cli_abort("Invalid GBFS feed: missing {.field data} field.")
  }

  # Find feeds in different language codes
  lang_codes <- names(gbfs_data$data)
  feeds <- NULL

  for (lang in lang_codes) {
    if ("feeds" %in% names(gbfs_data$data[[lang]])) {
      feeds <- gbfs_data$data[[lang]]$feeds
      break
    }
  }

  if (is.null(feeds)) {
    cli::cli_abort("Could not find feeds list in GBFS auto-discovery feed.")
  }

  # Find the specific feed URL
  if (is.data.frame(feeds)) {
    feed_idx <- which(feeds$name == feed_name)
  } else {
    feed_idx <- which(sapply(feeds, function(x) {
      "name" %in% names(x) && x$name == feed_name
    }))
  }

  if (length(feed_idx) == 0) {
    cli::cli_abort(c(
      "{feed_name} feed not found.",
      "i" = "This GBFS feed may not include this data type."
    ))
  }

  feed_url <- if (is.data.frame(feeds)) {
    feeds$url[feed_idx[1]]
  } else {
    feeds[[feed_idx[1]]]$url
  }

  # Fetch the specific feed
  cli::cli_inform("Fetching {feed_name} from {.url {feed_url}}")
  jsonlite::fromJSON(feed_url, flatten = TRUE)
}

#' Get GBFS versions from Mobility Database API
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Retrieves version information for a GBFS feed directly from the Mobility
#' Database API. This includes version numbers, timestamps, validation reports,
#' and available endpoints for each version.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or [mobdb_search()].
#' @param ... Additional parameters passed to [feeds()] when searching
#'   (e.g., provider, country_code, etc.).
#'
#' @return A tibble containing version information with columns:
#'   \itemize{
#'     \item version: GBFS version number (semantic versioning)
#'     \item created_at: When this version was first detected
#'     \item last_updated_at: Most recent update timestamp
#'     \item source: How version was discovered (autodiscovery or gbfs_versions)
#'     \item endpoints: List column containing endpoint data frames
#'     \item validated_at: Validation timestamp
#'     \item total_error: Count of validation errors
#'     \item report_summary_url: URL to detailed validation report
#'     \item validator_version: Version of GBFS validator used
#'   }
#'
#' @examples
#' \dontrun{
#' # Get versions for a specific system
#' versions <- gbfs_versions("gbfs-bcycle_lametro")
#'
#' # Get versions from search results
#' feeds <- feeds(data_type = "gbfs", provider = "Metro Bike Share")
#' versions <- gbfs_versions(feeds[1, ])
#'
#' # Get versions by searching
#' versions <- gbfs_versions(provider = "Citi Bike")
#' }
#'
#' @export
gbfs_versions <- function(system_id = NULL, ...) {
  # Handle data frame input
  if (is.data.frame(system_id)) {
    if (nrow(system_id) != 1) {
      cli::cli_abort(c(
        "{.arg system_id} data frame must have exactly one row.",
        "i" = "Use {.code feed_df[1, ]} to select the first feed."
      ))
    }

    if (!"id" %in% names(system_id)) {
      cli::cli_abort(c(
        "{.arg system_id} data frame must have an {.field id} column.",
        "i" = "Pass a data frame from {.fn feeds} or {.fn mobdb_search}."
      ))
    }

    extracted_id <- system_id$id[1]
    system_id <- extracted_id
  }

  # Determine if we need to search
  search_params_provided <- length(list(...)) > 0

  if (is.null(system_id) && !search_params_provided) {
    cli::cli_abort(c(
      "Must provide either {.arg system_id} or search parameters.",
      "i" = "Specify {.arg system_id} directly, or use search parameters."
    ))
  }

  # Get feed details using GBFS-specific endpoint
  if (!is.null(system_id)) {
    # Use gbfs_feeds endpoint to get versions data
    req <- mobdb_request("gbfs_feeds") |>
      httr2::req_url_path_append(system_id)

    resp <- httr2::req_perform(req)
    # Get raw list to preserve nested structures
    feed_data <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  } else {
    # Search for feed
    search_results <- feeds(data_type = "gbfs", limit = 100, ...)

    if (nrow(search_results) == 0) {
      cli::cli_abort("No GBFS feeds found matching your criteria.")
    }

    if (nrow(search_results) > 1) {
      cli::cli_abort(c(
        "Multiple feeds found ({nrow(search_results)}). Please specify {.arg system_id}.",
        "i" = "Use {.fn feeds} to search and select a specific feed."
      ))
    }

    # Use gbfs_feeds endpoint
    req <- mobdb_request("gbfs_feeds") |>
      httr2::req_url_path_append(search_results$id[1])

    resp <- httr2::req_perform(req)
    # Get raw list to preserve nested structures
    feed_data <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  }

  # Extract versions
  if (is.null(feed_data$versions) || length(feed_data$versions) == 0) {
    cli::cli_warn("No version information available for this feed.")
    return(tibble::tibble())
  }

  versions_list <- feed_data$versions

  # Convert to tibble with nested endpoints
  versions_df <- tibble::tibble(
    version = sapply(versions_list, function(v) v$version %||% NA_character_),
    created_at = sapply(versions_list, function(v) v$created_at %||% NA_character_),
    last_updated_at = sapply(versions_list, function(v) {
      v$last_updated_at %||% NA_character_
    }),
    source = sapply(versions_list, function(v) v$source %||% NA_character_),
    endpoints = lapply(versions_list, function(v) {
      if (!is.null(v$endpoints) && length(v$endpoints) > 0) {
        # Convert list of endpoints to data frame
        do.call(rbind, lapply(v$endpoints, function(ep) {
          tibble::tibble(
            name = ep$name %||% NA_character_,
            url = ep$url %||% NA_character_,
            language = ep$language %||% NA_character_,
            is_feature = ep$is_feature %||% NA
          )
        }))
      } else {
        tibble::tibble(
          name = character(),
          url = character(),
          language = character(),
          is_feature = logical()
        )
      }
    }),
    validated_at = sapply(versions_list, function(v) {
      v$latest_validation_report$validated_at %||% NA_character_
    }),
    total_error = sapply(versions_list, function(v) {
      v$latest_validation_report$total_error %||% NA_integer_
    }),
    report_summary_url = sapply(versions_list, function(v) {
      v$latest_validation_report$report_summary_url %||% NA_character_
    }),
    validator_version = sapply(versions_list, function(v) {
      v$latest_validation_report$validator_version %||% NA_character_
    })
  )

  cli::cli_inform("Retrieved {nrow(versions_df)} GBFS version{?s}.")

  versions_df
}

#' Get GBFS endpoints from Mobility Database API
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Retrieves endpoint information for a GBFS feed directly from the Mobility
#' Database API. Returns all available endpoints across all versions, or
#' optionally filter to a specific version.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or [mobdb_search()].
#' @param version Character. Optional GBFS version to filter to (e.g., "2.3").
#'   If NULL (default), returns endpoints from the latest version.
#' @param all_versions Logical. If TRUE, returns endpoints from all versions.
#'   Default is FALSE (latest version only).
#' @param ... Additional parameters passed to [feeds()] when searching
#'   (e.g., provider, country_code, etc.).
#'
#' @return A tibble containing endpoint information with columns:
#'   \itemize{
#'     \item name: Endpoint name (e.g., station_information, station_status)
#'     \item url: Direct URL to the endpoint
#'     \item language: Language code (e.g., "en")
#'     \item is_feature: Whether this is an optional feature endpoint
#'     \item version: GBFS version (only included if all_versions = TRUE)
#'   }
#'
#' @examples
#' \dontrun{
#' # Get endpoints for latest version
#' endpoints <- gbfs_endpoints("gbfs-bcycle_lametro")
#'
#' # Get endpoints for a specific version
#' endpoints <- gbfs_endpoints("gbfs-bcycle_lametro", version = "2.3")
#'
#' # Get endpoints from all versions
#' endpoints <- gbfs_endpoints("gbfs-bcycle_lametro", all_versions = TRUE)
#'
#' # Get endpoints by searching
#' endpoints <- gbfs_endpoints(provider = "Citi Bike")
#'
#' # Access a specific endpoint URL
#' station_url <- endpoints |>
#'   dplyr::filter(name == "station_information") |>
#'   dplyr::pull(url)
#' }
#'
#' @export
gbfs_endpoints <- function(system_id = NULL,
                           version = NULL,
                           all_versions = FALSE,
                           ...) {
  # Get versions data
  versions_df <- gbfs_versions(system_id = system_id, ...)

  if (nrow(versions_df) == 0) {
    return(tibble::tibble(
      name = character(),
      url = character(),
      language = character(),
      is_feature = logical()
    ))
  }

  # Filter to specific version if requested
  if (!is.null(version)) {
    versions_df <- versions_df[versions_df$version == version, ]

    if (nrow(versions_df) == 0) {
      cli::cli_abort(c(
        "Version {.val {version}} not found.",
        "i" = "Use {.fn gbfs_versions} to see available versions."
      ))
    }
  } else if (!all_versions) {
    # Get latest version (most recent last_updated_at)
    versions_df <- versions_df[order(versions_df$last_updated_at,
                                     decreasing = TRUE), ]
    versions_df <- versions_df[1, ]
  }

  # Extract endpoints
  if (all_versions) {
    # Combine endpoints from all versions with version column
    endpoints_list <- lapply(seq_len(nrow(versions_df)), function(i) {
      ep <- versions_df$endpoints[[i]]
      if (nrow(ep) > 0) {
        ep$version <- versions_df$version[i]
      }
      ep
    })

    endpoints_df <- dplyr::bind_rows(endpoints_list)
  } else {
    # Single version
    endpoints_df <- versions_df$endpoints[[1]]
  }

  if (nrow(endpoints_df) == 0) {
    cli::cli_warn("No endpoints found in the selected version(s).")
  } else {
    cli::cli_inform("Retrieved {nrow(endpoints_df)} endpoint{?s}.")
  }

  endpoints_df
}

#' Get data from a specific GBFS endpoint
#'
#' @description
#' `r lifecycle::badge("experimental")`
#' Fetches data from a specific GBFS endpoint using the Mobility Database API
#' to look up the endpoint URL. This is a convenience wrapper around
#' [gbfs_endpoints()] that handles URL lookup and data fetching.
#'
#' @param system_id Character or data frame. The unique identifier for the
#'   GBFS system, or a single-row data frame from [feeds()] or [mobdb_search()].
#' @param endpoint_name Character. Name of the endpoint to fetch (e.g.,
#'   "station_information", "station_status", "system_information").
#' @param version Character. Optional GBFS version to use. If NULL (default),
#'   uses the latest version.
#' @param language Character. Optional language code to filter to (e.g., "en").
#'   If NULL (default), uses the first available language.
#' @param ... Additional parameters passed to [feeds()] when searching.
#'
#' @return The parsed JSON data from the endpoint, typically a list or data frame.
#'
#' @examples
#' \dontrun{
#' # Get station information
#' stations <- gbfs_get_endpoint("gbfs-bcycle_lametro", "station_information")
#'
#' # Get station status for a specific version
#' status <- gbfs_get_endpoint(
#'   "gbfs-bcycle_lametro",
#'   "station_status",
#'   version = "2.3"
#' )
#'
#' # Get system information by searching
#' info <- gbfs_get_endpoint(
#'   provider = "Citi Bike",
#'   endpoint_name = "system_information"
#' )
#' }
#'
#' @export
gbfs_get_endpoint <- function(system_id = NULL,
                              endpoint_name,
                              version = NULL,
                              language = NULL,
                              ...) {
  # Get endpoints
  endpoints_df <- gbfs_endpoints(
    system_id = system_id,
    version = version,
    all_versions = TRUE,
    ...
  )

  if (nrow(endpoints_df) == 0) {
    cli::cli_abort("No endpoints available.")
  }

  # Filter to requested endpoint
  endpoint_data <- endpoints_df[endpoints_df$name == endpoint_name, ]

  if (nrow(endpoint_data) == 0) {
    cli::cli_abort(c(
      "Endpoint {.val {endpoint_name}} not found.",
      "i" = "Available endpoints: {.val {unique(endpoints_df$name)}}"
    ))
  }

  # Filter by language if specified
  if (!is.null(language)) {
    endpoint_data <- endpoint_data[endpoint_data$language == language, ]

    if (nrow(endpoint_data) == 0) {
      cli::cli_abort(c(
        "Endpoint {.val {endpoint_name}} not available in language {.val {language}}.",
        "i" = "Try without specifying language, or check available languages."
      ))
    }
  }

  # Use first match
  endpoint_url <- endpoint_data$url[1]

  cli::cli_inform("Fetching {.val {endpoint_name}} from {.url {endpoint_url}}")

  # Fetch and parse the data
  data <- jsonlite::fromJSON(endpoint_url, flatten = TRUE)

  data
}
