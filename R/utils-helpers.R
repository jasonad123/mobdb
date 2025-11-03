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
