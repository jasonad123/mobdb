#' Find GTFS Schedule feeds by location
#'
#' @description
#' Discover GTFS Schedule feeds whose geographic coverage overlaps with or
#' is contained within a specified bounding box. This function is designed
#' for feed discovery based on geographic location.
#'
#' **Important:** This function only works with GTFS Schedule feeds because
#' bounding box data is derived from the feed's latest dataset.
#'
#' @param bbox A numeric vector of length 4 specifying the bounding box as
#'   `c(min_lon, min_lat, max_lon, max_lat)` in WGS84 coordinates
#'   (EPSG:4326). Alternatively, an `sf` bbox object can be provided if
#'   `sf` is installed.
#' @param filter_method A string. Method for filtering feeds by bounding box:
#'   * `"completely_enclosed"` (default) - Feeds whose coverage is fully
#'     inside the specified bounding box
#'   * `"partially_enclosed"` - Feeds whose coverage overlaps with the box
#'   * `"disjoint"` - Feeds whose coverage is completely outside the box
#' @param provider A string. Filter by provider/agency name (partial match).
#' @param country_code A string. Two-letter ISO country code (e.g., "US", "CA").
#' @param subdivision_name A string. State, province, or region name.
#' @param municipality A string. City or municipality name.
#' @param status A string. Feed status: "active", "deprecated", "inactive",
#'   "development", or "future".
#' @param official A logical. If `TRUE`, only return official feeds.
#'   If `FALSE`, only return unofficial feeds. If `NULL` (default),
#'   return all feeds regardless of official status.
#' @param limit An integer. Maximum number of results to return (default: 100).
#' @param offset An integer. Number of results to skip for pagination (default: 0).
#' @param use_cache A logical. If `TRUE` (default), use cached results if available.
#'   If `FALSE`, always fetch fresh data from the API. Cached data expires after 1 hour.
#'
#' @return A tibble containing GTFS Schedule feed information with columns including:
#'   * `id` - Unique feed identifier
#'   * `data_type` - Always "gtfs" for this function
#'   * `provider` - Transit agency/provider name
#'   * `status` - Feed status
#'   * `source_info` - Data frame containing download URLs and auth info
#'   * `latest_dataset` - Information about the most recent dataset including
#'     bounding box coordinates
#'   * Additional metadata columns
#'
#' @examples
#' \dontrun{
#' # Find feeds in the San Francisco Bay Area
#' # Bounding box: c(min_lon, min_lat, max_lon, max_lat)
#' bay_area_feeds <- feeds_bbox(
#'   bbox = c(-122.5, 37.2, -121.8, 38.0),
#'   filter_method = "partially_enclosed"
#' )
#'
#' # Find feeds completely within Los Angeles County
#' la_feeds <- feeds_bbox(
#'   bbox = c(-118.9, 33.7, -118.0, 34.8),
#'   filter_method = "completely_enclosed",
#'   status = "active"
#' )
#'
#' # Use with sf package (if installed)
#' library(sf)
#' # Create bbox from sf object
#' bbox_sf <- st_bbox(c(xmin = -122.5, ymin = 37.2,
#'                      xmax = -121.8, ymax = 38.0),
#'                    crs = 4326)
#' feeds <- feeds_bbox(bbox = bbox_sf)
#' }
#' @export
feeds_bbox <- function(bbox,
                       filter_method = "completely_enclosed",
                       provider = NULL,
                       country_code = NULL,
                       subdivision_name = NULL,
                       municipality = NULL,
                       status = NULL,
                       official = NULL,
                       limit = 100,
                       offset = 0,
                       use_cache = TRUE) {

  # Validate and extract bounding box coordinates
  bbox_coords <- extract_bbox(bbox)

  # Check cache first
  if (use_cache) {
    cache_key <- generate_cache_key(
      min_lon = bbox_coords$min_lon,
      min_lat = bbox_coords$min_lat,
      max_lon = bbox_coords$max_lon,
      max_lat = bbox_coords$max_lat,
      filter_method = filter_method,
      provider = provider,
      country_code = country_code,
      subdivision_name = subdivision_name,
      municipality = municipality,
      status = status,
      official = official,
      limit = limit,
      offset = offset,
      prefix = "feeds_bbox"
    )
    cached <- read_from_cache(cache_key, max_age = get_cache_ttl("feeds"))
    if (!is.null(cached)) return(cached)
  }

  # Validate filter_method
  filter_method <- match.arg(
    filter_method,
    c("completely_enclosed", "partially_enclosed", "disjoint")
  )

  # Validate status if provided
  if (!is.null(status)) {
    status <- match.arg(status, c("active", "deprecated", "inactive", "development", "future"))
  }

  # Build query parameters
  # API expects: dataset_latitudes=min,max and dataset_longitudes=min,max
  query_params <- build_query(
    provider = provider,
    country_code = country_code,
    subdivision_name = subdivision_name,
    municipality = municipality,
    status = status,
    official = official,
    dataset_latitudes = paste0(bbox_coords$min_lat, ",", bbox_coords$max_lat),
    dataset_longitudes = paste0(bbox_coords$min_lon, ",", bbox_coords$max_lon),
    bounding_filter_method = filter_method,
    limit = limit,
    offset = offset
  )

  # Make request to gtfs_feeds endpoint
  req <- mobdb_request("gtfs_feeds")

  if (length(query_params) > 0) {
    req <- httr2::req_url_query(req, !!!query_params)
  }

  resp <- httr2::req_perform(req)
  check_rate_limit(resp)

  result <- mobdb_parse_response(resp)

  # Post-filter for official status if needed (API may return NA values)
  if (!is.null(official) && nrow(result) > 0) {
    if (official) {
      result <- result[!is.na(result$official) & result$official == TRUE, ]
    } else {
      result <- result[!is.na(result$official) & result$official == FALSE, ]
    }
  }

  # Write to cache
  if (use_cache) {
    write_to_cache(result, cache_key)
  }

  result
}

#' Extract bounding box coordinates from various formats
#'
#' @description
#' Internal helper to extract bounding box coordinates from a numeric vector
#' or sf bbox object.
#'
#' @param bbox A numeric vector of length 4 as c(min_lon, min_lat, max_lon, max_lat),
#'   or an sf bbox object.
#'
#' @return A list with elements: min_lon, min_lat, max_lon, max_lat
#'
#' @keywords internal
#' @noRd
extract_bbox <- function(bbox) {
  # Check if sf is available and if bbox is an sf bbox object
  if (inherits(bbox, "bbox")) {
    # sf bbox object
    if (!requireNamespace("sf", quietly = TRUE)) {
      cli::cli_abort(c(
        "The {.pkg sf} package is required to use sf bbox objects.",
        "i" = "Install it with: {.code install.packages(\"sf\")}"
      ))
    }

    # sf bbox has names: xmin, ymin, xmax, ymax
    return(list(
      min_lon = unname(bbox["xmin"]),
      min_lat = unname(bbox["ymin"]),
      max_lon = unname(bbox["xmax"]),
      max_lat = unname(bbox["ymax"])
    ))
  }

  # Numeric vector
  if (!is.numeric(bbox) || length(bbox) != 4) {
    cli::cli_abort(c(
      "{.arg bbox} must be a numeric vector of length 4 or an sf bbox object.",
      "i" = "Provide as: {.code c(min_lon, min_lat, max_lon, max_lat)}",
      "x" = "You provided a {.cls {class(bbox)}} of length {length(bbox)}"
    ))
  }

  # Validate coordinate ranges
  min_lon <- bbox[1]
  min_lat <- bbox[2]
  max_lon <- bbox[3]
  max_lat <- bbox[4]

  if (min_lat < -90 || max_lat > 90) {
    cli::cli_abort(c(
      "Latitude values must be between -90 and 90.",
      "x" = "You provided: min_lat = {min_lat}, max_lat = {max_lat}"
    ))
  }

  if (min_lon < -180 || max_lon > 180) {
    cli::cli_abort(c(
      "Longitude values must be between -180 and 180.",
      "x" = "You provided: min_lon = {min_lon}, max_lon = {max_lon}"
    ))
  }

  if (min_lon >= max_lon) {
    cli::cli_abort(c(
      "min_lon must be less than max_lon.",
      "x" = "You provided: min_lon = {min_lon}, max_lon = {max_lon}"
    ))
  }

  if (min_lat >= max_lat) {
    cli::cli_abort(c(
      "min_lat must be less than max_lat.",
      "x" = "You provided: min_lat = {min_lat}, max_lat = {max_lat}"
    ))
  }

  list(
    min_lon = min_lon,
    min_lat = min_lat,
    max_lon = max_lon,
    max_lat = max_lat
  )
}
