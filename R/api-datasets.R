#' Get datasets for a feed
#'
#' @description
#' Retrieve information about available datasets (historical versions) for
#' a specific feed. Each dataset represents a snapshot of the feed at a
#' particular point in time.
#'
#' @param feed_id Character. The unique identifier for the feed.
#' @param latest Logical. If `TRUE` (default), return only the most recent dataset.
#'   If `FALSE`, return all available datasets.
#'
#' @return A tibble containing dataset information including:
#'   * `id` - Dataset identifier
#'   * `feed_id` - Associated feed ID
#'   * `downloaded_at` - Timestamp when dataset was captured
#'   * `hash` - Hash of the dataset file
#'   * `download_url` - URL to download this specific dataset version
#'   * Additional metadata columns
#'
#' @examples
#' \dontrun{
#' # Get latest dataset for a feed
#' latest <- mobdb_datasets("mdb-123")
#'
#' # Get all historical datasets
#' all_versions <- mobdb_datasets("mdb-123", latest = FALSE)
#' }
#'
#' @export
mobdb_datasets <- function(feed_id, latest = TRUE) {
  if (!is.character(feed_id) || length(feed_id) != 1) {
    cli::cli_abort("{.arg feed_id} must be a single character string.")
  }
  
  # Build query parameters
  query_params <- build_query(
    feed_id = feed_id,
    latest = if (latest) "true" else NULL
  )
  
  # Make request
  req <- mobdb_request("datasets") |>
    httr2::req_url_query(!!!query_params)
  
  resp <- httr2::req_perform(req)
  check_rate_limit(resp)
  
  mobdb_parse_response(resp)
}

#' Get details for a specific dataset
#'
#' @description
#' Retrieve detailed information about a single dataset by its ID.
#'
#' @param dataset_id Character. The unique identifier for the dataset.
#'
#' @return A list containing detailed dataset information.
#'
#' @examples
#' \dontrun{
#' # Get details for a specific dataset
#' dataset_info <- mobdb_get_dataset("dataset-456")
#' }
#'
#' @export
mobdb_get_dataset <- function(dataset_id) {
  if (!is.character(dataset_id) || length(dataset_id) != 1) {
    cli::cli_abort("{.arg dataset_id} must be a single character string.")
  }
  
  req <- mobdb_request("datasets") |>
    httr2::req_url_path_append(dataset_id)
  
  resp <- httr2::req_perform(req)
  check_rate_limit(resp)
  
  httr2::resp_body_json(resp)
}
