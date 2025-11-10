#' Extract download URLs from feed results
#'
#' @description
#' Helper function to extract producer URLs from a tibble of feeds returned
#' by [feeds()] or [mobdb_search()]. This is useful when you want to
#' get all the source URLs from a set of search results.
#'
#' @param feeds A tibble returned by [feeds()] or [mobdb_search()].
#'
#' @return A character vector of download URLs, with the same length as the
#'   input tibble. Returns `NA` for feeds without a URL.
#'
#' @examples
#' \dontrun{
#' # Search for feeds and get their URLs
#' feeds <- mobdb_search("California")
#' urls <- mobdb_extract_urls(feeds)
#'
#' # Filter and get URLs
#' ca_gtfs <- feeds(subdivision_name = "California", data_type = "gtfs")
#' ca_urls <- mobdb_extract_urls(ca_gtfs)
#' }
#' @export
mobdb_extract_urls <- function(feeds) {
  if (!is.data.frame(feeds)) {
    cli::cli_abort("{.arg feeds} must be a data frame/tibble.")
  }

  if (nrow(feeds) == 0) {
    return(character(0))
  }

  # Check if source_info column exists
  if (!"source_info" %in% names(feeds)) {
    cli::cli_abort(
      "Column {.field source_info} not found in {.arg feeds}.",
      "i" = "Ensure you're passing a tibble from {.fn feeds} or {.fn mobdb_search}."
    )
  }

  # source_info is already a data frame, just extract the producer_url column
  source_info <- feeds$source_info

  if (is.data.frame(source_info) && "producer_url" %in% names(source_info)) {
    # Return the producer_url column directly
    urls <- source_info$producer_url
    # Convert any NULLs or empty strings to NA
    urls[is.null(urls) | urls == ""] <- NA_character_
    as.character(urls)
  } else {
    # Fallback: return NAs
    rep(NA_character_, nrow(feeds))
  }
}

#' Extract location information from search results
#'
#' @description
#' Helper function to extract and unnest location information from search results.
#' The `locations` field in search results is a list of data frames; this function
#' flattens it into a more usable format.
#'
#' @param results A tibble returned by [mobdb_search()].
#' @param unnest Logical. If `TRUE` (default), unnest locations so each feed-location
#'   combination gets its own row. If `FALSE`, return a summary of locations per feed.
#'
#' @return A tibble with location information. If `unnest = TRUE`, each row represents
#'   a feed-location pair. If `unnest = FALSE`, returns one row per feed with
#'   concatenated location strings.
#'
#' @examples
#' \dontrun{
#' # Search for feeds
#' results <- mobdb_search("California")
#'
#' # Get unnested locations (multiple rows per feed if multiple locations)
#' locations <- mobdb_extract_locations(results)
#'
#' # Get summary (one row per feed)
#' location_summary <- mobdb_extract_locations(results, unnest = FALSE)
#' }
#' @export
mobdb_extract_locations <- function(results, unnest = TRUE) {
  if (!is.data.frame(results)) {
    cli::cli_abort("{.arg results} must be a data frame/tibble.")
  }

  if (!"locations" %in% names(results)) {
    cli::cli_warn(
      "Column {.field locations} not found. This function works best with search results."
    )
    return(results)
  }

  if (nrow(results) == 0) {
    return(results)
  }

  if (unnest) {
    # Unnest locations - each feed-location pair gets a row
    result <- tibble::tibble(
      id = character(),
      provider = character(),
      country_code = character(),
      country = character(),
      subdivision_name = character(),
      municipality = character()
    )

    for (i in seq_len(nrow(results))) {
      loc_df <- results$locations[[i]]

      if (is.data.frame(loc_df) && nrow(loc_df) > 0) {
        temp <- tibble::tibble(
          id = results$id[i],
          provider = results$provider[i],
          country_code = loc_df$country_code %||% NA_character_,
          country = loc_df$country %||% NA_character_,
          subdivision_name = loc_df$subdivision_name %||% NA_character_,
          municipality = loc_df$municipality %||% NA_character_
        )
        result <- rbind(result, temp)
      }
    }

    return(result)
  } else {
    # Summary: concatenate locations into strings
    results$location_summary <- vapply(seq_len(nrow(results)), function(i) {
      loc_df <- results$locations[[i]]

      if (is.data.frame(loc_df) && nrow(loc_df) > 0) {
        locs <- paste(
          loc_df$municipality,
          loc_df$subdivision_name,
          loc_df$country_code,
          sep = ", "
        )
        paste(locs, collapse = "; ")
      } else {
        NA_character_
      }
    }, character(1))

    return(results)
  }
}

#' Extract latest dataset information from search results
#'
#' @description
#' Helper function to extract dataset details from search results. The search
#' endpoint includes a `latest_dataset` field with comprehensive information
#' about the most recent dataset, including validation results.
#'
#' @param results A tibble returned by [mobdb_search()].
#'
#' @return A tibble with one row per feed, containing key dataset information:
#'   * `id` - Feed ID
#'   * `dataset_id` - Latest dataset ID
#'   * `hosted_url` - URL to download the latest validated dataset
#'   * `downloaded_at` - When the dataset was captured
#'   * `hash` - Dataset file hash
#'   * `service_date_range_start` - Start of service dates
#'   * `service_date_range_end` - End of service dates
#'   * `total_error` - Number of validation errors (if available)
#'   * `total_warning` - Number of validation warnings (if available)
#'   * Note: Report URLs (html_report, json_report) are only available when
#'     using [mobdb_datasets()], not from search results
#'
#' @examples
#' \dontrun{
#' # Search for feeds
#' results <- mobdb_search("transit")
#'
#' # Get dataset info with validation status
#' datasets <- mobdb_extract_datasets(results)
#'
#' # Filter for feeds with no errors
#' clean_feeds <- datasets |> filter(total_error == 0)
#' }
#' @seealso
#' [get_validation_report()] to get full validation details with report URLs,
#' [mobdb_search()] to search for feeds,
#' [mobdb_datasets()] to get dataset information directly
#'
#' @export
mobdb_extract_datasets <- function(results) {
  if (!is.data.frame(results)) {
    cli::cli_abort("{.arg results} must be a data frame/tibble.")
  }

  if (!"latest_dataset" %in% names(results)) {
    cli::cli_warn(
      "Column {.field latest_dataset} not found. This function works with search results."
    )
    return(tibble::tibble())
  }

  if (nrow(results) == 0) {
    return(tibble::tibble())
  }

  # Extract key fields from latest_dataset
  dataset_info <- tibble::tibble(
    feed_id = results$id,
    provider = results$provider,
    dataset_id = results$latest_dataset$id,
    hosted_url = results$latest_dataset$hosted_url,
    downloaded_at = results$latest_dataset$downloaded_at,
    hash = results$latest_dataset$hash,
    service_date_range_start = results$latest_dataset$service_date_range_start,
    service_date_range_end = results$latest_dataset$service_date_range_end,
    agency_timezone = results$latest_dataset$agency_timezone
  )

  # Add validation report summary if available
  if (is.data.frame(results$latest_dataset$validation_report)) {
    vr <- results$latest_dataset$validation_report
    dataset_info$total_error <- vr$total_error
    dataset_info$total_warning <- vr$total_warning
    dataset_info$total_info <- vr$total_info
    dataset_info$html_report <- vr$url_html
    dataset_info$json_report <- vr$url_json
  }

  dataset_info
}

#' Get GTFS-Schedule validation report for feeds or datasets
#'
#' @description
#' Extract validation report summary from feed/dataset results. MobilityData
#' runs all GTFS Schedule feeds through the canonical GTFS validator, and this
#' function surfaces that validation data to help assess feed quality before
#' downloading.
#'
#' **Note:** This function does *not* support GBFS validation reports at this time as
#' GBFS validation reports are located at a different endpoint and have a different
#' validation criteria.
#'
#' @param data A tibble from [feeds()], [mobdb_datasets()], or [mobdb_search()].
#'
#' @return A tibble with validation summary information:
#'   * `feed_id` or `dataset_id` - Identifier
#'   * `provider` - Provider name (if available)
#'   * `total_error` - Number of validation errors
#'   * `total_warning` - Number of validation warnings
#'   * `total_info` - Number of informational notices
#'   * `html_report` - URL to full HTML validation report
#'   * `json_report` - URL to JSON validation report
#'
#' @examples
#' \dontrun{
#' # Get validation report for feeds from search
#' bart_feeds <- feeds(provider = "Bay Area Rapid Transit")
#' datasets <- mobdb_datasets(bart_feeds$id[1])
#' validation <- get_validation_report(datasets)
#' print(validation)
#'
#' # Check TransLink Vancouver's validation (has known warnings)
#' # Per TransLink's GTFS page "We pass our data through Google's Transit Feed
#' # Validator at the error level, but the data may have warnings left unfixed
#' # in order to conform to TransLink's business rules, such as duplicate stops
#' # with no distance between them."
#' vancouver <- feeds(provider = "TransLink", country_code = "CA", data_type = "gtfs")
#' vancouver_datasets <- mobdb_datasets(vancouver$id[1])
#' validation <- get_validation_report(vancouver_datasets)
#' # Shows: 100,076 errors, 14,322,543 warnings
#' }
#' @seealso
#' [filter_by_validation()] to filter by quality thresholds,
#' [view_validation_report()] to open full HTML/JSON reports in browser,
#' [mobdb_datasets()] to get dataset information with validation data,
#' [mobdb_extract_datasets()] to extract validation from search results
#'
#' @concept validation
#' @export
get_validation_report <- function(data) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame/tibble.")
  }

  if (nrow(data) == 0) {
    cli::cli_warn("Empty data frame provided.")
    return(tibble::tibble())
  }

  # Check if this is dataset data (has validation_report column)
  if ("validation_report" %in% names(data)) {
    # Extract from datasets
    if (!is.data.frame(data$validation_report)) {
      cli::cli_warn("No validation report data found in datasets.")
      return(tibble::tibble())
    }

    vr <- data$validation_report

    result <- tibble::tibble(
      dataset_id = data$id,
      feed_id = if ("feed_id" %in% names(data)) data$feed_id else NA_character_,
      total_error = vr$total_error,
      total_warning = vr$total_warning,
      total_info = vr$total_info,
      unique_error_count = vr$unique_error_count,
      unique_warning_count = vr$unique_warning_count,
      unique_info_count = vr$unique_info_count,
      html_report = vr$url_html,
      json_report = vr$url_json,
      validated_at = vr$validated_at,
      validator_version = vr$validator_version
    )

    return(result)
  }

  # Check if this is search results (has latest_dataset column)
  if ("latest_dataset" %in% names(data)) {
    if (!is.data.frame(data$latest_dataset$validation_report)) {
      cli::cli_warn("No validation report data found in search results.")
      return(tibble::tibble())
    }

    vr <- data$latest_dataset$validation_report

    result <- tibble::tibble(
      feed_id = data$id,
      provider = if ("provider" %in% names(data)) data$provider else NA_character_,
      dataset_id = data$latest_dataset$id,
      total_error = vr$total_error,
      total_warning = vr$total_warning,
      total_info = vr$total_info,
      unique_error_count = vr$unique_error_count,
      unique_warning_count = vr$unique_warning_count,
      unique_info_count = vr$unique_info_count,
      html_report = vr$url_html,
      json_report = vr$url_json,
      validated_at = vr$validated_at,
      validator_version = vr$validator_version
    )

    return(result)
  }

  cli::cli_abort(c(
    "Could not find validation data in provided data frame.",
    "i" = "Pass results from {.fn mobdb_datasets} or {.fn mobdb_search}."
  ))
}

#' View GTFS-Schedule validation report in browser
#'
#' @description
#' Opens the MobilityData validation report for a feed or dataset in your
#' default web browser. The report shows detailed validation results from
#' the canonical GTFS validator.
#'
#' **Note:** This function does *not* support GBFS validation reports at this time as
#' GBFS validation reports are located at a different endpoint and have a different
#' validation criteria.
#' 
#' @param data One of:
#'   * A single-row tibble from [mobdb_datasets()] or [mobdb_search()]
#'   * A character string feed_id (e.g., "mdb-482")
#'   * A character string dataset_id (e.g., "mdb-482-202511010126")
#' @param format Character. Report format: "html" (default) or "json".
#'
#' @return Invisibly returns the URL that was opened.
#'
#' @examples
#' \dontrun{
#' # View validation report for Alexandria DASH
#' view_validation_report("mdb-482")
#'
#' # View report from dataset results
#' datasets <- mobdb_datasets("mdb-482")
#' view_validation_report(datasets)
#'
#' # View JSON report instead
#' view_validation_report("mdb-482", format = "json")
#' }
#' @seealso
#' [get_validation_report()] to extract validation data as a tibble,
#' [filter_by_validation()] to filter by quality thresholds,
#' [mobdb_datasets()] to get dataset information with validation reports
#'
#' @concept validation
#' @export
view_validation_report <- function(data, format = "html") {
  format <- match.arg(format, choices = c("html", "json"))

  # Case 1: Character string (feed_id or dataset_id)
  if (is.character(data) && length(data) == 1) {
    # Fetch latest dataset
    datasets <- mobdb_datasets(data, latest = TRUE)

    if (nrow(datasets) == 0) {
      cli::cli_abort("No datasets found for ID {.val {data}}.")
    }

    if (!is.data.frame(datasets$validation_report)) {
      cli::cli_abort("No validation report available for {.val {data}}.")
    }

    vr <- datasets$validation_report
    url <- if (format == "html") vr$url_html else vr$url_json

    # Case 2: Data frame (from mobdb_datasets or search results)
  } else if (is.data.frame(data)) {
    if (nrow(data) != 1) {
      cli::cli_abort(c(
        "{.arg data} data frame must have exactly one row.",
        "i" = "Use {.code data[1, ]} to select a single feed/dataset."
      ))
    }

    # Check if this is dataset data
    if ("validation_report" %in% names(data)) {
      if (!is.data.frame(data$validation_report)) {
        cli::cli_abort("No validation report available for this dataset.")
      }

      vr <- data$validation_report
      url <- if (format == "html") vr$url_html[1] else vr$url_json[1]

      # Check if this is search results
    } else if ("latest_dataset" %in% names(data)) {
      if (!is.data.frame(data$latest_dataset$validation_report)) {
        cli::cli_abort("No validation report available for this feed.")
      }

      vr <- data$latest_dataset$validation_report
      url <- if (format == "html") vr$url_html[1] else vr$url_json[1]

    } else {
      cli::cli_abort(c(
        "Could not find validation report in provided data frame.",
        "i" = "Pass results from {.fn mobdb_datasets} or {.fn mobdb_search}."
      ))
    }
  } else {
    cli::cli_abort("{.arg data} must be a character string or data frame.")
  }

  if (is.null(url) || is.na(url) || url == "") {
    cli::cli_abort("No validation report URL found.")
  }

  cli::cli_inform("Opening validation report in browser: {.url {url}}")
  utils::browseURL(url)

  invisible(url)
}

#' Filter feeds or datasets by validation quality
#'
#' @description
#' Filter feed or dataset results by validation quality thresholds. This is a
#' convenience wrapper around [get_validation_report()] that returns the original
#' data filtered to only include feeds/datasets meeting your quality criteria.
#'
#' **Note:** This function does *not* support GBFS validation reports at this time as
#' GBFS validation reports are located at a different endpoint and have a different
#' validation criteria.
#'
#' @param data A tibble from [feeds()], [mobdb_datasets()], or [mobdb_search()].
#' @param max_errors Maximum number of validation errors allowed. Use `0` for
#'   error-free feeds. If `NULL` (default), no error filtering is applied.
#' @param max_warnings Maximum number of validation warnings allowed. If `NULL`
#'   (default), no warning filtering is applied.
#' @param max_info Maximum number of informational notices allowed. If `NULL`
#'   (default), no info filtering is applied.
#' @param require_validation Logical. If `TRUE` (default), exclude feeds/datasets
#'   that have no validation data. If `FALSE`, include them in results.
#'
#' @return A filtered version of the input data frame containing only
#'   feeds/datasets that meet the specified quality criteria.
#'
#' @examples
#' \dontrun{
#' # Find all California feeds with zero errors
#' ca_feeds <- feeds(
#'   country_code = "US",
#'   subdivision_name = "California",
#'   data_type = "gtfs"
#' )
#' clean_feeds <- filter_by_validation(ca_feeds, max_errors = 0)
#'
#' # Find feeds with minimal issues
#' quality_feeds <- filter_by_validation(
#'   ca_feeds,
#'   max_errors = 0,
#'   max_warnings = 100
#' )
#'
#' # Get historical BART datasets with improving quality
#' bart <- feeds(provider = "Bay Area Rapid Transit")
#' datasets <- mobdb_datasets(bart$id[1], latest = FALSE)
#' improving <- filter_by_validation(datasets, max_errors = 5, max_warnings = 3000)
#' }
#' @seealso
#' [get_validation_report()] to inspect validation metrics,
#' [view_validation_report()] to view full validation reports
#'
#' @concept validation
#' @export
filter_by_validation <- function(data,
                                 max_errors = NULL,
                                 max_warnings = NULL,
                                 max_info = NULL,
                                 require_validation = TRUE) {
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame/tibble.")
  }

  if (nrow(data) == 0) {
    return(data)
  }

  # Determine data type and extract validation metrics
  has_validation <- FALSE
  validation_errors <- NULL
  validation_warnings <- NULL
  validation_info <- NULL

  # Check if this is dataset data (has validation_report column)
  if ("validation_report" %in% names(data)) {
    if (is.data.frame(data$validation_report)) {
      has_validation <- TRUE
      validation_errors <- data$validation_report$total_error
      validation_warnings <- data$validation_report$total_warning
      validation_info <- data$validation_report$total_info
    }
  }

  # Check if this is search results (has latest_dataset column)
  if ("latest_dataset" %in% names(data)) {
    if (is.data.frame(data$latest_dataset$validation_report)) {
      has_validation <- TRUE
      validation_errors <- data$latest_dataset$validation_report$total_error
      validation_warnings <- data$latest_dataset$validation_report$total_warning
      validation_info <- data$latest_dataset$validation_report$total_info
    }
  }

  if (!has_validation) {
    if (require_validation) {
      cli::cli_warn(c(
        "No validation data found in provided data frame.",
        "i" = "Set {.code require_validation = FALSE} to include feeds without validation data."
      ))
      return(data[0, ])
    } else {
      return(data)
    }
  }

  # Build filter mask
  keep_mask <- rep(TRUE, nrow(data))

  # Apply filters if specified
  if (!is.null(max_errors)) {
    if (!is.numeric(max_errors) || max_errors < 0) {
      cli::cli_abort("{.arg max_errors} must be a non-negative number.")
    }
    keep_mask <- keep_mask & (validation_errors <= max_errors)
  }

  if (!is.null(max_warnings)) {
    if (!is.numeric(max_warnings) || max_warnings < 0) {
      cli::cli_abort("{.arg max_warnings} must be a non-negative number.")
    }
    keep_mask <- keep_mask & (validation_warnings <= max_warnings)
  }

  if (!is.null(max_info)) {
    if (!is.numeric(max_info) || max_info < 0) {
      cli::cli_abort("{.arg max_info} must be a non-negative number.")
    }
    keep_mask <- keep_mask & (validation_info <= max_info)
  }

  # Apply filter
  result <- data[keep_mask, ]

  # Inform user of results
  n_filtered <- nrow(result)
  n_total <- nrow(data)

  if (n_filtered == 0) {
    cli::cli_warn(c(
      "No feeds/datasets match the specified quality criteria.",
      "i" = "Try relaxing the thresholds or check validation status with {.fn get_validation_report}."
    ))
  } else if (n_filtered < n_total) {
    cli::cli_inform("Filtered to {n_filtered} of {n_total} item{?s} matching quality criteria.")
  }

  result
}
