#' Extract download URLs from feed results
#'
#' @description
#' Helper function to extract producer URLs from a tibble of feeds returned
#' by [mobdb_feeds()] or [mobdb_search()]. This is useful when you want to
#' get all the download URLs from a set of search results.
#'
#' @param feeds A tibble returned by [mobdb_feeds()] or [mobdb_search()].
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
#' ca_gtfs <- mobdb_feeds(subdivision_name = "California", data_type = "gtfs")
#' ca_urls <- mobdb_extract_urls(ca_gtfs)
#' }
#'
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
      "i" = "Ensure you're passing a tibble from {.fn mobdb_feeds} or {.fn mobdb_search}."
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
#'
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
#'   * `total_error` - Number of validation errors
#'   * `total_warning` - Number of validation warnings
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
  }
  
  dataset_info
}
